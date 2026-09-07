local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local DefenseAnimationFactory = require(
    shared_folder:WaitForChild("DefenseAnimationFactory")
)
local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)
local ShieldPresentationBinding = require(
    shared_folder:WaitForChild("ShieldPresentationBinding")
)
local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)

local State = CombatTypes.State
local ShieldConfig = CombatConfig.PROTOTYPE_SHIELD
local DodgeStyle = DefenseAnimationFactory.DodgeStyle

local current_state = State.LOCOMOTION
local current_action_id = ""
local state_started_at = os.clock()
local root_joint: Instance? = nil
local waist_joint: Instance? = nil
local left_shoulder_joint: Instance? = nil
local left_elbow_joint: Instance? = nil
local left_wrist_joint: Instance? = nil
local left_hip_joint: Instance? = nil
local right_hip_joint: Instance? = nil
local left_knee_joint: Instance? = nil
local right_knee_joint: Instance? = nil
local shield_grip: Motor6D? = nil
local block_ik: IKControl? = nil
local block_ik_target: Attachment? = nil
local block_ik_pole: Attachment? = nil
local current_character: Model? = nil
local current_humanoid: Humanoid? = nil
local current_root_part: BasePart? = nil
local idle_shield_reference: BasePart? = nil
local block_shield_reference: BasePart? = nil
local current_dodge_style = DodgeStyle.FORWARD_ROLL
local current_dodge_view_locked = false
local dodge_style_is_latched = false
local unlocked_turn_start_rotation: CFrame? = nil


--[[
Checks whether an instance name matches one requested joint name.

Args:
    instance (Instance): Candidate rig joint.
    names ({string}): Accepted R15 joint names.

Returns:
    boolean: True when the instance name matches.
]]
local function name_matches(
    instance: Instance,
    names: {string}
): boolean
    for _, name in names do
        if instance.Name == name then
            return true
        end
    end

    return false
end


--[[
Finds a supported R15 animation joint by standard names.

Args:
    character (Model): Character whose joints are searched.
    names ({string}): Candidate joint names.

Returns:
    Instance?: Matching AnimationConstraint or Motor6D.
]]
local function find_rig_joint(
    character: Model,
    names: {string}
): Instance?
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("AnimationConstraint")
            and name_matches(descendant, names) then
            return descendant
        end
    end

    for _, descendant in character:GetDescendants() do
        if descendant:IsA("Motor6D")
            and name_matches(descendant, names) then
            return descendant
        end
    end

    return nil
end


--[[
Writes an absolute Transform to either supported rig-joint implementation.

Args:
    joint (Instance?): Joint to update.
    transform (CFrame): Transform to assign.

Returns:
    None.
]]
local function set_joint_transform(
    joint: Instance?,
    transform: CFrame
)
    if not joint then
        return
    end

    if joint:IsA("Motor6D") then
        joint.Transform = transform
        return
    end

    if joint:IsA("AnimationConstraint") then
        joint.Transform = transform
    end
end


--[[
Layers a procedural transform over the Animator transform for this frame.

Args:
    joint (Instance?): Joint to update.
    overlay (CFrame): Procedural transform to multiply onto Animator output.

Returns:
    None.
]]
local function layer_joint_transform(
    joint: Instance?,
    overlay: CFrame
)
    if not joint then
        return
    end

    if joint:IsA("Motor6D") then
        joint.Transform = joint.Transform * overlay
        return
    end

    if joint:IsA("AnimationConstraint") then
        joint.Transform = joint.Transform * overlay
    end
end


--[[
Places the root-owned shield grip at a desired world transform.

Args:
    desired_cframe (CFrame): World-space shield target.

Returns:
    None.
]]
local function set_shield_world_cframe(
    desired_cframe: CFrame
)
    if not shield_grip or not shield_grip.Part0 then
        return
    end

    local part0 = shield_grip.Part0
    local local_target = part0.CFrame:ToObjectSpace(
        desired_cframe
    )

    shield_grip.Transform =
        shield_grip.C0:Inverse()
        * local_target
        * shield_grip.C1
end


--[[
Returns the shield centre position from character-facing offsets.

Args:
    reference_part (BasePart): Body part anchoring the shield centre.
    left_studs (number): Distance left of character centre.
    forward_studs (number): Distance in front of character.
    down_studs (number): Distance below the reference part.

Returns:
    Vector3?: Desired world position, or nil without a root part.
]]
local function get_shield_position(
    reference_part: BasePart,
    left_studs: number,
    forward_studs: number,
    down_studs: number
): Vector3?
    if not current_root_part then
        return nil
    end

    local root_cframe = current_root_part.CFrame

    return reference_part.Position
        - root_cframe.RightVector * left_studs
        + root_cframe.LookVector * forward_studs
        - root_cframe.UpVector * down_studs
end


--[[
Updates the shield to its natural idle forearm position.

The broad shield face points mostly outward to the character's left. Walking
adds a controlled vertical bob without allowing the default walk animation to
swing the shield arm into a different pose.

Args:
    vertical_bob (number): Additional world-space Y bob in studs.
    forward_bob (number): Additional forward bob in studs.
    roll_degrees (number): Small shield roll around its face normal.

Returns:
    None.
]]
local function update_idle_shield(
    vertical_bob: number,
    forward_bob: number,
    roll_degrees: number
)
    if not idle_shield_reference or not current_root_part then
        return
    end

    local position = get_shield_position(
        idle_shield_reference,
        ShieldConfig.IDLE_OUTWARD_STUDS,
        ShieldConfig.IDLE_FORWARD_STUDS + forward_bob,
        ShieldConfig.IDLE_DOWN_STUDS
    )

    if not position then
        return
    end

    position += Vector3.yAxis * vertical_bob

    local root_cframe = current_root_part.CFrame
    local facing = (
        -root_cframe.RightVector
        + root_cframe.LookVector
            * ShieldConfig.IDLE_FACE_FORWARD_BLEND
    ).Unit
    local desired = CFrame.lookAt(
        position,
        position + facing,
        root_cframe.UpVector
    ) * CFrame.Angles(
        0,
        0,
        math.rad(roll_degrees)
    )

    set_shield_world_cframe(desired)
end


--[[
Updates the shield to the chest-centred shield-wall position.

The transform is derived from UpperTorso space so idle breathing moves the
shield, IK target, and arm together instead of making the solver chase a
root-space target.

Args:
    vertical_bob (number): Small controlled block bob in studs.

Returns:
    None.
]]
local function update_block_shield(vertical_bob: number)
    if not block_shield_reference then
        return
    end

    local reference_cframe = block_shield_reference.CFrame
    local position = reference_cframe.Position
        - reference_cframe.RightVector
            * ShieldConfig.BLOCK_LEFT_STUDS
        + reference_cframe.LookVector
            * ShieldConfig.BLOCK_FORWARD_STUDS
        - reference_cframe.UpVector
            * ShieldConfig.BLOCK_DOWN_STUDS
        + reference_cframe.UpVector * vertical_bob

    set_shield_world_cframe(
        CFrame.lookAt(
            position,
            position + reference_cframe.LookVector,
            reference_cframe.UpVector
        )
    )
end


--[[
Linearly interpolates two numeric presentation values.

Args:
    start_value (number): Value used at zero intensity.
    end_value (number): Value used at full intensity.
    alpha (number): Blend amount from zero to one.

Returns:
    number: Interpolated value.
]]
local function lerp_number(
    start_value: number,
    end_value: number,
    alpha: number
): number
    return start_value + (end_value - start_value) * alpha
end


--[[
Moves the visible shield from guard position into the bash extension.

Args:
    intensity (number): Bash extension amount from zero to one.

Returns:
    None.
]]
local function update_bash_shield(intensity: number)
    if not block_shield_reference then
        return
    end

    local alpha = math.clamp(intensity, 0, 1)
    local reference_cframe = block_shield_reference.CFrame
    local left_studs = lerp_number(
        ShieldConfig.BLOCK_LEFT_STUDS,
        ShieldConfig.BASH_LEFT_STUDS,
        alpha
    )
    local forward_studs = lerp_number(
        ShieldConfig.BLOCK_FORWARD_STUDS,
        ShieldConfig.BASH_FORWARD_STUDS,
        alpha
    )
    local down_studs = lerp_number(
        ShieldConfig.BLOCK_DOWN_STUDS,
        ShieldConfig.BASH_DOWN_STUDS,
        alpha
    )
    local position = reference_cframe.Position
        - reference_cframe.RightVector * left_studs
        + reference_cframe.LookVector * forward_studs
        - reference_cframe.UpVector * down_studs

    set_shield_world_cframe(
        CFrame.lookAt(
            position,
            position + reference_cframe.LookVector,
            reference_cframe.UpVector
        )
    )
end


--[[
Writes a torso-local position to one shield-arm IK attachment.

Args:
    attachment (Attachment?): Target or pole attachment.
    left_studs (number): Distance left of UpperTorso centre.
    forward_studs (number): Distance in front of UpperTorso.
    down_studs (number): Distance below UpperTorso centre.
    vertical_bob (number): Controlled local vertical bob.

Returns:
    None.
]]
local function set_ik_attachment_position(
    attachment: Attachment?,
    left_studs: number,
    forward_studs: number,
    down_studs: number,
    vertical_bob: number
)
    if not attachment then
        return
    end

    attachment.CFrame = CFrame.new(
        -left_studs,
        -down_studs + vertical_bob,
        -forward_studs
    )
end


--[[
Updates the persistent left-arm IK target for idle or blocking.

Both attachments are children of UpperTorso. This means breathing and torso
animation move the entire arm target frame together, preventing the visible
stretching that occurred when the target lived in HumanoidRootPart space.

Args:
    blocking (boolean): True for the forward shield-wall target.
    vertical_bob (number): Controlled arm bob in torso-local studs.

Returns:
    None.
]]
local function update_shield_arm_ik(
    blocking: boolean,
    vertical_bob: number
)
    if blocking then
        set_ik_attachment_position(
            block_ik_target,
            ShieldConfig.BLOCK_HAND_LEFT_STUDS,
            ShieldConfig.BLOCK_HAND_FORWARD_STUDS,
            ShieldConfig.BLOCK_HAND_DOWN_STUDS,
            vertical_bob
        )
        set_ik_attachment_position(
            block_ik_pole,
            ShieldConfig.BLOCK_POLE_LEFT_STUDS,
            ShieldConfig.BLOCK_POLE_FORWARD_STUDS,
            ShieldConfig.BLOCK_POLE_DOWN_STUDS,
            vertical_bob * 0.5
        )
        return
    end

    set_ik_attachment_position(
        block_ik_target,
        ShieldConfig.IDLE_HAND_LEFT_STUDS,
        ShieldConfig.IDLE_HAND_FORWARD_STUDS,
        ShieldConfig.IDLE_HAND_DOWN_STUDS,
        vertical_bob
    )
    set_ik_attachment_position(
        block_ik_pole,
        ShieldConfig.IDLE_POLE_LEFT_STUDS,
        ShieldConfig.IDLE_POLE_FORWARD_STUDS,
        ShieldConfig.IDLE_POLE_DOWN_STUDS,
        vertical_bob * 0.5
    )
end


--[[
Moves the shield-arm IK target from guard into the Shield Bash extension.

Args:
    intensity (number): Bash extension amount from zero to one.

Returns:
    None.
]]
local function update_bash_arm_ik(intensity: number)
    local alpha = math.clamp(intensity, 0, 1)

    set_ik_attachment_position(
        block_ik_target,
        lerp_number(
            ShieldConfig.BLOCK_HAND_LEFT_STUDS,
            ShieldConfig.BASH_HAND_LEFT_STUDS,
            alpha
        ),
        lerp_number(
            ShieldConfig.BLOCK_HAND_FORWARD_STUDS,
            ShieldConfig.BASH_HAND_FORWARD_STUDS,
            alpha
        ),
        lerp_number(
            ShieldConfig.BLOCK_HAND_DOWN_STUDS,
            ShieldConfig.BASH_HAND_DOWN_STUDS,
            alpha
        ),
        0
    )
    set_ik_attachment_position(
        block_ik_pole,
        lerp_number(
            ShieldConfig.BLOCK_POLE_LEFT_STUDS,
            ShieldConfig.BASH_POLE_LEFT_STUDS,
            alpha
        ),
        lerp_number(
            ShieldConfig.BLOCK_POLE_FORWARD_STUDS,
            ShieldConfig.BASH_POLE_FORWARD_STUDS,
            alpha
        ),
        lerp_number(
            ShieldConfig.BLOCK_POLE_DOWN_STUDS,
            ShieldConfig.BASH_POLE_DOWN_STUDS,
            alpha
        ),
        0
    )
end


--[[
Returns controlled walk bob values for the shield arm and shield.

Args:
    None.

Returns:
    number: Arm vertical bob.
    number: Extra shield vertical bob.
    number: Shield forward/back bob.
    number: Shield roll in degrees.
]]
local function get_walk_bob(): (number, number, number, number)
    if current_state ~= State.LOCOMOTION
        or not current_humanoid
        or not current_root_part then
        return 0, 0, 0, 0
    end

    local velocity = current_root_part.AssemblyLinearVelocity
    local planar_speed = Vector3.new(
        velocity.X,
        0,
        velocity.Z
    ).Magnitude
    local reference_speed = math.max(
        current_humanoid.WalkSpeed,
        1
    )
    local movement_alpha = math.clamp(
        planar_speed / reference_speed,
        0,
        1
    )

    if movement_alpha < 0.05 then
        return 0, 0, 0, 0
    end

    local phase = os.clock()
        * math.pi
        * 2
        * ShieldConfig.WALK_BOB_FREQUENCY_HZ
    local wave = math.sin(phase) * movement_alpha
    local secondary = math.cos(phase) * movement_alpha

    return wave * ShieldConfig.WALK_ARM_BOB_STUDS,
        wave * ShieldConfig.WALK_SHIELD_EXTRA_BOB_STUDS,
        secondary * ShieldConfig.WALK_FORWARD_BOB_STUDS,
        secondary * ShieldConfig.WALK_SHIELD_ROLL_DEGREES
end


--[[
Returns the small controlled bob used while actively blocking.

Args:
    None.

Returns:
    number: Vertical torso-local bob in studs.
]]
local function get_block_bob(): number
    local phase = os.clock()
        * math.pi
        * 2
        * ShieldConfig.BLOCK_BOB_FREQUENCY_HZ

    return math.sin(phase) * ShieldConfig.BLOCK_BOB_STUDS
end


--[[
Enables or disables the block-arm IK when available.

Args:
    enabled (boolean): Desired IK state.

Returns:
    None.
]]
local function set_block_ik_enabled(enabled: boolean)
    if block_ik then
        block_ik.Enabled = enabled
    end
end


--[[
Creates a left-arm IK chain whose hand target sits behind the shield.

Args:
    character (Model): Local R15 character.

Returns:
    None.
]]
local function create_block_ik(character: Model)
    if not current_root_part then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local upper_arm = character:FindFirstChild("LeftUpperArm")
    local hand = character:FindFirstChild("LeftHand")

    if not humanoid
        or not upper_arm
        or not upper_arm:IsA("BasePart")
        or not hand
        or not hand:IsA("BasePart") then
        return
    end

    if not block_shield_reference then
        return
    end

    local target = Instance.new("Attachment")
    target.Name = ShieldConfig.BLOCK_IK_TARGET_NAME
    target.Parent = block_shield_reference

    local pole = Instance.new("Attachment")
    pole.Name = ShieldConfig.BLOCK_IK_POLE_NAME
    pole.Parent = block_shield_reference

    local ik = Instance.new("IKControl")
    ik.Name = ShieldConfig.BLOCK_IK_NAME
    ik.Type = Enum.IKControlType.Position
    ik.ChainRoot = upper_arm
    ik.EndEffector = hand
    ik.Target = target
    ik.Pole = pole
    ik.SmoothTime = ShieldConfig.IK_SMOOTH_TIME
    ik.Weight = 1
    ik.Priority = 10
    ik.Enabled = true
    ik.Parent = humanoid

    block_ik_target = target
    block_ik_pole = pole
    block_ik = ik
end


--[[
Destroys local IK presentation objects for the old character.

Args:
    None.

Returns:
    None.
]]
local function destroy_block_ik()
    if block_ik then
        block_ik:Destroy()
    end

    if block_ik_target then
        block_ik_target:Destroy()
    end

    if block_ik_pole then
        block_ik_pole:Destroy()
    end

    block_ik = nil
    block_ik_target = nil
    block_ik_pole = nil
end


--[[
Resets defensive presentation transforms.

Args:
    None.

Returns:
    None.
]]
local function reset_pose()
    set_block_ik_enabled(true)
    set_joint_transform(root_joint, CFrame.identity)
    set_joint_transform(waist_joint, CFrame.identity)
    set_joint_transform(left_shoulder_joint, CFrame.identity)
    set_joint_transform(left_elbow_joint, CFrame.identity)
    set_joint_transform(left_wrist_joint, CFrame.identity)
    set_joint_transform(left_hip_joint, CFrame.identity)
    set_joint_transform(right_hip_joint, CFrame.identity)
    set_joint_transform(left_knee_joint, CFrame.identity)
    set_joint_transform(right_knee_joint, CFrame.identity)

    update_shield_arm_ik(false, 0)
    update_idle_shield(0, 0, 0)
end


--[[
Returns local yaw from character facing toward authoritative dodge travel.

Args:
    character (Model): Character carrying the direction attribute.
    root_part (BasePart): Character root used as the local facing basis.

Returns:
    number: Local yaw in radians. Zero means straight forward.
]]
local function get_dodge_direction_yaw(
    character: Model,
    root_part: BasePart
): number
    local attribute_name =
        CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE
    local direction = character:GetAttribute(attribute_name)

    if typeof(direction) ~= "Vector3"
        or direction.Magnitude < 0.001 then
        return 0
    end

    local local_direction = root_part.CFrame
        :VectorToObjectSpace(direction.Unit)

    return math.atan2(
        -local_direction.X,
        -local_direction.Z
    )
end


--[[
Returns the authoritative world dodge direction when available.

Args:
    None.

Returns:
    Vector3?: Normalized planar dodge direction.
]]
local function get_dodge_world_direction(): Vector3?
    if not current_character then
        return nil
    end

    local direction = current_character:GetAttribute(
        CombatConfig.DEFENSE.DODGE_DIRECTION_ATTRIBUTE
    )

    if typeof(direction) ~= "Vector3" then
        return nil
    end

    local planar = Vector3.new(
        direction.X,
        0,
        direction.Z
    )

    if planar.Magnitude < 0.001 then
        return nil
    end

    return planar.Unit
end


--[[
Returns whether a server-provided dodge style is recognised locally.

Args:
    style (any): Attribute value supplied by the server.

Returns:
    boolean: True only for one supported dodge family.
]]
local function is_valid_dodge_style(style: any): boolean
    return style == DodgeStyle.FORWARD_ROLL
        or style == DodgeStyle.SIDE_DASH
        or style == DodgeStyle.BACKWARD_ROLL
end


--[[
Latches one dodge animation family for the full defensive action.

The server attribute is preferred. If it has not replicated yet, unlocked
dodges can safely latch ForwardRoll immediately. View-Locked dodges wait for
a valid direction and classify it once, never again during that dodge.

Args:
    None.

Returns:
    None.
]]
local function try_latch_dodge_style()
    if dodge_style_is_latched then
        return
    end

    if current_character then
        local style = current_character:GetAttribute(
            CombatConfig.DEFENSE.DODGE_STYLE_ATTRIBUTE
        )

        if is_valid_dodge_style(style) then
            current_dodge_style = style
            dodge_style_is_latched = true
            return
        end
    end

    if not current_dodge_view_locked then
        current_dodge_style = DodgeStyle.FORWARD_ROLL
        dodge_style_is_latched = true
        return
    end

    if current_character and current_root_part
        and get_dodge_world_direction() then
        local yaw = get_dodge_direction_yaw(
            current_character,
            current_root_part
        )

        current_dodge_style =
            DefenseAnimationFactory.get_dodge_style(yaw)
        dodge_style_is_latched = true
    end
end


--[[
Begins one stable dodge presentation from server-owned attributes.

Unlocked dodges always keep the forward-roll family and temporarily disable
Humanoid AutoRotate while the local network owner turns smoothly into travel.

Args:
    None.

Returns:
    None.
]]
local function begin_dodge_presentation()
    current_dodge_style = DodgeStyle.FORWARD_ROLL
    current_dodge_view_locked = false
    dodge_style_is_latched = false
    unlocked_turn_start_rotation = nil

    if current_character then
        local view_locked_attribute =
            current_character:GetAttribute(
                CombatConfig.DEFENSE
                    .DODGE_VIEW_LOCKED_ATTRIBUTE
            )

        if typeof(view_locked_attribute) == "boolean" then
            current_dodge_view_locked =
                view_locked_attribute
        else
            current_dodge_view_locked =
                player:GetAttribute(
                    CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE
                ) == true
        end
    end

    try_latch_dodge_style()

    if current_dodge_view_locked then
        return
    end

    if current_root_part then
        unlocked_turn_start_rotation =
            current_root_part.CFrame
            - current_root_part.Position
    end

    if current_humanoid then
        current_humanoid.AutoRotate = false
    end
end


--[[
Restores normal rotation ownership after an unlocked dodge finishes.

Args:
    None.

Returns:
    None.
]]
local function end_dodge_presentation()
    if current_humanoid then
        local view_locked = player:GetAttribute(
            CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE
        ) == true

        current_humanoid.AutoRotate = not view_locked
    end

    current_dodge_style = DodgeStyle.FORWARD_ROLL
    current_dodge_view_locked = false
    dodge_style_is_latched = false
    unlocked_turn_start_rotation = nil
end


--[[
Turns an unlocked roll smoothly into its camera-relative travel direction.

The translation is already active while this brief local yaw blend occurs.
Only the locally owned root rotation is changed, avoiding the previous
server-side CFrame snap that fought normal character ownership.

Args:
    elapsed (number): Seconds since the dodge presentation started.

Returns:
    None.
]]
local function update_unlocked_dodge_facing(elapsed: number)
    if current_dodge_view_locked
        or not current_root_part
        or not unlocked_turn_start_rotation then
        return
    end

    local direction = get_dodge_world_direction()

    if not direction then
        return
    end

    local duration =
        CombatConfig.DEFENSE.UNLOCKED_DODGE_TURN_SECONDS
    local linear = math.clamp(
        elapsed / math.max(duration, 0.001),
        0,
        1
    )
    local alpha = linear
        * linear
        * (3 - (2 * linear))
    local target_rotation = CFrame.lookAt(
        Vector3.zero,
        direction,
        Vector3.yAxis
    )
    local rotation = unlocked_turn_start_rotation:Lerp(
        target_rotation,
        alpha
    )
    local position = current_root_part.Position

    current_root_part.CFrame =
        CFrame.new(position) * rotation

    if linear >= 1 then
        unlocked_turn_start_rotation = nil
    end
end


--[[
Stores R15 joints needed by defensive presentation.

Args:
    character (Model): Newly spawned local character.

Returns:
    None.
]]
local function on_character_added(character: Model)
    current_character = character
    current_humanoid = character:WaitForChild(
        "Humanoid"
    ) :: Humanoid
    current_root_part = character:WaitForChild(
        "HumanoidRootPart"
    ) :: BasePart
    idle_shield_reference = character:WaitForChild(
        ShieldConfig.IDLE_REFERENCE_PART_NAME
    ) :: BasePart
    block_shield_reference = character:WaitForChild(
        ShieldConfig.BLOCK_REFERENCE_PART_NAME
    ) :: BasePart

    task.defer(function()
        root_joint = find_rig_joint(
            character,
            {"Root", "RootJoint"}
        )
        waist_joint = find_rig_joint(
            character,
            {"Waist"}
        )
        left_shoulder_joint = find_rig_joint(
            character,
            {"LeftShoulder"}
        )
        left_elbow_joint = find_rig_joint(
            character,
            {"LeftElbow"}
        )
        left_wrist_joint = find_rig_joint(
            character,
            {"LeftWrist"}
        )
        left_hip_joint = find_rig_joint(
            character,
            {"LeftHip"}
        )
        right_hip_joint = find_rig_joint(
            character,
            {"RightHip"}
        )
        left_knee_joint = find_rig_joint(
            character,
            {"LeftKnee"}
        )
        right_knee_joint = find_rig_joint(
            character,
            {"RightKnee"}
        )

        local grip, binding_source =
            ShieldPresentationBinding.resolve(
                character,
                ShieldConfig,
                5
            )

        if grip then
            shield_grip = grip

            print(
                "[Combat Prototype] Shield presentation bound ("
                    .. binding_source
                    .. ")."
            )
        else
            warn(
                "[Combat Prototype] Shield presentation unavailable: "
                    .. binding_source
                    .. "."
            )
        end

        destroy_block_ik()
        create_block_ik(character)
        reset_pose()
    end)
end


--[[
Clears defensive presentation references when the character despawns.

Args:
    character (Model): Character being removed.

Returns:
    None.
]]
local function on_character_removing(
    _character: Model
)
    end_dodge_presentation()
    reset_pose()
    destroy_block_ik()
    root_joint = nil
    waist_joint = nil
    left_shoulder_joint = nil
    left_elbow_joint = nil
    left_wrist_joint = nil
    left_hip_joint = nil
    right_hip_joint = nil
    left_knee_joint = nil
    right_knee_joint = nil
    shield_grip = nil
    current_character = nil
    current_humanoid = nil
    current_root_part = nil
    idle_shield_reference = nil
    block_shield_reference = nil
end


--[[
Tracks authoritative defensive state mirrored by ClientCombatController.

Args:
    state_name (string): Local presentation combat state.
    attack_id (string): Current attack id, unused here.

Returns:
    None.
]]
local function on_state_changed(
    state_name: string,
    action_id: string
)
    local previous_state = current_state
    local was_defending =
        previous_state == State.BLOCKING
        or previous_state == State.DODGING
        or previous_state == State.GUARD_BREAK

    if previous_state == State.DODGING
        and state_name ~= State.DODGING then
        end_dodge_presentation()
    end

    current_state = state_name
    current_action_id = action_id
    state_started_at = os.clock()

    if current_state == State.DODGING then
        begin_dodge_presentation()
    end

    local is_defending =
        current_state == State.BLOCKING
        or current_state == State.DODGING
        or current_state == State.GUARD_BREAK

    if was_defending and not is_defending then
        reset_pose()
    end
end


--[[
Returns the current Shield Bash presentation extension from combat timing.

Args:
    skill_definition (table): Authoritative shared Shield Bash timing data.

Returns:
    number: Extension intensity from zero to one.
]]
local function get_shield_bash_intensity(
    skill_definition: any
): number
    local elapsed = os.clock() - state_started_at

    if current_state == State.WIND_UP then
        return math.clamp(
            elapsed / skill_definition.WIND_UP_SECONDS,
            0,
            1
        )
    end

    if current_state == State.ACTIVE then
        return 1
    end

    if current_state == State.RECOVERY then
        return 1 - math.clamp(
            elapsed / skill_definition.RECOVERY_SECONDS,
            0,
            1
        )
    end

    return 0
end


--[[
Applies the prototype Shield Bash shield, arm, and torso presentation.

Args:
    None.

Returns:
    None.
]]
local function render_shield_bash()
    local skill_definition = SkillDefinitions.get(current_action_id)

    if not skill_definition then
        return
    end

    local intensity = get_shield_bash_intensity(skill_definition)

    set_block_ik_enabled(true)
    update_bash_shield(intensity)
    update_bash_arm_ik(intensity)
    layer_joint_transform(
        waist_joint,
        CFrame.Angles(
            math.rad(
                -ShieldConfig.BASH_TORSO_LEAN_DEGREES * intensity
            ),
            0,
            0
        )
    )
end


--[[
Applies the active shield-wall presentation.

Args:
    None.

Returns:
    None.
]]
local function render_block()
    local block_bob = get_block_bob()

    update_block_shield(block_bob)
    update_shield_arm_ik(true, block_bob)

    if block_ik then
        set_block_ik_enabled(true)
    else
        set_joint_transform(
            left_shoulder_joint,
            DefenseAnimationFactory
                .get_block_shoulder_transform()
        )
        set_joint_transform(
            left_elbow_joint,
            DefenseAnimationFactory
                .get_block_elbow_transform()
        )
        set_joint_transform(
            left_wrist_joint,
            DefenseAnimationFactory
                .get_block_wrist_transform()
        )
    end

    layer_joint_transform(
        waist_joint,
        DefenseAnimationFactory.get_block_waist_transform()
    )
end


--[[
Applies the visual pose for the active dodge family.

Args:
    elapsed (number): Seconds since authoritative dodge state began.

Returns:
    None.
]]
local function render_dodge(elapsed: number)
    update_unlocked_dodge_facing(elapsed)
    try_latch_dodge_style()

    local direction_yaw = 0

    if current_dodge_view_locked
        and current_character
        and current_root_part then
        direction_yaw = get_dodge_direction_yaw(
            current_character,
            current_root_part
        )
    end

    local dodge_style = current_dodge_style
    local duration = CombatConfig.DEFENSE.DODGE_DURATION_SECONDS

    if dodge_style == DodgeStyle.SIDE_DASH then
        duration = CombatConfig.DEFENSE.SIDE_DASH_DURATION_SECONDS
    end

    local progress = elapsed / duration
    local dodge_transform = CFrame.identity

    if dodge_style == DodgeStyle.SIDE_DASH then
        dodge_transform = DefenseAnimationFactory
            .get_side_dash_root_transform(
                progress,
                direction_yaw
            )

        set_joint_transform(
            left_hip_joint,
            DefenseAnimationFactory
                .get_side_dash_left_hip_transform(
                    progress,
                    direction_yaw
                )
        )
        set_joint_transform(
            right_hip_joint,
            DefenseAnimationFactory
                .get_side_dash_right_hip_transform(
                    progress,
                    direction_yaw
                )
        )
        set_joint_transform(
            left_knee_joint,
            DefenseAnimationFactory
                .get_side_dash_left_knee_transform(
                    progress,
                    direction_yaw
                )
        )
        set_joint_transform(
            right_knee_joint,
            DefenseAnimationFactory
                .get_side_dash_right_knee_transform(
                    progress,
                    direction_yaw
                )
        )
        layer_joint_transform(
            waist_joint,
            DefenseAnimationFactory
                .get_side_dash_waist_transform(
                    progress,
                    direction_yaw
                )
        )
    elseif dodge_style == DodgeStyle.BACKWARD_ROLL then
        dodge_transform = DefenseAnimationFactory
            .get_backward_roll_root_transform(
                progress,
                direction_yaw
            )
    else
        dodge_transform = DefenseAnimationFactory
            .get_roll_root_transform(
                progress,
                direction_yaw
            )
    end

    layer_joint_transform(
        root_joint or waist_joint,
        dodge_transform
    )
end


--[[
Layers defensive presentation after the Animator evaluates.

Args:
    delta_time (number): PreSimulation frame delta, unused.

Returns:
    None.
]]
local function reconcile_shield_binding()
    if not current_character then
        return
    end

    local preferred, source =
        ShieldPresentationBinding.reconcile(
            current_character,
            ShieldConfig,
            shield_grip
        )

    if preferred and preferred ~= shield_grip then
        shield_grip = preferred

        print(
            "[Combat Prototype] Shield presentation rebound ("
                .. source
                .. ")."
        )
    end
end


local function render_defense(_delta_time: number)
    reconcile_shield_binding()

    if current_action_id == "ShieldBash"
        and (
            current_state == State.WIND_UP
            or current_state == State.ACTIVE
            or current_state == State.RECOVERY
        ) then
        render_shield_bash()
        return
    end

    if current_state == State.BLOCKING then
        render_block()
        return
    end

    if current_state == State.GUARD_BREAK then
        set_block_ik_enabled(false)
        update_idle_shield(0, 0, 0)

        local elapsed = os.clock() - state_started_at
        local progress = elapsed
            / CombatConfig.DEFENSE.GUARD_BREAK_SECONDS

        layer_joint_transform(
            waist_joint,
            DefenseAnimationFactory
                .get_guard_break_waist_transform(progress)
        )
        layer_joint_transform(
            left_shoulder_joint,
            CFrame.Angles(
                math.rad(25),
                0,
                math.rad(65)
            )
        )
        return
    end

    set_block_ik_enabled(true)

    local arm_bob, shield_extra_bob, forward_bob, shield_roll =
        get_walk_bob()

    update_shield_arm_ik(false, arm_bob)
    update_idle_shield(
        shield_extra_bob,
        forward_bob,
        shield_roll
    )

    if current_state == State.DODGING then
        render_dodge(os.clock() - state_started_at)
    end
end


ClientCombatController.on_state_changed(
    on_state_changed
)
player.CharacterAdded:Connect(on_character_added)
player.CharacterRemoving:Connect(on_character_removing)
RunService.PreSimulation:Connect(render_defense)

if player.Character then
    on_character_added(player.Character)
end
