local PrototypeAnimationFactory = {}

type PoseMap = {
    UpperTorso: CFrame,
    RightUpperArm: CFrame,
    RightLowerArm: CFrame,
    RightHand: CFrame,
    LeftUpperArm: CFrame,
}

type AttackPoseSet = {
    ANTICIPATION: PoseMap,
    WIND_UP: PoseMap,
    CONTACT: PoseMap,
    FOLLOW_THROUGH: PoseMap,
}

type RuntimePoseMap = {
    UpperTorso: CFrame,
    RightUpperArm: CFrame,
    RightLowerArm: CFrame,
    RightHand: CFrame,
}

local IDENTITY_POSE: PoseMap = {
    UpperTorso = CFrame.identity,
    RightUpperArm = CFrame.identity,
    RightLowerArm = CFrame.identity,
    RightHand = CFrame.identity,
    LeftUpperArm = CFrame.identity,
}

local ATTACK_POSES: {[string]: AttackPoseSet} = {
    Slash1 = {
        ANTICIPATION = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(18),
                math.rad(-3)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-24),
                math.rad(8),
                math.rad(38)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-18),
                0,
                math.rad(5)
            ),
            RightHand = CFrame.Angles(
                0,
                0,
                math.rad(10)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(-8)
            ),
        },

        WIND_UP = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(38),
                math.rad(-5)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-52),
                math.rad(10),
                math.rad(76)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-36),
                0,
                math.rad(10)
            ),
            RightHand = CFrame.Angles(
                math.rad(-5),
                0,
                math.rad(24)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(10),
                math.rad(-5),
                math.rad(-14)
            ),
        },

        CONTACT = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(-16),
                math.rad(3)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(8),
                math.rad(-7),
                math.rad(-28)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-10),
                0,
                math.rad(-5)
            ),
            RightHand = CFrame.Angles(
                0,
                0,
                math.rad(-14)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-8),
                math.rad(5),
                math.rad(10)
            ),
        },

        FOLLOW_THROUGH = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(-40),
                math.rad(6)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(28),
                math.rad(-10),
                math.rad(-62)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(4),
                0,
                math.rad(-10)
            ),
            RightHand = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(-28)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-12),
                math.rad(5),
                math.rad(16)
            ),
        },
    },

    Slash2 = {
        ANTICIPATION = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(-16),
                math.rad(3)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-20),
                math.rad(-8),
                math.rad(-30)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-16),
                0,
                math.rad(-6)
            ),
            RightHand = CFrame.Angles(
                0,
                0,
                math.rad(-8)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(8)
            ),
        },

        WIND_UP = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(-36),
                math.rad(5)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-44),
                math.rad(-10),
                math.rad(-66)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-32),
                0,
                math.rad(-10)
            ),
            RightHand = CFrame.Angles(
                math.rad(-5),
                0,
                math.rad(-22)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(10),
                math.rad(5),
                math.rad(14)
            ),
        },

        CONTACT = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(15),
                math.rad(-3)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(7),
                math.rad(7),
                math.rad(26)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-8),
                0,
                math.rad(5)
            ),
            RightHand = CFrame.Angles(
                0,
                0,
                math.rad(13)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-7),
                math.rad(-5),
                math.rad(-9)
            ),
        },

        FOLLOW_THROUGH = {
            UpperTorso = CFrame.Angles(
                0,
                math.rad(38),
                math.rad(-6)
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(26),
                math.rad(10),
                math.rad(58)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(9)
            ),
            RightHand = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(26)
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-12),
                math.rad(-5),
                math.rad(-15)
            ),
        },
    },

    Finisher = {
        ANTICIPATION = {
            UpperTorso = CFrame.Angles(
                math.rad(-6),
                0,
                0
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-62),
                0,
                math.rad(12)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-26),
                0,
                0
            ),
            RightHand = CFrame.Angles(
                math.rad(-8),
                0,
                0
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-14),
                0,
                math.rad(-6)
            ),
        },

        WIND_UP = {
            UpperTorso = CFrame.Angles(
                math.rad(-13),
                0,
                0
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(-126),
                0,
                math.rad(14)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-54),
                0,
                0
            ),
            RightHand = CFrame.Angles(
                math.rad(-14),
                0,
                0
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(-28),
                0,
                math.rad(-10)
            ),
        },

        CONTACT = {
            UpperTorso = CFrame.Angles(
                math.rad(9),
                0,
                0
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(2),
                0,
                math.rad(-5)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(-10),
                0,
                0
            ),
            RightHand = CFrame.Angles(
                math.rad(8),
                0,
                0
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(5),
                0,
                math.rad(5)
            ),
        },

        FOLLOW_THROUGH = {
            UpperTorso = CFrame.Angles(
                math.rad(20),
                0,
                0
            ),
            RightUpperArm = CFrame.Angles(
                math.rad(54),
                0,
                math.rad(-10)
            ),
            RightLowerArm = CFrame.Angles(
                math.rad(8),
                0,
                0
            ),
            RightHand = CFrame.Angles(
                math.rad(16),
                0,
                0
            ),
            LeftUpperArm = CFrame.Angles(
                math.rad(15),
                0,
                math.rad(8)
            ),
        },
    },
}


--[[
Creates one Pose with consistent combat-animation easing.

Args:
    name (string): R15 BasePart name targeted by the pose.
    pose_cframe (CFrame): Relative animation transform for the joint.

Returns:
    Pose: Configured pose instance.
]]
local function create_pose(
    name: string,
    pose_cframe: CFrame
): Pose
    local pose = Instance.new("Pose")

    pose.Name = name
    pose.CFrame = pose_cframe
    pose.EasingStyle = Enum.PoseEasingStyle.Cubic
    pose.EasingDirection = Enum.PoseEasingDirection.Out

    return pose
end


--[[
Creates one R15 upper-body pose hierarchy for a keyframe.

Args:
    pose_map (PoseMap): Relative transforms for animated body parts.

Returns:
    Pose: Root HumanoidRootPart pose containing the hierarchy.
]]
local function create_r15_pose_tree(
    pose_map: PoseMap
): Pose
    local root = create_pose(
        "HumanoidRootPart",
        CFrame.identity
    )
    local lower_torso = create_pose(
        "LowerTorso",
        CFrame.identity
    )
    local upper_torso = create_pose(
        "UpperTorso",
        pose_map.UpperTorso
    )
    local right_upper_arm = create_pose(
        "RightUpperArm",
        pose_map.RightUpperArm
    )
    local right_lower_arm = create_pose(
        "RightLowerArm",
        pose_map.RightLowerArm
    )
    local right_hand = create_pose(
        "RightHand",
        pose_map.RightHand
    )
    local left_upper_arm = create_pose(
        "LeftUpperArm",
        pose_map.LeftUpperArm
    )
    local left_lower_arm = create_pose(
        "LeftLowerArm",
        CFrame.identity
    )
    local left_hand = create_pose(
        "LeftHand",
        CFrame.identity
    )

    right_lower_arm:AddSubPose(right_hand)
    right_upper_arm:AddSubPose(right_lower_arm)

    left_lower_arm:AddSubPose(left_hand)
    left_upper_arm:AddSubPose(left_lower_arm)

    upper_torso:AddSubPose(right_upper_arm)
    upper_torso:AddSubPose(left_upper_arm)

    lower_torso:AddSubPose(upper_torso)
    root:AddSubPose(lower_torso)

    return root
end


--[[
Adds a timed R15 upper-body keyframe to a sequence.

Args:
    sequence (KeyframeSequence): Sequence receiving the keyframe.
    time_seconds (number): Playback position of the keyframe.
    pose_map (PoseMap): Body pose to apply at this time.

Returns:
    Keyframe: Created keyframe.
]]
local function add_keyframe(
    sequence: KeyframeSequence,
    time_seconds: number,
    pose_map: PoseMap
): Keyframe
    local keyframe = Instance.new("Keyframe")

    keyframe.Time = time_seconds
    keyframe:AddPose(create_r15_pose_tree(pose_map))
    sequence:AddKeyframe(keyframe)

    return keyframe
end


--[[
Returns the complete configured duration for an attack.

Args:
    attack_definition (table): CombatConfig attack definition.

Returns:
    number: Total wind-up, active, and recovery duration.
]]
local function get_total_duration(
    attack_definition: any
): number
    return attack_definition.WIND_UP_SECONDS
        + attack_definition.ACTIVE_SECONDS
        + attack_definition.RECOVERY_SECONDS
end


local function runtime_pose(
    pose: PoseMap
): RuntimePoseMap
    return {
        UpperTorso = pose.UpperTorso,
        RightUpperArm = pose.RightUpperArm,
        RightLowerArm = pose.RightLowerArm,
        RightHand = pose.RightHand,
    }
end


local function lerp_runtime_pose(
    first: PoseMap,
    second: PoseMap,
    alpha: number
): RuntimePoseMap
    local clamped = math.clamp(alpha, 0, 1)

    return {
        UpperTorso = first.UpperTorso:Lerp(
            second.UpperTorso,
            clamped
        ),
        RightUpperArm = first.RightUpperArm:Lerp(
            second.RightUpperArm,
            clamped
        ),
        RightLowerArm = first.RightLowerArm:Lerp(
            second.RightLowerArm,
            clamped
        ),
        RightHand = first.RightHand:Lerp(
            second.RightHand,
            clamped
        ),
    }
end


function PrototypeAnimationFactory.sample_attack_pose(
    attack_id: string,
    attack_definition: any,
    elapsed_seconds: number
): RuntimePoseMap
    local pose_set = ATTACK_POSES[attack_id]

    if not pose_set then
        error(
            "No prototype animation poses configured for "
                .. attack_id
        )
    end

    local wind_up = attack_definition.WIND_UP_SECONDS
    local active = attack_definition.ACTIVE_SECONDS
    local active_end = wind_up + active
    local total_duration = get_total_duration(
        attack_definition
    )
    local samples = {
        {
            time = 0,
            pose = IDENTITY_POSE,
        },
        {
            time = wind_up * 0.55,
            pose = pose_set.ANTICIPATION,
        },
        {
            time = wind_up,
            pose = pose_set.WIND_UP,
        },
        {
            time = wind_up + (active * 0.55),
            pose = pose_set.CONTACT,
        },
        {
            time = active_end,
            pose = pose_set.FOLLOW_THROUGH,
        },
        {
            time = total_duration,
            pose = IDENTITY_POSE,
        },
    }

    local elapsed = math.clamp(
        elapsed_seconds,
        0,
        total_duration
    )

    for index = 2, #samples do
        local previous = samples[index - 1]
        local current = samples[index]

        if elapsed <= current.time then
            local duration = current.time - previous.time
            local alpha = if duration <= 0
                then 1
                else (elapsed - previous.time) / duration

            return lerp_runtime_pose(
                previous.pose,
                current.pose,
                alpha
            )
        end
    end

    return runtime_pose(IDENTITY_POSE)
end


--[[
Builds a temporary R15 attack KeyframeSequence.

Six keyframes provide anticipation, committed wind-up, contact,
follow-through, and controlled recovery while preserving combat timing.

Args:
    attack_id (string): Slash1, Slash2, or Finisher identifier.
    attack_definition (table): CombatConfig timing definition.

Returns:
    KeyframeSequence: Action-priority clip for Studio playback.
]]
function PrototypeAnimationFactory.create_sequence(
    attack_id: string,
    attack_definition: any
): KeyframeSequence
    local pose_set = ATTACK_POSES[attack_id]

    if not pose_set then
        error(
            "No prototype animation poses configured for "
                .. attack_id
        )
    end

    local sequence = Instance.new("KeyframeSequence")
    local wind_up = attack_definition.WIND_UP_SECONDS
    local active = attack_definition.ACTIVE_SECONDS
    local recovery = attack_definition.RECOVERY_SECONDS
    local active_end = wind_up + active
    local total_duration = wind_up + active + recovery

    sequence.Name = attack_id .. "PrototypeSequence"
    sequence.Loop = false
    sequence.Priority = Enum.AnimationPriority.Action

    add_keyframe(
        sequence,
        0,
        IDENTITY_POSE
    )
    add_keyframe(
        sequence,
        wind_up * 0.55,
        pose_set.ANTICIPATION
    )
    add_keyframe(
        sequence,
        wind_up,
        pose_set.WIND_UP
    )
    add_keyframe(
        sequence,
        wind_up + (active * 0.55),
        pose_set.CONTACT
    )
    add_keyframe(
        sequence,
        active_end,
        pose_set.FOLLOW_THROUGH
    )
    add_keyframe(
        sequence,
        total_duration,
        IDENTITY_POSE
    )

    return sequence
end


--[[
Builds a small source-controlled right-arm sword carry overlay.

This is used only as a clean-build fallback when the Studio-only AnimSaves
source collection is unavailable. The left arm branch is removed so shield
presentation remains free to control that arm.

Args:
    target_name (string): Name assigned to the generated sequence.

Returns:
    KeyframeSequence: Looping Action-priority right-arm carry clip.
]]
function PrototypeAnimationFactory.create_carry_sequence(
    target_name: string
): KeyframeSequence
    local carry_pose: PoseMap = {
        UpperTorso = CFrame.identity,
        RightUpperArm = CFrame.Angles(
            math.rad(-5),
            0,
            math.rad(9)
        ),
        RightLowerArm = CFrame.Angles(
            math.rad(-4),
            0,
            math.rad(3)
        ),
        RightHand = CFrame.Angles(
            0,
            0,
            math.rad(3)
        ),
        LeftUpperArm = CFrame.identity,
    }

    local sequence = Instance.new("KeyframeSequence")

    sequence.Name = target_name
    sequence.Loop = true
    sequence.Priority = Enum.AnimationPriority.Action

    add_keyframe(sequence, 0, carry_pose)
    add_keyframe(sequence, 1, carry_pose)

    for _, descendant in sequence:GetDescendants() do
        if descendant:IsA("Pose")
            and descendant.Name == "LeftUpperArm" then
            descendant:Destroy()
        end
    end

    return sequence
end


function PrototypeAnimationFactory.get_carry_pose(): RuntimePoseMap
    return {
        UpperTorso = CFrame.identity,
        RightUpperArm = CFrame.Angles(
            math.rad(-5),
            0,
            math.rad(9)
        ),
        RightLowerArm = CFrame.Angles(
            math.rad(-4),
            0,
            math.rad(3)
        ),
        RightHand = CFrame.Angles(
            0,
            0,
            math.rad(3)
        ),
    }
end


--[[
Returns the expected duration for a generated sequence.

Args:
    attack_definition (table): CombatConfig attack definition.

Returns:
    number: Total animation duration in seconds.
]]
function PrototypeAnimationFactory.get_expected_duration(
    attack_definition: any
): number
    return get_total_duration(attack_definition)
end


return PrototypeAnimationFactory
