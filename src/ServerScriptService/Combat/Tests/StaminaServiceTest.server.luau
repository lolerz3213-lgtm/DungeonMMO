local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local StaminaService = require(
    combat_folder:WaitForChild("StaminaService")
)

local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Stamina Service Tests] " .. message, 2)
    end

    assertion_count += 1
end

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

local subject = Instance.new("Folder")
subject.Name = "StaminaTestSubject"
subject.Parent = workspace
local fake_player = subject :: any

StaminaService.initialize_player(fake_player)

assert_close(
    StaminaService.get(fake_player),
    100,
    0.001,
    "Initial Stamina is wrong."
)

assert_true(
    StaminaService.try_spend(fake_player, 25),
    "A 25-Stamina dodge-sized spend should succeed."
)
assert_close(
    StaminaService.get(fake_player),
    75,
    0.001,
    "Stamina after a 25 spend is wrong."
)

assert_true(
    StaminaService.try_spend(fake_player, 55),
    "A spend leaving 20 Stamina should succeed."
)
assert_true(
    not StaminaService.try_spend(fake_player, 25),
    "A spend larger than current Stamina must fail."
)
assert_close(
    StaminaService.get(fake_player),
    20,
    0.001,
    "Failed spend must not mutate Stamina."
)

local spent, exhausted = StaminaService.apply_loss(
    fake_player,
    30,
    1.5
)
assert_close(
    spent,
    20,
    0.001,
    "Stamina loss should clamp to the remaining amount."
)
assert_true(
    exhausted,
    "Loss beyond remaining Stamina must report exhaustion."
)
assert_close(
    StaminaService.get(fake_player),
    0,
    0.001,
    "Exhausted Stamina must be zero."
)

StaminaService.reset_player(fake_player)
StaminaService.set_regen_paused(fake_player, true)
assert_true(
    StaminaService.try_spend(fake_player, 25),
    "Paused-regeneration spend should succeed."
)

task.wait(1.15)
assert_close(
    StaminaService.get(fake_player),
    75,
    0.01,
    "Stamina must not regenerate while paused."
)

StaminaService.set_regen_paused(fake_player, false)
task.wait(0.20)
assert_true(
    StaminaService.get(fake_player) > 75,
    "Stamina should regenerate after block is released and delay elapsed."
)

StaminaService.remove_player(fake_player)
subject:Destroy()

print(
    string.format(
        "[Stamina Service Tests] PASS: %d assertions.",
        assertion_count
    )
)
