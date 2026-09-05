local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local AggroGraceRules = require(
    script.Parent:WaitForChild("AggroGraceRules")
)
local DamageService = require(script.Parent:WaitForChild("DamageService"))
local DefenseService = require(script.Parent:WaitForChild("DefenseService"))
local CombatValidationService = require(
    script.Parent:WaitForChild("CombatValidationService")
)
local MarauderAttackRules = require(
    script.Parent:WaitForChild("MarauderAttackRules")
)
local MarauderBehaviorRules = require(
    script.Parent:WaitForChild("MarauderBehaviorRules")
)
local MarauderPresentationService = require(
    script.Parent:WaitForChild("MarauderPresentationService")
)
local MarauderSpacingRules = require(
    script.Parent:WaitForChild("MarauderSpacingRules")
)
local StaggerService = require(script.Parent:WaitForChild("StaggerService"))

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local DEBUG = CombatConfig.DEBUG

export type AttackDefinition = {
    DISPLAY_NAME: string,
    ATTACK_REACH_STUDS: number,
    ATTACK_ARC_DEGREES: number,
    WIND_UP_SECONDS: number,
    ATTACK_LOCK_SECONDS: number,
    ATTACK_INTERVAL_SECONDS: number,
    HEALTH_DAMAGE: number,
    STAMINA_DAMAGE: number,
    TELEGRAPH_COLOR: Color3,
}

type TargetContext = {
    player: Player,
    character: Model,
    root: BasePart,
    distance: number,
}

type MarauderRuntime = {
    model: Model,
    root: BasePart,
    body: BasePart,
    humanoid: Humanoid,
    spawn_cframe: CFrame,
    normal_body_color: Color3,
    normal_material: Enum.Material,
    next_attack_at: number,
    attacking: boolean,
    stagger_feedback_sequence: number,
    current_target: Player?,
    pattern_index: number,
    life_sequence: number,
    steering_candidate_index: number?,
    steering_commit_until: number,
}

local runtimes: {MarauderRuntime} = {}
local runtime_by_model: {[Model]: MarauderRuntime} = {}
local attach_death_handler: (MarauderRuntime) -> ()


--[[Sets one Marauder's replicated AI state.]]
local function set_ai_state(runtime: MarauderRuntime, state_name: string)
    runtime.model:SetAttribute(MarauderConfig.AI_STATE_ATTRIBUTE, state_name)
end


--[[Clears a Marauder's temporary avoidance steering commitment.]]
local function clear_steering_commit(runtime: MarauderRuntime)
    runtime.steering_candidate_index = nil
    runtime.steering_commit_until = 0
end


--[[Sets one Marauder's retained target and debug attribute.]]
local function set_current_target(runtime: MarauderRuntime, player: Player?)
    if runtime.current_target ~= player then
        clear_steering_commit(runtime)
    end

    runtime.current_target = player
    runtime.model:SetAttribute(
        MarauderConfig.AGGRO_TARGET_ATTRIBUTE,
        if player then player.UserId else 0
    )
end


--[[Returns planar XZ offset and distance between two positions.]]
local function get_planar_offset(
    from_position: Vector3,
    to_position: Vector3
): (Vector3, number)
    local offset = Vector3.new(
        to_position.X - from_position.X,
        0,
        to_position.Z - from_position.Z
    )

    return offset, offset.Magnitude
end


--[[Returns the active character and root for a living player.]]
local function get_living_character(player: Player): (Model?, BasePart?)
    local character = player.Character

    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid
        or humanoid.Health <= 0
        or not root
        or not root:IsA("BasePart") then
        return nil, nil
    end

    return character, root
end


--[[Builds target context for one Marauder/player pair.]]
local function get_target_context(
    runtime: MarauderRuntime,
    player: Player
): TargetContext?
    local character, target_root = get_living_character(player)

    if not character or not target_root then
        return nil
    end

    local model_encounter = runtime.model:GetAttribute(MarauderConfig.ENCOUNTER_ATTRIBUTE)
    local target_is_dungeon_member = character:GetAttribute(MarauderConfig.RUN_PARTICIPANT_ATTRIBUTE) == true
    local target_encounter = character:GetAttribute(MarauderConfig.ENCOUNTER_ATTRIBUTE)
    if type(model_encounter) == "string" and model_encounter ~= "" then
        if target_encounter ~= model_encounter then
            return nil
        end
    elseif target_is_dungeon_member then
        -- Keep the legacy Phase 1 training pack isolated from real dungeon participants.
        return nil
    end

    local aggro_suppressed = character:GetAttribute(
        MarauderConfig.AGGRO_SUPPRESSED_ATTRIBUTE
    ) == true

    if not AggroGraceRules.can_target(aggro_suppressed) then
        return nil
    end

    local _, distance = get_planar_offset(
        runtime.root.Position,
        target_root.Position
    )

    return {
        player = player,
        character = character,
        root = target_root,
        distance = distance,
    }
end


--[[Finds the nearest living room target for one Marauder.]]
local function find_nearest_target(runtime: MarauderRuntime): TargetContext?
    local best_context: TargetContext? = nil

    for _, player in Players:GetPlayers() do
        local context = get_target_context(runtime, player)

        if context
            and MarauderBehaviorRules.can_acquire(context.distance)
            and (not best_context or context.distance < best_context.distance) then
            best_context = context
        end
    end

    return best_context
end


--[[Retains or reacquires one Marauder's target.]]
local function update_target(runtime: MarauderRuntime): TargetContext?
    if runtime.current_target then
        local retained = get_target_context(runtime, runtime.current_target)

        if retained and MarauderBehaviorRules.can_retain(retained.distance) then
            return retained
        end

        set_current_target(runtime, nil)
    end

    local acquired = find_nearest_target(runtime)

    if acquired then
        set_current_target(runtime, acquired.player)
    end

    return acquired
end


--[[Faces one Marauder toward a target root on the ground plane.]]
local function face_target(runtime: MarauderRuntime, target_root: BasePart)
    local target_position = Vector3.new(
        target_root.Position.X,
        runtime.root.Position.Y,
        target_root.Position.Z
    )

    if (target_position - runtime.root.Position).Magnitude <= 1e-6 then
        return
    end

    runtime.model:PivotTo(CFrame.lookAt(runtime.root.Position, target_position))
end


--[[Builds chase/attack raycast exclusions for the multi-enemy prototype.]]
local function get_raycast_exclusions(target_character: Model): {Instance}
    local exclusions: {Instance} = {target_character}

    for _, runtime in runtimes do
        table.insert(exclusions, runtime.model)
    end

    return exclusions
end


--[[Returns whether one proposed Marauder chase movement is unobstructed.]]
local function is_chase_path_clear(
    runtime: MarauderRuntime,
    character: Model,
    movement: Vector3
): boolean
    if movement.Magnitude <= 1e-6 then
        return true
    end

    local params = RaycastParams.new()

    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = get_raycast_exclusions(character)
    params.RespectCanCollide = true

    return Workspace:Raycast(runtime.root.Position, movement, params) == nil
end


--[[Returns living Marauder root positions other than this runtime.]]
local function get_other_marauder_positions(
    runtime: MarauderRuntime
): {Vector3}
    local positions = {}

    for _, other_runtime in runtimes do
        if other_runtime ~= runtime
            and other_runtime.model.Parent
            and other_runtime.humanoid.Health > 0 then
            table.insert(positions, other_runtime.root.Position)
        end
    end

    return positions
end


--[[Chooses a chase step that preserves enemy personal space.]]
local function choose_chase_movement(
    runtime: MarauderRuntime,
    character: Model,
    desired_movement: Vector3
): Vector3
    local other_positions = get_other_marauder_positions(runtime)
    local candidates = MarauderSpacingRules.get_movement_candidates(
        desired_movement
    )
    local now = os.clock()
    local committed_index = runtime.steering_candidate_index

    if now >= runtime.steering_commit_until then
        committed_index = nil
        clear_steering_commit(runtime)
    end

    local candidate_order = MarauderSpacingRules.get_candidate_order(
        #candidates,
        committed_index
    )

    for _, candidate_index in candidate_order do
        local candidate = candidates[candidate_index]
        local next_position = runtime.root.Position + candidate
        local spacing_allowed = MarauderSpacingRules.is_position_allowed(
            runtime.root.Position,
            next_position,
            other_positions,
            MarauderConfig.MIN_CENTER_SEPARATION_STUDS
        )

        if spacing_allowed
            and is_chase_path_clear(runtime, character, candidate) then
            if candidate_index == 1 then
                clear_steering_commit(runtime)
            elseif committed_index ~= candidate_index then
                runtime.steering_candidate_index = candidate_index
                runtime.steering_commit_until = now
                    + MarauderConfig.STEERING_COMMIT_SECONDS
            end

            return candidate
        end
    end

    clear_steering_commit(runtime)
    return Vector3.zero
end

--[[Moves one Marauder toward its retained target for one AI tick.]]
local function chase_target(
    runtime: MarauderRuntime,
    context: TargetContext,
    delta_seconds: number
)
    local offset = get_planar_offset(runtime.root.Position, context.root.Position)
    local movement_distance = MarauderBehaviorRules.get_chase_step(
        context.distance,
        delta_seconds
    )

    if movement_distance <= 0 or offset.Magnitude <= 1e-6 then
        MarauderPresentationService.reset_pose(runtime.model, 0)
        face_target(runtime, context.root)
        return
    end

    local desired_movement = offset.Unit * movement_distance
    local movement = choose_chase_movement(
        runtime,
        context.character,
        desired_movement
    )

    if movement.Magnitude <= 1e-6 then
        MarauderPresentationService.reset_pose(runtime.model, 0)
        face_target(runtime, context.root)
        return
    end

    local next_position = runtime.root.Position + movement
    local look_position = Vector3.new(
        context.root.Position.X,
        next_position.Y,
        context.root.Position.Z
    )

    runtime.model:PivotTo(CFrame.lookAt(next_position, look_position))
    MarauderPresentationService.set_chase_pose(runtime.model, os.clock())
end


--[[Restores ordinary body presentation when no action owns it.]]
local function restore_body_if_idle(runtime: MarauderRuntime)
    if runtime.humanoid.Health <= 0
        or runtime.attacking
        or StaggerService.is_staggered(runtime.model) then
        return
    end

    runtime.body.Material = runtime.normal_material
    runtime.body.Color = runtime.normal_body_color
    MarauderPresentationService.reset_pose(runtime.model, 0.12)
end


--[[Refreshes one Marauder's stagger feedback from shared stagger state.]]
local function refresh_stagger_feedback(runtime: MarauderRuntime)
    runtime.stagger_feedback_sequence += 1
    local sequence_id = runtime.stagger_feedback_sequence
    local remaining = StaggerService.get_remaining(runtime.model)

    if remaining <= 0 then
        restore_body_if_idle(runtime)
        return
    end

    set_ai_state(runtime, "Staggered")
    runtime.body.Material = Enum.Material.Neon
    runtime.body.Color = Color3.fromRGB(110, 175, 235)
    MarauderPresentationService.play_stagger(runtime.model, remaining)

    task.delay(remaining, function()
        if sequence_id == runtime.stagger_feedback_sequence then
            restore_body_if_idle(runtime)
        end
    end)
end


--[[Clears one Marauder's active attack presentation.]]
local function clear_attack_presentation(runtime: MarauderRuntime)
    runtime.model:SetAttribute("AttackTelegraph", false)
    runtime.model:SetAttribute(MarauderConfig.ATTACK_NAME_ATTRIBUTE, "")
    runtime.attacking = false
end


--[[Cancels one attack after an interrupting stagger.]]
local function cancel_attack_for_stagger(runtime: MarauderRuntime)
    clear_attack_presentation(runtime)
    set_ai_state(runtime, "Staggered")
    refresh_stagger_feedback(runtime)
end


--[[Checks whether one committed strike can geometrically reach its target.]]
local function can_hit(
    runtime: MarauderRuntime,
    character: Model,
    target_root: BasePart,
    attack_definition: AttackDefinition
): (boolean, string?)
    local offset = get_planar_offset(runtime.root.Position, target_root.Position)

    if offset.Magnitude > attack_definition.ATTACK_REACH_STUDS then
        return false, "Range"
    end

    if offset.Magnitude <= 1e-6 then
        return false, "Overlap"
    end

    local forward = Vector3.new(
        runtime.root.CFrame.LookVector.X,
        0,
        runtime.root.CFrame.LookVector.Z
    )

    if forward.Magnitude <= 1e-6 then
        return false, "Facing"
    end

    local dot = math.clamp(forward.Unit:Dot(offset.Unit), -1, 1)
    local angle = math.deg(math.acos(dot))

    if angle > attack_definition.ATTACK_ARC_DEGREES / 2 then
        return false, "Arc"
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = get_raycast_exclusions(character)
    params.RespectCanCollide = true

    if Workspace:Raycast(
        runtime.root.Position,
        target_root.Position - runtime.root.Position,
        params
    ) then
        return false, "Obstructed"
    end

    return true, nil
end


--[[Applies one committed Marauder strike through defence and damage services.]]
local function resolve_strike(
    runtime: MarauderRuntime,
    player: Player,
    attack_name: string,
    attack_definition: AttackDefinition
)
    local character, target_root = get_living_character(player)

    if not character or not target_root then
        CombatValidationService.emit(
            player,
            "ENEMY_HIT",
            "REJECT",
            runtime.model.Name .. " " .. attack_name .. " TargetUnavailable",
            nil
        )
        return
    end

    local can_reach, rejection_reason = can_hit(
        runtime,
        character,
        target_root,
        attack_definition
    )

    if not can_reach then
        CombatValidationService.emit(
            player,
            "ENEMY_HIT",
            "REJECT",
            runtime.model.Name
                .. " "
                .. attack_name
                .. " "
                .. tostring(rejection_reason),
            nil
        )
        return
    end

    local source_id = "TrainingMarauder" .. attack_name
    local result = DefenseService.resolve({
        attacker = runtime.model,
        target_player = player,
        target_character = character,
        source_kind = "EnemyMelee",
        source_id = source_id,
        attack_position = runtime.root.Position,
        stamina_damage = attack_definition.STAMINA_DAMAGE,
        blockable = true,
        parryable = true,
    })

    if DEBUG.PRINT_DEFENSE then
        print(string.format("[Defense] %s %s -> %s", runtime.model.Name, attack_name, result.outcome))
    end

    CombatValidationService.emit(
        player,
        "ENEMY_ATTACK",
        string.upper(result.outcome),
        runtime.model.Name .. " " .. attack_name,
        nil
    )

    if result.outcome == "Parried" then
        StaggerService.apply(runtime.model, result.attacker_stagger_seconds)
        return
    end

    if result.outcome == "Hit" then
        DamageService.apply_damage({
            attacker = nil,
            attacker_character = runtime.model,
            target = character,
            source_kind = "EnemyMelee",
            source_id = source_id,
            attack_id = nil,
            base_damage = attack_definition.HEALTH_DAMAGE,
            multiplier = 1,
            sequence_id = runtime.life_sequence,
        })
    end
end


--[[Returns whether death/stagger/life reset invalidates one attack task.]]
local function attack_is_interrupted(
    runtime: MarauderRuntime,
    life_sequence: number
): boolean
    return runtime.life_sequence ~= life_sequence
        or runtime.humanoid.Health <= 0
        or StaggerService.is_staggered(runtime.model)
end


--[[Runs one configured Marauder attack sequence.]]
local function attack(runtime: MarauderRuntime, player: Player)
    if runtime.attacking
        or runtime.humanoid.Health <= 0
        or StaggerService.is_staggered(runtime.model) then
        return
    end

    local _, target_root = get_living_character(player)
    if not target_root then
        return
    end

    local life_sequence = runtime.life_sequence
    local attack_name = MarauderAttackRules.get_attack_name(runtime.pattern_index)
    local attack_definition = MarauderAttackRules.get_attack_definition(attack_name) :: AttackDefinition

    runtime.pattern_index = MarauderAttackRules.get_next_pattern_index(runtime.pattern_index)
    runtime.attacking = true
    runtime.next_attack_at = os.clock() + attack_definition.ATTACK_INTERVAL_SECONDS
    set_ai_state(runtime, "Attacking")
    face_target(runtime, target_root)

    runtime.body.Material = Enum.Material.Neon
    runtime.body.Color = attack_definition.TELEGRAPH_COLOR
    runtime.model:SetAttribute("AttackTelegraph", true)
    runtime.model:SetAttribute(MarauderConfig.ATTACK_NAME_ATTRIBUTE, attack_name)

    local early_windup = math.max(
        0,
        attack_definition.WIND_UP_SECONDS - attack_definition.ATTACK_LOCK_SECONDS
    )
    MarauderPresentationService.play_attack_windup(
        runtime.model,
        attack_name,
        early_windup
    )
    task.wait(early_windup)

    if attack_is_interrupted(runtime, life_sequence) then
        CombatValidationService.emit(
            player,
            "ENEMY_SEQUENCE",
            "CANCELLED",
            runtime.model.Name .. " " .. attack_name,
            nil
        )
        if StaggerService.is_staggered(runtime.model) then
            cancel_attack_for_stagger(runtime)
        end
        return
    end

    local _, lock_root = get_living_character(player)
    if lock_root then
        face_target(runtime, lock_root)
    end

    MarauderPresentationService.play_attack_strike(
        runtime.model,
        attack_name,
        attack_definition.ATTACK_LOCK_SECONDS
    )
    task.wait(attack_definition.ATTACK_LOCK_SECONDS)
    if attack_is_interrupted(runtime, life_sequence) then
        CombatValidationService.emit(
            player,
            "ENEMY_SEQUENCE",
            "CANCELLED",
            runtime.model.Name .. " " .. attack_name,
            nil
        )
        if StaggerService.is_staggered(runtime.model) then
            cancel_attack_for_stagger(runtime)
        end
        return
    end

    runtime.model:SetAttribute("AttackTelegraph", false)
    runtime.body.Material = runtime.normal_material
    runtime.body.Color = runtime.normal_body_color
    resolve_strike(runtime, player, attack_name, attack_definition)
    clear_attack_presentation(runtime)
    restore_body_if_idle(runtime)
end


--[[Runs one hostile-loop update for one Marauder.]]
local function update_hostile_loop(runtime: MarauderRuntime, delta_seconds: number)
    if runtime.humanoid.Health <= 0 then
        set_ai_state(runtime, "Dead")
        return
    end

    if StaggerService.is_staggered(runtime.model) then
        set_ai_state(runtime, "Staggered")
        return
    end

    if runtime.attacking then
        set_ai_state(runtime, "Attacking")
        return
    end

    local context = update_target(runtime)
    if not context then
        set_ai_state(runtime, "Idle")
        MarauderPresentationService.reset_pose(runtime.model, 0)
        return
    end

    if MarauderBehaviorRules.get_range_state(context.distance) == "Chasing" then
        set_ai_state(runtime, "Chasing")
        chase_target(runtime, context, delta_seconds)
        return
    end

    set_ai_state(runtime, "Ready")
    MarauderPresentationService.reset_pose(runtime.model, 0)
    face_target(runtime, context.root)
    if os.clock() >= runtime.next_attack_at then
        task.spawn(attack, runtime, context.player)
    end
end


--[[Creates a fresh Humanoid for one respawned Marauder.]]
local function create_humanoid(model: Model): Humanoid
    local humanoid = Instance.new("Humanoid")

    humanoid.MaxHealth = MarauderConfig.MAX_HEALTH
    humanoid.Health = MarauderConfig.MAX_HEALTH
    humanoid.DisplayName = "Training Marauder"
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = model

    return humanoid
end


--[[Resets one dead Marauder to its original independent spawn.]]
local function reset_runtime(runtime: MarauderRuntime)
    local old_humanoid = runtime.model:FindFirstChildOfClass("Humanoid")
    if old_humanoid then
        old_humanoid:Destroy()
    end

    runtime.humanoid = create_humanoid(runtime.model)
    runtime.model:PivotTo(runtime.spawn_cframe)
    runtime.body.Material = runtime.normal_material
    runtime.body.Color = runtime.normal_body_color
    MarauderPresentationService.reset_pose(runtime.model, 0)
    runtime.attacking = false
    runtime.pattern_index = 1
    runtime.next_attack_at = os.clock() + MarauderConfig.RESPAWN_ATTACK_DELAY_SECONDS
    runtime.stagger_feedback_sequence += 1

    StaggerService.clear(runtime.model)
    set_current_target(runtime, nil)
    runtime.model:SetAttribute("AttackTelegraph", false)
    runtime.model:SetAttribute(MarauderConfig.ATTACK_NAME_ATTRIBUTE, "")
    set_ai_state(runtime, "Idle")
    attach_death_handler(runtime)
end


--[[Handles one Marauder death and schedules guarded respawn.]]
local function handle_death(runtime: MarauderRuntime)
    runtime.life_sequence += 1
    local expected_sequence = runtime.life_sequence

    StaggerService.clear(runtime.model)
    set_current_target(runtime, nil)
    clear_attack_presentation(runtime)
    MarauderPresentationService.play_death(runtime.model)
    set_ai_state(runtime, "Dead")

    if runtime.model:GetAttribute("MarauderRespawnEnabled") == false then
        return
    end

    task.delay(MarauderConfig.RESPAWN_SECONDS, function()
        if runtime.model.Parent
            and runtime.life_sequence == expected_sequence
            and runtime.humanoid.Health <= 0 then
            reset_runtime(runtime)
        end
    end)
end


attach_death_handler = function(runtime: MarauderRuntime)
    runtime.humanoid.Died:Connect(function()
        handle_death(runtime)
    end)
end


--[[Builds runtime state around one configured Marauder model.]]
local function create_runtime(model: Model, spawn_cframe: CFrame): MarauderRuntime
    local root = model:WaitForChild("HumanoidRootPart") :: BasePart
    local body = model:WaitForChild("Body") :: BasePart
    local humanoid = model:WaitForChild("Humanoid") :: Humanoid

    return {
        model = model,
        root = root,
        body = body,
        humanoid = humanoid,
        spawn_cframe = spawn_cframe,
        normal_body_color = body.Color,
        normal_material = body.Material,
        next_attack_at = os.clock() + 3,
        attacking = false,
        stagger_feedback_sequence = 0,
        current_target = nil,
        pattern_index = 1,
        life_sequence = 0,
        steering_candidate_index = nil,
        steering_commit_until = 0,
    }
end


--[[Initialises replicated state and listeners for one runtime.]]
local function initialise_runtime(runtime: MarauderRuntime)
    set_ai_state(runtime, "Idle")
    set_current_target(runtime, nil)
    runtime.model:SetAttribute("AttackTelegraph", false)
    runtime.model:SetAttribute(MarauderConfig.ATTACK_NAME_ATTRIBUTE, "")
    MarauderPresentationService.reset_pose(runtime.model, 0)

    runtime.model:GetAttributeChangedSignal("CombatStaggeredUntil"):Connect(
        function()
            refresh_stagger_feedback(runtime)
        end
    )
    attach_death_handler(runtime)
end


local function get_spawn_cframe(model: Model): CFrame
    local x = model:GetAttribute("MarauderSpawnX")
    local y = model:GetAttribute("MarauderSpawnY")
    local z = model:GetAttribute("MarauderSpawnZ")
    if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        return CFrame.new(x, y, z)
    end
    return model:GetPivot()
end

local function attach_model(model_instance: Instance)
    if not model_instance:IsA("Model") or runtime_by_model[model_instance] then
        return
    end

    task.spawn(function()
        if not model_instance.Parent or runtime_by_model[model_instance] then
            return
        end
        local model = model_instance :: Model
        local runtime = create_runtime(model, get_spawn_cframe(model))
        runtime_by_model[model] = runtime
        table.insert(runtimes, runtime)
        initialise_runtime(runtime)
    end)
end

for _, tagged in ipairs(CollectionService:GetTagged(MarauderConfig.CONTROLLER_TAG)) do
    attach_model(tagged)
end

CollectionService:GetInstanceAddedSignal(MarauderConfig.CONTROLLER_TAG):Connect(attach_model)


task.spawn(function()
    local previous_tick = os.clock()

    while true do
        task.wait(MarauderConfig.AI_TICK_SECONDS)

        local now = os.clock()
        local delta_seconds = math.min(0.25, math.max(0, now - previous_tick))
        previous_tick = now

        for _, runtime in runtimes do
            if runtime.model.Parent then
                update_hostile_loop(runtime, delta_seconds)
            end
        end
    end
end)
