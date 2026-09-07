local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local shared_folder = combat_folder:WaitForChild("Shared")
local remotes_folder = combat_folder:WaitForChild("Remotes")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local StateRules = require(
    shared_folder:WaitForChild("StateRules")
)
local AttackStepRules = require(
    shared_folder:WaitForChild("AttackStepRules")
)
local HotbarConfig = require(
    shared_folder:WaitForChild("HotbarConfig")
)
local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)

local MeleeHitService = require(
    script.Parent:WaitForChild("MeleeHitService")
)
local DamageService = require(
    script.Parent:WaitForChild("DamageService")
)
local SkillCooldownService = require(
    script.Parent:WaitForChild("SkillCooldownService")
)
local MendService = require(
    script.Parent:WaitForChild("MendService")
)
local StaggerService = require(
    script.Parent:WaitForChild("StaggerService")
)
local StaminaService = require(
    script.Parent:WaitForChild("StaminaService")
)
local DefenseService = require(
    script.Parent:WaitForChild("DefenseService")
)
local DodgeDirectionRules = require(
    script.Parent:WaitForChild("DodgeDirectionRules")
)
local DodgeClearanceRules = require(
    script.Parent:WaitForChild("DodgeClearanceRules")
)
local CombatValidationService = require(
    script.Parent:WaitForChild("CombatValidationService")
)
local ProgressionRuntimeState = require(
    ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProgressionRuntimeState")
)
local DungeonProgressionBridge = require(
    ServerScriptService:WaitForChild("Dungeon"):WaitForChild("DungeonProgressionBridge")
)

local attack_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.ATTACK_REQUEST
) :: RemoteEvent
local state_changed = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.STATE_CHANGED
) :: RemoteEvent
local defense_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.DEFENSE_REQUEST
) :: RemoteEvent
local skill_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.SKILL_REQUEST
) :: RemoteEvent

local State = CombatTypes.State
local BasicAttack = CombatConfig.BASIC_ATTACK

type PlayerCombatState = {
    state_name: string,
    state_started_at: number,
    current_attack_id: string?,
    current_skill_id: string?,
    next_attack_id: string,
    queued_attack: boolean,
    combo_expires_at: number,
    sequence_id: number,
    base_walk_speed: number,
}

local player_states: {[Player]: PlayerCombatState} = {}
local has_spawned_character: {[Player]: boolean} = {}

type DodgeMovementProfile = {
    distance: number,
    duration: number,
    start_speed_multiplier: number,
    end_speed_multiplier: number,
}

type DodgeMovementRecord = {
    player: Player,
    character: Model,
    root_part: BasePart,
    velocity: LinearVelocity,
    raycast_params: RaycastParams,
    started_at: number,
    distance: number,
    duration: number,
    start_speed_multiplier: number,
    end_speed_multiplier: number,
    clearance: number,
    input_code: string,
    view_locked: boolean,
    unlocked_direction: Vector3?,
    heartbeat_connection: RBXScriptConnection?,
}

local dodge_movements: {[Player]: DodgeMovementRecord} = {}


--[[
Creates a fresh authoritative combat record for a player.

Args:
    base_walk_speed (number): Character walk speed outside attack states.

Returns:
    PlayerCombatState: New combat record in the Locomotion state.
]]
local function create_player_state(base_walk_speed: number): PlayerCombatState
    return {
        state_name = State.LOCOMOTION,
        state_started_at = os.clock(),
        current_attack_id = nil,
        current_skill_id = nil,
        next_attack_id = BasicAttack.ATTACK_ORDER[1],
        queued_attack = false,
        combo_expires_at = 0,
        sequence_id = 0,
        base_walk_speed = base_walk_speed,
    }
end


--[[Returns the current committed offensive/support action label.]]
local function get_committed_action_label(
    record: PlayerCombatState
): string?
    if record.current_skill_id then
        return record.current_skill_id
    end

    if record.current_attack_id then
        return record.current_attack_id
    end

    if record.state_name == State.MENDING then
        return "Mend"
    end

    return nil
end


--[[Reports cancellation before a defensive action invalidates a sequence.]]
local function report_sequence_cancel(
    player: Player,
    record: PlayerCombatState,
    reason: string
)
    local action_label = get_committed_action_label(record)

    if action_label then
        CombatValidationService.emit(
            player,
            "SEQUENCE",
            "CANCELLED",
            action_label .. " by " .. reason,
            record.sequence_id
        )
    end
end


--[[
Gets the active humanoid and root part for a player.

Args:
    player (Player): Player whose character is required.

Returns:
    Humanoid?: Active Humanoid when available.
    BasePart?: Active HumanoidRootPart when available.
]]
local function get_character_parts(
    player: Player
): (Humanoid?, BasePart?)
    local character = player.Character

    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root_part = character:FindFirstChild("HumanoidRootPart")

    if not root_part or not root_part:IsA("BasePart") then
        return humanoid, nil
    end

    return humanoid, root_part
end


--[[
Writes diagnostic combat attributes onto the active character.

Args:
    player (Player): Player whose character receives attributes.
    record (PlayerCombatState): Current authoritative combat record.

Returns:
    None.
]]
local function update_character_attributes(
    player: Player,
    record: PlayerCombatState
)
    local character = player.Character

    if not character then
        return
    end

    character:SetAttribute("CombatState", record.state_name)
    character:SetAttribute(
        "CurrentAttackId",
        record.current_attack_id or ""
    )
    character:SetAttribute(
        "CurrentSkillId",
        record.current_skill_id or ""
    )
    character:SetAttribute("AttackBuffered", record.queued_attack)
end


--[[
Applies state-specific movement commitment on the server.

Args:
    player (Player): Player whose Humanoid is updated.
    record (PlayerCombatState): Current authoritative combat record.

Returns:
    None.
]]
local function apply_movement_scale(
    player: Player,
    record: PlayerCombatState
)
    local humanoid = get_character_parts(player)

    if not humanoid then
        return
    end

    local scale = 1

    if record.state_name == State.DODGING
        or record.state_name == State.GUARD_BREAK
        or record.state_name == State.MENDING
        or record.state_name == State.DEAD then
        scale = 0
    elseif record.current_attack_id then
        local attack_definition = BasicAttack.ATTACKS[
            record.current_attack_id
        ]

        if attack_definition then
            scale = StateRules.get_movement_scale(
                record.state_name,
                attack_definition
            )
        end
    elseif record.current_skill_id then
        local skill_definition = SkillDefinitions.get(
            record.current_skill_id
        )

        if skill_definition then
            scale = StateRules.get_movement_scale(
                record.state_name,
                skill_definition
            )
        end
    end

    humanoid.WalkSpeed = record.base_walk_speed * scale

    local mending = record.state_name == State.MENDING
    humanoid.Jump = false
    humanoid:SetStateEnabled(
        Enum.HumanoidStateType.Jumping,
        not mending
    )
end


--[[
Publishes an authoritative state transition to diagnostics and the client.

Args:
    player (Player): Player whose state is changing.
    record (PlayerCombatState): Authoritative combat record.
    next_state (string): State to enter.

Returns:
    boolean: True when the transition was accepted.
]]
local function set_state(
    player: Player,
    record: PlayerCombatState,
    next_state: string
): boolean
    if record.state_name ~= next_state then
        local allowed = StateRules.can_transition(
            record.state_name,
            next_state
        )

        if not allowed then
            warn(
                string.format(
                    "[Combat] Rejected state transition %s -> %s for %s.",
                    record.state_name,
                    next_state,
                    player.Name
                )
            )
            return false
        end
    end

    record.state_name = next_state
    record.state_started_at = os.clock()

    apply_movement_scale(player, record)
    update_character_attributes(player, record)

    state_changed:FireClient(
        player,
        record.state_name,
        record.current_attack_id
            or record.current_skill_id
            or "",
        Workspace:GetServerTimeNow()
    )

    return true
end


--[[
Applies a brief planar velocity so attack commitment reads as a step.

Args:
    player (Player): Player whose character receives the step.
    distance (number): Requested forward travel in studs.
    attack_definition (table): Current attack timing definition.

Returns:
    None.
]]
local function apply_forward_step(
    player: Player,
    distance: number,
    attack_definition: any
)
    local character = player.Character
    local _, root_part = get_character_parts(player)

    if not character or not root_part then
        return
    end

    local forward = Vector3.new(
        root_part.CFrame.LookVector.X,
        0,
        root_part.CFrame.LookVector.Z
    )

    if forward.Magnitude < 0.001 then
        return
    end

    forward = forward.Unit

    local raycast_params = RaycastParams.new()
    raycast_params.FilterType =
        Enum.RaycastFilterType.Exclude
    raycast_params.FilterDescendantsInstances = {
        character,
    }
    raycast_params.IgnoreWater = true

    local result = Workspace:Raycast(
        root_part.Position,
        forward * distance,
        raycast_params
    )

    local obstacle_distance = nil

    if result then
        obstacle_distance = result.Distance
    end

    local allowed_distance =
        AttackStepRules.get_allowed_distance(
            distance,
            obstacle_distance
        )

    if allowed_distance <= 0 then
        return
    end

    local duration =
        AttackStepRules.get_step_duration(
            attack_definition
        )
    local speed =
        AttackStepRules.get_step_speed(
            allowed_distance,
            duration
        )

    local old_velocity = root_part:FindFirstChild(
        "CombatStepVelocity"
    )

    if old_velocity then
        old_velocity:Destroy()
    end

    local attachment = root_part:FindFirstChild(
        "CombatStepAttachment"
    )

    if not attachment
        or not attachment:IsA("Attachment") then
        attachment = Instance.new("Attachment")
        attachment.Name = "CombatStepAttachment"
        attachment.Parent = root_part
    end

    local velocity = Instance.new("LinearVelocity")

    velocity.Name = "CombatStepVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo =
        Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode =
        Enum.VelocityConstraintMode.Plane
    velocity.PrimaryTangentAxis =
        Vector3.new(1, 0, 0)
    velocity.SecondaryTangentAxis =
        Vector3.new(0, 0, 1)
    velocity.PlaneVelocity = Vector2.new(
        forward.X * speed,
        forward.Z * speed
    )
    velocity.ForceLimitsEnabled = false
    velocity.Parent = root_part

    task.delay(duration, function()
        if velocity.Parent then
            velocity:Destroy()
        end
    end)
end


--[[
Stops any active attack/skill forward-step velocity before a higher-priority
defensive movement begins.

Args:
    player (Player): Player whose attack step must be cancelled.

Returns:
    None.
]]
local function stop_attack_step(player: Player)
    local _, root_part = get_character_parts(player)

    if not root_part then
        return
    end

    local velocity = root_part:FindFirstChild("CombatStepVelocity")

    if velocity then
        velocity:Destroy()
    end
end


--[[
Returns the movement profile for one dodge input.

Pure A/D input uses the shorter lateral slide-dash only while View Lock is
active. Unlocked camera-relative dodges always use the forward-roll profile.

Args:
    input_code (string): Validated eight-way dodge input code.

Returns:
    DodgeMovementProfile: Server-owned distance, duration, and speed curve.
]]
local function get_dodge_profile(
    input_code: string,
    view_locked: boolean
): DodgeMovementProfile
    if DodgeDirectionRules.should_use_lateral_profile(
        input_code,
        view_locked
    ) then
        return {
            distance = CombatConfig.DEFENSE.SIDE_DASH_DISTANCE_STUDS,
            duration = CombatConfig.DEFENSE.SIDE_DASH_DURATION_SECONDS,
            start_speed_multiplier = CombatConfig.DEFENSE
                .SIDE_DASH_START_SPEED_MULTIPLIER,
            end_speed_multiplier = CombatConfig.DEFENSE
                .SIDE_DASH_END_SPEED_MULTIPLIER,
        }
    end

    return {
        distance = CombatConfig.DEFENSE.DODGE_DISTANCE_STUDS,
        duration = CombatConfig.DEFENSE.DODGE_DURATION_SECONDS,
        start_speed_multiplier = CombatConfig.DEFENSE
            .DODGE_START_SPEED_MULTIPLIER,
        end_speed_multiplier = CombatConfig.DEFENSE
            .DODGE_END_SPEED_MULTIPLIER,
    }
end


--[[
Returns the current dodge speed from normalized movement progress.

Args:
    movement (DodgeMovementRecord): Active dodge movement profile.
    progress (number): Normalized dodge progress from zero to one.

Returns:
    number: Desired planar dodge speed in studs per second.
]]
local function get_dodge_speed(
    movement: DodgeMovementRecord,
    progress: number
): number
    local clamped = math.clamp(progress, 0, 1)
    local eased = clamped * clamped * (3 - (2 * clamped))
    local multiplier = movement.start_speed_multiplier
        + (
            (movement.end_speed_multiplier
                - movement.start_speed_multiplier)
            * eased
        )
    local average_speed = movement.distance / movement.duration

    return average_speed * multiplier
end


--[[
Stops and removes the active dodge movement for one player.

Args:
    player (Player): Player whose dodge movement is stopped.

Returns:
    None.
]]
local function stop_dodge_movement(player: Player)
    local movement = dodge_movements[player]

    if not movement then
        return
    end

    dodge_movements[player] = nil

    if movement.heartbeat_connection then
        movement.heartbeat_connection:Disconnect()
        movement.heartbeat_connection = nil
    end

    if movement.velocity.Parent then
        movement.velocity:Destroy()
    end

    if movement.character.Parent then
        movement.character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE,
            Vector3.zero
        )
        movement.character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_STYLE_ATTRIBUTE,
            ""
        )
        movement.character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_VIEW_LOCKED_ATTRIBUTE,
            false
        )
    end
end


--[[
Updates one steerable dodge movement from current movement input and facing.

Args:
    movement (DodgeMovementRecord): Active dodge movement record.
    delta_time (number): Server Heartbeat delta in seconds.

Returns:
    None.
]]
local function update_dodge_movement(
    movement: DodgeMovementRecord,
    delta_time: number
)
    if dodge_movements[movement.player] ~= movement then
        return
    end

    if movement.player.Character ~= movement.character
        or movement.root_part.Parent ~= movement.character
        or not movement.velocity.Parent then
        stop_dodge_movement(movement.player)
        return
    end

    local elapsed = os.clock() - movement.started_at

    if elapsed >= movement.duration then
        stop_dodge_movement(movement.player)
        return
    end

    local root_part = movement.root_part
    local direction = movement.unlocked_direction

    if DodgeDirectionRules.should_follow_facing_during_dodge(
        movement.view_locked
    ) then
        direction = DodgeDirectionRules.resolve(
            movement.input_code,
            root_part.CFrame.LookVector
        )
    elseif not direction then
        direction = DodgeDirectionRules.resolve(
            movement.input_code,
            root_part.CFrame.LookVector
        )
    end

    movement.character:SetAttribute(
        CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE,
        direction
    )

    local progress = elapsed / movement.duration
    local speed = get_dodge_speed(movement, progress)
    local safe_delta = math.max(delta_time, 1 / 240)
    local probe_size = DodgeClearanceRules.get_probe_size(
        root_part.Size,
        movement.clearance
    )

    local overlap_params = OverlapParams.new()
    overlap_params.FilterType =
        Enum.RaycastFilterType.Exclude
    overlap_params.FilterDescendantsInstances = {
        movement.character,
    }
    overlap_params.RespectCanCollide = true
    overlap_params.MaxParts = 1

    local initially_blocked =
        #Workspace:GetPartBoundsInBox(
            root_part.CFrame,
            probe_size,
            overlap_params
        ) > 0

    local safety_margin =
        DodgeClearanceRules.get_safety_margin(
            movement.clearance
        )
    local probe_distance =
        (speed * safe_delta) + safety_margin

    movement.raycast_params.RespectCanCollide = true

    local result = Workspace:Blockcast(
        root_part.CFrame,
        probe_size,
        direction * probe_distance,
        movement.raycast_params
    )

    speed = DodgeClearanceRules.limit_speed(
        speed,
        safe_delta,
        if result then result.Distance else nil,
        movement.clearance,
        initially_blocked
    )

    movement.velocity.PlaneVelocity = Vector2.new(
        direction.X * speed,
        direction.Z * speed
    )
end


--[[
Runs one collision-safe View-Lock-aware dodge movement.

With View Lock active, the server re-resolves the validated eight-way input
against current facing every frame so camera turns can steer the dodge. With
View Lock off, the server keeps one validated camera-relative world direction.
The local network owner handles the brief visual turn while movement begins.

Args:
    player (Player): Player performing the dodge.

Returns:
    None.
]]
local function apply_dodge_step(
    player: Player,
    input_code: string,
    profile: DodgeMovementProfile,
    view_locked: boolean,
    unlocked_direction: Vector3?
)
    local character = player.Character
    local _, root_part = get_character_parts(player)

    if not character or not root_part then
        return
    end

    stop_dodge_movement(player)

    local attachment = root_part:FindFirstChild(
        "CombatDodgeAttachment"
    )

    if not attachment
        or not attachment:IsA("Attachment") then
        attachment = Instance.new("Attachment")
        attachment.Name = "CombatDodgeAttachment"
        attachment.Parent = root_part
    end

    local old_velocity = root_part:FindFirstChild(
        "CombatDodgeVelocity"
    )

    if old_velocity then
        old_velocity:Destroy()
    end

    local velocity = Instance.new("LinearVelocity")

    velocity.Name = "CombatDodgeVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo =
        Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode =
        Enum.VelocityConstraintMode.Plane
    velocity.PrimaryTangentAxis =
        Vector3.new(1, 0, 0)
    velocity.SecondaryTangentAxis =
        Vector3.new(0, 0, 1)
    velocity.ForceLimitsEnabled = false
    velocity.Parent = root_part

    local raycast_params = RaycastParams.new()

    raycast_params.FilterType =
        Enum.RaycastFilterType.Exclude
    raycast_params.FilterDescendantsInstances = {
        character,
    }
    raycast_params.IgnoreWater = true

    local movement: DodgeMovementRecord = {
        player = player,
        character = character,
        root_part = root_part,
        velocity = velocity,
        raycast_params = raycast_params,
        started_at = os.clock(),
        distance = profile.distance,
        duration = profile.duration,
        start_speed_multiplier = profile.start_speed_multiplier,
        end_speed_multiplier = profile.end_speed_multiplier,
        clearance = CombatConfig.DEFENSE
            .DODGE_WALL_CLEARANCE_STUDS,
        input_code = input_code,
        view_locked = view_locked,
        unlocked_direction = unlocked_direction,
        heartbeat_connection = nil,
    }

    dodge_movements[player] = movement
    movement.heartbeat_connection = RunService.Heartbeat:Connect(
        function(delta_time: number)
            update_dodge_movement(movement, delta_time)
        end
    )

    update_dodge_movement(movement, 1 / 60)
end


--[[
Checks whether a delayed callback still belongs to the current attack.

Args:
    player (Player): Player owning the attack.
    record (PlayerCombatState): Combat record captured by the callback.
    sequence_id (number): Attack sequence identifier captured earlier.
    expected_state (string): State required for the callback to continue.

Returns:
    boolean: True when the callback is still current and valid.
]]
local function sequence_is_current(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    expected_state: string
): boolean
    return player_states[player] == record
        and record.sequence_id == sequence_id
        and record.state_name == expected_state
end


local start_attack


--[[
Finishes recovery, continuing a buffered chain or returning to movement.

Args:
    player (Player): Player whose attack is ending.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Current attack sequence identifier.

Returns:
    None.
]]
local function finish_attack(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.RECOVERY
    ) then
        return
    end

    local current_attack_id = record.current_attack_id

    if not current_attack_id then
        return
    end

    local next_attack_id = StateRules.get_next_attack_id(
        current_attack_id,
        BasicAttack.ATTACK_ORDER
    )

    if record.queued_attack then
        record.queued_attack = false
        update_character_attributes(player, record)
        start_attack(player, record, next_attack_id)
        return
    end

    record.next_attack_id = next_attack_id
    record.combo_expires_at = os.clock()
        + BasicAttack.COMBO_RESET_SECONDS

    set_state(player, record, State.LOCOMOTION)
    record.current_attack_id = nil
    update_character_attributes(player, record)
end


--[[
Enters recovery and schedules the end of the current attack.

Args:
    player (Player): Player performing the attack.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Current attack sequence identifier.
    attack_definition (table): Configuration for the current attack.

Returns:
    None.
]]
local function enter_recovery(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    attack_definition: any
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.ACTIVE
    ) then
        return
    end

    if not set_state(player, record, State.RECOVERY) then
        return
    end

    task.delay(attack_definition.RECOVERY_SECONDS, function()
        finish_attack(player, record, sequence_id)
    end)
end


--[[
Enters the active hit phase and applies the prototype forward step.

Args:
    player (Player): Player performing the attack.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Current attack sequence identifier.
    attack_definition (table): Configuration for the current attack.

Returns:
    None.
]]
local function enter_active(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    attack_definition: any
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.WIND_UP
    ) then
        return
    end

    if not set_state(player, record, State.ACTIVE) then
        return
    end

    apply_forward_step(
        player,
        attack_definition.FORWARD_STEP_STUDS,
        attack_definition
    )

    local character = player.Character
    local attack_id = record.current_attack_id

    if character and attack_id then
        MeleeHitService.begin_active_window({
            attacker = player,
            character = character,
            attack_id = attack_id,
            attack_definition = attack_definition,
            base_damage =
                CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE * ProgressionRuntimeState.get_physical_multiplier(player.UserId),
            sequence_id = sequence_id,
            is_cancelled = function()
                return not sequence_is_current(
                    player,
                    record,
                    sequence_id,
                    State.ACTIVE
                )
            end,
            on_candidate_rejected = function(target: Model, reason: string)
                CombatValidationService.emit(
                    player,
                    "HIT",
                    "REJECT",
                    attack_id .. " " .. target.Name .. " " .. reason,
                    sequence_id
                )
            end,
            on_target_accepted = function(target: Model)
                CombatValidationService.emit(
                    player,
                    "HIT",
                    "CONFIRMED",
                    attack_id .. " -> " .. target.Name,
                    sequence_id
                )
            end,
            on_window_cancelled = function()
                CombatValidationService.emit(
                    player,
                    "HIT_WINDOW",
                    "CANCELLED",
                    attack_id,
                    sequence_id
                )
            end,
        })
    end

    task.delay(attack_definition.ACTIVE_SECONDS, function()
        enter_recovery(
            player,
            record,
            sequence_id,
            attack_definition
        )
    end)
end


--[[
Starts one authoritative basic attack and schedules its wind-up.

Args:
    player (Player): Player performing the attack.
    record (PlayerCombatState): Authoritative combat record.
    attack_id (string): Server-selected attack identifier.

Returns:
    None.
]]
start_attack = function(
    player: Player,
    record: PlayerCombatState,
    attack_id: string
)
    local attack_definition = BasicAttack.ATTACKS[attack_id]

    if not attack_definition then
        warn("[Combat] Unknown attack id: " .. attack_id)
        return
    end

    record.sequence_id += 1
    record.current_attack_id = attack_id
    record.current_skill_id = nil
    record.queued_attack = false

    local sequence_id = record.sequence_id

    if not set_state(player, record, State.WIND_UP) then
        return
    end

    CombatValidationService.emit(
        player,
        "ATTACK",
        "ACCEPT",
        attack_id,
        sequence_id
    )

    task.delay(attack_definition.WIND_UP_SECONDS, function()
        enter_active(
            player,
            record,
            sequence_id,
            attack_definition
        )
    end)
end


--[[
Handles a validated basic-attack request without trusting client attack data.

Args:
    player (Player): Player who requested a basic attack.

Returns:
    None.
]]
local function handle_attack_request(player: Player)
    local record = player_states[player]

    if not record then
        return
    end

    if record.state_name == State.LOCOMOTION then
        local attack_id = record.next_attack_id

        if os.clock() >= record.combo_expires_at then
            attack_id = BasicAttack.ATTACK_ORDER[1]
        end

        start_attack(player, record, attack_id)
        return
    end

    if record.state_name ~= State.RECOVERY then
        CombatValidationService.emit(
            player,
            "ATTACK",
            "REJECT",
            "State=" .. record.state_name,
            record.sequence_id
        )
        return
    end

    local current_attack_id = record.current_attack_id

    if not current_attack_id or record.queued_attack then
        CombatValidationService.emit(
            player,
            "ATTACK",
            "REJECT",
            "BufferUnavailable",
            record.sequence_id
        )
        return
    end

    local attack_definition = BasicAttack.ATTACKS[
        current_attack_id
    ]
    local recovery_elapsed = os.clock() - record.state_started_at

    local buffer_open = StateRules.is_buffer_window_open(
        recovery_elapsed,
        attack_definition.RECOVERY_SECONDS,
        BasicAttack.COMBO_BUFFER_SECONDS
    )

    if buffer_open then
        record.queued_attack = true
        update_character_attributes(player, record)
        CombatValidationService.emit(
            player,
            "ATTACK",
            "BUFFERED",
            current_attack_id,
            record.sequence_id
        )
    else
        CombatValidationService.emit(
            player,
            "ATTACK",
            "REJECT",
            "BufferClosed",
            record.sequence_id
        )
    end
end


--[[Returns server-observed weapon tags for the currently equipped Tool.]]
local function get_equipped_weapon_tags(player: Player): {[string]: boolean}
    local tags: {[string]: boolean} = {}
    local character = player.Character
    if not character then return tags end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            if child:GetAttribute("WeaponTagOneHandedSword") == true
                or child.Name == "PrototypeSword" then
                tags.OneHandedSword = true
            end
        end
    end
    return tags
end


--[[
Applies the server-owned health and stagger effects of Shield Bash.

Args:
    player (Player): Player who performed Shield Bash.
    character (Model): Attacking character model.
    skill_definition (table): Authoritative Shield Bash definition.
    target (Model): Valid NPC target accepted by melee acquisition.

Returns:
    None.
]]
local function apply_shield_bash_target(
    player: Player,
    character: Model,
    skill_definition: any,
    target: Model,
    sequence_id: number
)
    local applied_damage = DamageService.apply_damage({
        attacker = player,
        attacker_character = character,
        target = target,
        source_kind = "Skill",
        source_id = skill_definition.ID,
        attack_id = nil,
        base_damage = skill_definition.BASE_DAMAGE,
        multiplier = ProgressionRuntimeState.get_physical_multiplier(player.UserId),
        sequence_id = sequence_id,
    })

    local already_staggered = StaggerService.is_staggered(target)
    StaggerService.apply(target, skill_definition.STAGGER_SECONDS)
    DungeonProgressionBridge.award_damage(player, skill_definition.ID, target, applied_damage, 1)
    DungeonProgressionBridge.award_control(player, skill_definition.ID, target, "Stagger", not already_staggered)
end


--[[Applies one server-authoritative Arc Slash target hit.]]
local function apply_arc_slash_target(
    player: Player,
    character: Model,
    skill_definition: any,
    target: Model,
    sequence_id: number,
    target_index: number
)
    local applied_damage = DamageService.apply_damage({
        attacker = player,
        attacker_character = character,
        target = target,
        source_kind = "Skill",
        source_id = skill_definition.ID,
        attack_id = nil,
        base_damage = skill_definition.BASE_DAMAGE,
        multiplier = ProgressionRuntimeState.get_physical_multiplier(player.UserId),
        sequence_id = sequence_id,
    })
    DungeonProgressionBridge.award_damage(
        player,
        skill_definition.ID,
        target,
        applied_damage,
        target_index
    )
end


--[[
Finishes active-skill recovery and returns the player to Locomotion.

Args:
    player (Player): Player whose active skill is ending.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Skill sequence identifier captured at start.

Returns:
    None.
]]
local function finish_skill(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.RECOVERY
    ) then
        return
    end

    record.current_skill_id = nil
    set_state(player, record, State.LOCOMOTION)
end


--[[
Enters active-skill recovery and schedules the final Locomotion transition.

Args:
    player (Player): Player using the skill.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Skill sequence identifier captured at start.
    skill_definition (table): Authoritative active-skill definition.

Returns:
    None.
]]
local function enter_skill_recovery(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    skill_definition: any
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.ACTIVE
    ) then
        return
    end

    if not set_state(player, record, State.RECOVERY) then
        return
    end

    task.delay(skill_definition.RECOVERY_SECONDS, function()
        finish_skill(player, record, sequence_id)
    end)
end


--[[
Enters Shield Bash active frames and starts authoritative melee acquisition.

Args:
    player (Player): Player using Shield Bash.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Skill sequence identifier captured at start.
    skill_definition (table): Authoritative Shield Bash definition.

Returns:
    None.
]]
local function enter_skill_active(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    skill_definition: any
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.WIND_UP
    ) then
        return
    end

    if not set_state(player, record, State.ACTIVE) then
        return
    end

    apply_forward_step(
        player,
        skill_definition.FORWARD_STEP_STUDS,
        skill_definition
    )

    local character = player.Character

    if character then
        MeleeHitService.begin_active_window({
            attacker = player,
            character = character,
            attack_id = skill_definition.ID,
            attack_definition = skill_definition,
            base_damage = skill_definition.BASE_DAMAGE,
            sequence_id = sequence_id,
            is_cancelled = function()
                return not sequence_is_current(
                    player,
                    record,
                    sequence_id,
                    State.ACTIVE
                )
            end,
            on_target = (function()
                local target_index = 0
                return function(target: Model)
                    target_index += 1
                    if skill_definition.ID == "ArcSlash" then
                        apply_arc_slash_target(
                            player,
                            character,
                            skill_definition,
                            target,
                            sequence_id,
                            target_index
                        )
                    else
                        apply_shield_bash_target(
                            player,
                            character,
                            skill_definition,
                            target,
                            sequence_id
                        )
                    end
                end
            end)(),
            on_candidate_rejected = function(target: Model, reason: string)
                CombatValidationService.emit(
                    player,
                    "HIT",
                    "REJECT",
                    skill_definition.ID .. " " .. target.Name .. " " .. reason,
                    sequence_id
                )
            end,
            on_target_accepted = function(target: Model)
                CombatValidationService.emit(
                    player,
                    "HIT",
                    "CONFIRMED",
                    skill_definition.ID .. " -> " .. target.Name,
                    sequence_id
                )
            end,
            on_window_cancelled = function()
                CombatValidationService.emit(
                    player,
                    "HIT_WINDOW",
                    "CANCELLED",
                    skill_definition.ID,
                    sequence_id
                )
            end,
        })
    end

    task.delay(skill_definition.ACTIVE_SECONDS, function()
        enter_skill_recovery(
            player,
            record,
            sequence_id,
            skill_definition
        )
    end)
end


--[[
Starts one authoritative active-skill sequence after request validation.

Args:
    player (Player): Player using the skill.
    record (PlayerCombatState): Authoritative combat record.
    skill_definition (table): Authoritative active-skill definition.

Returns:
    boolean: True when the skill entered WindUp.
]]
local function start_skill(
    player: Player,
    record: PlayerCombatState,
    skill_definition: any
): boolean
    record.sequence_id += 1
    record.current_attack_id = nil
    record.current_skill_id = skill_definition.ID

    local sequence_id = record.sequence_id

    if not set_state(player, record, State.WIND_UP) then
        record.current_skill_id = nil
        update_character_attributes(player, record)
        return false
    end

    CombatValidationService.emit(
        player,
        "SKILL",
        "ACCEPT",
        skill_definition.ID,
        sequence_id
    )

    task.delay(skill_definition.WIND_UP_SECONDS, function()
        enter_skill_active(
            player,
            record,
            sequence_id,
            skill_definition
        )
    end)

    return true
end


--[[
Finishes a Mend channel and returns the caster to Locomotion.

Args:
    player (Player): Player whose Mend is ending.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Mend sequence captured at channel start.

Returns:
    None.
]]
local function finish_mend(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.MENDING
    ) then
        return
    end

    MendService.cancel_channel(player)
    record.current_skill_id = nil
    set_state(player, record, State.LOCOMOTION)
end


--[[
Runs one scheduled Mend pulse against the locked support target.

Args:
    player (Player): Player performing Mend.
    record (PlayerCombatState): Authoritative combat record.
    sequence_id (number): Mend sequence captured at channel start.
    skill_definition (table): Authoritative Mend definition.
    pulse_index (number): One-based pulse number.

Returns:
    None.
]]
local function run_mend_pulse(
    player: Player,
    record: PlayerCombatState,
    sequence_id: number,
    skill_definition: any,
    pulse_index: number
)
    if not sequence_is_current(
        player,
        record,
        sequence_id,
        State.MENDING
    ) then
        return
    end

    local mend_target = MendService.get_channel_target(player)
    local valid, healed = MendService.apply_channel_pulse(
        player,
        skill_definition.PULSE_HEAL * ProgressionRuntimeState.get_heal_multiplier(player.UserId)
    )
    if valid and mend_target and healed > 0 then
        DungeonProgressionBridge.award_heal(player, skill_definition.ID, mend_target, healed)
    end

    if not valid then
        CombatValidationService.emit(
            player,
            "MEND",
            "CANCELLED",
            "TargetInvalid",
            sequence_id
        )
        finish_mend(player, record, sequence_id)
        return
    end

    CombatValidationService.emit(
        player,
        "MEND",
        "PULSE",
        string.format(
            "%d/%d +%.1fHP",
            pulse_index,
            skill_definition.PULSE_COUNT,
            healed
        ),
        sequence_id
    )

    if pulse_index >= skill_definition.PULSE_COUNT then
        finish_mend(player, record, sequence_id)
    end
end


--[[
Starts one committed server-authoritative Mend channel.

The target is fixed when the channel starts. Cooldown is consumed once the
Mending state and target lock are both accepted. Five sequence-guarded pulse
callbacks then resolve over the full channel duration.

Args:
    player (Player): Player beginning Mend.
    record (PlayerCombatState): Authoritative combat record.
    skill_definition (table): Authoritative Mend definition.
    target (Player): Server-selected Mend recipient.

Returns:
    boolean: True when the Mend channel started.
]]
local function start_mend(
    player: Player,
    record: PlayerCombatState,
    skill_definition: any,
    target: Player
): boolean
    record.sequence_id += 1
    record.current_attack_id = nil
    record.current_skill_id = skill_definition.ID
    record.queued_attack = false

    local sequence_id = record.sequence_id

    if not set_state(player, record, State.MENDING) then
        record.current_skill_id = nil
        update_character_attributes(player, record)
        return false
    end

    if not MendService.start_channel(
        player,
        target,
        skill_definition.RANGE_STUDS
    ) then
        record.current_skill_id = nil
        set_state(player, record, State.LOCOMOTION)
        return false
    end

    SkillCooldownService.start(
        player,
        skill_definition.ID,
        skill_definition.COOLDOWN_SECONDS
    )

    CombatValidationService.emit(
        player,
        "MEND",
        "ACCEPT",
        target.Name,
        sequence_id
    )

    for pulse_index = 1, skill_definition.PULSE_COUNT do
        task.delay(
            pulse_index * skill_definition.PULSE_INTERVAL_SECONDS,
            function()
                run_mend_pulse(
                    player,
                    record,
                    sequence_id,
                    skill_definition,
                    pulse_index
                )
            end
        )
    end

    return true
end


--[[
Handles one active-skill request without trusting client combat results.

Args:
    player (Player): Player requesting an active skill.
    requested_skill_id (any): Client-provided skill identity only.

Returns:
    None.
]]
local function handle_skill_request(
    player: Player,
    requested_skill_id: any
)
    if type(requested_skill_id) ~= "string" then
        CombatValidationService.emit(player, "SKILL", "REJECT", "MalformedRequest", nil)
        return
    end

    local record = player_states[player]

    if not record or record.state_name ~= State.LOCOMOTION then
        CombatValidationService.emit(
            player,
            "SKILL",
            "REJECT",
            record and ("State=" .. record.state_name) or "NoState",
            record and record.sequence_id or nil
        )
        return
    end

    local base_definition = SkillDefinitions.get(requested_skill_id)
    if not base_definition then
        CombatValidationService.emit(player, "SKILL", "REJECT", "UnknownSkill", record.sequence_id)
        return
    end

    local usable, unusable_reason = ProgressionRuntimeState.is_skill_usable(
        player.UserId,
        requested_skill_id,
        get_equipped_weapon_tags(player)
    )
    if not usable then
        CombatValidationService.emit(
            player,
            "SKILL",
            "REJECT",
            unusable_reason or "SkillUnavailable",
            record.sequence_id
        )
        return
    end

    local rank = ProgressionRuntimeState.get_skill_rank(player.UserId, requested_skill_id)
    local skill_definition = SkillDefinitions.get_for_rank(requested_skill_id, rank)
    if not skill_definition then
        CombatValidationService.emit(player, "SKILL", "REJECT", "RankDefinitionMissing", record.sequence_id)
        return
    end

    local humanoid = get_character_parts(player)

    if not humanoid or humanoid.Health <= 0 then
        CombatValidationService.emit(player, "SKILL", "REJECT", "Dead", record.sequence_id)
        return
    end

    if not SkillCooldownService.is_ready(
        player,
        requested_skill_id
    ) then
        CombatValidationService.emit(player, "SKILL", "REJECT", "Cooldown", record.sequence_id)
        return
    end

    if skill_definition.KIND == "Support" then
        if skill_definition.ID ~= "Mend" then
            return
        end

        local target = MendService.find_target(
            player,
            skill_definition.RANGE_STUDS
        )

        if not target then
            CombatValidationService.emit(
                player,
                "MEND",
                "REJECT",
                "NoInjuredTarget",
                record.sequence_id
            )
            return
        end

        if not StaminaService.try_spend(
            player,
            skill_definition.STAMINA_COST
        ) then
            CombatValidationService.emit(player, "SKILL", "REJECT", "Stamina", record.sequence_id)
            return
        end

        start_mend(
            player,
            record,
            skill_definition,
            target
        )
        return
    end

    if not StaminaService.try_spend(
        player,
        skill_definition.STAMINA_COST
    ) then
        CombatValidationService.emit(player, "SKILL", "REJECT", "Stamina", record.sequence_id)
        return
    end

    SkillCooldownService.start(
        player,
        requested_skill_id,
        skill_definition.COOLDOWN_SECONDS
    )

    start_skill(player, record, skill_definition)
end


--[[
Starts or ends authoritative defensive actions from client intent only.

Args:
    player (Player): Player requesting the defensive action.
    action (string): BlockStart, BlockEnd, or Dodge.
    dodge_input_code (any): Eight-way direction intent for Dodge only.
    view_locked_intent (any): Client View Lock presentation intent.
    dodge_world_direction (any): Camera-relative world direction intent.

Returns:
    None.
]]
local function handle_defense_request(
    player: Player,
    action: string,
    dodge_input_code: any,
    view_locked_intent: any,
    dodge_world_direction: any
)
    local record = player_states[player]

    if not record then
        return
    end

    if action == "BlockStart" then
        if not StateRules.can_transition(
            record.state_name,
            State.BLOCKING
        ) then
            CombatValidationService.emit(
                player,
                "BLOCK",
                "REJECT",
                "State=" .. record.state_name,
                record.sequence_id
            )
            return
        end

        local character = player.Character

        if not character then
            return
        end

        report_sequence_cancel(player, record, "Block")

        if record.state_name == State.MENDING then
            MendService.cancel_channel(player)
        end

        record.sequence_id += 1
        record.current_attack_id = nil
        record.current_skill_id = nil
        record.queued_attack = false
        record.next_attack_id = BasicAttack.ATTACK_ORDER[1]
        record.combo_expires_at = 0

        stop_attack_step(player)

        if not set_state(
            player,
            record,
            State.BLOCKING
        ) then
            return
        end

        StaminaService.set_regen_paused(
            player,
            true
        )
        DefenseService.begin_block(
            player,
            character,
            record.state_started_at
        )
        CombatValidationService.emit(
            player,
            "BLOCK",
            "ACCEPT",
            "ParryWindowOpen",
            record.sequence_id
        )
        return
    end

    if action == "BlockEnd" then
        if record.state_name ~= State.BLOCKING then
            return
        end

        DefenseService.end_block(player)
        StaminaService.set_regen_paused(
            player,
            false
        )
        set_state(
            player,
            record,
            State.LOCOMOTION
        )
        CombatValidationService.emit(player, "BLOCK", "END", "Released", record.sequence_id)
        return
    end

    if action ~= "Dodge" then
        CombatValidationService.emit(
            player,
            "DEFENSE",
            "REJECT",
            "UnknownAction=" .. tostring(action),
            record.sequence_id
        )
        return
    end

    if not StateRules.can_transition(
        record.state_name,
        State.DODGING
    ) then
        CombatValidationService.emit(
            player,
            "DODGE",
            "REJECT",
            "State=" .. record.state_name,
            record.sequence_id
        )
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local resolved_input_code = dodge_input_code

    if resolved_input_code == nil then
        resolved_input_code = "Forward"
    end

    if not DodgeDirectionRules.is_valid_input_code(
        resolved_input_code
    ) then
        CombatValidationService.emit(player, "DODGE", "REJECT", "Direction", record.sequence_id)
        return
    end

    local view_locked = view_locked_intent == true
    local unlocked_direction: Vector3? = nil

    if not view_locked then
        unlocked_direction =
            DodgeDirectionRules.sanitize_world_direction(
                dodge_world_direction
            )

        if not unlocked_direction then
            local _, root_part = get_character_parts(player)

            if root_part then
                unlocked_direction =
                    DodgeDirectionRules.sanitize_world_direction(
                        root_part.CFrame.LookVector
                    )
            end
        end

        if not unlocked_direction then
            return
        end
    end

    local spent = StaminaService.try_spend(
        player,
        CombatConfig.STAMINA.DODGE_COST
    )

    if not spent then
        CombatValidationService.emit(player, "DODGE", "REJECT", "Stamina", record.sequence_id)
        return
    end

    local _, root_part = get_character_parts(player)

    if not root_part then
        return
    end

    local initial_direction = unlocked_direction

    if view_locked then
        initial_direction = DodgeDirectionRules.resolve(
            resolved_input_code,
            root_part.CFrame.LookVector
        )
    end

    if not initial_direction then
        return
    end

    local dodge_style = DodgeDirectionRules.get_dodge_style(
        resolved_input_code,
        view_locked
    )

    character:SetAttribute(
        CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE,
        initial_direction
    )
    character:SetAttribute(
        CombatConfig.DEFENSE.DODGE_STYLE_ATTRIBUTE,
        dodge_style
    )
    character:SetAttribute(
        CombatConfig.DEFENSE.DODGE_VIEW_LOCKED_ATTRIBUTE,
        view_locked
    )

    report_sequence_cancel(player, record, "Dodge")

    if record.state_name == State.MENDING then
        MendService.cancel_channel(player)
    end

    record.sequence_id += 1
    record.current_attack_id = nil
    record.current_skill_id = nil
    record.queued_attack = false
    record.next_attack_id = BasicAttack.ATTACK_ORDER[1]
    record.combo_expires_at = 0

    stop_attack_step(player)

    if not set_state(
        player,
        record,
        State.DODGING
    ) then
        character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE,
            Vector3.zero
        )
        character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_STYLE_ATTRIBUTE,
            ""
        )
        character:SetAttribute(
            CombatConfig.DEFENSE.DODGE_VIEW_LOCKED_ATTRIBUTE,
            false
        )
        return
    end

    local dodge_sequence = record.sequence_id
    local dodge_profile = get_dodge_profile(
        resolved_input_code,
        view_locked
    )

    DefenseService.begin_dodge(
        player,
        character,
        record.state_started_at
    )
    CombatValidationService.emit(
        player,
        "DODGE",
        "ACCEPT",
        resolved_input_code,
        dodge_sequence
    )
    apply_dodge_step(
        player,
        resolved_input_code,
        dodge_profile,
        view_locked,
        unlocked_direction
    )

    task.delay(
        dodge_profile.duration,
        function()
            if not sequence_is_current(
                player,
                record,
                dodge_sequence,
                State.DODGING
            ) then
                return
            end

            stop_dodge_movement(player)
            DefenseService.end_dodge(player)
            CombatValidationService.emit(
                player,
                "DODGE",
                "COMPLETE",
                resolved_input_code,
                dodge_sequence
            )
            set_state(
                player,
                record,
                State.LOCOMOTION
            )
        end
    )
end


DefenseService.on_guard_break(function(player: Player)
    local record = player_states[player]

    if not record
        or record.state_name ~= State.BLOCKING then
        return
    end

    record.sequence_id += 1
    local guard_sequence = record.sequence_id

    DefenseService.end_block(player)
    StaminaService.set_regen_paused(
        player,
        false
    )

    if not set_state(
        player,
        record,
        State.GUARD_BREAK
    ) then
        return
    end

    task.delay(
        CombatConfig.DEFENSE.GUARD_BREAK_SECONDS,
        function()
            if not sequence_is_current(
                player,
                record,
                guard_sequence,
                State.GUARD_BREAK
            ) then
                return
            end

            set_state(
                player,
                record,
                State.LOCOMOTION
            )
        end
    )
end)


--[[
Cancels Mend channels targeting one player and releases their living casters.

Args:
    target (Player): Recipient who died or left the server.

Returns:
    None.
]]
local function cancel_mends_targeting_player(target: Player)
    local cancelled_casters = MendService.cancel_channels_for_target(target)

    for _, caster in cancelled_casters do
        local caster_record = player_states[caster]

        if caster_record
            and caster_record.state_name == State.MENDING then
            CombatValidationService.emit(
                caster,
                "MEND",
                "CANCELLED",
                "RecipientUnavailable",
                caster_record.sequence_id
            )
            caster_record.sequence_id += 1
            caster_record.current_skill_id = nil
            set_state(caster, caster_record, State.LOCOMOTION)
        end
    end
end


--[[
Terminates every runtime combat action owned by one dead character.

Args:
    player (Player): Player whose active character died.
    character (Model): Character that emitted the death event.
    record (PlayerCombatState): Combat record created for that character.

Returns:
    None.
]]
local function handle_character_death(
    player: Player,
    character: Model,
    record: PlayerCombatState
)
    if player_states[player] ~= record
        or player.Character ~= character then
        return
    end

    record.sequence_id += 1
    record.current_attack_id = nil
    record.current_skill_id = nil
    record.queued_attack = false
    record.next_attack_id = BasicAttack.ATTACK_ORDER[1]
    record.combo_expires_at = 0

    MendService.cancel_channel(player)
    cancel_mends_targeting_player(player)
    stop_dodge_movement(player)
    stop_attack_step(player)
    DefenseService.clear(player)
    StaminaService.set_regen_paused(player, false)
    SkillCooldownService.remove_owner(player)

    set_state(player, record, State.DEAD)
    CombatValidationService.emit(player, "LIFECYCLE", "DEAD", "CombatReset", record.sequence_id)
end


--[[
Temporarily suppresses Marauder target acquisition after a respawn.

This is not invulnerability: it only marks the character as ineligible for
new Marauder aggro while the short arena re-entry grace period is active.
]]
local function begin_respawn_aggro_grace(
    player: Player,
    character: Model,
    record: PlayerCombatState
)
    local marauder_config = CombatConfig.TRAINING_MARAUDER
    local attribute_name = marauder_config.AGGRO_SUPPRESSED_ATTRIBUTE
    local grace_seconds = marauder_config.RESPAWN_AGGRO_GRACE_SECONDS

    character:SetAttribute(attribute_name, true)
    CombatValidationService.emit(
        player,
        "LIFECYCLE",
        "AGGRO_GRACE",
        string.format("%.1fs", grace_seconds),
        record.sequence_id
    )

    task.delay(grace_seconds, function()
        if player.Character ~= character or not character.Parent then
            return
        end

        character:SetAttribute(attribute_name, false)
        CombatValidationService.emit(
            player,
            "LIFECYCLE",
            "AGGRO_READY",
            "RoomWide",
            record.sequence_id
        )
    end)
end


--[[
Resets authoritative combat state for a newly spawned character.

Args:
    player (Player): Player whose character spawned.
    character (Model): Newly spawned character model.

Returns:
    None.
]]
local function on_character_added(
    player: Player,
    character: Model
)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local record = create_player_state(humanoid.WalkSpeed)
    local is_respawn = has_spawned_character[player] == true

    has_spawned_character[player] = true
    character:SetAttribute(
        CombatConfig.TRAINING_MARAUDER.AGGRO_SUPPRESSED_ATTRIBUTE,
        false
    )

    stop_dodge_movement(player)
    player_states[player] = record
    StaminaService.reset_player(player)
    ProgressionRuntimeState.apply_max_health(player)
    SkillCooldownService.remove_owner(player)
    DefenseService.clear(player)
    set_state(player, record, State.LOCOMOTION)
    CombatValidationService.emit(player, "LIFECYCLE", "RESPAWN", "Locomotion", record.sequence_id)

    if is_respawn then
        begin_respawn_aggro_grace(player, character, record)
    end

    humanoid.Died:Connect(function()
        handle_character_death(player, character, record)
    end)
end


--[[
Initialises combat state ownership for one player.

Args:
    player (Player): Player entering the server.

Returns:
    None.
]]
local function on_player_added(player: Player)
    StaminaService.initialize_player(player)

    player.CharacterAdded:Connect(function(character)
        on_character_added(player, character)
    end)

    if player.Character then
        on_character_added(player, player.Character)
    end
end


attack_request.OnServerEvent:Connect(handle_attack_request)
defense_request.OnServerEvent:Connect(handle_defense_request)
skill_request.OnServerEvent:Connect(handle_skill_request)
Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(function(player)
    MendService.cancel_channel(player)
    cancel_mends_targeting_player(player)
    stop_dodge_movement(player)
    DefenseService.clear(player)
    StaminaService.remove_player(player)
    SkillCooldownService.remove_owner(player)
    player_states[player] = nil
    has_spawned_character[player] = nil
    ProgressionRuntimeState.clear_character(player.UserId)
end)

for _, player in Players:GetPlayers() do
    on_player_added(player)
end
