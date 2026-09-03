local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)
local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local combat_folder = ServerScriptService
    :WaitForChild("Combat")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local module_script = combat_folder:FindFirstChild(
    "DamageService"
)

if not module_script then
    error(
        "[Damage Service Tests] RED: "
            .. "DamageService module is missing."
    )
end

local DamageService = require(module_script)

local assertion_count = 0
local EPSILON = 1e-6


--[[
Raises an error when a damage-service assertion fails.

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
            "[Damage Service Tests] " .. message
        )
    end
end


--[[
Checks two numbers using a small floating-point tolerance.

Args:
    actual (number): Value returned by production code.
    expected (number): Required value.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_number(
    actual: number,
    expected: number,
    message: string
)
    assert_true(
        math.abs(actual - expected) <= EPSILON,
        string.format(
            "%s Expected %.3f, got %.3f.",
            message,
            expected,
            actual
        )
    )
end


--[[
Creates a simple damageable target with a Humanoid.

Args:
    name (string): Model name.
    health (number): Initial and maximum health.

Returns:
    Model: Test target Model.
]]
local function create_target(
    name: string,
    health: number
): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace

    local humanoid = Instance.new("Humanoid")

    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.Parent = model

    return model
end


assert_true(
    CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE ~= nil,
    "Prototype weapon must define BASE_DAMAGE."
)

assert_number(
    DamageService.calculate_damage(
        10,
        1.00
    ),
    10,
    "Slash1 prototype damage is wrong."
)

assert_number(
    DamageService.calculate_damage(
        10,
        1.05
    ),
    10.5,
    "Slash2 prototype damage is wrong."
)

assert_number(
    DamageService.calculate_damage(
        10,
        1.35
    ),
    13.5,
    "Finisher prototype damage is wrong."
)

assert_number(
    DamageService.calculate_damage(
        -10,
        1
    ),
    0,
    "Negative base damage must clamp to zero."
)

assert_number(
    DamageService.calculate_damage(
        10,
        -2
    ),
    0,
    "Negative multiplier must clamp final damage to zero."
)

local target = create_target(
    "DamageServiceTarget",
    100
)

local applied = DamageService.apply_damage({
    attacker = nil,
    attacker_character = nil,
    target = target,
    source_kind = "Melee",
    source_id = "PrototypeSword",
    attack_id = "Slash2",
    base_damage = 10,
    multiplier = 1.05,
})

local humanoid =
    target:FindFirstChildOfClass("Humanoid")

assert_number(
    applied,
    10.5,
    "apply_damage must return exact applied damage."
)

assert_true(
    humanoid ~= nil,
    "Test target Humanoid must exist."
)

if humanoid then
    assert_number(
        humanoid.Health,
        89.5,
        "Humanoid health must preserve decimal damage."
    )
end

local dead_target = create_target(
    "DamageServiceDeadTarget",
    100
)
local dead_humanoid =
    dead_target:FindFirstChildOfClass("Humanoid")

if dead_humanoid then
    dead_humanoid.Health = 0
end

local dead_damage =
    DamageService.apply_damage({
        attacker = nil,
        attacker_character = nil,
        target = dead_target,
        source_kind = "AreaEffect",
        source_id = "FutureFireball",
        attack_id = nil,
        base_damage = 50,
        multiplier = 2,
    })

assert_number(
    dead_damage,
    0,
    "Dead target must not receive further damage."
)

target:Destroy()
dead_target:Destroy()

print(
    string.format(
        "[Damage Service Tests] PASS: %d assertions.",
        assertion_count
    )
)
