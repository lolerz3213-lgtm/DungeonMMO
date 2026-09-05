--!strict
-- Base-side profile lifecycle, reconnect routing and solo TestDungeon entry.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Core = ServerScriptService:WaitForChild("Core")
local Services = Core:WaitForChild("Services")
local Adapters = Core:WaitForChild("Adapters")
local Base = ServerScriptService:WaitForChild("Base")

local RuntimeServices = require(Services:WaitForChild("RuntimeServices"))
local ProgressionRuntimeState = require(Services:WaitForChild("ProgressionRuntimeState"))
local TeleportCoordinator = require(Services:WaitForChild("TeleportCoordinator"))
local RobloxTeleportAdapter = require(Adapters:WaitForChild("RobloxTeleportAdapter"))
local TestFailureSwitches = require(Core:WaitForChild("TestFailureSwitches"))
local BaseReconnectRouting = require(Base:WaitForChild("BaseReconnectRouting"))
local BaseReturnAdmissionRules = require(Base:WaitForChild("BaseReturnAdmissionRules"))

local remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local entry_request = remotes:WaitForChild("DungeonEntryRequest") :: RemoteEvent
local entry_result = remotes:WaitForChild("DungeonEntryResult") :: RemoteEvent
local profile_snapshot = remotes:WaitForChild("ProfileSnapshot") :: RemoteEvent
local inventory_snapshot = remotes:WaitForChild("InventorySnapshot") :: RemoteEvent

local runtime = RuntimeServices.new("Base")
local profiles = runtime.ProfileService
local leases = runtime.LeaseService
local sessions = runtime.SessionService
local force_outbound_failure = TestFailureSwitches.is_enabled(
    TestFailureSwitches.OUTBOUND_ATTRIBUTE
)
local coordinator = TeleportCoordinator.new(
    RobloxTeleportAdapter.new({
        force_teleport_failure = force_outbound_failure,
        failure_reason = "TEST_ForcedOutboundTeleportFailure",
    }),
    profiles,
    leases,
    sessions
)
if force_outbound_failure then
    warn("[TEST Failure Injection] Outbound dungeon teleports are forced to fail.")
end

local loaded_users: {[number]: boolean} = {}
local last_entry_request: {[number]: number} = {}
local ENTRY_RATE_LIMIT_SECONDS = 2
local AUTOSAVE_SECONDS = 30
local LEASE_RENEW_SECONDS = 15

local function send_profile(player: Player)
    local character = profiles:get_character(player.UserId, 1)
    if not character then
        return
    end
    profile_snapshot:FireClient(player, {
        Slot = 1,
        Level = character.Level,
        XP = character.XP,
        Gold = character.Gold,
    })
    inventory_snapshot:FireClient(player, character.Inventory)
end

local function send_entry_result(player: Player, result: any)
    entry_result:FireClient(player, {
        ok = result.ok == true,
        reason = result.reason,
        SessionId = if result.session then result.session.SessionId else nil,
        DungeonId = if result.session then result.session.DungeonId else nil,
    })
end

local function configured_dungeon_place_id(): (number?, string?)
    if RunService:IsStudio() then
        return nil, "PublishedTeleportRequired"
    end

    local place_id = ServerScriptService:GetAttribute("DungeonMMODungeonPlaceId")
    if type(place_id) ~= "number" or place_id <= 0 or place_id % 1 ~= 0 then
        return nil, "DungeonPlaceIdNotConfigured"
    end
    return place_id, nil
end

local function current_session_for(user_id: number): any?
    local session = sessions:get_for_user(user_id)
    if session and (session.State == "Creating" or session.State == "Active") then
        sessions:expire_if_stale(session.SessionId)
        session = sessions:get(session.SessionId)
    end
    return session
end

local function route_recoverable_session(player: Player, session: any): boolean
    local decision = BaseReconnectRouting.decide(session, player.UserId, os.time())
    if decision.route ~= "Dungeon" then
        return false
    end

    local dungeon_place_id, place_error = configured_dungeon_place_id()
    if not dungeon_place_id then
        print(string.format(
            "[Base Runtime] Recoverable session %s found for %s; %s.",
            tostring(session.SessionId),
            player.Name,
            tostring(place_error)
        ))
        send_entry_result(player, {ok = false, reason = place_error, session = session})
        return true
    end

    local result = coordinator:rejoin_session(player, session, dungeon_place_id)
    send_entry_result(player, result)
    if not result.ok then
        warn(string.format("[Base Runtime] Rejoin failed for %s: %s", player.Name, tostring(result.reason)))
    end
    return true
end

local function claim_return_handoff_if_present(player: Player): (boolean, string?)
    if RunService:IsStudio() then return true, nil end
    local join_data = player:GetJoinData()
    local teleport_data = join_data and join_data.TeleportData
    if type(teleport_data) ~= "table" or type(teleport_data.SessionId) ~= "string" then
        return true, nil
    end
    local session = sessions:get(teleport_data.SessionId)
    local admission = BaseReturnAdmissionRules.validate(session, teleport_data, player.UserId)
    if not admission.ok then return false, admission.reason end
    local nonce = sessions:get_handoff_nonce(session.SessionId, player.UserId)
    if not nonce then return false, "MissingHandoffNonce" end
    local claimed = leases:claim_handoff(player.UserId, nonce)
    if not claimed.ok then return false, claimed.reason end
    sessions:clear_handoff_nonce(session.SessionId, player.UserId)
    return true, nil
end

local function load_player(player: Player)
    local handoff_ok, handoff_error = claim_return_handoff_if_present(player)
    if not handoff_ok then
        warn(string.format("[Base Runtime] Return handoff rejected for %s: %s", player.Name, tostring(handoff_error)))
        player:Kick("Return-to-Base handoff rejected: " .. tostring(handoff_error))
        return
    end

    local loaded, load_error = profiles:load(player.UserId)
    if not loaded then
        warn(string.format("[Base Runtime] Profile load failed for %s: %s", player.Name, tostring(load_error)))
        send_entry_result(player, {ok = false, reason = load_error or "ProfileLoadFailed"})
        return
    end

    loaded_users[player.UserId] = true
    ProgressionRuntimeState.set_character(player.UserId, loaded.Characters.Slot1)
    ProgressionRuntimeState.apply_max_health(player)
    player.CharacterAdded:Connect(function() task.defer(ProgressionRuntimeState.apply_max_health, player) end)
    send_profile(player)
    print(string.format(
        "[Base Runtime] Slot1 loaded for %s (Level %d, XP %d, Gold %d).",
        player.Name,
        loaded.Characters.Slot1.Level,
        loaded.Characters.Slot1.XP,
        loaded.Characters.Slot1.Gold
    ))

    local session = current_session_for(player.UserId)
    if session then
        route_recoverable_session(player, session)
    end
end

local function handle_entry(player: Player, dungeon_id: any)
    if dungeon_id ~= "TestDungeon" then
        send_entry_result(player, {ok = false, reason = "UnknownDungeon"})
        return
    end
    if loaded_users[player.UserId] ~= true or not profiles:get_profile(player.UserId) then
        send_entry_result(player, {ok = false, reason = "ProfileNotReady"})
        return
    end
    if coordinator:is_pending(player.UserId) then
        send_entry_result(player, {ok = false, reason = "TeleportAlreadyPending"})
        return
    end

    local now = os.clock()
    local previous = last_entry_request[player.UserId]
    if previous and now - previous < ENTRY_RATE_LIMIT_SECONDS then
        send_entry_result(player, {ok = false, reason = "EntryRateLimited"})
        return
    end
    last_entry_request[player.UserId] = now

    local existing = current_session_for(player.UserId)
    if existing then
        local decision = BaseReconnectRouting.decide(existing, player.UserId, os.time())
        if decision.route == "Dungeon" then
            route_recoverable_session(player, existing)
            return
        end
    end

    local dungeon_place_id, place_error = configured_dungeon_place_id()
    if not dungeon_place_id then
        send_entry_result(player, {ok = false, reason = place_error})
        print(string.format("[Base Runtime] %s entry blocked: %s.", player.Name, tostring(place_error)))
        return
    end

    local result = coordinator:start_dungeon({player}, "TestDungeon", dungeon_place_id)
    send_entry_result(player, result)
    if not result.ok then
        warn(string.format("[Base Runtime] Dungeon start failed for %s: %s", player.Name, tostring(result.reason)))
    end
end

entry_request.OnServerEvent:Connect(function(player: Player, dungeon_id: any)
    handle_entry(player, dungeon_id)
end)

profile_snapshot.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Request" and loaded_users[player.UserId] then send_profile(player) end
end)

local function connect_prompt()
    local base_root = Workspace:WaitForChild("BasePrototype", 10)
    if not base_root then
        warn("[Base Runtime] BasePrototype was not created.")
        return
    end
    local portal = base_root:WaitForChild("TestDungeonPortal", 5)
    if not portal then
        warn("[Base Runtime] TestDungeonPortal was not created.")
        return
    end
    local prompt = portal:WaitForChild("DungeonEntryPrompt", 5)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Triggered:Connect(function(player: Player)
            handle_entry(player, "TestDungeon")
        end)
    end
end

task.spawn(connect_prompt)

Players.PlayerAdded:Connect(load_player)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(load_player, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
    local user_id = player.UserId
    loaded_users[user_id] = nil
    ProgressionRuntimeState.clear_character(user_id)
    last_entry_request[user_id] = nil

    if coordinator:is_pending(user_id) then
        local forgot, forget_error = profiles:forget_for_handoff(user_id)
        if not forgot then
            warn(string.format("[Base Runtime] Could not forget handoff profile %d: %s", user_id, tostring(forget_error)))
        end
        coordinator:acknowledge_departure(user_id)
        return
    end

    local released, release_error = profiles:release(user_id, "PlayerRemoving")
    if not released then
        warn(string.format("[Base Runtime] Profile release failed for %d: %s", user_id, tostring(release_error)))
    end
end)

task.spawn(function()
    while true do
        task.wait(LEASE_RENEW_SECONDS)
        for user_id in pairs(loaded_users) do
            if not coordinator:is_pending(user_id) then
                local renewal = leases:renew(user_id)
                if not renewal.ok then
                    warn(string.format("[Base Runtime] Lease renewal failed for %d: %s", user_id, tostring(renewal.reason)))
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_SECONDS)
        for user_id in pairs(loaded_users) do
            if not coordinator:is_pending(user_id) then
                local saved, save_error = profiles:save(user_id, "Autosave")
                if not saved then
                    warn(string.format("[Base Runtime] Autosave failed for %d: %s", user_id, tostring(save_error)))
                end
            end
        end
    end
end)

game:BindToClose(function()
    for user_id in pairs(loaded_users) do
        if coordinator:is_pending(user_id) then
            profiles:forget_for_handoff(user_id)
        else
            profiles:release(user_id, "BindToClose")
        end
    end
end)

print("[Base Runtime] Profile lifecycle and TestDungeon entry ready.")
