--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local CharacterCombatStats = require(
    Shared:WaitForChild(
        "CharacterCombatStats"
    )
)

local ProgressionRuntimeState = require(
    Services:WaitForChild(
        "ProgressionRuntimeState"
    )
)

local assertions = 0

local EPSILON = 0.00001

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Character Combat Stats Tests] "
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

local human_attributes = {
    Strength = 5,
    Dexterity = 4,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

local elf_attributes = {
    Strength = 5,
    Dexterity = 6,
    Vitality = 4,
    Intellect = 5,
    Spirit = 5,
}

-- ------------------------------------------------------------
-- Pure Human stats
-- ------------------------------------------------------------

check(
    approximately(
        CharacterCombatStats
            .critical_chance(
                human_attributes,
                "Human"
            ),
        0.045
    ),
    "Level-1 Human crit chance must be 4.5%."
)

check(
    approximately(
        CharacterCombatStats
            .critical_damage_multiplier(
                "Human"
            ),
        1.65
    ),
    "Level-1 Human crit damage must be 1.65x."
)

check(
    approximately(
        CharacterCombatStats
            .max_health(
                human_attributes,
                "Human"
            ),
        113.4
    ),
    "Level-1 Human MaxHealth must be 113.4."
)

check(
    approximately(
        CharacterCombatStats
            .basic_attack_rate(
                "Human"
            ),
        0.95
    ),
    "Human basic attack rate must be 0.95."
)

-- ------------------------------------------------------------
-- Pure Elf stats
-- ------------------------------------------------------------

check(
    approximately(
        CharacterCombatStats
            .critical_chance(
                elf_attributes,
                "Elf"
            ),
        0.105
    ),
    "Level-1 Elf crit chance must be 10.5%."
)

check(
    approximately(
        CharacterCombatStats
            .critical_damage_multiplier(
                "Elf"
            ),
        1.50
    ),
    "Level-1 Elf crit damage must remain 1.50x."
)

check(
    approximately(
        CharacterCombatStats
            .max_health(
                elf_attributes,
                "Elf"
            ),
        87.4
    ),
    "Level-1 Elf MaxHealth must be 87.4."
)

check(
    approximately(
        CharacterCombatStats
            .basic_attack_rate(
                "Elf"
            ),
        1.08
    ),
    "Elf basic attack rate must be 1.08."
)

-- ------------------------------------------------------------
-- Neutral fallback
-- ------------------------------------------------------------

local neutral_attributes = {
    Strength = 5,
    Dexterity = 5,
    Vitality = 5,
    Intellect = 5,
    Spirit = 5,
}

check(
    approximately(
        CharacterCombatStats
            .critical_chance(
                neutral_attributes,
                nil
            ),
        0.05
    ),
    "missing race must retain base 5% crit."
)

check(
    approximately(
        CharacterCombatStats
            .critical_damage_multiplier(
                nil
            ),
        1.50
    ),
    "missing race must retain base crit damage."
)

check(
    approximately(
        CharacterCombatStats
            .max_health(
                neutral_attributes,
                nil
            ),
        100
    ),
    "missing race must retain neutral MaxHealth."
)

check(
    approximately(
        CharacterCombatStats
            .basic_attack_rate(
                nil
            ),
        1
    ),
    "missing race must use attack-rate fallback 1."
)

-- ------------------------------------------------------------
-- Crit chance safety clamp
-- ------------------------------------------------------------

check(
    CharacterCombatStats
        .critical_chance(
            {
                Dexterity = -1000,
                Vitality = 5,
            },
            nil
        )
        == 0,
    "critical chance must clamp to zero."
)

check(
    CharacterCombatStats
        .critical_chance(
            {
                Dexterity = 1000,
                Vitality = 5,
            },
            "Elf"
        )
        == 1,
    "critical chance must clamp to one."
)

-- ------------------------------------------------------------
-- Runtime state retains Identity + Progression internally
-- while preserving the old public progression snapshot shape.
-- ------------------------------------------------------------

local human_user_id = 9801

ProgressionRuntimeState.set_character(
    human_user_id,
    {
        Identity = {
            Version = 1,
            RaceId = "Human",
            BaseClassId = "Fighter",
            ClassId = "Fighter",
            CreationStage = "Complete",
        },

        Progression = {
            Attributes = human_attributes,

            Skills = {
                ShieldBash = {
                    Known = true,
                    StarterGranted = true,
                    PurchasedRank = 1,
                    Proficiency = 0,
                },
            },

            Loadout = {
                [1] = "ShieldBash",
            },
        },
    }
)

check(
    ProgressionRuntimeState
        .get_race_id(
            human_user_id
        )
        == "Human",
    "runtime state must retain Human RaceId."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_critical_chance(
                human_user_id
            ),
        0.045
    ),
    "runtime Human crit chance must match pure derivation."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_critical_damage_multiplier(
                human_user_id
            ),
        1.65
    ),
    "runtime Human crit damage must match pure derivation."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_max_health(
                human_user_id
            ),
        113.4
    ),
    "runtime Human MaxHealth must match pure derivation."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_basic_attack_rate(
                human_user_id
            ),
        0.95
    ),
    "runtime Human attack rate must match pure derivation."
)

local human_snapshot =
    ProgressionRuntimeState
        .get_snapshot(
            human_user_id
        )

check(
    human_snapshot.Attributes.Dexterity
        == 4
        and human_snapshot.Identity
            == nil,
    "existing get_snapshot contract must remain Progression-shaped."
)

check(
    ProgressionRuntimeState
        .get_skill_rank(
            human_user_id,
            "ShieldBash"
        )
        == 1,
    "existing skill-rank runtime consumer must remain compatible."
)

check(
    ProgressionRuntimeState
        .is_skill_equipped(
            human_user_id,
            "ShieldBash"
        )
        == true,
    "existing loadout runtime consumer must remain compatible."
)

-- ------------------------------------------------------------
-- Legacy progression-only set_character compatibility
-- ------------------------------------------------------------

local legacy_user_id = 9802

ProgressionRuntimeState.set_character(
    legacy_user_id,
    {
        Attributes = {
            Strength = 6,
            Dexterity = 5,
            Vitality = 6,
            Intellect = 5,
            Spirit = 5,
        },

        Skills = {},
        Loadout = {},
    }
)

check(
    ProgressionRuntimeState
        .get_race_id(
            legacy_user_id
        )
        == nil,
    "progression-only runtime input must use neutral race fallback."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_max_health(
                legacy_user_id
            ),
        105
    ),
    "progression-only input must preserve attribute health without racial multiplier."
)

check(
    approximately(
        ProgressionRuntimeState
            .get_basic_attack_rate(
                legacy_user_id
            ),
        1
    ),
    "progression-only runtime input must use neutral attack rate."
)

-- ------------------------------------------------------------
-- apply_runtime_stats: Human
-- ------------------------------------------------------------

local human_model =
    Instance.new("Model")

human_model.Name =
    "Task8HumanRuntimeCharacter"

local human_humanoid =
    Instance.new("Humanoid")

human_humanoid.MaxHealth = 100
human_humanoid.Health = 100
human_humanoid.Parent = human_model

local fake_human_attributes: {[string]: any} = {}
local fake_human_player: any = {
    UserId = human_user_id,
    Character = human_model,
    SetAttribute = function(_self: any, key: string, value: any)
        fake_human_attributes[key] = value
    end,
    GetAttribute = function(_self: any, key: string): any
        return fake_human_attributes[key]
    end,
}

ProgressionRuntimeState
    .apply_runtime_stats(
        fake_human_player
    )

check(
    approximately(
        human_humanoid.MaxHealth,
        113.4
    ),
    "apply_runtime_stats must apply Human MaxHealth."
)

check(
    approximately(
        human_humanoid.Health,
        113.4
    ),
    "full-health Human must remain full after MaxHealth increase."
)

check(
    approximately(
        human_model:GetAttribute(
            "DungeonMMOBasicAttackRate"
        ),
        0.95
    ),
    "Human attack rate must replicate as character attribute."
)

human_humanoid.MaxHealth = 100
human_humanoid.Health = 50

ProgressionRuntimeState
    .apply_runtime_stats(
        fake_human_player
    )

check(
    approximately(
        human_humanoid.MaxHealth,
        113.4
    )
        and approximately(
            human_humanoid.Health,
            50
        ),
    "wounded health amount must be preserved when MaxHealth increases."
)

-- ------------------------------------------------------------
-- apply_runtime_stats: Elf
-- ------------------------------------------------------------

local elf_user_id = 9803

ProgressionRuntimeState.set_character(
    elf_user_id,
    {
        Identity = {
            Version = 1,
            RaceId = "Elf",
            BaseClassId = "Fighter",
            ClassId = "Fighter",
            CreationStage = "Complete",
        },

        Progression = {
            Attributes = elf_attributes,
            Skills = {},
            Loadout = {},
        },
    }
)

local elf_model =
    Instance.new("Model")

elf_model.Name =
    "Task8ElfRuntimeCharacter"

local elf_humanoid =
    Instance.new("Humanoid")

elf_humanoid.MaxHealth = 100
elf_humanoid.Health = 100
elf_humanoid.Parent = elf_model

local fake_elf_attributes: {[string]: any} = {}
local fake_elf_player: any = {
    UserId = elf_user_id,
    Character = elf_model,
    SetAttribute = function(_self: any, key: string, value: any)
        fake_elf_attributes[key] = value
    end,
    GetAttribute = function(_self: any, key: string): any
        return fake_elf_attributes[key]
    end,
}

ProgressionRuntimeState
    .apply_runtime_stats(
        fake_elf_player
    )

check(
    approximately(
        elf_humanoid.MaxHealth,
        87.4
    ),
    "apply_runtime_stats must apply Elf MaxHealth."
)

check(
    approximately(
        elf_humanoid.Health,
        87.4
    ),
    "full-health Elf must clamp to new lower MaxHealth."
)

check(
    approximately(
        elf_model:GetAttribute(
            "DungeonMMOBasicAttackRate"
        ),
        1.08
    ),
    "Elf attack rate must replicate as character attribute."
)

human_model:Destroy()
elf_model:Destroy()

ProgressionRuntimeState.clear_character(
    human_user_id
)

ProgressionRuntimeState.clear_character(
    legacy_user_id
)

ProgressionRuntimeState.clear_character(
    elf_user_id
)

print(
    string.format(
        "[Character Combat Stats Tests] PASS: %d assertions.",
        assertions
    )
)