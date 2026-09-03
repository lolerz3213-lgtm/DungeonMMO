local OneHandedAnimationConverter = {}

local ATTACK_TORSO_WEIGHT = 0.68
local ATTACK_RIGHT_UPPER_WEIGHT = 0.95
local ATTACK_RIGHT_LOWER_WEIGHT = 0.90
local ATTACK_RIGHT_HAND_WEIGHT = 0.82

local CARRY_RIGHT_UPPER_WEIGHT = 0.06
local CARRY_RIGHT_LOWER_WEIGHT = 0.05
local CARRY_RIGHT_HAND_WEIGHT = 0.04


--[[
Returns the final keyframe time in a sequence.

Args:
    sequence (KeyframeSequence): Sequence being measured.

Returns:
    number: Latest keyframe time.
]]
local function get_sequence_length(
    sequence: KeyframeSequence
): number
    local length = 0

    for _, keyframe in sequence:GetKeyframes() do
        length = math.max(
            length,
            keyframe.Time
        )
    end

    return length
end


--[[
Finds every Pose with the requested name.

Args:
    parent (Instance): Animation hierarchy root.
    pose_name (string): Pose name to locate.

Returns:
    {Pose}: Matching poses.
]]
local function find_poses(
    parent: Instance,
    pose_name: string
): {Pose}
    local matches = {}

    for _, descendant in parent:GetDescendants() do
        if descendant:IsA("Pose")
            and descendant.Name == pose_name then
            table.insert(
                matches,
                descendant
            )
        end
    end

    return matches
end


--[[
Removes the left-arm animation branch from all keyframes.

Args:
    sequence (KeyframeSequence): Converted sequence.

Returns:
    None.
]]
local function remove_left_arm(
    sequence: KeyframeSequence
)
    for _, pose in find_poses(
        sequence,
        "LeftUpperArm"
    ) do
        pose:Destroy()
    end
end


--[[
Softens a pose toward the neutral joint transform.

Args:
    sequence (KeyframeSequence): Sequence being modified.
    pose_name (string): R15 Pose name.
    source_weight (number): Amount of source motion to retain.

Returns:
    None.
]]
local function damp_pose(
    sequence: KeyframeSequence,
    pose_name: string,
    source_weight: number
)
    for _, pose in find_poses(
        sequence,
        pose_name
    ) do
        pose.CFrame = CFrame.identity:Lerp(
            pose.CFrame,
            source_weight
        )
    end
end


--[[
Retimes a sequence proportionally to a requested duration.

Args:
    sequence (KeyframeSequence): Sequence being retimed.
    target_duration (number): New total duration in seconds.

Returns:
    None.
]]
local function retime_sequence(
    sequence: KeyframeSequence,
    target_duration: number
)
    local source_duration =
        get_sequence_length(sequence)

    if source_duration <= 0 then
        return
    end

    for _, keyframe in sequence:GetKeyframes() do
        local normalized =
            keyframe.Time / source_duration

        keyframe.Time =
            normalized * target_duration
    end
end


--[[
Removes animation branches that are not required for the sword arm.

The hierarchy above RightUpperArm is retained because Roblox poses
follow the rig hierarchy, but torso and leg transforms are reset so
normal locomotion remains visually dominant.

Args:
    sequence (KeyframeSequence): Carry overlay being reduced.

Returns:
    None.
]]
local function prune_to_sword_arm(
    sequence: KeyframeSequence
)
    remove_left_arm(sequence)

    local reset_names = {
        "HumanoidRootPart",
        "LowerTorso",
        "UpperTorso",
    }

    for _, pose_name in reset_names do
        for _, pose in find_poses(
            sequence,
            pose_name
        ) do
            pose.CFrame = CFrame.identity
        end
    end

    local removable_names = {
        "Head",
        "LeftUpperLeg",
        "LeftLowerLeg",
        "LeftFoot",
        "RightUpperLeg",
        "RightLowerLeg",
        "RightFoot",
    }

    for _, pose_name in removable_names do
        for _, pose in find_poses(
            sequence,
            pose_name
        ) do
            pose:Destroy()
        end
    end
end


--[[
Converts a two-handed R15 sword attack to one-handed presentation.

Args:
    source (KeyframeSequence): Source R15 sword attack.
    target_name (string): Name for converted sequence.
    target_duration (number): Required combat duration.

Returns:
    KeyframeSequence: Converted one-handed attack.
]]
function OneHandedAnimationConverter.convert_attack(
    source: KeyframeSequence,
    target_name: string,
    target_duration: number
): KeyframeSequence
    local sequence =
        source:Clone() :: KeyframeSequence

    sequence.Name = target_name
    sequence.Loop = false
    sequence.Priority =
        Enum.AnimationPriority.Action2

    remove_left_arm(sequence)

    damp_pose(
        sequence,
        "UpperTorso",
        ATTACK_TORSO_WEIGHT
    )
    damp_pose(
        sequence,
        "RightUpperArm",
        ATTACK_RIGHT_UPPER_WEIGHT
    )
    damp_pose(
        sequence,
        "RightLowerArm",
        ATTACK_RIGHT_LOWER_WEIGHT
    )
    damp_pose(
        sequence,
        "RightHand",
        ATTACK_RIGHT_HAND_WEIGHT
    )

    retime_sequence(
        sequence,
        target_duration
    )

    return sequence
end


--[[
Creates a light right-arm sword carry overlay from the source idle.

The source katana pose is almost completely damped toward the neutral
R15 arm position. Playback weight is then changed by the client so
normal Roblox locomotion remains visible while the sword stays biased
toward the player's side.

Args:
    source (KeyframeSequence): Source R15 sword idle.
    target_name (string): Name for the carry overlay.

Returns:
    KeyframeSequence: Looping right-arm-only carry overlay.
]]
function OneHandedAnimationConverter.convert_carry(
    source: KeyframeSequence,
    target_name: string
): KeyframeSequence
    local sequence =
        source:Clone() :: KeyframeSequence

    sequence.Name = target_name
    sequence.Loop = true
    sequence.Priority =
        Enum.AnimationPriority.Action

    prune_to_sword_arm(sequence)

    damp_pose(
        sequence,
        "RightUpperArm",
        CARRY_RIGHT_UPPER_WEIGHT
    )
    damp_pose(
        sequence,
        "RightLowerArm",
        CARRY_RIGHT_LOWER_WEIGHT
    )
    damp_pose(
        sequence,
        "RightHand",
        CARRY_RIGHT_HAND_WEIGHT
    )

    return sequence
end


return table.freeze(OneHandedAnimationConverter)
