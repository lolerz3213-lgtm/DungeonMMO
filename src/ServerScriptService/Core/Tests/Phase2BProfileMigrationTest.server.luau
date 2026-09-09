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
            "[Phase 2B Profile Migration Tests] " ..
                message,
            2
        )
    end
end

local phase2a = {
    SchemaVersion = 2,
    Account = {
        SelectedCharacterSlot = 1,
    },
    Characters = {
        Slot1 = {
            Level = 5,
            XP = 25,
            Gold = 9,
            Inventory = {},
            DungeonProgress = {},
            RewardHistory = {
                Completion = {},
                Monster = {},
            },
        },
    },
}

local first = ProfileMigration.migrate(phase2a)
local second = ProfileMigration.migrate(first)

local character = first.Characters.Slot1
local progression = character.Progression

local second_character = second.Characters.Slot1
local second_progression = second_character.Progression

check(
    ProfileSchema.VERSION == 5,
    "Schema version must advance to 5."
)
check(
    character.Identity.Version == 1,
    "Legacy identity version must be 1."
)
check(
    character.Identity.RaceId == nil,
    "Legacy race must remain unresolved."
)
check(
    character.Identity.BaseClassId == "Fighter",
    "Legacy base class must be Fighter."
)
check(
    character.Identity.ClassId == "Fighter",
    "Legacy current class must be Fighter."
)
check(
    character.Identity.CreationStage
        == "LegacyRaceSelection",
    "Legacy character must require one race choice."
)

check(
    progression.AttributePointEntitlement == 4,
    "Level 5 must retain four AP entitlement."
)
check(
    progression.SkillPointEntitlement == 4,
    "Level 5 must retain four SP entitlement."
)
check(
    progression.Attributes.Strength == 5
        and progression.Attributes.Dexterity == 5
        and progression.Attributes.Vitality == 5
        and progression.Attributes.Intellect == 5
        and progression.Attributes.Spirit == 5,
    "Legacy attributes must retain neutral v2 baseline."
)

check(
    progression.Skills.Mend.Known == true
        and progression.Skills.Mend.PurchasedRank == 1
        and progression.Skills.Mend.StarterGranted
            == true,
    "Mend must migrate as preserved Fighter starter."
)
check(
    progression.Skills.ShieldBash.Known == true
        and progression.Skills.ShieldBash.PurchasedRank
            == 1
        and progression.Skills.ShieldBash.StarterGranted
            == true,
    "Shield Bash must migrate as Fighter starter."
)

check(
    progression.Loadout[1] == "ShieldBash"
        and progression.Loadout[2] == "Mend",
    "Legacy starter loadout must be repaired."
)

check(
    progression.RespecCounters.Attributes == 0
        and progression.RespecCounters.Skills == 0,
    "Legacy respec counters must start at zero."
)
check(
    progression.OneTimeRewards.ArcSlashFirstClear
        == false,
    "Arc Slash reward flag must default false."
)

check(
    second_character.Identity.CreationStage
        == "LegacyRaceSelection",
    "Second migration must not complete race choice."
)
check(
    second_character.Identity.RaceId == nil,
    "Second migration must not invent a race."
)
check(
    second_progression.AttributePointEntitlement == 4
        and second_progression.SkillPointEntitlement
            == 4,
    "Repeated migration must not mint AP or SP."
)
check(
    second_progression.Skills.ShieldBash.PurchasedRank
        == 1
        and second_progression.Skills.Mend.PurchasedRank
            == 1,
    "Repeated migration must not duplicate starters."
)

print(
    string.format(
        "[Phase 2B Profile Migration Tests] PASS: %d assertions.",
        assertion_count
    )
)
