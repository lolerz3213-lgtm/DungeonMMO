--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local ProfileSchema = require(
    shared:WaitForChild("ProfileSchema")
)

local ProfileMigration = require(
    services:WaitForChild("ProfileMigration")
)

local assertion_count = 0

local function check(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Profile Schema/Migration Tests] " .. message,
            2
        )
    end
end

local fresh_a = ProfileSchema.create_default(123)
local fresh_b = ProfileSchema.create_default(456)

local fresh_character = fresh_a.Characters.Slot1
local fresh_progression = fresh_character.Progression

check(
    fresh_a.SchemaVersion == 4,
    "Fresh profile must use schema version 4."
)
check(
    fresh_a.Account.SelectedCharacterSlot == 1,
    "Slot 1 must be selected by default."
)
check(
    fresh_character.Level == 1,
    "Fresh Slot1 Level must be 1."
)
check(
    fresh_character.XP == 0,
    "Fresh Slot1 XP must be 0."
)
check(
    fresh_character.Gold == 0,
    "Fresh Slot1 Gold must be 0."
)

check(
    fresh_character.Identity.Version == 1,
    "Fresh identity version must be 1."
)
check(
    fresh_character.Identity.RaceId == nil,
    "Fresh race must be unresolved."
)
check(
    fresh_character.Identity.BaseClassId == nil,
    "Fresh base class must be unresolved."
)
check(
    fresh_character.Identity.ClassId == nil,
    "Fresh class must be unresolved."
)
check(
    fresh_character.Identity.CreationStage
        == "RaceSelection",
    "Fresh character must require race selection."
)

check(
    next(fresh_progression.Skills) == nil,
    "Fresh profile must not pre-grant Fighter skills."
)
check(
    next(fresh_progression.Loadout) == nil,
    "Fresh profile must not pre-seed Fighter loadout."
)

check(
    fresh_character.Inventory
        ~= fresh_b.Characters.Slot1.Inventory,
    "Fresh profiles must not share Inventory tables."
)
check(
    fresh_character.RewardHistory.Completion
        ~= fresh_b.Characters.Slot1
            .RewardHistory.Completion,
    "Fresh profiles must not share reward tables."
)

local migrated_new = ProfileMigration.migrate(nil)
local migrated_new_character =
    migrated_new.Characters.Slot1

check(
    migrated_new.SchemaVersion == 4,
    "Nil storage must create schema v4."
)
check(
    migrated_new_character.Identity.CreationStage
        == "RaceSelection",
    "Nil storage must be genuinely fresh."
)
check(
    next(migrated_new_character.Progression.Skills)
        == nil,
    "Nil storage must not receive legacy starters."
)
check(
    next(migrated_new_character.Progression.Loadout)
        == nil,
    "Nil storage must not receive legacy loadout."
)

local migrated_new_again = ProfileMigration.migrate(
    migrated_new
)

check(
    migrated_new_again.Characters.Slot1
        .Identity.CreationStage == "RaceSelection",
    "Fresh v4 re-migration must remain fresh."
)
check(
    next(
        migrated_new_again.Characters.Slot1
            .Progression.Skills
    ) == nil,
    "Fresh v4 re-migration must not gain starters."
)

-- An existing table without a schema version is old data,
-- not a brand-new 2C.A character.
local migrated_empty = ProfileMigration.migrate({})

check(
    migrated_empty.SchemaVersion == 4,
    "Existing empty profile must migrate to v4."
)
check(
    migrated_empty.Characters.Slot1
        .Identity.CreationStage
        == "LegacyRaceSelection",
    "Existing pre-v4 table must become legacy."
)
check(
    migrated_empty.Characters.Slot1
        .Identity.BaseClassId == "Fighter",
    "Legacy character must retain Fighter base class."
)
check(
    migrated_empty.Characters.Slot1
        .Progression.Skills.ShieldBash.Known == true,
    "Legacy migration must repair Shield Bash."
)
check(
    migrated_empty.Characters.Slot1
        .Progression.Skills.Mend.Known == true,
    "Legacy migration must repair Mend."
)

local migrated_partial = ProfileMigration.migrate({
    CustomFutureField = {
        KeepMe = true,
    },
    Account = {
        CustomAccountField = "keep",
    },
    Characters = {
        Slot1 = {
            Level = 4,
            XP = -10,
            Gold = 0 / 0,
            Inventory = {
                "ExistingItem",
            },
            CustomCharacterField = 99,
        },
    },
})

check(
    migrated_partial.CustomFutureField.KeepMe == true,
    "Unknown top-level fields must be preserved."
)
check(
    migrated_partial.Account.CustomAccountField
        == "keep",
    "Unknown Account fields must be preserved."
)
check(
    migrated_partial.Characters.Slot1
        .CustomCharacterField == 99,
    "Unknown character fields must be preserved."
)
check(
    migrated_partial.Characters.Slot1.Level == 4,
    "Valid Level must be preserved."
)
check(
    migrated_partial.Characters.Slot1.XP == 0,
    "Negative XP must sanitize to zero."
)
check(
    migrated_partial.Characters.Slot1.Gold == 0,
    "NaN Gold must sanitize to zero."
)
check(
    migrated_partial.Characters.Slot1.Inventory[1]
        == "ExistingItem",
    "Existing inventory must survive migration."
)
check(
    migrated_partial.Characters.Slot1
        .Identity.CreationStage
        == "LegacyRaceSelection",
    "Existing partial data must require legacy race."
)

local sanitized_inf = ProfileMigration.migrate({
    Characters = {
        Slot1 = {
            XP = math.huge,
            Gold = math.huge,
        },
    },
})

check(
    sanitized_inf.Characters.Slot1.XP == 0,
    "Infinite XP must sanitize to zero."
)
check(
    sanitized_inf.Characters.Slot1.Gold == 0,
    "Infinite Gold must sanitize to zero."
)

-- Critical v4 regression:
-- race baselines below neutral 5 must survive future
-- ProfileService mutation/migration passes.
local v4_elf = ProfileSchema.create_default(789)

v4_elf.Characters.Slot1.Identity.RaceId = "Elf"
v4_elf.Characters.Slot1.Identity.CreationStage =
    "ClassSelection"

v4_elf.Characters.Slot1.Progression.Attributes = {
    Strength = 5,
    Dexterity = 6,
    Vitality = 4,
    Intellect = 5,
    Spirit = 5,
}

local preserved_elf = ProfileMigration.migrate(v4_elf)

check(
    preserved_elf.Characters.Slot1
        .Progression.Attributes.Dexterity == 6,
    "Elf DEX baseline must survive v4 migration."
)
check(
    preserved_elf.Characters.Slot1
        .Progression.Attributes.Vitality == 4,
    "Elf VIT 4 must not be clamped back to 5."
)
check(
    preserved_elf.Characters.Slot1.Identity.RaceId
        == "Elf",
    "Known v4 Elf identity must be preserved."
)
check(
    preserved_elf.Characters.Slot1
        .Identity.CreationStage == "ClassSelection",
    "Valid v4 ClassSelection must be preserved."
)

local malformed = ProfileSchema.create_default(900)

malformed.Characters.Slot1.Identity.Version = 1
malformed.Characters.Slot1.Identity.RaceId = "Orc"
malformed.Characters.Slot1.Identity.BaseClassId =
    "Fighter"
malformed.Characters.Slot1.Identity.ClassId =
    "Fighter"
malformed.Characters.Slot1.Identity.CreationStage =
    "Complete"

local safe = ProfileMigration.migrate(malformed)

check(
    safe.Characters.Slot1.Identity.RaceId == nil,
    "Unknown persisted race must fail closed."
)
check(
    safe.Characters.Slot1.Identity.BaseClassId == nil,
    "Malformed identity must not invent a class."
)
check(
    safe.Characters.Slot1.Identity.ClassId == nil,
    "Malformed identity must clear invalid class."
)
check(
    safe.Characters.Slot1.Identity.CreationStage
        == "RaceSelection",
    "Malformed v4 identity must return to safe selection."
)

print(
    string.format(
        "[Profile Schema/Migration Tests] PASS: %d assertions.",
        assertion_count
    )
)