--!strict
-- Short-lived authoritative dungeon-run state shared across Base and Dungeon Places.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReviveConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ReviveConfig")
)

local DungeonSessionService = {}
DungeonSessionService.__index = DungeonSessionService

DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS = 90
DungeonSessionService.RECONNECT_GRACE_SECONDS = ReviveConfig.RECONNECT_GRACE_SECONDS
DungeonSessionService.STORAGE_TTL_SECONDS = 7200
DungeonSessionService.TERMINAL_TTL_SECONDS = 1200

local VALID_MEMBER_MODES: {[string]: boolean} = table.freeze({
    Active = true,
    Dead = true,
    Reviving = true,
    Spectating = true,
})

local function deep_clone(value: any): any
    if type(value) ~= "table" then
        return value
    end

    local cloned = {}
    for key, child in pairs(value) do
        cloned[deep_clone(key)] = deep_clone(child)
    end
    return cloned
end

local function session_key(session_id: string): string
    return "Session_" .. session_id
end

local function member_key(user_id: number): string
    return tostring(user_id)
end

local function member_session_index_key(user_id: number): string
    return "MemberSession_" .. tostring(user_id)
end

local function is_terminal(state: string): boolean
    return state == "Complete" or state == "Failed" or state == "Expired"
end

local function any_connected(session: any): boolean
    for _, member in pairs(session.Members) do
        if member.Connected == true then
            return true
        end
    end
    return false
end

local function operation(ok: boolean, reason: string?, session: any?): any
    return {
        ok = ok,
        reason = reason,
        session = session,
    }
end

local function validate_members(member_user_ids: {number}): string?
    if #member_user_ids < 1 or #member_user_ids > 4 then
        return "MemberCountOutOfRange"
    end

    local seen: {[number]: boolean} = {}
    for _, user_id in ipairs(member_user_ids) do
        if type(user_id) ~= "number" or user_id <= 0 or user_id % 1 ~= 0 then
            return "InvalidMemberUserId"
        end
        if seen[user_id] then
            return "DuplicateMember"
        end
        seen[user_id] = true
    end
    return nil
end

function DungeonSessionService.new(map_adapter: any, clock: (() -> number)?): any
    assert(map_adapter ~= nil, "DungeonSessionService requires a map adapter.")

    local self = setmetatable({}, DungeonSessionService)
    self._map = map_adapter
    self._clock = clock or os.time
    return self
end

function DungeonSessionService:_update(session_id: string, transform: (any, number) -> (any, any), storage_ttl: number?): any
    if type(session_id) ~= "string" or session_id == "" then
        return operation(false, "InvalidSessionId")
    end

    local now = self._clock()
    local operation_result = operation(false, "SessionUpdateFailed")
    local stored, store_error = self._map:update(session_key(session_id), function(old_session: any)
        local new_session, new_result = transform(old_session, now)
        operation_result = new_result
        return new_session
    end, storage_ttl or DungeonSessionService.STORAGE_TTL_SECONDS)

    if stored == nil then
        return operation(false, store_error or "SessionStoreFailed")
    end
    if operation_result.ok then
        operation_result.session = deep_clone(stored)
    end
    return operation_result
end

function DungeonSessionService:create(
    dungeon_id: string,
    member_user_ids: {number},
    return_place_id: number,
    reserved_code: string
): (any?, string?)
    if type(dungeon_id) ~= "string" or dungeon_id == "" then
        return nil, "InvalidDungeonId"
    end
    local member_error = validate_members(member_user_ids)
    if member_error then
        return nil, member_error
    end
    if type(return_place_id) ~= "number" or return_place_id < 0 then
        return nil, "InvalidReturnPlaceId"
    end
    if type(reserved_code) ~= "string" or reserved_code == "" then
        return nil, "InvalidReservedCode"
    end

    for _, user_id in ipairs(member_user_ids) do
        local existing = self:get_for_user(user_id)
        if existing and (existing.State == "Creating" or existing.State == "Active") then
            return nil, "MemberAlreadyInActiveSession"
        end
    end

    local now = self._clock()
    local members: {[string]: any} = {}
    for _, user_id in ipairs(member_user_ids) do
        members[member_key(user_id)] = {
            UserId = user_id,
            Connected = false,
            Mode = "Active",
            FreeReviveUsed = false,
            PaidReviveCount = 0,
            Abandoned = false,
        }
    end

    for _attempt = 1, 3 do
        local session_id = HttpService:GenerateGUID(false)
        local created = false
        local record = {
            SessionId = session_id,
            DungeonId = dungeon_id,
            DungeonVersion = 1,
            ReservedAccessCode = reserved_code,
            ReturnPlaceId = return_place_id,
            MemberUserIds = deep_clone(member_user_ids),
            Members = deep_clone(members),
            State = "Creating",
            Checkpoint = {
                Id = "Entrance",
                Sequence = 0,
            },
            CurrentRoomId = "Entrance",
            CurrentEncounterId = "",
            CreatedAt = now,
            UpdatedAt = now,
            ExpiresAt = now + DungeonSessionService.RECONNECT_GRACE_SECONDS,
        }

        local stored, store_error = self._map:update(session_key(session_id), function(old_session: any)
            if old_session ~= nil then
                return old_session
            end
            created = true
            return record
        end, DungeonSessionService.STORAGE_TTL_SECONDS)

        if stored == nil then
            return nil, store_error or "SessionStoreFailed"
        end
        if created then
            for _, user_id in ipairs(member_user_ids) do
                local indexed, index_error = self._map:update(member_session_index_key(user_id), function(_old_index: any)
                    return {
                        SessionId = session_id,
                        DungeonId = dungeon_id,
                        UpdatedAt = now,
                    }
                end, DungeonSessionService.STORAGE_TTL_SECONDS)
                if indexed == nil then
                    self:mark_failed(session_id, "SessionIndexFailed")
                    return nil, index_error or "SessionIndexFailed"
                end
            end
            return deep_clone(stored), nil
        end
    end

    return nil, "SessionIdCollision"
end

function DungeonSessionService:get(session_id: string): any?
    if type(session_id) ~= "string" or session_id == "" then
        return nil
    end
    local stored = self._map:get(session_key(session_id))
    return deep_clone(stored)
end

function DungeonSessionService:get_for_user(user_id: number): any?
    if type(user_id) ~= "number" or user_id <= 0 or user_id % 1 ~= 0 then
        return nil
    end

    local index = self._map:get(member_session_index_key(user_id))
    if type(index) ~= "table" or type(index.SessionId) ~= "string" then
        return nil
    end

    local session = self:get(index.SessionId)
    if not session then
        self._map:remove(member_session_index_key(user_id))
        return nil
    end
    return session
end

function DungeonSessionService:set_handoff_nonce(session_id: string, user_id: number, nonce: string): any
    if type(nonce) ~= "string" or nonce == "" then
        return operation(false, "InvalidNonce")
    end

    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State == "Expired" then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end

        if type(session.HandoffNonces) ~= "table" then
            session.HandoffNonces = {}
        end
        session.HandoffNonces[member_key(user_id)] = nonce
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:get_handoff_nonce(session_id: string, user_id: number): string?
    local session = self:get(session_id)
    if not session or type(session.HandoffNonces) ~= "table" then
        return nil
    end
    local nonce = session.HandoffNonces[member_key(user_id)]
    return if type(nonce) == "string" then nonce else nil
end

function DungeonSessionService:clear_handoff_nonce(session_id: string, user_id: number): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if not session.Members[member_key(user_id)] then
            return session, operation(false, "NotMember")
        end
        if type(session.HandoffNonces) == "table" then
            session.HandoffNonces[member_key(user_id)] = nil
        end
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:mark_connected(session_id: string, user_id: number): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if is_terminal(session.State) then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end

        member.Connected = true
        member.LastConnectedAt = now
        if session.State == "Creating" then
            session.State = "Active"
        end
        session.UpdatedAt = now
        session.ExpiresAt = now + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:mark_disconnected(session_id: string, user_id: number): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if is_terminal(session.State) then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end

        member.Connected = false
        member.LastDisconnectedAt = now
        session.UpdatedAt = now
        if any_connected(session) then
            session.ExpiresAt = now + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
        else
            session.ExpiresAt = now + DungeonSessionService.RECONNECT_GRACE_SECONDS
        end
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:refresh(session_id: string): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        if not any_connected(session) then
            return session, operation(false, "NoConnectedMembers")
        end

        session.UpdatedAt = now
        session.ExpiresAt = now + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:set_member_mode(session_id: string, user_id: number, mode: string): any
    if VALID_MEMBER_MODES[mode] ~= true then
        return operation(false, "InvalidMemberMode")
    end

    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end

        member.Mode = mode
        session.UpdatedAt = now
        if any_connected(session) then
            session.ExpiresAt = now + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
        end
        return session, operation(true, nil)
    end)
end



function DungeonSessionService:set_member_completion_eligibility(
    session_id: string,
    user_id: number,
    eligible: boolean
): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        local member = session.Members[member_key(user_id)]
        if not member then return session, operation(false, "NotMember") end
        member.CompletionEligibleBeforeDeath = eligible == true
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:consume_free_revive(session_id: string, user_id: number): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end
        if member.Mode ~= "Dead" and member.Mode ~= "Spectating" then
            return session, operation(false, "MemberNotDead")
        end
        if member.FreeReviveUsed == true then
            return session, operation(false, "FreeReviveAlreadyUsed")
        end

        member.FreeReviveUsed = true
        member.Mode = "Reviving"
        session.WipeDecisionEndsAt = nil
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:grant_paid_revive_once(
    session_id: string,
    user_id: number,
    purchase_id: string
): any
    if type(purchase_id) ~= "string" or purchase_id == "" then
        return operation(false, "InvalidPurchaseId")
    end

    local already_applied = false
    local result = self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        local member = session.Members[member_key(user_id)]
        if not member then
            return session, operation(false, "NotMember")
        end

        if type(session.ProcessedRevivePurchases) ~= "table" then
            session.ProcessedRevivePurchases = {}
        end
        local existing = session.ProcessedRevivePurchases[purchase_id]
        if existing then
            already_applied = true
            return session, operation(true, nil)
        end

        if member.FreeReviveUsed ~= true then
            return session, operation(false, "FreeReviveStillAvailable")
        end
        if member.Mode ~= "Dead" and member.Mode ~= "Spectating" then
            return session, operation(false, "MemberNotDead")
        end

        member.PaidReviveCount = (member.PaidReviveCount or 0) + 1
        member.Mode = "Active"
        session.ProcessedRevivePurchases[purchase_id] = {
            UserId = user_id,
            AppliedAt = now,
            PaidReviveNumber = member.PaidReviveCount,
        }
        session.WipeDecisionEndsAt = nil
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)

    result.already_applied = already_applied
    return result
end

function DungeonSessionService:abandon_member(
    session_id: string,
    user_id: number
): any
    local updated = self:_update(
        session_id,
        function(session: any, now: number)
            if type(session) ~= "table" then
                return {
                    State = "Expired",
                    SessionId = session_id,
                    Members = {},
                    UpdatedAt = now,
                    ExpiresAt = now,
                }, operation(false, "SessionNotFound")
            end

            local member = session.Members[member_key(user_id)]
            if not member then
                return session, operation(false, "NotMember")
            end
            if member.Abandoned == true then
                return session, operation(true, nil)
            end
            if session.State ~= "Active" then
                return session, operation(false, "InvalidTransition")
            end

            member.Abandoned = true
            member.Connected = false
            member.Mode = "Spectating"
            member.LastDisconnectedAt = now

            local remaining_member = false
            for _, candidate in pairs(session.Members) do
                if candidate.Abandoned ~= true then
                    remaining_member = true
                    break
                end
            end

            if remaining_member then
                session.UpdatedAt = now
                if any_connected(session) then
                    session.ExpiresAt = now
                        + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
                else
                    session.ExpiresAt = now
                        + DungeonSessionService.RECONNECT_GRACE_SECONDS
                end
            else
                session.State = "Failed"
                session.FailureReason = "AllMembersAbandoned"
                session.FailedAt = now
                session.UpdatedAt = now
                session.ExpiresAt = now
                    + DungeonSessionService.RECONNECT_GRACE_SECONDS
            end

            return session, operation(true, nil)
        end
    )

    if not updated.ok then
        return updated
    end

    local removed, remove_error = self._map:remove(
        member_session_index_key(user_id)
    )
    if not removed then
        return operation(
            false,
            remove_error or "AbandonIndexRemoveFailed",
            updated.session
        )
    end
    return updated
end

function DungeonSessionService:set_wipe_deadline(session_id: string, deadline: number?): any
    if deadline ~= nil and (type(deadline) ~= "number" or deadline < 0) then
        return operation(false, "InvalidWipeDeadline")
    end

    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        session.WipeDecisionEndsAt = deadline
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:set_runtime_progress(
    session_id: string,
    room_id: string,
    encounter_id: string
): any
    if type(room_id) ~= "string" or room_id == "" or type(encounter_id) ~= "string" then
        return operation(false, "InvalidRuntimeProgress")
    end

    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end
        session.CurrentRoomId = room_id
        session.CurrentEncounterId = encounter_id
        session.UpdatedAt = now
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:activate_checkpoint(session_id: string, checkpoint_id: string, sequence: number?): any
    if type(checkpoint_id) ~= "string" or checkpoint_id == "" then
        return operation(false, "InvalidCheckpoint")
    end

    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end

        local next_sequence = sequence or (session.Checkpoint.Sequence + 1)
        if type(next_sequence) ~= "number" or next_sequence < session.Checkpoint.Sequence or next_sequence % 1 ~= 0 then
            return session, operation(false, "CheckpointRegression")
        end

        session.Checkpoint = {
            Id = checkpoint_id,
            Sequence = next_sequence,
        }
        session.UpdatedAt = now
        if any_connected(session) then
            session.ExpiresAt = now + DungeonSessionService.ACTIVE_HEARTBEAT_SECONDS
        end
        return session, operation(true, nil)
    end)
end

function DungeonSessionService:mark_complete(session_id: string, completion_recipients: {number}?): any
    local recipients = deep_clone(completion_recipients or {})
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end

        local seen: {[number]: boolean} = {}
        for _, user_id in ipairs(recipients) do
            if type(user_id) ~= "number" or user_id <= 0 or seen[user_id] or session.Members[member_key(user_id)] == nil then
                return session, operation(false, "InvalidCompletionRecipients")
            end
            seen[user_id] = true
        end

        session.State = "Complete"
        session.CompletionRecipients = deep_clone(recipients)
        session.CompletedAt = now
        session.UpdatedAt = now
        session.ExpiresAt = now + DungeonSessionService.RECONNECT_GRACE_SECONDS
        return session, operation(true, nil)
    end, DungeonSessionService.TERMINAL_TTL_SECONDS)
end

function DungeonSessionService:mark_completion_rewards_committed(session_id: string, summary: any): any
    local summary_copy = deep_clone(summary or {})
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Complete" then
            return session, operation(false, "InvalidTransition")
        end
        if session.CompletionRewardsCommitted == true then
            return session, operation(true, nil)
        end
        session.CompletionRewardsCommitted = true
        session.CompletionRewardSummary = summary_copy
        session.CompletionRewardsCommittedAt = now
        session.UpdatedAt = now
        return session, operation(true, nil)
    end, DungeonSessionService.TERMINAL_TTL_SECONDS)
end

function DungeonSessionService:mark_failed(session_id: string, reason: string?): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if session.State ~= "Creating" and session.State ~= "Active" then
            return session, operation(false, "InvalidTransition")
        end

        session.State = "Failed"
        session.FailureReason = reason or "Failed"
        session.FailedAt = now
        session.UpdatedAt = now
        session.ExpiresAt = now + DungeonSessionService.RECONNECT_GRACE_SECONDS
        return session, operation(true, nil)
    end, DungeonSessionService.TERMINAL_TTL_SECONDS)
end

function DungeonSessionService:expire_if_stale(session_id: string): any
    return self:_update(session_id, function(session: any, now: number)
        if type(session) ~= "table" then
            return {State = "Expired", SessionId = session_id, Members = {}, UpdatedAt = now, ExpiresAt = now}, operation(false, "SessionNotFound")
        end
        if is_terminal(session.State) then
            return session, operation(true, nil)
        end
        if type(session.ExpiresAt) ~= "number" or now < session.ExpiresAt then
            return session, operation(true, nil)
        end

        if any_connected(session) then
            -- A connected flag with no heartbeat means the runtime likely vanished. Convert to
            -- disconnected recovery instead of immediately destroying the player's 10-minute rejoin chance.
            for _, member in pairs(session.Members) do
                if member.Connected == true then
                    member.Connected = false
                    member.LastDisconnectedAt = now
                end
            end
            session.UpdatedAt = now
            session.ExpiresAt = now + DungeonSessionService.RECONNECT_GRACE_SECONDS
            return session, operation(true, "RuntimeStaleRecoveryStarted")
        end

        session.State = "Expired"
        session.ExpiredAt = now
        session.UpdatedAt = now
        session.ExpiresAt = now
        return session, operation(true, nil)
    end, DungeonSessionService.TERMINAL_TTL_SECONDS)
end

return table.freeze(DungeonSessionService)
