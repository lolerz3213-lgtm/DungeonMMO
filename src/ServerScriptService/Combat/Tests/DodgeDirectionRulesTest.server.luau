local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local DodgeDirectionRules = require(
    combat_folder:WaitForChild("DodgeDirectionRules")
)

local assertion_count = 0
local FORWARD = Vector3.new(0, 0, -1)
local RIGHT = Vector3.new(1, 0, 0)

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Dodge Direction Tests] " .. message, 2)
    end

    assertion_count += 1
end

local function assert_near(
    actual: Vector3,
    expected: Vector3,
    message: string
)
    assert_true(
        (actual - expected).Magnitude < 0.001,
        message
    )
end

local valid_codes = {
    "Forward",
    "Backward",
    "Left",
    "Right",
    "ForwardLeft",
    "ForwardRight",
    "BackwardLeft",
    "BackwardRight",
}

for _, input_code in valid_codes do
    assert_true(
        DodgeDirectionRules.is_valid_input_code(input_code),
        input_code .. " must be accepted."
    )
end

assert_true(
    not DodgeDirectionRules.is_valid_input_code("Teleport"),
    "Unknown dodge input must be rejected."
)
assert_true(
    not DodgeDirectionRules.is_valid_input_code(Vector3.zero),
    "Non-string dodge input must be rejected."
)

assert_near(
    DodgeDirectionRules.resolve("Forward", FORWARD),
    FORWARD,
    "W must dodge forward."
)
assert_near(
    DodgeDirectionRules.resolve("Backward", FORWARD),
    -FORWARD,
    "S must dodge backward."
)
assert_near(
    DodgeDirectionRules.resolve("Left", FORWARD),
    -RIGHT,
    "A must dodge left."
)
assert_near(
    DodgeDirectionRules.resolve("Right", FORWARD),
    RIGHT,
    "D must dodge right."
)
assert_near(
    DodgeDirectionRules.resolve("ForwardLeft", FORWARD),
    (FORWARD - RIGHT).Unit,
    "W+A must dodge forward-left."
)
assert_near(
    DodgeDirectionRules.resolve("ForwardRight", FORWARD),
    (FORWARD + RIGHT).Unit,
    "W+D must dodge forward-right."
)
assert_near(
    DodgeDirectionRules.resolve("BackwardLeft", FORWARD),
    (-FORWARD - RIGHT).Unit,
    "S+A must dodge backward-left."
)
assert_near(
    DodgeDirectionRules.resolve("BackwardRight", FORWARD),
    (-FORWARD + RIGHT).Unit,
    "S+D must dodge backward-right."
)


assert_true(
    DodgeDirectionRules.is_lateral_input_code("Left"),
    "Left must use the lateral slide-dash profile."
)
assert_true(
    DodgeDirectionRules.is_lateral_input_code("Right"),
    "Right must use the lateral slide-dash profile."
)
assert_true(
    not DodgeDirectionRules.is_lateral_input_code("ForwardLeft"),
    "Forward-left must keep the roll profile."
)
assert_true(
    not DodgeDirectionRules.is_lateral_input_code("BackwardRight"),
    "Backward-right must keep the roll profile."
)


assert_true(
    DodgeDirectionRules.should_use_lateral_profile("Left", true),
    "View-Locked A must use the lateral slide-dash profile."
)
assert_true(
    DodgeDirectionRules.should_use_lateral_profile("Right", true),
    "View-Locked D must use the lateral slide-dash profile."
)
assert_true(
    not DodgeDirectionRules.should_use_lateral_profile("Left", false),
    "Unlocked A must rotate into a normal forward roll."
)
assert_true(
    not DodgeDirectionRules.should_use_lateral_profile("Right", false),
    "Unlocked D must rotate into a normal forward roll."
)

local DodgeStyle = DodgeDirectionRules.DodgeStyle

assert_true(
    DodgeDirectionRules.get_dodge_style("Left", false)
        == DodgeStyle.FORWARD_ROLL,
    "Unlocked A must use one stable forward-roll presentation."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("Right", false)
        == DodgeStyle.FORWARD_ROLL,
    "Unlocked D must use one stable forward-roll presentation."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("Backward", false)
        == DodgeStyle.FORWARD_ROLL,
    "Unlocked S must turn into travel and use a forward roll."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("Left", true)
        == DodgeStyle.SIDE_DASH,
    "View-Locked A must use the lateral slide-dash."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("Right", true)
        == DodgeStyle.SIDE_DASH,
    "View-Locked D must use the lateral slide-dash."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("Backward", true)
        == DodgeStyle.BACKWARD_ROLL,
    "View-Locked S must use the backward roll."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("BackwardLeft", true)
        == DodgeStyle.BACKWARD_ROLL,
    "View-Locked S+A must stay in the backward-roll family."
)
assert_true(
    DodgeDirectionRules.get_dodge_style("ForwardRight", true)
        == DodgeStyle.FORWARD_ROLL,
    "View-Locked W+D must stay in the forward-roll family."
)
assert_true(
    DodgeDirectionRules.is_backward_input_code("BackwardRight"),
    "Backward-right must be recognised as a backward input."
)
assert_true(
    not DodgeDirectionRules.is_backward_input_code("Right"),
    "Pure right must not be recognised as a backward input."
)

assert_true(
    DodgeDirectionRules.should_follow_facing_during_dodge(true),
    "View-Locked dodge must keep following live character facing."
)
assert_true(
    not DodgeDirectionRules.should_follow_facing_during_dodge(false),
    "Unlocked roll must turn once and not rewrite facing every frame."
)

local unlocked_right =
    DodgeDirectionRules.sanitize_world_direction(
        Vector3.new(3, 7, 0)
    )
assert_true(
    unlocked_right ~= nil,
    "Valid camera-relative world direction must be accepted."
)
assert_near(
    unlocked_right or Vector3.zero,
    RIGHT,
    "Unlocked direction must discard Y and normalize magnitude."
)
assert_true(
    DodgeDirectionRules.sanitize_world_direction(Vector3.zero) == nil,
    "Zero camera-relative direction must be rejected."
)
assert_true(
    DodgeDirectionRules.sanitize_world_direction("Right") == nil,
    "Non-Vector3 camera-relative direction must be rejected."
)
assert_true(
    DodgeDirectionRules.sanitize_world_direction(
        Vector3.new(1000001, 0, 0)
    ) == nil,
    "Unreasonably large camera-relative direction must be rejected."
)

local turned_facing = Vector3.new(1, 0, 0)
assert_near(
    DodgeDirectionRules.resolve("Forward", turned_facing),
    turned_facing,
    "Forward dodge must follow changed View Lock facing."
)
assert_near(
    DodgeDirectionRules.resolve("Left", turned_facing),
    Vector3.new(0, 0, -1),
    "Left dodge must stay relative to changed View Lock facing."
)

print(
    string.format(
        "[Dodge Direction Tests] PASS: %d assertions.",
        assertion_count
    )
)
