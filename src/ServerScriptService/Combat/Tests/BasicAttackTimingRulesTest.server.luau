--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local BasicAttackTimingRules = require(
    Shared:WaitForChild(
        "BasicAttackTimingRules"
    )
)

local assertions = 0
local EPSILON = 0.000001

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Basic Attack Timing Rules Tests] "
                .. message,
            2
        )
    end
end

local function approximately(
    actual: number,
    expected: number
): boolean
    return math.abs(
        actual - expected
    ) <= EPSILON
end

local hitbox = {
    SIZE = Vector3.new(4, 5, 6),
    FORWARD_OFFSET = 3,
    SAMPLE_COUNT = 4,
}

local definition = {
    WIND_UP_SECONDS = 0.20,
    ACTIVE_SECONDS = 0.10,
    RECOVERY_SECONDS = 0.30,

    POWER_MULTIPLIER = 1.35,
    FORWARD_STEP_STUDS = 2.5,
    HITBOX = hitbox,

    EXTRA_TEST_VALUE = "Unchanged",
}

-- ------------------------------------------------------------
-- Human 0.95
-- ------------------------------------------------------------

local human =
    BasicAttackTimingRules
        .scale_definition(
            definition,
            0.95
        )

check(
    approximately(
        human.WIND_UP_SECONDS,
        0.20 / 0.95
    ),
    "Human wind-up must be base / 0.95."
)

check(
    approximately(
        human.ACTIVE_SECONDS,
        0.10 / 0.95
    ),
    "Human Active duration must be base / 0.95."
)

check(
    approximately(
        human.RECOVERY_SECONDS,
        0.30 / 0.95
    ),
    "Human recovery must be base / 0.95."
)

-- ------------------------------------------------------------
-- Elf 1.08
-- ------------------------------------------------------------

local elf =
    BasicAttackTimingRules
        .scale_definition(
            definition,
            1.08
        )

check(
    approximately(
        elf.WIND_UP_SECONDS,
        0.20 / 1.08
    ),
    "Elf wind-up must be base / 1.08."
)

check(
    approximately(
        elf.ACTIVE_SECONDS,
        0.10 / 1.08
    ),
    "Elf Active duration must be base / 1.08."
)

check(
    approximately(
        elf.RECOVERY_SECONDS,
        0.30 / 1.08
    ),
    "Elf recovery must be base / 1.08."
)

-- ------------------------------------------------------------
-- Non-timing fields remain untouched
-- ------------------------------------------------------------

check(
    human.POWER_MULTIPLIER
        == definition.POWER_MULTIPLIER,
    "power multiplier must not be scaled."
)

check(
    human.FORWARD_STEP_STUDS
        == definition.FORWARD_STEP_STUDS,
    "forward-step distance must not be scaled."
)

check(
    human.HITBOX == hitbox,
    "hitbox definition must remain unchanged."
)

check(
    human.EXTRA_TEST_VALUE
        == "Unchanged",
    "unrelated fields must remain unchanged."
)

check(
    human ~= definition,
    "scaled definition must be a new table."
)

check(
    approximately(
        definition.WIND_UP_SECONDS,
        0.20
    )
        and approximately(
            definition.ACTIVE_SECONDS,
            0.10
        )
        and approximately(
            definition.RECOVERY_SECONDS,
            0.30
        ),
    "source definition must not be mutated."
)

-- ------------------------------------------------------------
-- Safe-rate fallbacks
-- ------------------------------------------------------------

for _, invalid in ipairs({
    0,
    -1,
    math.huge,
    -math.huge,
    0 / 0,
}) do
    check(
        BasicAttackTimingRules
            .get_safe_rate(invalid)
            == 1,
        "invalid rate must safely fall back to 1."
    )

    local fallback =
        BasicAttackTimingRules
            .scale_definition(
                definition,
                invalid
            )

    check(
        approximately(
            fallback.WIND_UP_SECONDS,
            0.20
        )
            and approximately(
                fallback.ACTIVE_SECONDS,
                0.10
            )
            and approximately(
                fallback.RECOVERY_SECONDS,
                0.30
            ),
        "invalid rate must preserve base timing."
    )
end

check(
    BasicAttackTimingRules
        .get_safe_rate(nil)
        == 1,
    "missing rate must fall back to 1."
)

check(
    BasicAttackTimingRules
        .get_safe_rate("1.08")
        == 1,
    "non-number rate must fall back to 1."
)

check(
    BasicAttackTimingRules
        .get_safe_rate(1.08)
        == 1.08,
    "valid positive rate must be preserved."
)

print(
    string.format(
        "[Basic Attack Timing Rules Tests] PASS: %d assertions.",
        assertions
    )
)