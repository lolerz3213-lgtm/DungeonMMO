local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local MeleeHitService = require(
    script.Parent:WaitForChild("MeleeHitService")
)

local attack_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.ATTACK_REQUEST
) :: RemoteEvent
local state_changed = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.STATE_CHANGED
) :: RemoteEvent

local State = CombatTypes.State
local BasicAttack = CombatConfig.BASIC_ATTACK

type PlayerCombatState = {
    state_name: string,
    state_started_at: number,
    current_attack_id: string?,
    next_attack_id: string,
    queued_attack: boolean,
    combo_expires_at: number,
    sequence_id: number,
    base_walk_speed: number,
}

local player_states: {[Player]: PlayerCombatState} = {}


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
        next_attack_id = BasicAttack.ATTACK_ORDER[1],
        queued_attack = false,
        combo_expires_at = 0,
        sequence_id = 0,
        base_walk_speed = base_walk_speed,
    }
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

    if record.current_attack_id then
        local attack_definition = BasicAttack.ATTACKS[
            record.current_attack_id
        ]

        if attack_definition then
            scale = StateRules.get_movement_scale(
                record.state_name,
                attack_definition
            )
        end
    end

    humanoid.WalkSpeed = record.base_walk_speed * scale
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
        record.current_attack_id or "",
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
                CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE,
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
    record.queued_attack = false

    local sequence_id = record.sequence_id

    if not set_state(player, record, State.WIND_UP) then
        return
    end

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
        return
    end

    local current_attack_id = record.current_attack_id

    if not current_attack_id or record.queued_attack then
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
    end
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

    player_states[player] = record
    update_character_attributes(player, record)

    humanoid.Died:Connect(function()
        record.sequence_id += 1
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
    player.CharacterAdded:Connect(function(character)
        on_character_added(player, character)
    end)

    if player.Character then
        on_character_added(player, player.Character)
    end
end


attack_request.OnServerEvent:Connect(handle_attack_request)
Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(function(player)
    player_states[player] = nil
end)

for _, player in Players:GetPlayers() do
    on_player_added(player)
end
