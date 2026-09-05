local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local shared_folder = combat_folder:WaitForChild("Shared")
local remotes_folder = combat_folder:WaitForChild("Remotes")
local server_combat_folder = ServerScriptService:WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local StateRules = require(
    shared_folder:WaitForChild("StateRules")
)

local State = CombatTypes.State
local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Defensive Combat Integration Tests] " .. message, 2)
    end

    assertion_count += 1
end

assert_true(State.BLOCKING == "Blocking", "Blocking state is missing.")
assert_true(State.DODGING == "Dodging", "Dodging state is missing.")
assert_true(State.GUARD_BREAK == "GuardBreak", "GuardBreak state is missing.")

assert_true(
    CombatConfig.STAMINA.MAX == 100,
    "Maximum Stamina must be 100."
)
assert_true(
    CombatConfig.STAMINA.DODGE_COST == 25,
    "Dodge must cost 25 Stamina."
)
assert_true(
    CombatConfig.STAMINA.REGEN_DELAY_SECONDS == 1.0,
    "Normal Stamina regen delay must be 1 second."
)
assert_true(
    CombatConfig.STAMINA.REGEN_PER_SECOND == 25,
    "Stamina regeneration must be 25 per second."
)
assert_true(
    CombatConfig.DEFENSE.BLOCK_ARC_DEGREES == 120,
    "Block cone must be 120 degrees."
)
assert_true(
    CombatConfig.DEFENSE.PARRY_WINDOW_SECONDS == 0.18,
    "Parry window must be 0.18 seconds."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_IFRAME_SECONDS == 0.22,
    "Dodge i-frames must last 0.22 seconds."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_DISTANCE_STUDS == 12,
    "Steerable roll must travel about 12 studs."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_DURATION_SECONDS == 0.55,
    "Dodge movement and roll animation must end together at 0.55s."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_START_SPEED_MULTIPLIER == 1.35,
    "Dodge must start with a strong forward speed burst."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_END_SPEED_MULTIPLIER == 0.65,
    "Dodge must ease down instead of stopping before the roll ends."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_MOVE_SECONDS == nil,
    "Dodge must no longer use a shorter movement-only window."
)
assert_true(
    CombatConfig.VIEW_LOCK.TOGGLE_KEY == Enum.KeyCode.LeftControl,
    "View Lock must use Left Ctrl."
)
assert_true(
    CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE == "CombatViewLocked",
    "View Lock must expose a local state attribute for dodge intent."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_KEY == Enum.KeyCode.LeftShift,
    "Dodge must use Left Shift."
)

assert_true(
    CombatConfig.DEFENSE.UNLOCKED_DODGE_TURN_SECONDS == 0.075,
    "Unlocked dodge turn-in must finish in 0.075 seconds."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_STYLE_ATTRIBUTE
        == "CombatDodgeStyle",
    "Dodge style must be replicated as a server-owned attribute."
)
assert_true(
    CombatConfig.DEFENSE.DODGE_VIEW_LOCKED_ATTRIBUTE
        == "CombatDodgeViewLocked",
    "Dodge View Lock mode must be latched for presentation."
)

assert_true(
    StateRules.can_transition(State.LOCOMOTION, State.BLOCKING),
    "Locomotion must allow Blocking."
)
assert_true(
    StateRules.can_transition(State.BLOCKING, State.LOCOMOTION),
    "Blocking must allow Locomotion."
)
assert_true(
    StateRules.can_transition(State.LOCOMOTION, State.DODGING),
    "Locomotion must allow Dodging."
)
assert_true(
    StateRules.can_transition(State.DODGING, State.LOCOMOTION),
    "Dodging must allow Locomotion."
)
assert_true(
    StateRules.can_transition(State.BLOCKING, State.GUARD_BREAK),
    "Blocking must allow GuardBreak."
)
assert_true(
    not StateRules.can_transition(State.BLOCKING, State.WIND_UP),
    "Blocking must not start a basic attack."
)

assert_true(
    remotes_folder:FindFirstChild(
        CombatConfig.REMOTES.DEFENSE_REQUEST
    ) ~= nil,
    "DefenseRequest RemoteEvent is missing."
)
assert_true(
    server_combat_folder:FindFirstChild("StaminaService") ~= nil,
    "StaminaService is missing."
)
assert_true(
    server_combat_folder:FindFirstChild("DefenseService") ~= nil,
    "DefenseService is missing."
)

assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash1.STAMINA_COST == nil,
    "Basic Slash1 must remain free."
)
assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash2.STAMINA_COST == nil,
    "Basic Slash2 must remain free."
)
assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Finisher.STAMINA_COST == nil,
    "Basic Finisher must remain free."
)

local deadline = os.clock() + 2
local marauder = workspace:FindFirstChild("TrainingMarauder")
while not marauder and os.clock() < deadline do
    task.wait(0.05)
    marauder = workspace:FindFirstChild("TrainingMarauder")
end

assert_true(marauder ~= nil, "TrainingMarauder runtime model is missing.")

assert_true(
    CombatConfig.PROTOTYPE_SHIELD.ATTACH_PART_NAME
        == "HumanoidRootPart",
    "Shield presentation grip must remain root-owned."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BLOCK_REFERENCE_PART_NAME
        == "UpperTorso",
    "Shield-arm IK must use UpperTorso-relative targets."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.WALK_SHIELD_EXTRA_BOB_STUDS > 0,
    "Walking shield bob must be configured."
)
assert_true(
    CombatConfig.DEFENSE.SIDE_DASH_DISTANCE_STUDS == 8,
    "Lateral slide-dash must travel 8 studs."
)
assert_true(
    CombatConfig.DEFENSE.SIDE_DASH_DURATION_SECONDS == 0.30,
    "Lateral slide-dash must finish in 0.30 seconds."
)
assert_true(
    CombatConfig.DEFENSE.SIDE_DASH_START_SPEED_MULTIPLIER == 1.55,
    "Lateral slide-dash must start with an explosive burst."
)
assert_true(
    CombatConfig.DEFENSE.SIDE_DASH_END_SPEED_MULTIPLIER == 0.45,
    "Lateral slide-dash must ease into its recovery."
)
assert_true(
    server_combat_folder:FindFirstChild("DodgeDirectionRules") ~= nil,
    "DodgeDirectionRules is missing."
)

print(
    string.format(
        "[Defensive Combat Integration Tests] PASS: %d assertions.",
        assertion_count
    )
)
