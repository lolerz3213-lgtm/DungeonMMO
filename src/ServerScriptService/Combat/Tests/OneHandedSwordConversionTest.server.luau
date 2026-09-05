local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local combat_folder = ReplicatedStorage
    :WaitForChild("Combat")
local shared_folder = combat_folder
    :WaitForChild("Shared")

local AttackStepRules = require(
    shared_folder:WaitForChild("AttackStepRules")
)
local converter = require(
    shared_folder:WaitForChild(
        "OneHandedAnimationConverter"
    )
)

local assertion_count = 0
local EPSILON = 1e-6


--[[
Raises an error when an assertion is false.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[One-Handed Sword Tests] " .. message
        )
    end
end


--[[
Checks whether an animation contains a named Pose.

Args:
    parent (Instance): Animation hierarchy root.
    pose_name (string): Pose name being searched.

Returns:
    boolean: True when the Pose exists.
]]
local function contains_pose(
    parent: Instance,
    pose_name: string
): boolean
    for _, descendant in parent:GetDescendants() do
        if descendant:IsA("Pose")
            and descendant.Name == pose_name then
            return true
        end
    end

    return false
end


--[[
Creates a tiny R15-like animation for converter tests.

Args:
    None.

Returns:
    KeyframeSequence: Two-keyframe source animation.
]]
local function create_test_sequence(): KeyframeSequence
    local sequence = Instance.new(
        "KeyframeSequence"
    )

    for index = 0, 1 do
        local keyframe = Instance.new("Keyframe")
        keyframe.Time = index

        local root = Instance.new("Pose")
        root.Name = "HumanoidRootPart"

        local lower = Instance.new("Pose")
        lower.Name = "LowerTorso"

        local upper = Instance.new("Pose")
        upper.Name = "UpperTorso"

        local right_upper = Instance.new("Pose")
        right_upper.Name = "RightUpperArm"
        right_upper.CFrame = CFrame.Angles(
            math.rad(20),
            0,
            math.rad(40)
        )

        local right_lower = Instance.new("Pose")
        right_lower.Name = "RightLowerArm"

        local right_hand = Instance.new("Pose")
        right_hand.Name = "RightHand"

        local left_upper = Instance.new("Pose")
        left_upper.Name = "LeftUpperArm"

        local right_leg = Instance.new("Pose")
        right_leg.Name = "RightUpperLeg"

        right_lower:AddSubPose(right_hand)
        right_upper:AddSubPose(right_lower)
        upper:AddSubPose(right_upper)
        upper:AddSubPose(left_upper)
        lower:AddSubPose(upper)
        lower:AddSubPose(right_leg)
        root:AddSubPose(lower)
        keyframe:AddPose(root)
        sequence:AddKeyframe(keyframe)
    end

    return sequence
end


local source = create_test_sequence()
local attack = converter.convert_attack(
    source,
    "ConvertedAttack",
    0.60
)
local carry = converter.convert_carry(
    source,
    "SwordCarry"
)

assert_true(
    attack.Priority
        == Enum.AnimationPriority.Action2,
    "Attacks must keep Action2 priority."
)
assert_true(
    not attack.Loop,
    "Attacks must not loop."
)
assert_true(
    not contains_pose(
        attack,
        "LeftUpperArm"
    ),
    "Attack must leave the left arm free."
)
assert_true(
    contains_pose(
        attack,
        "RightUpperArm"
    ),
    "Attack must retain the sword arm."
)

local attack_length = 0

for _, keyframe in attack:GetKeyframes() do
    attack_length = math.max(
        attack_length,
        keyframe.Time
    )
end

assert_true(
    math.abs(attack_length - 0.60) <= EPSILON,
    "Attack must retime to combat duration."
)

assert_true(
    carry.Loop,
    "Sword carry overlay must loop."
)
assert_true(
    carry.Priority == Enum.AnimationPriority.Action,
    "Sword carry overlay must use Action priority."
)
assert_true(
    contains_pose(
        carry,
        "RightUpperArm"
    ),
    "Sword carry must animate the sword arm."
)
assert_true(
    contains_pose(
        carry,
        "RightLowerArm"
    ),
    "Sword carry must include the forearm."
)
assert_true(
    contains_pose(
        carry,
        "RightHand"
    ),
    "Sword carry must include the hand."
)
assert_true(
    not contains_pose(
        carry,
        "LeftUpperArm"
    ),
    "Sword carry must leave the left arm free."
)
assert_true(
    not contains_pose(
        carry,
        "RightUpperLeg"
    ),
    "Sword carry must not override leg locomotion."
)

local step_definition = {
    ACTIVE_SECONDS = 0.10,
    RECOVERY_SECONDS = 0.30,
}

local step_duration =
    AttackStepRules.get_step_duration(
        step_definition
    )

assert_true(
    step_duration > 0.10
        and step_duration <= 0.22,
    "Attack step duration must remain brief."
)
assert_true(
    math.abs(
        AttackStepRules.get_step_speed(
            1.4,
            step_duration
        )
        - (1.4 / step_duration)
    ) <= EPSILON,
    "Step speed must cover the configured distance."
)

source:Destroy()
attack:Destroy()
carry:Destroy()

local imported = combat_folder:WaitForChild(
    "PrototypeAnimations",
    5
)

assert_true(
    imported ~= nil,
    "Runtime importer must create PrototypeAnimations."
)

if imported then
    for _, name in {
        "Slice1",
        "Slice2",
        "Slice5",
        "SwordCarry",
    } do
        local sequence = imported:FindFirstChild(
            name
        )

        assert_true(
            sequence ~= nil
                and sequence:IsA(
                    "KeyframeSequence"
                ),
            name .. " must be imported."
        )
    end
end

print(
    string.format(
        "[One-Handed Sword Tests] PASS: %d assertions.",
        assertion_count
    )
)
