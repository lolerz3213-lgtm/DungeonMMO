local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local shared_folder = combat_folder:WaitForChild("Shared")
local remotes_folder = combat_folder:WaitForChild("Remotes")
local server_combat_folder = ServerScriptService:WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local HotbarConfig = require(
    shared_folder:WaitForChild("HotbarConfig")
)
local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)

local assertion_count = 0


--[[
Raises an error when one Shield Bash integration assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Shield Bash Integration Tests] " .. message, 2)
    end
end


local shield_bash = SkillDefinitions.get("ShieldBash")

assert_true(
    remotes_folder:FindFirstChild(CombatConfig.REMOTES.SKILL_REQUEST)
        ~= nil,
    "SkillRequest RemoteEvent is missing."
)
assert_true(
    server_combat_folder:FindFirstChild("SkillCooldownService") ~= nil,
    "SkillCooldownService is missing."
)
assert_true(
    server_combat_folder:FindFirstChild("StaggerService") ~= nil,
    "StaggerService is missing."
)
assert_true(
    HotbarConfig.get_action_name(1) == "SkillSlot1",
    "Slot 1 must use the logical SkillSlot1 action name."
)
assert_true(
    HotbarConfig.get_default_key(1) == Enum.KeyCode.One,
    "Slot 1 must default to the 1 key."
)
assert_true(
    HotbarConfig.get_skill_for_slot(1) == "ShieldBash",
    "Slot 1 must equip Shield Bash."
)
assert_true(
    shield_bash.STAMINA_COST == 20,
    "Shield Bash Stamina cost is wrong."
)
assert_true(
    shield_bash.COOLDOWN_SECONDS == 4,
    "Shield Bash cooldown is wrong."
)
assert_true(
    shield_bash.WIND_UP_SECONDS == 0.16,
    "Shield Bash wind-up is wrong."
)
assert_true(
    shield_bash.REACH_STUDS == 6.0,
    "Shield Bash reach must be 6 studs."
)
assert_true(
    shield_bash.ARC_DEGREES
        == CombatConfig.DEFENSE.BLOCK_ARC_DEGREES,
    "Shield Bash must use the same frontal cone as blocking."
)
assert_true(
    shield_bash.STAGGER_SECONDS > 0,
    "Shield Bash must define stagger."
)
assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash1.STAMINA_COST == nil,
    "Slash1 must remain free after Shield Bash is added."
)
assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash2.STAMINA_COST == nil,
    "Slash2 must remain free after Shield Bash is added."
)
assert_true(
    CombatConfig.BASIC_ATTACK.ATTACKS.Finisher.STAMINA_COST == nil,
    "Finisher must remain free after Shield Bash is added."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BASH_FORWARD_STUDS
        > CombatConfig.PROTOTYPE_SHIELD.BLOCK_FORWARD_STUDS,
    "Shield Bash presentation must push the shield beyond block pose."
)
assert_true(
    CombatConfig.PROTOTYPE_SHIELD.BASH_HAND_FORWARD_STUDS
        > CombatConfig.PROTOTYPE_SHIELD.BLOCK_HAND_FORWARD_STUDS,
    "Shield Bash IK target must extend the shield arm forward."
)

print(
    string.format(
        "[Shield Bash Integration Tests] PASS: %d assertions.",
        assertion_count
    )
)
