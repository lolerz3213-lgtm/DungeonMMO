local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local module_script = combat_folder:FindFirstChild("SkillCooldownService")

if not module_script then
    error(
        "[Skill Cooldown Tests] RED: "
            .. "SkillCooldownService is missing."
    )
end

local SkillCooldownService = require(module_script)

local assertion_count = 0


--[[
Raises an error when one cooldown assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Skill Cooldown Tests] " .. message, 2)
    end
end


--[[
Checks a numeric cooldown result with a small tolerance.

Args:
    actual (number): Actual result.
    expected (number): Required result.
    tolerance (number): Maximum accepted absolute difference.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_close(
    actual: number,
    expected: number,
    tolerance: number,
    message: string
)
    assert_true(
        math.abs(actual - expected) <= tolerance,
        string.format(
            "%s Expected %.3f, received %.3f.",
            message,
            expected,
            actual
        )
    )
end


local owner = Instance.new("Folder")
owner.Name = "SkillCooldownTestOwner"
owner.Parent = workspace

assert_true(
    SkillCooldownService.is_ready(owner, "ShieldBash", 10),
    "A fresh skill must be ready."
)

local expiry = SkillCooldownService.start(
    owner,
    "ShieldBash",
    4,
    10
)

assert_close(expiry, 14, 0.001, "Cooldown expiry is wrong.")
assert_true(
    not SkillCooldownService.is_ready(owner, "ShieldBash", 12),
    "Skill must remain unavailable during cooldown."
)
assert_close(
    SkillCooldownService.get_remaining(owner, "ShieldBash", 12),
    2,
    0.001,
    "Remaining cooldown is wrong."
)
assert_true(
    SkillCooldownService.is_ready(owner, "ShieldBash", 14),
    "Skill must become ready at exact cooldown expiry."
)
assert_close(
    SkillCooldownService.get_remaining(owner, "ShieldBash", 15),
    0,
    0.001,
    "Expired cooldown must report zero remaining."
)

SkillCooldownService.start(owner, "ShieldBash", 4, 20)
SkillCooldownService.start(owner, "OtherSkill", 1, 20)
assert_true(
    SkillCooldownService.is_ready(owner, "OtherSkill", 21),
    "One skill cooldown must not affect another skill id."
)
assert_true(
    not SkillCooldownService.is_ready(owner, "ShieldBash", 21),
    "Shield Bash cooldown must remain independent."
)

SkillCooldownService.remove_owner(owner)
assert_true(
    SkillCooldownService.is_ready(owner, "ShieldBash", 21),
    "Removing an owner must clear stale cooldown state."
)

owner:Destroy()

print(
    string.format(
        "[Skill Cooldown Tests] PASS: %d assertions.",
        assertion_count
    )
)
