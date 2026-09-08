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
local BaseProgressionController = require(Base:WaitForChild("BaseProgressionController"))

local remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local entry_request = remotes:WaitForChild("DungeonEntryRequest") :: RemoteEvent
local entry_result = remotes:WaitForChild("DungeonEntryResult") :: RemoteEvent
local profile_snapshot = remotes:WaitForChild("ProfileSnapshot") :: RemoteEvent
local inventory_snapshot = remotes:WaitForChild("InventorySnapshot") :: RemoteEvent
local progression_snapshot = remotes:WaitForChild("ProgressionSnapshot") :: RemoteEvent
local progression_action_result = remotes:WaitForChild("ProgressionActionResult") :: RemoteEvent
local identity_selection_request = remotes:WaitForChild("IdentitySelectionRequest") :: RemoteEvent
local attribute_commit_request = remotes:WaitForChild("AttributeCommitRequest") :: RemoteEvent
local skill_learn_request = remotes:WaitForChild("SkillLearnRequest") :: RemoteEvent
local skill_rank_request = remotes:WaitForChild("SkillRankRequest") :: RemoteEvent
local attribute_respec_request = remotes:WaitForChild("AttributeRespecRequest") :: RemoteEvent
local skill_respec_request = remotes:WaitForChild("SkillRespecRequest") :: RemoteEvent
local loadout_request = remotes:WaitForChild("LoadoutRequest") :: RemoteEvent

local runtime = RuntimeServices.new("Base")
local profiles = runtime.ProfileService
local leases = runtime.LeaseService
local sessions = runtime.SessionService
local inventory = runtime.InventoryService
local attributes = runtime.AttributeService
local loadout = runtime.LoadoutService
local skills = runtime.SkillProgressionService
local identity = runtime.IdentityService
local progression_controller = BaseProgressionController.new({
    context = "Base",
    profiles = profiles,
    inventory = inventory,
    attributes = attributes,
    loadout = loadout,
    skills = skills,
})
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

local function send_progression(player: Player)
    progression_snapshot:FireClient(player, progression_controller:build_snapshot(player.UserId))
end

runtime.ProgressionService:set_change_callback(function(user_id: number)
    local player = Players:GetPlayerByUserId(user_id)
    if player and loaded_users[user_id] then send_progression(player) end
end)

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
    send_progression(player)
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

progression_snapshot.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Request" and loaded_users[player.UserId] then send_progression(player) end
end)

local function refresh_runtime_character(player: Player)
    local character = profiles:get_character(player.UserId)

    if not character then
        return
    end

    ProgressionRuntimeState.set_character(
        player.UserId,
        character
    )

    ProgressionRuntimeState.apply_max_health(
        player
    )
end

local function finish_progression_action(
    player: Player,
    action: string,
    result: any
)
    local payload = {
        action = action,
        ok = result and result.ok == true,
        reason = result and result.reason or nil,
    }

    progression_action_result:FireClient(
        player,
        payload
    )

    if payload.ok then
        refresh_runtime_character(player)
        send_profile(player)
    end
end

identity_selection_request.OnServerEvent:Connect(
    function(
        player: Player,
        kind: any,
        selection_id: any
    )
        if loaded_users[player.UserId] ~= true then
            return
        end

        if type(selection_id) ~= "string" then
            finish_progression_action(
                player,
                "IdentitySelection",
                {
                    ok = false,
                    reason = "InvalidIdentitySelection",
                }
            )
            return
        end

        local action: string
        local result: any

        if kind == "Race" then
            action = "RaceSelection"

            result = identity:select_race(
                player.UserId,
                selection_id
            )
        elseif kind == "Class" then
            action = "ClassSelection"

            result = identity:select_base_class(
                player.UserId,
                selection_id
            )
        else
            action = "IdentitySelection"

            result = {
                ok = false,
                reason = "InvalidIdentitySelection",
            }
        end

        finish_progression_action(
            player,
            action,
            result
        )

        if result and result.ok == true then
            print(
                string.format(
                    "[Base Identity] %s completed %s -> %s.",
                    player.Name,
                    tostring(kind),
                    tostring(selection_id)
                )
            )
        end
    end
)

attribute_commit_request.OnServerEvent:Connect(function(player: Player, desired: any)
    if not loaded_users[player.UserId] then return end
    finish_progression_action(player, "AttributeCommit", progression_controller:commit_attributes(player.UserId, desired))
end)
skill_learn_request.OnServerEvent:Connect(function(player: Player, skill_id: any)
    if not loaded_users[player.UserId] or type(skill_id) ~= "string" then return end
    finish_progression_action(player, "SkillLearn", progression_controller:learn_skill(player.UserId, skill_id))
end)
skill_rank_request.OnServerEvent:Connect(function(player: Player, skill_id: any)
    if not loaded_users[player.UserId] or type(skill_id) ~= "string" then return end
    finish_progression_action(player, "SkillRank", progression_controller:purchase_rank(player.UserId, skill_id))
end)
attribute_respec_request.OnServerEvent:Connect(function(player: Player)
    if not loaded_users[player.UserId] then return end
    finish_progression_action(player, "AttributeRespec", progression_controller:respec_attributes(player.UserId))
end)
skill_respec_request.OnServerEvent:Connect(function(player: Player)
    if not loaded_users[player.UserId] then return end
    finish_progression_action(player, "SkillRespec", progression_controller:respec_skills(player.UserId))
end)
loadout_request.OnServerEvent:Connect(function(player: Player, first: any, second: any)
    if not loaded_users[player.UserId] then return end
    local result:any
    if type(first)=="string" then
        result=progression_controller:move_skill_to_slot(player.UserId,first,second)
    elseif type(first)=="table" and second==nil then
        -- Backwards-compatible path for older clients; new clients use atomic move-to-slot.
        result=progression_controller:set_loadout(player.UserId,first)
    else
        result={ok=false,reason="InvalidLoadoutRequest"}
    end
    finish_progression_action(player,"Loadout",result)
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
