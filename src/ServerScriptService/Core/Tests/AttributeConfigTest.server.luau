--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local AttributeConfig = require(
    Shared:WaitForChild("AttributeConfig")
)

local assertions = 0

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Attribute Config Tests] "
                .. message,
            2
        )
    end
end

check(
    AttributeConfig.BASE_VALUE == 5,
    "neutral base value must remain 5."
)

check(
    AttributeConfig
        .signed_effective_delta(5)
        == 0,
    "5 must have zero signed effective delta."
)

check(
    AttributeConfig
        .signed_effective_delta(4)
        < 0,
    "4 must produce a negative effective delta."
)

check(
    AttributeConfig
        .signed_effective_delta(6)
        > 0,
    "6 must produce a positive effective delta."
)

check(
    AttributeConfig.physical_multiplier(4)
        < 1,
    "Strength 4 must apply a physical penalty."
)

check(
    AttributeConfig.physical_multiplier(5)
        == 1,
    "Strength 5 must remain neutral."
)

check(
    AttributeConfig.physical_multiplier(6)
        > 1,
    "Strength 6 must increase physical damage."
)

check(
    AttributeConfig.heal_multiplier(4)
        < 1,
    "Spirit 4 must apply a healing penalty."
)

check(
    AttributeConfig.heal_multiplier(5)
        == 1,
    "Spirit 5 must remain neutral."
)

check(
    AttributeConfig.heal_multiplier(6)
        > 1,
    "Spirit 6 must increase healing."
)

check(
    AttributeConfig.max_health(4)
        < 100,
    "Vitality 4 must reduce base max health."
)

check(
    AttributeConfig.max_health(5)
        == 100,
    "Vitality 5 must yield 100 base health."
)

check(
    AttributeConfig.max_health(6)
        > 100,
    "Vitality 6 must increase base max health."
)

local diminished =
    AttributeConfig.effective_investment(
        20
    )

check(
    diminished > 15
        and diminished < 20,
    "soft cap must still diminish investment above 15."
)

print(
    string.format(
        "[Attribute Config Tests] PASS: %d assertions.",
        assertions
    )
)