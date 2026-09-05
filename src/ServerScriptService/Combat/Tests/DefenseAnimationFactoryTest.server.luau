local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local DefenseAnimationFactory = require(
    shared_folder:WaitForChild("DefenseAnimationFactory")
)

local assertion_count = 0
local DodgeStyle = DefenseAnimationFactory.DodgeStyle

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Defense Animation Tests] " .. message, 2)
    end

    assertion_count += 1
end

local start_transform =
    DefenseAnimationFactory.get_roll_root_transform(0)
local midpoint_transform =
    DefenseAnimationFactory.get_roll_root_transform(0.5)
local end_transform =
    DefenseAnimationFactory.get_roll_root_transform(1)
local forward_left_roll =
    DefenseAnimationFactory.get_roll_root_transform(
        0,
        math.rad(45)
    )
local side_left_transform =
    DefenseAnimationFactory.get_side_dash_root_transform(
        0.5,
        math.rad(90)
    )
local side_right_transform =
    DefenseAnimationFactory.get_side_dash_root_transform(
        0.5,
        math.rad(-90)
    )
local side_start_transform =
    DefenseAnimationFactory.get_side_dash_root_transform(
        0,
        math.rad(90)
    )
local side_end_transform =
    DefenseAnimationFactory.get_side_dash_root_transform(
        1,
        math.rad(90)
    )
local side_waist_transform =
    DefenseAnimationFactory.get_side_dash_waist_transform(
        0.5,
        math.rad(90)
    )
local backward_start =
    DefenseAnimationFactory.get_backward_roll_root_transform(
        0,
        math.rad(180)
    )
local backward_midpoint =
    DefenseAnimationFactory.get_backward_roll_root_transform(
        0.5,
        math.rad(180)
    )
local backward_end =
    DefenseAnimationFactory.get_backward_roll_root_transform(
        1,
        math.rad(180)
    )
local backward_left =
    DefenseAnimationFactory.get_backward_roll_root_transform(
        0.5,
        math.rad(135)
    )
local backward_right =
    DefenseAnimationFactory.get_backward_roll_root_transform(
        0.5,
        math.rad(-135)
    )
local block_transform =
    DefenseAnimationFactory.get_block_shoulder_transform()
local block_elbow_transform =
    DefenseAnimationFactory.get_block_elbow_transform()
local block_wrist_transform =
    DefenseAnimationFactory.get_block_wrist_transform()
local block_waist_transform =
    DefenseAnimationFactory.get_block_waist_transform()
local guard_break_transform =
    DefenseAnimationFactory.get_guard_break_waist_transform(0.5)

assert_true(
    DefenseAnimationFactory.get_dodge_style(0)
        == DodgeStyle.FORWARD_ROLL,
    "Forward dodge must use the forward-roll animation."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(45))
        == DodgeStyle.FORWARD_ROLL,
    "Forward-left dodge must remain a forward roll."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(-45))
        == DodgeStyle.FORWARD_ROLL,
    "Forward-right dodge must remain a forward roll."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(90))
        == DodgeStyle.SIDE_DASH,
    "Left dodge must use the lateral slide-dash."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(-90))
        == DodgeStyle.SIDE_DASH,
    "Right dodge must use the lateral slide-dash."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(135))
        == DodgeStyle.BACKWARD_ROLL,
    "Backward-left dodge must use a backward roll."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(-135))
        == DodgeStyle.BACKWARD_ROLL,
    "Backward-right dodge must use a backward roll."
)
assert_true(
    DefenseAnimationFactory.get_dodge_style(math.rad(180))
        == DodgeStyle.BACKWARD_ROLL,
    "Backward dodge must use a backward roll."
)
assert_true(
    start_transform.Position.Magnitude < 0.001,
    "Forward roll must start without a positional offset."
)
assert_true(
    start_transform.UpVector.Y > 0.99,
    "Forward roll must begin upright."
)
assert_true(
    midpoint_transform.UpVector.Y < -0.9,
    "Forward roll midpoint must visibly invert the character."
)
assert_true(
    midpoint_transform.Position.Y > 0.3,
    "Forward roll midpoint must add a small lift."
)
assert_true(
    end_transform.UpVector.Y > 0.99,
    "Forward roll must finish upright."
)
assert_true(
    forward_left_roll.LookVector.X < 0,
    "Forward diagonal roll may angle toward travel."
)
assert_true(
    forward_left_roll.LookVector.Z < -0.8,
    "Forward diagonal roll must still read as forward-facing."
)
assert_true(
    side_left_transform.LookVector.Z < -0.9,
    "Left slide-dash must not turn the character left."
)
assert_true(
    side_right_transform.LookVector.Z < -0.9,
    "Right slide-dash must not turn the character right."
)
assert_true(
    side_left_transform ~= side_right_transform,
    "Left and right slide-dashes must lean in opposite directions."
)
assert_true(
    side_left_transform.Position.Y <= 0,
    "Lateral slide-dash must stay grounded instead of jumping."
)
assert_true(
    side_left_transform.Position.Y > -0.10,
    "Lateral slide-dash must stay low without sinking into the floor."
)
assert_true(
    side_left_transform.UpVector.X < 0,
    "Left slide-dash must reverse the previous live-rig lean."
)
assert_true(
    side_right_transform.UpVector.X > 0,
    "Right slide-dash must reverse the previous live-rig lean."
)
assert_true(
    math.abs(side_left_transform.UpVector.X) > 0.12,
    "Left slide-dash must keep a visible stylised lean."
)
assert_true(
    math.abs(side_right_transform.UpVector.X) > 0.12,
    "Right slide-dash must keep a visible stylised lean."
)
assert_true(
    side_start_transform.Position.Magnitude < 0.001,
    "Lateral slide-dash must begin from a neutral body position."
)
assert_true(
    side_end_transform.Position.Magnitude < 0.001,
    "Lateral slide-dash must land back on the neutral body position."
)
assert_true(
    side_start_transform.UpVector.Y > 0.99,
    "Lateral slide-dash must begin upright."
)
assert_true(
    side_end_transform.UpVector.Y > 0.99,
    "Lateral slide-dash must finish upright for immediate movement."
)
assert_true(
    side_waist_transform ~= CFrame.identity,
    "Lateral slide-dash must counterbalance through the waist."
)

local left_dash_left_hip =
    DefenseAnimationFactory.get_side_dash_left_hip_transform(
        0.5,
        math.rad(90)
    )
local left_dash_right_hip =
    DefenseAnimationFactory.get_side_dash_right_hip_transform(
        0.5,
        math.rad(90)
    )
local left_dash_left_knee =
    DefenseAnimationFactory.get_side_dash_left_knee_transform(
        0.5,
        math.rad(90)
    )
local left_dash_right_knee =
    DefenseAnimationFactory.get_side_dash_right_knee_transform(
        0.5,
        math.rad(90)
    )

assert_true(
    left_dash_left_hip ~= CFrame.identity,
    "Lateral slide-dash must pose the leading leg."
)
assert_true(
    left_dash_right_hip ~= CFrame.identity,
    "Lateral slide-dash must pose the trailing leg."
)
assert_true(
    left_dash_left_hip ~= left_dash_right_hip,
    "Lateral slide-dash must keep a small directional hip asymmetry."
)
assert_true(
    left_dash_left_knee ~= CFrame.identity,
    "Leading knee must stay flexed through the low slide."
)
assert_true(
    left_dash_right_knee ~= CFrame.identity,
    "Trailing knee must stay flexed through the low slide."
)
assert_true(
    left_dash_left_knee ~= left_dash_right_knee,
    "The lead knee may retain a small directional emphasis."
)

local left_hip_pitch = select(
    1,
    left_dash_left_hip:ToOrientation()
)
local right_hip_pitch = select(
    1,
    left_dash_right_hip:ToOrientation()
)
local left_knee_pitch = select(
    1,
    left_dash_left_knee:ToOrientation()
)
local right_knee_pitch = select(
    1,
    left_dash_right_knee:ToOrientation()
)

assert_true(
    left_hip_pitch < 0 and right_hip_pitch < 0,
    "Both hips must stay loaded under the body during the slide."
)
assert_true(
    math.abs(left_hip_pitch - right_hip_pitch) < math.rad(5),
    "Lateral slide hips must remain nearly symmetrical."
)
assert_true(
    left_knee_pitch > 0 and right_knee_pitch > 0,
    "Both knees must remain flexed through the slide."
)
assert_true(
    math.abs(left_knee_pitch - right_knee_pitch) < math.rad(5),
    "Lateral slide knees must avoid a one-foot hop silhouette."
)
assert_true(
    backward_start.UpVector.Y > 0.99,
    "Backward roll must begin upright."
)
assert_true(
    backward_start.LookVector.Z < -0.9,
    "Backward roll must begin facing the combat direction."
)
assert_true(
    backward_midpoint.UpVector.Y < -0.9,
    "Backward roll midpoint must visibly invert the character."
)
assert_true(
    backward_midpoint.Position.Y > 0.25,
    "Backward roll midpoint must lift off the ground."
)
assert_true(
    backward_end.UpVector.Y > 0.99,
    "Backward roll must finish upright."
)
assert_true(
    backward_end.LookVector.Z < -0.9,
    "Backward roll must finish facing the combat direction."
)
assert_true(
    backward_left ~= backward_right,
    "Backward diagonal rolls must lean toward opposite sides."
)
assert_true(
    block_transform.Position.Z < -0.15,
    "Block shoulder must push the shield arm forward."
)
assert_true(
    block_elbow_transform ~= CFrame.identity,
    "Block pose must bend the left elbow behind the shield."
)
assert_true(
    block_wrist_transform ~= CFrame.identity,
    "Block pose must brace the left hand behind the shield."
)
assert_true(
    block_waist_transform.Position.Z < 0,
    "Block torso must brace slightly forward."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.ATTACH_PART_NAME
        == "HumanoidRootPart",
    "Prototype shield presentation grip must be root-owned."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.IDLE_REFERENCE_PART_NAME
        == "LeftLowerArm",
    "Idle shield placement must follow the left forearm."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BLOCK_REFERENCE_PART_NAME
        == "UpperTorso",
    "Block shield placement must use the upper torso."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BLOCK_FORWARD_STUDS > 1,
    "Block shield wall must sit clearly in front of the torso."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BLOCK_LEFT_STUDS < 0.5,
    "Block shield wall must remain near torso centre."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.IK_SMOOTH_TIME > 0,
    "Shield-arm IK must smooth target transitions."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.WALK_ARM_BOB_STUDS > 0,
    "Walking must add a controlled shield-arm bob."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.WALK_SHIELD_EXTRA_BOB_STUDS
        > CombatConfig.PROTOTYPE_SHIELD.WALK_ARM_BOB_STUDS,
    "Shield must bob more visibly than the stabilised arm."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.IDLE_HAND_DOWN_STUDS
        > CombatConfig.PROTOTYPE_SHIELD.BLOCK_HAND_DOWN_STUDS,
    "Idle shield hand must sit lower than the active block hand."
)
assert_true(
    guard_break_transform ~= CFrame.identity,
    "Guard Break midpoint must visibly recoil."
)

print(
    string.format(
        "[Defense Animation Tests] PASS: %d assertions.",
        assertion_count
    )
)
