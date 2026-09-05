local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local module_script = combat_folder:FindFirstChild("StaggerService")

if not module_script then
    error("[Stagger Service Tests] RED: StaggerService is missing.")
end

local StaggerService = require(module_script)

local assertion_count = 0


--[[
Raises an error when one stagger assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Stagger Service Tests] " .. message, 2)
    end
end


--[[
Checks a numeric stagger result with a small tolerance.

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


local target = Instance.new("Model")
target.Name = "StaggerTestTarget"
target.Parent = workspace

local expiry = StaggerService.apply(target, 1.0, 10)

assert_close(expiry, 11, 0.001, "First stagger expiry is wrong.")
assert_true(
    StaggerService.is_staggered(target, 10.5),
    "Target must report staggered before expiry."
)
assert_close(
    StaggerService.get_remaining(target, 10.5),
    0.5,
    0.001,
    "Remaining stagger is wrong."
)
assert_close(
    target:GetAttribute("CombatStaggeredUntil"),
    11,
    0.001,
    "Stagger expiry attribute is wrong."
)

StaggerService.apply(target, 0.25, 10.2)
assert_close(
    StaggerService.get_remaining(target, 10.2),
    0.8,
    0.001,
    "A shorter stagger must not reduce remaining duration."
)

StaggerService.apply(target, 1.0, 10.5)
assert_close(
    StaggerService.get_remaining(target, 10.5),
    1.0,
    0.001,
    "A longer stagger must refresh to the greater expiry."
)
assert_true(
    not StaggerService.is_staggered(target, 11.5),
    "Target must stop being staggered at expiry."
)

StaggerService.clear(target)
assert_close(
    target:GetAttribute("CombatStaggeredUntil") or 0,
    0,
    0.001,
    "Clear must reset the replicated stagger attribute."
)

target:Destroy()

print(
    string.format(
        "[Stagger Service Tests] PASS: %d assertions.",
        assertion_count
    )
)
