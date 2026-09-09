--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local combat_folder =
    ServerScriptService
        :WaitForChild("Combat")

local shared_folder =
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild(
        "CombatConfig"
    )
)

local DamageService = require(
    combat_folder:WaitForChild(
        "DamageService"
    )
)

local assertion_count = 0

local EPSILON = 1e-6

local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Damage Service Tests] "
                .. message,
            2
        )
    end
end

local function assert_number(
    actual: number,
    expected: number,
    message: string
)
    assert_true(
        math.abs(
            actual - expected
        ) <= EPSILON,
        string.format(
            "%s Expected %.3f, got %.3f.",
            message,
            expected,
            actual
        )
    )
end

local function create_target(
    name: string,
    health: number
): Model
    local model =
        Instance.new("Model")

    model.Name = name
    model.Parent = workspace

    local humanoid =
        Instance.new("Humanoid")

    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.Parent = model

    return model
end

-- ------------------------------------------------------------
-- Accepted existing damage contract
-- ------------------------------------------------------------

assert_true(
    CombatConfig
        .PROTOTYPE_WEAPON
        .BASE_DAMAGE
        ~= nil,
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

local target =
    create_target(
        "DamageServiceTarget",
        100
    )

local applied =
    DamageService.apply_damage({
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
    target:FindFirstChildOfClass(
        "Humanoid"
    )

assert_number(
    applied,
    10.5,
    "old context without crit fields must preserve exact damage."
)

assert_true(
    humanoid ~= nil,
    "Test target Humanoid must exist."
)

if humanoid then
    assert_number(
        humanoid.Health,
        89.5,
        "old context must preserve decimal Humanoid damage."
    )
end

-- ------------------------------------------------------------
-- Deterministic critical damage
-- ------------------------------------------------------------

local critical_target =
    create_target(
        "DamageServiceCriticalTarget",
        100
    )

local critical_damage =
    DamageService.apply_damage({
        attacker = nil,
        attacker_character = nil,
        target = critical_target,
        source_kind = "Melee",
        source_id = "PrototypeSword",
        attack_id = "Slash1",
        base_damage = 10,
        multiplier = 1,
        critical_chance = 1,
        critical_damage_multiplier = 1.65,
        critical_roll = 0,
    })

assert_number(
    critical_damage,
    16.5,
    "guaranteed 1.65x critical hit must deal 16.5."
)

local critical_humanoid =
    critical_target
        :FindFirstChildOfClass(
            "Humanoid"
        )

assert_true(
    critical_humanoid ~= nil,
    "Critical target Humanoid must exist."
)

if critical_humanoid then
    assert_number(
        critical_humanoid.Health,
        83.5,
        "critical damage must be applied to Humanoid."
    )
end

local noncritical_target =
    create_target(
        "DamageServiceNonCriticalTarget",
        100
    )

local noncritical_damage =
    DamageService.apply_damage({
        attacker = nil,
        attacker_character = nil,
        target = noncritical_target,
        source_kind = "Melee",
        source_id = "PrototypeSword",
        attack_id = "Slash1",
        base_damage = 10,
        multiplier = 1,
        critical_chance = 0,
        critical_damage_multiplier = 1.65,
        critical_roll = 0,
    })

assert_number(
    noncritical_damage,
    10,
    "zero critical chance must preserve normal damage."
)

local missing_multiplier_target =
    create_target(
        "DamageServiceMissingCritMultiplierTarget",
        100
    )

local missing_multiplier_damage =
    DamageService.apply_damage({
        attacker = nil,
        attacker_character = nil,
        target =
            missing_multiplier_target,
        source_kind = "Melee",
        source_id = "PrototypeSword",
        attack_id = "Slash1",
        base_damage = 10,
        multiplier = 1,
        critical_chance = 1,
        critical_roll = 0,
    })

assert_number(
    missing_multiplier_damage,
    10,
    "partial crit context must fail safely to old damage behaviour."
)

-- ------------------------------------------------------------
-- Dead-target regression
-- ------------------------------------------------------------

local dead_target =
    create_target(
        "DamageServiceDeadTarget",
        100
    )

local dead_humanoid =
    dead_target
        :FindFirstChildOfClass(
            "Humanoid"
        )

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
critical_target:Destroy()
noncritical_target:Destroy()
missing_multiplier_target:Destroy()
dead_target:Destroy()

print(
    string.format(
        "[Damage Service Tests] PASS: %d assertions.",
        assertion_count
    )
)