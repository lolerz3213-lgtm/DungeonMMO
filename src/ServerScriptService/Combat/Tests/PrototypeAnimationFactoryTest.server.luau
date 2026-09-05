local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local PrototypeAnimationFactory = require(
    shared_folder:WaitForChild("PrototypeAnimationFactory")
)

local BasicAttack = CombatConfig.BASIC_ATTACK
local assertion_count = 0
local EPSILON = 1e-6


--[[
Raises an error when a combat-animation assertion is false.

Args:
    condition (boolean): Test condition that must be true.
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
            "[Combat Animation Tests] " .. message
        )
    end
end


--[[
Returns the latest keyframe time in a sequence.

Args:
    sequence (KeyframeSequence): Sequence being inspected.

Returns:
    number: Greatest Keyframe.Time value.
]]
local function get_sequence_length(
    sequence: KeyframeSequence
): number
    local length = 0

    for _, keyframe in sequence:GetKeyframes() do
        length = math.max(length, keyframe.Time)
    end

    return length
end


--[[
Recursively checks whether a pose hierarchy contains a named pose.

Args:
    parent (Instance): Keyframe or Pose being searched.
    pose_name (string): R15 BasePart pose name.

Returns:
    boolean: True when the pose exists in the hierarchy.
]]
local function contains_pose(
    parent: Instance,
    pose_name: string
): boolean
    for _, child in parent:GetChildren() do
        if child:IsA("Pose") then
            if child.Name == pose_name then
                return true
            end

            if contains_pose(child, pose_name) then
                return true
            end
        end
    end

    return false
end


--[[
Validates one generated attack sequence.

Args:
    attack_id (string): Attack identifier being tested.
    attack_definition (table): CombatConfig definition for attack.

Returns:
    None.
]]
local function test_attack_sequence(
    attack_id: string,
    attack_definition: any
)
    local sequence =
        PrototypeAnimationFactory.create_sequence(
            attack_id,
            attack_definition
        )

    local keyframes = sequence:GetKeyframes()
    local expected_duration =
        PrototypeAnimationFactory.get_expected_duration(
            attack_definition
        )

    assert_true(
        sequence:IsA("KeyframeSequence"),
        attack_id .. " must create a KeyframeSequence."
    )
    assert_true(
        sequence.Priority == Enum.AnimationPriority.Action,
        attack_id .. " must use Action priority."
    )
    assert_true(
        sequence.Loop == false,
        attack_id .. " must not loop."
    )
    assert_true(
        #keyframes == 6,
        attack_id .. " must contain six keyframes."
    )
    assert_true(
        math.abs(
            get_sequence_length(sequence)
                - expected_duration
        ) <= EPSILON,
        attack_id .. " duration must match combat timing."
    )

    local first_keyframe = keyframes[1]

    assert_true(
        contains_pose(first_keyframe, "UpperTorso"),
        attack_id .. " must animate UpperTorso."
    )
    assert_true(
        contains_pose(first_keyframe, "RightUpperArm"),
        attack_id .. " must animate RightUpperArm."
    )
    assert_true(
        contains_pose(first_keyframe, "RightLowerArm"),
        attack_id .. " must animate RightLowerArm."
    )
    assert_true(
        contains_pose(first_keyframe, "RightHand"),
        attack_id .. " must animate RightHand."
    )

    sequence:Destroy()
end


for _, attack_id in BasicAttack.ATTACK_ORDER do
    local attack_definition =
        BasicAttack.ATTACKS[attack_id]

    test_attack_sequence(
        attack_id,
        attack_definition
    )
end


local carry =
    PrototypeAnimationFactory.create_carry_sequence(
        "SwordCarry"
    )

assert_true(
    carry:IsA("KeyframeSequence"),
    "Fallback carry must create a KeyframeSequence."
)
assert_true(
    carry.Name == "SwordCarry",
    "Fallback carry must keep the requested clip name."
)
assert_true(
    carry.Loop == true,
    "Fallback carry must loop."
)
assert_true(
    carry.Priority == Enum.AnimationPriority.Action,
    "Fallback carry must use Action priority."
)
local carry_keyframes = carry:GetKeyframes()
local carry_first_keyframe = carry_keyframes[1]

assert_true(
    carry_first_keyframe ~= nil,
    "Fallback carry must contain at least one keyframe."
)
assert_true(
    not contains_pose(carry_first_keyframe, "LeftUpperArm"),
    "Fallback carry must leave the shield arm free."
)
assert_true(
    contains_pose(carry_first_keyframe, "RightUpperArm"),
    "Fallback carry must retain the sword arm."
)

carry:Destroy()

print(
    string.format(
        "[Combat Animation Tests] PASS: %d assertions.",
        assertion_count
    )
)
