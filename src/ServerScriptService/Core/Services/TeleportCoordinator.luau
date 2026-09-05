--!strict
-- Server-authoritative Base/Dungeon teleport orchestration. TeleportData contains routing IDs only;
-- profile value, loot, revive and eligibility authority stays in DataStore/MemoryStore services.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonDefinitions = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("DungeonDefinitions")
)

local TeleportCoordinator = {}
TeleportCoordinator.__index = TeleportCoordinator
TeleportCoordinator.MAX_TELEPORT_ATTEMPTS = 2

local function response(ok: boolean, reason: string?, session: any?): any
    return {
        ok = ok,
        reason = reason,
        session = session,
    }
end

local function user_id_from_player(player: any): number?
    local user_id = player and player.UserId
    if type(user_id) ~= "number" or user_id <= 0 or user_id % 1 ~= 0 then
        return nil
    end
    return user_id
end

local function known_dungeon(dungeon_id: string): boolean
    return dungeon_id == DungeonDefinitions.TEST_DUNGEON.Id
end

local function is_retryable(teleport_result: any): boolean
    local name = if typeof(teleport_result) == "EnumItem" then teleport_result.Name else tostring(teleport_result)
    return name == "Failure" or name == "Flooded"
end

function TeleportCoordinator.new(
    teleport_adapter: any,
    profile_service: any,
    lease_service: any,
    session_service: any
): any
    assert(teleport_adapter ~= nil, "TeleportCoordinator requires a teleport adapter.")
    assert(profile_service ~= nil, "TeleportCoordinator requires ProfileService.")
    assert(lease_service ~= nil, "TeleportCoordinator requires ProfileLeaseService.")
    assert(session_service ~= nil, "TeleportCoordinator requires DungeonSessionService.")

    local self = setmetatable({}, TeleportCoordinator)
    self._teleport = teleport_adapter
    self._profiles = profile_service
    self._leases = lease_service
    self._sessions = session_service
    self._pending = {}

    if type(teleport_adapter.connect_init_failed) == "function" then
        self._init_failed_connection = teleport_adapter:connect_init_failed(function(
            player: any,
            teleport_result: any,
            error_message: string,
            _place_id: number,
            _teleport_options: any
        )
            self:_handle_init_failed(player, teleport_result, error_message)
        end)
    end

    return self
end

function TeleportCoordinator:is_pending(user_id: number): boolean
    return self._pending[user_id] ~= nil
end

function TeleportCoordinator:acknowledge_departure(user_id: number)
    self._pending[user_id] = nil
end

function TeleportCoordinator:_cancel_pending(user_id: number, reason: string)
    local pending = self._pending[user_id]
    if not pending then
        return
    end

    self._leases:cancel_handoff(user_id, pending.nonce)
    self._pending[user_id] = nil

    if pending.fail_new_session == true then
        self._sessions:mark_failed(pending.session_id, reason)
    end
end

function TeleportCoordinator:_handle_init_failed(player: any, teleport_result: any, error_message: string)
    local user_id = user_id_from_player(player)
    if not user_id then
        return
    end
    local pending = self._pending[user_id]
    if not pending then
        return
    end

    if is_retryable(teleport_result) and pending.attempts < TeleportCoordinator.MAX_TELEPORT_ATTEMPTS then
        pending.attempts += 1
        task.defer(function()
            local ok, retry_error = self._teleport:teleport(
                pending.place_id,
                {pending.player},
                pending.reserved_code,
                pending.teleport_data
            )
            if not ok then
                self:_cancel_pending(user_id, retry_error or "TeleportRetryFailed")
            end
        end)
        return
    end

    self:_cancel_pending(user_id, error_message ~= "" and error_message or "TeleportInitFailed")
end

function TeleportCoordinator:_prepare_handoffs(
    players: {any},
    session: any,
    destination_kind: string,
    place_id: number,
    reserved_code: string?,
    teleport_data: any,
    fail_new_session: boolean
): (boolean, string?)
    local prepared = {}

    for _, player in ipairs(players) do
        local user_id = user_id_from_player(player)
        if not user_id then
            for _, prepared_user_id in ipairs(prepared) do
                self:_cancel_pending(prepared_user_id, "InvalidPlayer")
            end
            return false, "InvalidPlayer"
        end

        local saved, save_error = self._profiles:save(user_id, "PreTeleportHandoff")
        if not saved then
            for _, prepared_user_id in ipairs(prepared) do
                self:_cancel_pending(prepared_user_id, save_error or "ProfileSaveFailed")
            end
            return false, save_error or "ProfileSaveFailed"
        end

        local nonce = HttpService:GenerateGUID(false)
        local handoff = self._leases:begin_handoff(user_id, nonce, destination_kind)
        if not handoff or handoff.ok ~= true then
            for _, prepared_user_id in ipairs(prepared) do
                self:_cancel_pending(prepared_user_id, handoff and handoff.reason or "HandoffFailed")
            end
            return false, if handoff and handoff.reason then handoff.reason else "HandoffFailed"
        end

        self._pending[user_id] = {
            player = player,
            nonce = nonce,
            session_id = session.SessionId,
            place_id = place_id,
            reserved_code = reserved_code,
            teleport_data = teleport_data,
            attempts = 1,
            fail_new_session = fail_new_session,
        }

        local nonce_result = self._sessions:set_handoff_nonce(session.SessionId, user_id, nonce)
        if not nonce_result or nonce_result.ok ~= true then
            self:_cancel_pending(user_id, nonce_result and nonce_result.reason or "SessionNonceFailed")
            for _, prepared_user_id in ipairs(prepared) do
                self:_cancel_pending(prepared_user_id, "SessionNonceFailed")
            end
            return false, if nonce_result and nonce_result.reason then nonce_result.reason else "SessionNonceFailed"
        end

        table.insert(prepared, user_id)
    end

    return true, nil
end

function TeleportCoordinator:_teleport_prepared(players: {any}, session: any, place_id: number, reserved_code: string?): any
    local teleport_data = {
        SessionId = session.SessionId,
        DungeonId = session.DungeonId,
    }

    local ok, teleport_error = self._teleport:teleport(place_id, players, reserved_code, teleport_data)
    if not ok then
        for _, player in ipairs(players) do
            local user_id = user_id_from_player(player)
            if user_id then
                self:_cancel_pending(user_id, teleport_error or "TeleportFailed")
            end
        end
        return response(false, teleport_error or "TeleportFailed", session)
    end

    return response(true, nil, session)
end

function TeleportCoordinator:start_dungeon(players: {any}, dungeon_id: string, dungeon_place_id: number): any
    if not known_dungeon(dungeon_id) then
        return response(false, "UnknownDungeon")
    end
    if type(dungeon_place_id) ~= "number" or dungeon_place_id <= 0 then
        return response(false, "InvalidDungeonPlaceId")
    end
    if #players < 1 or #players > DungeonDefinitions.TEST_DUNGEON.MaxPlayers then
        return response(false, "PlayerCountOutOfRange")
    end

    local member_user_ids = {}
    for _, player in ipairs(players) do
        local user_id = user_id_from_player(player)
        if not user_id then
            return response(false, "InvalidPlayer")
        end
        if self:is_pending(user_id) then
            return response(false, "TeleportAlreadyPending")
        end
        local existing = self._sessions:get_for_user(user_id)
        if existing and (existing.State == "Creating" or existing.State == "Active") then
            return response(false, "ActiveSessionExists", existing)
        end
        table.insert(member_user_ids, user_id)
    end

    local reserved_ok, reserved_or_error = self._teleport:reserve_server(dungeon_place_id)
    if not reserved_ok then
        return response(false, reserved_or_error or "ReserveServerFailed")
    end
    local reserved_code = reserved_or_error

    local session, session_error = self._sessions:create(
        dungeon_id,
        member_user_ids,
        game.PlaceId,
        reserved_code
    )
    if not session then
        return response(false, session_error or "SessionCreateFailed")
    end

    local teleport_data = {SessionId = session.SessionId, DungeonId = session.DungeonId}
    local prepared, prepare_error = self:_prepare_handoffs(
        players,
        session,
        "Dungeon",
        dungeon_place_id,
        reserved_code,
        teleport_data,
        true
    )
    if not prepared then
        self._sessions:mark_failed(session.SessionId, prepare_error or "HandoffPrepareFailed")
        return response(false, prepare_error or "HandoffPrepareFailed", session)
    end

    return self:_teleport_prepared(players, session, dungeon_place_id, reserved_code)
end

function TeleportCoordinator:rejoin_session(player: any, session_record: any, dungeon_place_id: number): any
    local user_id = user_id_from_player(player)
    if not user_id then
        return response(false, "InvalidPlayer")
    end
    if self:is_pending(user_id) then
        return response(false, "TeleportAlreadyPending")
    end
    if type(session_record) ~= "table"
        or (session_record.State ~= "Creating" and session_record.State ~= "Active")
        or type(session_record.ReservedAccessCode) ~= "string"
        or session_record.ReservedAccessCode == ""
        or not session_record.Members
        or not session_record.Members[tostring(user_id)]
    then
        return response(false, "SessionNotRecoverable")
    end
    if type(dungeon_place_id) ~= "number" or dungeon_place_id <= 0 then
        return response(false, "InvalidDungeonPlaceId")
    end

    local teleport_data = {SessionId = session_record.SessionId, DungeonId = session_record.DungeonId}
    local prepared, prepare_error = self:_prepare_handoffs(
        {player},
        session_record,
        "Dungeon",
        dungeon_place_id,
        session_record.ReservedAccessCode,
        teleport_data,
        false
    )
    if not prepared then
        return response(false, prepare_error or "HandoffPrepareFailed", session_record)
    end

    return self:_teleport_prepared({player}, session_record, dungeon_place_id, session_record.ReservedAccessCode)
end

function TeleportCoordinator:return_to_base(players: {any}, session_record: any): any
    if type(session_record) ~= "table"
        or type(session_record.ReturnPlaceId) ~= "number"
        or session_record.ReturnPlaceId <= 0
    then
        return response(false, "InvalidReturnDestination")
    end

    local teleport_data = {SessionId = session_record.SessionId, DungeonId = session_record.DungeonId}
    local prepared, prepare_error = self:_prepare_handoffs(
        players,
        session_record,
        "Base",
        session_record.ReturnPlaceId,
        nil,
        teleport_data,
        false
    )
    if not prepared then
        return response(false, prepare_error or "HandoffPrepareFailed", session_record)
    end

    return self:_teleport_prepared(players, session_record, session_record.ReturnPlaceId, nil)
end

return table.freeze(TeleportCoordinator)
