local ReplicatedStorage = game:GetService("ReplicatedStorage")

local core = ReplicatedStorage:FindFirstChild("Core")

assert(
    core,
    "[Phase 2C.A Race Definitions] Core missing"
)

local shared = core:FindFirstChild("Shared")

assert(
    shared,
    "[Phase 2C.A Race Definitions] Shared missing"
)

local RaceDefinitions = require(
    shared:WaitForChild("RaceDefinitions")
)

local CharacterIdentityRules = require(
    shared:WaitForChild("CharacterIdentityRules")
)

local ClassDefinitions = require(
    shared:WaitForChild("ClassProgressionDefinitions")
)

local assertion_count = 0

--[[
Checks one Task 1 contract.

Args:
    condition (boolean): Whether the contract is satisfied.
    message (string): Assertion failure message.

Returns:
    nil
]]
local function check(
    condition: boolean,
    message: string
)
    assertion_count += 1
    assert(condition, message)
end

local human = assert(
    RaceDefinitions.get("Human"),
    "Human definition missing"
)

local elf = assert(
    RaceDefinitions.get("Elf"),
    "Elf definition missing"
)

check(
    human.BaseAttributes.Strength == 5,
    "Human STR"
)
check(
    human.BaseAttributes.Dexterity == 4,
    "Human DEX"
)
check(
    human.BaseAttributes.Vitality == 6,
    "Human VIT"
)
check(
    human.BaseAttributes.Intellect == 5,
    "Human INT"
)
check(
    human.BaseAttributes.Spirit == 5,
    "Human SPI"
)
check(
    human.Passive.MaxHealthMultiplier == 1.08,
    "Human health"
)
check(
    human.Passive.BasicAttackRateMultiplier == 0.95,
    "Human attack rate"
)
check(
    human.Passive.CritChanceBonus == 0,
    "Human crit chance"
)
check(
    human.Passive.CritDamageBonus == 0.15,
    "Human crit damage"
)
check(
    human.Visual.Kind == "Human",
    "Human visual"
)

check(
    elf.BaseAttributes.Strength == 5,
    "Elf STR"
)
check(
    elf.BaseAttributes.Dexterity == 6,
    "Elf DEX"
)
check(
    elf.BaseAttributes.Vitality == 4,
    "Elf VIT"
)
check(
    elf.BaseAttributes.Intellect == 5,
    "Elf INT"
)
check(
    elf.BaseAttributes.Spirit == 5,
    "Elf SPI"
)
check(
    elf.Passive.MaxHealthMultiplier == 0.92,
    "Elf health"
)
check(
    elf.Passive.BasicAttackRateMultiplier == 1.08,
    "Elf attack rate"
)
check(
    elf.Passive.CritChanceBonus == 0.05,
    "Elf crit chance"
)
check(
    elf.Passive.CritDamageBonus == 0,
    "Elf crit damage"
)
check(
    elf.Visual.Kind == "ElfEars",
    "Elf visual"
)

check(
    CharacterIdentityRules.Stages.RaceSelection ==
        "RaceSelection",
    "RaceSelection stage"
)
check(
    CharacterIdentityRules.Stages.ClassSelection ==
        "ClassSelection",
    "ClassSelection stage"
)
check(
    CharacterIdentityRules.Stages.LegacyRaceSelection ==
        "LegacyRaceSelection",
    "LegacyRaceSelection stage"
)
check(
    CharacterIdentityRules.Stages.Complete ==
        "Complete",
    "Complete stage"
)

local elf_character = {
    Identity = {
        RaceId = "Elf",
        BaseClassId = "Fighter",
        ClassId = "Fighter",
        CreationStage = "Complete",
    },
}

check(
    CharacterIdentityRules.is_complete(elf_character),
    "Completed Elf Fighter identity"
)
check(
    CharacterIdentityRules.get_race_id(
        elf_character
    ) == "Elf",
    "Elf RaceId"
)
check(
    CharacterIdentityRules.get_class_id(
        elf_character
    ) == "Fighter",
    "Fighter ClassId"
)

local baseline_a = assert(
    CharacterIdentityRules.get_attribute_baseline(
        elf_character
    )
)

check(
    baseline_a.Dexterity == 6,
    "Elf baseline DEX"
)
check(
    baseline_a.Vitality == 4,
    "Elf baseline VIT"
)

baseline_a.Dexterity = 99

local baseline_b = assert(
    CharacterIdentityRules.get_attribute_baseline(
        elf_character
    )
)

check(
    baseline_b.Dexterity == 6,
    "Baseline must be cloned"
)

local fighter = assert(
    ClassDefinitions.get("Fighter"),
    "Fighter missing"
)

check(
    fighter.StarterSkills[1] == "ShieldBash",
    "Fighter Shield Bash starter"
)
check(
    fighter.StarterSkills[2] == "Mend",
    "Fighter Mend starter"
)
check(
    fighter.TeachableSkills[1] == "ArcSlash",
    "Fighter Arc Slash teachable"
)
check(
    ClassDefinitions.can_teach(
        "Fighter",
        "ArcSlash"
    ),
    "Fighter teaches Arc Slash"
)
check(
    ClassDefinitions.get("Prototype") == nil,
    "Prototype class must be retired"
)

print(
    "[Phase 2C.A Race Definitions] PASS (" ..
        tostring(assertion_count) ..
        " assertions)"
)