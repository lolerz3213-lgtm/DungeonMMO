--!strict
-- First real dungeon runtime: admission, two combat rooms, checkpoint, rewards, death/revive and wipe failure.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

Players.CharacterAutoLoads = false

local Core = ServerScriptService:WaitForChild("Core")
local Services = Core:WaitForChild("Services")
local Adapters = Core:WaitForChild("Adapters")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local Combat = ServerScriptService:WaitForChild("Combat")
local SharedCore = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local SharedCombat = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared")

local DungeonDefinitions = require(SharedCore:WaitForChild("DungeonDefinitions"))
local CharacterIdentityRules = require(
    SharedCore:WaitForChild("CharacterIdentityRules")
)
local CombatConfig = require(SharedCombat:WaitForChild("CombatConfig"))
local RuntimeServices = require(Services:WaitForChild("RuntimeServices"))
local ProgressionRuntimeState = require(Services:WaitForChild("ProgressionRuntimeState"))
local RacePresentationService = require(
    Services:WaitForChild("RacePresentationService")
)
local ProgressionSnapshotBuilder = require(Services:WaitForChild("ProgressionSnapshotBuilder"))
local RevivePurchaseService = require(Services:WaitForChild("RevivePurchaseService"))
local RevivePurchaseRegistry = require(Services:WaitForChild("RevivePurchaseRegistry"))
local TeleportCoordinator = require(Services:WaitForChild("TeleportCoordinator"))
local RobloxTeleportAdapter = require(Adapters:WaitForChild("RobloxTeleportAdapter"))
local TestFailureSwitches = require(Core:WaitForChild("TestFailureSwitches"))
local DungeonAdmissionRules = require(Dungeon:WaitForChild("DungeonAdmissionRules"))
local StudioSessionFactory = require(Dungeon:WaitForChild("StudioSessionFactory"))
local EncounterService = require(Dungeon:WaitForChild("EncounterService"))
local CheckpointService = require(Dungeon:WaitForChild("CheckpointService"))
local DungeonRecoveryRules = require(Dungeon:WaitForChild("DungeonRecoveryRules"))
local DungeonProgressionBridge = require(Dungeon:WaitForChild("DungeonProgressionBridge"))
local DungeonDeathService = require(
    Dungeon:WaitForChild("DungeonDeathService")
)
local DungeonDeathPresentation = require(
    Dungeon:WaitForChild("DungeonDeathPresentation")
)
local DungeonEnemyCleanup = require(Dungeon:WaitForChild("DungeonEnemyCleanup"))
local MarauderCaptainFactory = require(Dungeon:WaitForChild("MarauderCaptainFactory"))
local DungeonBossSpawnGuard = require(
    Dungeon:WaitForChild("DungeonBossSpawnGuard")
)
local CompletionEligibilityRules = require(Dungeon:WaitForChild("CompletionEligibilityRules"))
local CompletionService = require(Dungeon:WaitForChild("CompletionService"))
local ReturnPortalService = require(Dungeon:WaitForChild("ReturnPortalService"))
local DungeonMarauderFactory = require(
    Dungeon:WaitForChild("DungeonMarauderFactory")
)

local remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local dungeon_state = remotes:WaitForChild("DungeonStateChanged") :: RemoteEvent
local revive_request = remotes:WaitForChild("ReviveRequest") :: RemoteEvent
local revive_state = remotes:WaitForChild("ReviveStateChanged") :: RemoteEvent
local profile_snapshot = remotes:WaitForChild("ProfileSnapshot") :: RemoteEvent
local inventory_snapshot = remotes:WaitForChild("InventorySnapshot") :: RemoteEvent
local progression_snapshot = remotes:WaitForChild("ProgressionSnapshot") :: RemoteEvent
local progression_action_result = remotes:WaitForChild("ProgressionActionResult") :: RemoteEvent
local loadout_request = remotes:WaitForChild("LoadoutRequest") :: RemoteEvent
local return_request = remotes:WaitForChild("ReturnRequest") :: RemoteEvent

local runtime = RuntimeServices.new("Dungeon")
local profiles = runtime.ProfileService
local leases = runtime.LeaseService
local sessions = runtime.SessionService
local rewards = runtime.RewardService
local proficiency = runtime.ProficiencyService
local inventory = runtime.InventoryService
local attributes = runtime.AttributeService
local loadout = runtime.LoadoutService
local skills = runtime.SkillProgressionService
local identity = runtime.IdentityService

local dungeon_root = Workspace:WaitForChild("DungeonRuntime", 10)
assert(dungeon_root, "DungeonRuntime greybox was not created")
local spawn_part = dungeon_root:FindFirstChild("DungeonSpawn", true) :: BasePart
local room1_trigger = dungeon_root:FindFirstChild("Room1StartTrigger", true) :: BasePart
local room2_trigger = dungeon_root:FindFirstChild("Room2StartTrigger", true) :: BasePart
local room1_gate = dungeon_root:FindFirstChild(
    "Room1ExitGate",
    true
) :: BasePart
local room2_gate = dungeon_root:FindFirstChild(
    "Room2ExitGate",
    true
) :: BasePart
local boss_trigger = dungeon_root:FindFirstChild(
    "BossStartTrigger",
    true
) :: BasePart
assert(
    spawn_part
        and room1_trigger
        and room2_trigger
        and room1_gate
        and room2_gate
        and boss_trigger
)

local enemies_folder = Instance.new("Folder")
enemies_folder.Name = "DungeonEnemies"
enemies_folder.Parent = dungeon_root

local active_session_id: string? = nil
local encounter_service: any = nil
local checkpoint_service: any = nil
local death_service: any = nil
local purchase_service: any = nil
local completion_service: any = nil
local return_service: any = nil
local force_return_failure = TestFailureSwitches.is_enabled(
    TestFailureSwitches.RETURN_ATTRIBUTE
)
local coordinator = TeleportCoordinator.new(
    RobloxTeleportAdapter.new({
        force_teleport_failure = force_return_failure,
        failure_reason = "TEST_ForcedReturnTeleportFailure",
    }),
    profiles,
    leases,
    sessions
)
if force_return_failure then
    warn("[TEST Failure Injection] Return-to-Base teleports are forced to fail.")
end
local loaded_users: {[number]: boolean} = {}
local bound_characters: {[Model]: boolean} = {}
local room_started = {CombatRoom1 = false, CombatRoom2 = false}
local room_cleared = {CombatRoom1 = false, CombatRoom2 = false}
local boss_started = false
local boss_cleared = false
local completion_pending = false
local completion_committed = false
local next_completion_retry_at = 0
local current_encounter_id = ""
local active_captain: Model? = nil
local AUTOSAVE_SECONDS = 30
local LEASE_RENEW_SECONDS = 15
local SESSION_REFRESH_SECONDS = 30

local function current_session(): any?
    return if active_session_id then sessions:get(active_session_id) else nil
end

local function set_gate_open(gate: BasePart, open: boolean)
    gate.CanCollide = not open
    gate.Transparency = if open then 0.75 else 0
    gate.Color = if open then Color3.fromRGB(70, 145, 85) else Color3.fromRGB(150, 72, 72)
end

local function send_objective(text: string, state_name: string?)
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then
            dungeon_state:FireClient(player, {
                state = state_name or "Active",
                objective = text,
                session_id = active_session_id,
                encounter_id = current_encounter_id,
            })
        end
    end
    print("[Dungeon Runtime] " .. text)
end

local function build_progression_snapshot(user_id: number): any
    local c = profiles:get_character(user_id, 1)
    return ProgressionSnapshotBuilder.build(c)
end

local function send_progression(player: Player)
    progression_snapshot:FireClient(player, build_progression_snapshot(player.UserId))
end

runtime.ProgressionService:set_change_callback(function(user_id: number)
    local player = Players:GetPlayerByUserId(user_id)
    if player and loaded_users[user_id] then send_progression(player) end
end)

local function send_profile(player: Player)
    local character = profiles:get_character(player.UserId, 1)
    if not character then return end
    profile_snapshot:FireClient(player, {Slot = 1, Level = character.Level, XP = character.XP, Gold = character.Gold})
    inventory_snapshot:FireClient(player, character.Inventory)
    send_progression(player)
end

local function apply_race_presentation(
    player: Player,
    character_model: Model?
)
    local profile_character =
        profiles:get_character(
            player.UserId,
            1
        )

    local race_id =
        profile_character
        and profile_character.Identity
        and profile_character.Identity.RaceId
        or nil

    local target =
        character_model
        or player.Character

    if not target then
        return
    end

    local result =
        RacePresentationService.apply(
            target,
            race_id
        )

    if not result.ok
        and result.reason ~= "HeadNotFound"
    then
        warn(
            string.format(
                "[Dungeon Race Presentation] %s: %s",
                player.Name,
                tostring(result.reason)
            )
        )
    end
end


local function set_character_encounter(player: Player, encounter_id: string)
    local character = player.Character
    if character then
        character:SetAttribute(CombatConfig.TRAINING_MARAUDER.RUN_PARTICIPANT_ATTRIBUTE, true)
        character:SetAttribute(CombatConfig.TRAINING_MARAUDER.ENCOUNTER_ATTRIBUTE, encounter_id)
    end
end

local function sync_all_character_encounters(encounter_id: string)
    current_encounter_id = encounter_id
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then
            set_character_encounter(player, encounter_id)
        end
    end
end

local function get_player_from_touch(hit: BasePart): Player?
    local character = hit:FindFirstAncestorOfClass("Model")
    if not character then return nil end
    local player = Players:GetPlayerFromCharacter(character)
    if not player or not loaded_users[player.UserId] then return nil end
    local session = current_session()
    if not session or session.State ~= "Active" then return nil end
    local member = session.Members[tostring(player.UserId)]
    if not member or member.Mode ~= "Active" then return nil end
    return player
end

local function member_user_ids(): {number}
    local result = {}
    local session = current_session()
    if not session then return result end
    for _, user_id in ipairs(session.MemberUserIds or {}) do
        table.insert(result, user_id)
    end
    return result
end

local function sync_encounter_members_from_session()
    local session = current_session()
    if not session or not encounter_service then return end
    for _, member in pairs(session.Members or {}) do
        encounter_service:mark_member_connected(member.UserId, member.Connected == true)
        encounter_service:mark_member_mode(member.UserId, member.Mode or "Active")
    end
end

local function spawn_marauder(encounter_id: string, enemy_id: string, position: Vector3, spawn_index: number): Model
    local reward = DungeonDefinitions.TEST_DUNGEON.StandardMarauderReward
    return DungeonMarauderFactory.create({
        Parent = enemies_folder,
        Name = enemy_id,
        SpawnCFrame = CFrame.new(position),
        SpawnIndex = spawn_index,
        RespawnEnabled = false,
        ControllerEnabled = true,
        EncounterId = encounter_id,
        EnemyId = enemy_id,
        LifeIndex = 1,
        RewardXP = reward.XP,
        RewardGoldMin = reward.GoldMin,
        RewardGoldMax = reward.GoldMax,
    })
end

local function print_reward_result(result: any)
    if not result or not result.reward_result or not result.reward_result.member_results then return end
    for user_key, member_result in pairs(result.reward_result.member_results) do
        local user_id = tonumber(user_key)
        local player = if user_id then Players:GetPlayerByUserId(user_id) else nil
        if player then
            local saved, save_error = profiles:save(player.UserId, "MonsterReward")
            if not saved then
                warn(string.format("[Dungeon Runtime] Monster reward save failed for %s: %s", player.Name, tostring(save_error)))
            end
            send_profile(player)
            print(string.format(
                "[Dungeon Reward] %s +%d XP +%d Gold -> Level %d, %d XP carried.",
                player.Name,
                member_result.xp_granted or 0,
                member_result.gold_granted or 0,
                member_result.new_level or 1,
                member_result.carried_xp or 0
            ))
        end
    end
end

local function connected_member_user_ids(): {number}
    local ids = {}
    local session = current_session()
    if not session then return ids end
    for _, player in ipairs(Players:GetPlayers()) do
        local member = session.Members and session.Members[tostring(player.UserId)]
        if loaded_users[player.UserId] and member and member.Connected == true then
            table.insert(ids, player.UserId)
        end
    end
    table.sort(ids)
    return ids
end

local function connected_loaded_players(): {Player}
    local result = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then table.insert(result, player) end
    end
    return result
end

local function send_boss_state(humanoid: Humanoid)
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then
            dungeon_state:FireClient(player, {
                state = "Boss",
                objective = "Defeat the Marauder Captain.",
                session_id = active_session_id,
                encounter_id = "MarauderCaptain",
                boss_name = "Marauder Captain",
                boss_health = math.max(0, humanoid.Health),
                boss_max_health = humanoid.MaxHealth,
            })
        end
    end
end

local handle_boss_cleared: (() -> ())? = nil

local function advance_checkpoint(checkpoint_id: string): boolean
    if not checkpoint_service or not active_session_id then
        return false
    end
    local advanced = checkpoint_service:activate(checkpoint_id)
    if not advanced.ok then
        warn(
            "[Dungeon Runtime] Checkpoint advance failed: "
                .. tostring(advanced.reason)
        )
        return false
    end
    return true
end

local function connect_enemy(enemy: Model, encounter_id: string)
    local humanoid = enemy:WaitForChild("Humanoid") :: Humanoid
    local fired = false
    humanoid.Died:Connect(function()
        if fired then return end
        fired = true
        local result = encounter_service:on_enemy_died(enemy)
        if result.ok ~= true then
            warn(string.format("[Dungeon Runtime] Enemy reward/clear failed: %s", tostring(result.reason)))
            return
        end
        print_reward_result(result)
        DungeonEnemyCleanup.retire(enemy)
        if result.cleared then
            room_cleared[encounter_id] = true
            if encounter_id == "CombatRoom1" then
                set_gate_open(room1_gate, true)
                sync_all_character_encounters("")
                advance_checkpoint("Room2Start")
                sessions:set_runtime_progress(
                    active_session_id :: string,
                    "CombatRoom1Clear",
                    ""
                )
                send_objective(
                    "Room 1 cleared. Room 2 unlocked; checkpoint moved."
                )
            elseif encounter_id == "CombatRoom2" then
                set_gate_open(room2_gate, true)
                sync_all_character_encounters("")
                advance_checkpoint("BossRoomStart")
                sessions:set_runtime_progress(
                    active_session_id :: string,
                    "CombatRoom2Clear",
                    ""
                )
                send_objective(
                    "Room 2 cleared. Boss unlocked; checkpoint moved."
                )
            elseif encounter_id == "MarauderCaptain" then
                boss_cleared = true
                sync_all_character_encounters("")
                if handle_boss_cleared then handle_boss_cleared() end
            end
        end
    end)
end

local function start_room1()
    if room_started.CombatRoom1 or not active_session_id then return end
    room_started.CombatRoom1 = true
    sync_all_character_encounters("CombatRoom1")
    sessions:set_runtime_progress(active_session_id, "CombatRoom1", "CombatRoom1")
    local room1_positions = {Vector3.new(238, 2, -48), Vector3.new(262, 2, -48)}
    local enemies = {}
    for index = 1, DungeonDefinitions.TEST_DUNGEON.RoomPacks.CombatRoom1.MarauderCount do
        table.insert(enemies, spawn_marauder("CombatRoom1", "Room1_Marauder_" .. tostring(index), room1_positions[index], 100 + index))
    end
    local started = encounter_service:start("CombatRoom1", member_user_ids(), enemies)
    if not started.ok then error("Room1 encounter failed: " .. tostring(started.reason)) end
    sync_encounter_members_from_session()
    for _, enemy in ipairs(enemies) do connect_enemy(enemy, "CombatRoom1") end
    send_objective("Combat Room 1: defeat both Marauders.")
end

local function start_room2()
    if room_started.CombatRoom2 or not room_cleared.CombatRoom1 or not active_session_id then return end
    room_started.CombatRoom2 = true
    sync_all_character_encounters("CombatRoom2")
    sessions:set_runtime_progress(active_session_id, "CombatRoom2", "CombatRoom2")
    local room2_positions = {Vector3.new(232, 2, -148), Vector3.new(250, 2, -160), Vector3.new(268, 2, -148)}
    local enemies = {}
    for index = 1, DungeonDefinitions.TEST_DUNGEON.RoomPacks.CombatRoom2.MarauderCount do
        table.insert(enemies, spawn_marauder("CombatRoom2", "Room2_Marauder_" .. tostring(index), room2_positions[index], 200 + index))
    end
    local started = encounter_service:start("CombatRoom2", member_user_ids(), enemies)
    if not started.ok then error("Room2 encounter failed: " .. tostring(started.reason)) end
    sync_encounter_members_from_session()
    for _, enemy in ipairs(enemies) do connect_enemy(enemy, "CombatRoom2") end
    send_objective("Combat Room 2: defeat the larger Marauder pack.")
end

local function send_completion_state(commit_result: any, return_at: number)
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then
            local own = commit_result.member_results and commit_result.member_results[tostring(player.UserId)] or nil
            dungeon_state:FireClient(player, {
                state = "Complete",
                objective = "Dungeon complete. Return to Base or wait "
                    .. "for auto-return.",
                session_id = active_session_id,
                completion = own,
                completion_eligible = own ~= nil,
                return_at = return_at,
                server_time = os.time(),
            })
        end
    end
end

local function commit_and_open_completion()
    if completion_committed or not completion_pending or not active_session_id or not completion_service or not return_service then return end
    local committed = completion_service:commit(active_session_id)
    if not committed.ok then
        next_completion_retry_at = os.clock() + 5
        send_objective("Captain defeated. Saving completion rewards before return...", "CompletionSaveError")
        warn("[Dungeon Runtime] Completion save barrier failed: " .. tostring(committed.reason))
        return
    end

    local opened = return_service:open(active_session_id, committed)
    if not opened.ok then
        next_completion_retry_at = os.clock() + 5
        warn("[Dungeon Runtime] Return portal could not open: " .. tostring(opened.reason))
        return
    end

    completion_pending = false
    completion_committed = true
    for _, player in ipairs(Players:GetPlayers()) do
        if loaded_users[player.UserId] then send_profile(player) end
    end
    send_completion_state(committed, opened.return_at)
    print(
        "[Dungeon Runtime] Completion rewards committed; "
            .. "return available for 60 seconds."
    )
end

handle_boss_cleared = function()
    if not active_session_id or completion_pending or completion_committed then return end
    local session = current_session()
    if not session or session.State ~= "Active" then return end
    if not room_cleared.CombatRoom1
        or not room_cleared.CombatRoom2
        or not boss_cleared
    then
        warn("[Dungeon Runtime] Boss clear rejected because dungeon progression is incomplete.")
        return
    end

    local recipients = CompletionEligibilityRules.build_snapshot(session, connected_member_user_ids())
    local marked = sessions:mark_complete(active_session_id, recipients)
    if not marked.ok then
        warn("[Dungeon Runtime] Session completion failed: " .. tostring(marked.reason))
        return
    end
    completion_pending = true
    commit_and_open_completion()
end

local function start_boss()
    if boss_started
        or not room_cleared.CombatRoom2
        or not active_session_id
    then
        return
    end
    local session = current_session()
    if not session or session.State ~= "Active" then return end

    if not DungeonBossSpawnGuard.claim(
        dungeon_root,
        active_session_id
    ) then
        boss_started = true
        warn(
            "[Dungeon Runtime] Duplicate Captain spawn blocked "
                .. "for session "
                .. active_session_id
                .. "."
        )
        return
    end

    boss_started = true
    sync_all_character_encounters("MarauderCaptain")
    sessions:set_runtime_progress(active_session_id, "MarauderCaptain", "MarauderCaptain")
    local reward = DungeonDefinitions.TEST_DUNGEON.MarauderCaptainReward
    local captain = MarauderCaptainFactory.create({
        Parent = enemies_folder,
        SpawnCFrame = CFrame.new(DungeonDefinitions.TEST_DUNGEON.MarauderCaptain.SpawnPosition),
        EncounterId = "MarauderCaptain",
        RewardXP = reward.XP,
        RewardGoldMin = reward.GoldMin,
        RewardGoldMax = reward.GoldMax,
    })
    active_captain = captain
    local started = encounter_service:start("MarauderCaptain", member_user_ids(), {captain})
    if not started.ok then error("Captain encounter failed: " .. tostring(started.reason)) end
    sync_encounter_members_from_session()
    connect_enemy(captain, "MarauderCaptain")
    send_objective("BOSS: Defeat the Marauder Captain.", "Boss")
    local humanoid = captain:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function() send_boss_state(humanoid) end)
        send_boss_state(humanoid)
    end
end

room1_trigger.Touched:Connect(function(hit)
    if get_player_from_touch(hit) then
        start_room1()
    end
end)
room2_trigger.Touched:Connect(function(hit)
    if get_player_from_touch(hit) then
        start_room2()
    end
end)
boss_trigger.Touched:Connect(function(hit)
    if get_player_from_touch(hit) then
        start_boss()
    end
end)

local function emit_revive_state(user_id: number, payload: any)
    local player = Players:GetPlayerByUserId(user_id)
    if player then
        payload.server_time = os.time()
        revive_state:FireClient(player, payload)
    end
end

local function apply_recovery_plan(session: any): any
    local checkpoint_id = "Entrance"
    if type(session.Checkpoint) == "table"
        and type(session.Checkpoint.Id) == "string"
    then
        checkpoint_id = session.Checkpoint.Id
    end

    local plan = DungeonRecoveryRules.from_checkpoint(checkpoint_id)
    if not plan.valid_checkpoint then
        warn(
            "[Dungeon Runtime] Unknown persisted checkpoint "
                .. tostring(checkpoint_id)
                .. "; recovering at Entrance."
        )
    end

    room_started.CombatRoom1 = plan.room1_cleared
    room_cleared.CombatRoom1 = plan.room1_cleared
    room_started.CombatRoom2 = plan.room2_cleared
    room_cleared.CombatRoom2 = plan.room2_cleared
    boss_started = false
    boss_cleared = false
    sync_all_character_encounters("")
    set_gate_open(room1_gate, plan.room1_cleared)
    set_gate_open(room2_gate, plan.room2_cleared)

    if checkpoint_id ~= "Entrance" and active_session_id then
        sessions:set_runtime_progress(
            active_session_id,
            plan.runtime_room_id,
            ""
        )
    end
    return plan
end

local function initialize_session_services(session: any): (any?, boolean)
    if active_session_id and active_session_id ~= session.SessionId then
        error("Reserved Dungeon server received more than one SessionId")
    end
    if encounter_service then return nil, false end
    active_session_id = session.SessionId
    encounter_service = EncounterService.new(rewards, session.SessionId)
    DungeonProgressionBridge.bind({proficiency_service = proficiency, encounter_service = encounter_service})
    checkpoint_service = CheckpointService.new(sessions, session.SessionId)
    checkpoint_service:register(
        "Entrance",
        0,
        spawn_part.CFrame + Vector3.new(0, 3, 0)
    )
    checkpoint_service:register(
        "Room1Start",
        1,
        room1_trigger.CFrame + Vector3.new(0, 3, 0)
    )
    checkpoint_service:register(
        "Room2Start",
        2,
        room2_trigger.CFrame + Vector3.new(0, 3, 0)
    )
    checkpoint_service:register(
        "BossRoomStart",
        3,
        boss_trigger.CFrame + Vector3.new(0, 3, 0)
    )
    local recovery_plan = apply_recovery_plan(session)
    completion_service = CompletionService.new(
        sessions,
        rewards,
        profiles,
        DungeonDefinitions.TEST_DUNGEON.CompletionReward,
        skills
    )
    return_service = ReturnPortalService.new(sessions, coordinator, {
        is_studio = RunService:IsStudio(),
        auto_return_seconds = 60,
    })

    local death_ref: any = nil
    purchase_service = RevivePurchaseService.new(sessions, {
        is_studio = RunService:IsStudio(),
        on_granted = function(user_id: number, session_id: string)
            if session_id ~= active_session_id or not death_ref then return end
            local player = Players:GetPlayerByUserId(user_id)
            if player then
                local revived = death_ref:complete_paid_revive(player)
                if not revived.ok then warn("[Dungeon Runtime] Paid revive spawn failed: " .. tostring(revived.reason)) end
            end
        end,
    })
    RevivePurchaseRegistry.set(purchase_service)

    death_service = DungeonDeathService.new(sessions, checkpoint_service, session.SessionId, {
        emit_state = emit_revive_state,
        paid_offer_provider = function(user_id: number)
            local latest = sessions:get(session.SessionId)
            return if latest then purchase_service:get_current_offer(latest, user_id) else nil
        end,
        on_member_mode = function(user_id: number, mode: string)
            encounter_service:mark_member_mode(user_id, mode)
        end,
    })
    death_ref = death_service
    return recovery_plan, true
end

local function claim_published_handoff(player: Player, session: any): (boolean, string?)
    local nonce = sessions:get_handoff_nonce(session.SessionId, player.UserId)
    if not nonce then return false, "MissingHandoffNonce" end
    local claimed = leases:claim_handoff(player.UserId, nonce)
    if not claimed.ok then return false, claimed.reason end
    sessions:clear_handoff_nonce(session.SessionId, player.UserId)
    return true, nil
end

local function bind_character(player: Player, character: Model)
    if bound_characters[character] then return end
    bound_characters[character] = true

    apply_race_presentation(
        player,
        character
    )
    character:SetAttribute(CombatConfig.TRAINING_MARAUDER.RUN_PARTICIPANT_ATTRIBUTE, true)
    character:SetAttribute(CombatConfig.TRAINING_MARAUDER.ENCOUNTER_ATTRIBUTE, current_encounter_id)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local root = character:WaitForChild("HumanoidRootPart") :: BasePart
    local handled = false
    humanoid.Died:Connect(function()
        if handled or not death_service then
            return
        end
        handled = true
        DungeonDeathPresentation.disable_view_lock(player)
        local death_result = death_service:on_player_died(
            player,
            root.CFrame
        )
        if not death_result.ok then warn("[Dungeon Runtime] Death handling failed: " .. tostring(death_result.reason)) end
    end)
end

local function load_character_at(player: Player, target: CFrame)
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    bind_character(player, character)
    character:PivotTo(target)
end

local function member_is_reconnecting(session: any, user_id: number): boolean
    local members = if type(session) == "table" then session.Members else nil
    local member = if type(members) == "table" then members[tostring(user_id)] else nil
    return type(member) == "table" and member.LastConnectedAt ~= nil
end

local function reconnect_objective(plan: any): (string, string)
    if current_encounter_id == "CombatRoom1" then
        return "Combat Room 1: defeat both Marauders.", "Active"
    elseif current_encounter_id == "CombatRoom2" then
        return "Combat Room 2: defeat the larger Marauder pack.", "Active"
    elseif current_encounter_id == "MarauderCaptain" then
        return "BOSS: Defeat the Marauder Captain.", "Boss"
    end
    return plan.objective, plan.objective_state
end

local function admit_player(player: Player)
    local session: any = nil
    local teleport_data: any = nil

    if RunService:IsStudio() then
        local studio = StudioSessionFactory.create_for_players({player}, sessions)
        if not studio.ok then
            player:Kick("Studio dungeon session failed: " .. tostring(studio.reason))
            return
        end
        session = studio.session
        teleport_data = studio.teleport_data
    else
        teleport_data = player:GetJoinData().TeleportData
        if type(teleport_data) ~= "table" or type(teleport_data.SessionId) ~= "string" then
            player:Kick("Missing dungeon session routing data.")
            return
        end
        session = sessions:get(teleport_data.SessionId)
    end

    local admission = DungeonAdmissionRules.validate(
        session,
        teleport_data,
        player.UserId,
        DungeonDefinitions.TEST_DUNGEON.Id
    )
    if not admission.ok then
        player:Kick("Dungeon admission rejected: " .. tostring(admission.reason))
        return
    end

    if not RunService:IsStudio() then
        local claimed, claim_error = claim_published_handoff(player, session)
        if not claimed then
            player:Kick("Profile handoff rejected: " .. tostring(claim_error))
            return
        end
    end

    local loaded, load_error = profiles:load(player.UserId)
    if not loaded then
        player:Kick("Profile load failed: " .. tostring(load_error))
        return
    end

    local identity_character =
        profiles:get_character(
            player.UserId,
            1
        )

    if (
        not identity_character
        or not CharacterIdentityRules
            .is_complete(identity_character)
    ) then
        if RunService:IsStudio() then
            local race_result =
                identity:select_race(
                    player.UserId,
                    "Human"
                )

            if not race_result.ok then
                profiles:release(
                    player.UserId,
                    "DungeonAdmissionFailed"
                )

                player:Kick(
                    "Studio identity bootstrap failed: "
                        .. tostring(
                            race_result.reason
                        )
                )

                return
            end

            identity_character =
                profiles:get_character(
                    player.UserId,
                    1
                )

            local creation_stage =
                identity_character
                and identity_character.Identity
                and identity_character
                    .Identity
                    .CreationStage

            if creation_stage == "ClassSelection" then
                local class_result =
                    identity:select_base_class(
                        player.UserId,
                        "Fighter"
                    )

                if not class_result.ok then
                    profiles:release(
                        player.UserId,
                        "DungeonAdmissionFailed"
                    )

                    player:Kick(
                        "Studio class bootstrap failed: "
                            .. tostring(
                                class_result.reason
                            )
                    )

                    return
                end
            end

            identity_character =
                profiles:get_character(
                    player.UserId,
                    1
                )

            if (
                not identity_character
                or not CharacterIdentityRules
                    .is_complete(
                        identity_character
                    )
            ) then
                profiles:release(
                    player.UserId,
                    "DungeonAdmissionFailed"
                )

                player:Kick(
                    "Studio identity bootstrap remained incomplete."
                )

                return
            end

            print(
                string.format(
                    "[Dungeon Runtime] Studio-only identity bootstrap: %s / %s for %s.",
                    tostring(
                        identity_character
                            .Identity
                            .RaceId
                    ),
                    tostring(
                        identity_character
                            .Identity
                            .ClassId
                    ),
                    player.Name
                )
            )
        else
            profiles:release(
                player.UserId,
                "IdentityIncomplete"
            )

            player:Kick(
                "Dungeon admission rejected: IdentityIncomplete"
            )

            return
        end
    end

    local reconnecting = member_is_reconnecting(session, player.UserId)
    local recovery_plan, runtime_created = initialize_session_services(session)
    local connected = sessions:mark_connected(session.SessionId, player.UserId)
    if not connected.ok then
        profiles:release(player.UserId, "DungeonAdmissionFailed")
        player:Kick("Session connection failed: " .. tostring(connected.reason))
        return
    end
    if reconnecting then
        local latest_session = sessions:get(session.SessionId)
        local latest_member = latest_session and latest_session.Members[tostring(player.UserId)]
        local recovery_mode = DungeonRecoveryRules.member_mode_on_reconnect(latest_member)
        if latest_member and latest_member.Mode ~= recovery_mode then
            local normalized = sessions:set_member_mode(session.SessionId, player.UserId, recovery_mode)
            if not normalized.ok then
                profiles:release(player.UserId, "DungeonAdmissionFailed")
                player:Kick("Session recovery failed: " .. tostring(normalized.reason))
                return
            end
        end
        if encounter_service then encounter_service:mark_member_mode(player.UserId, recovery_mode) end
    end
    loaded_users[player.UserId] = true
    local loaded_character = profiles:get_character(player.UserId, 1)
    if loaded_character then ProgressionRuntimeState.set_character(player.UserId, loaded_character) end
    if encounter_service then
        encounter_service:mark_member_connected(player.UserId, true)
    end
    if not reconnecting and checkpoint_service then
        local initial_checkpoint = checkpoint_service:activate("Room1Start")
        if not initial_checkpoint.ok then
            warn(
                "[Dungeon Runtime] Initial room checkpoint failed: "
                    .. tostring(initial_checkpoint.reason)
            )
        end
    end

    player.CharacterAdded:Connect(function(character)
        task.defer(ProgressionRuntimeState.apply_runtime_stats, player)
        task.defer(function()
            if character.Parent then
                bind_character(player, character)
            end
        end)
    end)

    local spawn_cframe = spawn_part.CFrame + Vector3.new(0, 3, 0)
    if reconnecting and checkpoint_service then
        spawn_cframe = checkpoint_service:get_active_checkpoint().CFrame
    end
    load_character_at(player, spawn_cframe)
    ProgressionRuntimeState.apply_runtime_stats(player)
    send_profile(player)

    if reconnecting then
        local plan = recovery_plan
        if not plan and checkpoint_service then
            local checkpoint = checkpoint_service:get_active_checkpoint()
            plan = DungeonRecoveryRules.from_checkpoint(checkpoint.Id)
        end
        plan = plan or DungeonRecoveryRules.from_checkpoint("Entrance")
        local objective, state_name = reconnect_objective(plan)
        send_objective(objective, state_name)
        if runtime_created then
            print(string.format(
                "[Dungeon Runtime] %s reconstructed %s from checkpoint %s; current encounter reset.",
                player.Name,
                session.SessionId,
                tostring(plan.spawn_checkpoint_id)
            ))
        end
    else
        send_objective("Enter Combat Room 1 to begin the dungeon.")
    end
    print(string.format("[Dungeon Runtime] %s admitted to %s.", player.Name, session.SessionId))
end

local function request_return(players_to_return: {Player})
    if not return_service or not active_session_id or not completion_committed then
        return {ok = false, reason = "ReturnNotReady"}
    end
    local returned = return_service:request_return(active_session_id, players_to_return)
    if returned.ok and returned.simulated == true then
        for _, player in ipairs(players_to_return) do
            if loaded_users[player.UserId] then
                dungeon_state:FireClient(player, {
                    state = "Complete",
                    objective = "Studio return simulated. Published TEST will teleport you back to Base.",
                    return_simulated = true,
                })
            end
        end
    elseif not returned.ok then
        warn("[Dungeon Runtime] Return request failed: " .. tostring(returned.reason))
    end
    return returned
end

return_request.OnServerEvent:Connect(function(
    player: Player,
    action: any
)
    if not loaded_users[player.UserId] then
        return
    end
    if action == "Abandon" then
        if not return_service or not active_session_id then
            emit_revive_state(player.UserId, {error = "ReturnNotReady"})
            return
        end
        local abandoned = return_service:request_abandon(
            active_session_id,
            {player}
        )
        if not abandoned.ok then
            emit_revive_state(
                player.UserId,
                {error = abandoned.reason}
            )
        elseif abandoned.simulated == true then
            dungeon_state:FireClient(player, {
                state = "Failed",
                objective = "Studio Return to Lobby simulated.",
            })
        end
        return
    end
    request_return({player})
end)

profile_snapshot.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Request" and loaded_users[player.UserId] then send_profile(player) end
end)

progression_snapshot.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Request" and loaded_users[player.UserId] then send_progression(player) end
end)

loadout_request.OnServerEvent:Connect(function(player: Player, first: any, second: any)
    if not loaded_users[player.UserId] then return end
    local context = "DungeonClear"
    if encounter_service and current_encounter_id ~= "" and not encounter_service:is_clear(current_encounter_id) then
        context = "DungeonActive"
    end
    local result:any
    if type(first)=="string" then
        result=loadout:move_to_slot(player.UserId,first,second,context)
    elseif type(first)=="table" and second==nil then
        result=loadout:set(player.UserId,first,context)
    else
        result={ok=false,reason="InvalidLoadoutRequest"}
    end
    progression_action_result:FireClient(player, {action = "Loadout", ok = result.ok == true, reason = result.reason})
    if result.ok then send_progression(player) end
end)

revive_request.OnServerEvent:Connect(function(player: Player, action: any)
    if not death_service or not loaded_users[player.UserId] then return end
    if action == "Free" then
        local result = death_service:request_free_revive(player)
        if not result.ok then emit_revive_state(player.UserId, {error = result.reason}) end
    elseif action == "Paid" then
        if RunService:IsStudio() then
            local result = purchase_service:simulate_approved_purchase(player.UserId, active_session_id)
            if not result.ok then emit_revive_state(player.UserId, {error = result.reason}) end
        else
            emit_revive_state(player.UserId, {error = "PaidRevivesLiveDisabled"})
        end
    end
end)

Players.PlayerAdded:Connect(function(player) task.spawn(admit_player, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(admit_player, player) end

Players.PlayerRemoving:Connect(function(player)
    local user_id = player.UserId
    if not loaded_users[user_id] then return end
    loaded_users[user_id] = nil
    ProgressionRuntimeState.clear_character(user_id)
    if encounter_service then encounter_service:mark_member_connected(user_id, false) end
    local session = current_session()
    if active_session_id and session and session.State == "Active" then sessions:mark_disconnected(active_session_id, user_id) end

    if coordinator:is_pending(user_id) then
        local forgot, forget_error = profiles:forget_for_handoff(user_id)
        if not forgot then warn("[Dungeon Runtime] Return handoff forget failed: " .. tostring(forget_error)) end
        coordinator:acknowledge_departure(user_id)
        return
    end

    local released, release_error = profiles:release(user_id, "DungeonPlayerRemoving")
    if not released then warn("[Dungeon Runtime] Profile release failed: " .. tostring(release_error)) end
end)

task.spawn(function()
    while true do
        task.wait(0.25)
        if death_service then
            local result = death_service:tick(os.time())
            if result.failed then
                sync_all_character_encounters("")
                send_objective("Dungeon failed: revive window expired.", "Failed")
            end
        end
        if completion_pending and not completion_committed and os.clock() >= next_completion_retry_at then
            commit_and_open_completion()
        end
        if completion_committed and return_service and active_session_id then
            local auto = return_service:tick(active_session_id, connected_loaded_players())
            if auto.triggered and auto.result and auto.result.ok and auto.result.simulated == true then
                send_objective("Studio auto-return simulated. Published TEST will return remaining players to Base.", "Complete")
            elseif auto.triggered and auto.result and not auto.result.ok then
                warn("[Dungeon Runtime] Automatic return failed: " .. tostring(auto.result.reason))
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(LEASE_RENEW_SECONDS)
        for user_id in pairs(loaded_users) do
            if not coordinator:is_pending(user_id) then
                local result = leases:renew(user_id)
                if not result.ok then warn(string.format("[Dungeon Runtime] Lease renewal failed for %d: %s", user_id, tostring(result.reason))) end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_SECONDS)
        for user_id in pairs(loaded_users) do
            if not coordinator:is_pending(user_id) then
                local ok, err = profiles:save(user_id, "DungeonAutosave")
                if not ok then warn(string.format("[Dungeon Runtime] Autosave failed for %d: %s", user_id, tostring(err))) end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(SESSION_REFRESH_SECONDS)
        if active_session_id then sessions:refresh(active_session_id) end
    end
end)

game:BindToClose(function()
    RevivePurchaseRegistry.set(nil)
    for user_id in pairs(loaded_users) do
        if coordinator:is_pending(user_id) then
            profiles:forget_for_handoff(user_id)
        else
            local session = current_session()
            if active_session_id and session and session.State == "Active" then sessions:mark_disconnected(active_session_id, user_id) end
            profiles:release(user_id, "DungeonBindToClose")
        end
    end
end)

print(
    "[Dungeon Runtime] Full Phase 2A dungeon loop ready: "
        .. "room-start checkpoints, Captain, completion and return."
)
