--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CriticalHitRules = require(
    Shared:WaitForChild(
        "CriticalHitRules"
    )
)

local assertions = 0

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Critical Hit Rules Tests] "
                .. message,
            2
        )
    end
end

local crit =
    CriticalHitRules.resolve(
        0.105,
        1.5,
        0.10
    )

check(
    crit.is_critical == true,
    "10% roll under 10.5% must crit."
)

check(
    crit.multiplier == 1.5,
    "critical result must use supplied crit multiplier."
)

local miss =
    CriticalHitRules.resolve(
        0.105,
        1.5,
        0.11
    )

check(
    miss.is_critical == false,
    "11% roll above 10.5% must not crit."
)

check(
    miss.multiplier == 1,
    "non-critical result must use multiplier 1."
)

local equal =
    CriticalHitRules.resolve(
        0.105,
        1.5,
        0.105
    )

check(
    equal.is_critical == false,
    "roll exactly equal to chance must be non-critical."
)

local negative =
    CriticalHitRules.resolve(
        -10,
        1.5,
        0
    )

check(
    negative.is_critical == false,
    "negative critical chance must clamp to zero."
)

local over_one =
    CriticalHitRules.resolve(
        10,
        1.5,
        0.999
    )

check(
    over_one.is_critical == true,
    "critical chance above one must clamp to one."
)

check(
    over_one.multiplier == 1.5,
    "clamped guaranteed crit must preserve crit multiplier."
)

local invalid_multiplier =
    CriticalHitRules.resolve(
        1,
        -5,
        0
    )

check(
    invalid_multiplier.is_critical == true
        and invalid_multiplier.multiplier
            == 1,
    "invalid critical multiplier must fail safely to 1."
)

local invalid_roll =
    CriticalHitRules.resolve(
        0.5,
        1.5,
        0 / 0
    )

check(
    invalid_roll.is_critical == false,
    "non-finite roll must fail closed."
)

print(
    string.format(
        "[Critical Hit Rules Tests] PASS: %d assertions.",
        assertions
    )
)