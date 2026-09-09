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
            "[Phase 2C.A Profile Migration Tests] " ..
                message,
            2
        )
    end
end

local function deep_equal(
    left: any,
    right: any
): boolean
    if type(left) ~= type(right) then
        return false
    end

    if type(left) ~= "table" then
        return left == right
    end

    for key, value in pairs(left) do
        if not deep_equal(value, right[key]) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

local phase2b_v3 = {
    SchemaVersion = 3,

    CustomTopLevelField = {
        Preserve = "top",
    },

    Account = {
        SelectedCharacterSlot = 1,
        CustomAccountField = "account",
    },

    Characters = {
        Slot1 = {
            Level = 8,
            XP = 345,
            Gold = 777,

            Inventory = {
                arc_slash_book_bound = 2,
                CustomInventoryField = "inventory",
            },

            DungeonProgress = {
                TestDungeon = {
                    Clears = 4,
                },
            },

            RewardHistory = {
                Completion = {
                    ["legacy-completion"] = true,
                },
                Monster = {
                    ["legacy-monster"] = true,
                },
                CustomRewardHistoryField = "history",
            },

            CustomCharacterField = {
                Preserve = "character",
            },

            Progression = {
                Attributes = {
                    Strength = 8,
                    Dexterity = 6,
                    Vitality = 7,
                    Intellect = 5,
                    Spirit = 9,
                },

                AttributePointEntitlement = 12,
                SkillPointEntitlement = 13,

                Skills = {
                    ShieldBash = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 75,
                        CustomSkillField = "shield",
                    },

                    Mend = {
                        Known = true,
                        StarterGranted = true,
                        PurchasedRank = 1,
                        Proficiency = 55,
                        CustomSkillField = "mend",
                    },

                    ArcSlash = {
                        Known = true,
                        StarterGranted = false,
                        PurchasedRank = 2,
                        Proficiency = 420,
                        CustomSkillField = "arc",
                    },
                },

                Loadout = {
                    [1] = "Mend",
                    [3] = "ArcSlash",
                    [6] = "ShieldBash",
                },

                RespecCounters = {
                    Attributes = 2,
                    Skills = 3,
                    CustomRespecField = "respec",
                },

                OneTimeRewards = {
                    ArcSlashFirstClear = true,
                    CustomRewardField = "reward",
                },

                ArchivedSkillKnowledge = {
                    LegacySkill = {
                        Proficiency = 17,
                    },
                },

                CustomProgressionField = {
                    Preserve = "progression",
                },
            },
        },
    },
}

local original = ProfileSchema.deep_clone(phase2b_v3)
local original_progression =
    ProfileSchema.deep_clone(
        phase2b_v3.Characters.Slot1.Progression
    )

local first = ProfileMigration.migrate(phase2b_v3)
local character = first.Characters.Slot1
local progression = character.Progression

check(
    phase2b_v3.SchemaVersion == 3,
    "Migration must not mutate the source table."
)
check(
    deep_equal(phase2b_v3, original),
    "Raw Phase 2B source must remain unchanged."
)

check(
    first.SchemaVersion == 5,
    "Legacy profile must migrate through schema v5."
)
check(
    character.Identity.Version == 1,
    "Migrated identity version must be 1."
)
check(
    character.Identity.RaceId == nil,
    "Migration must never silently choose a race."
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
    "Legacy profile must require one-time race choice."
)

check(
    character.Level == 8,
    "Level must be preserved."
)
check(
    character.XP == 345,
    "XP must be preserved."
)
check(
    character.Gold == 777,
    "Gold must be preserved."
)

check(
    deep_equal(
        character.Inventory,
        phase2b_v3.Characters.Slot1.Inventory
    ),
    "Inventory must be preserved exactly."
)
check(
    deep_equal(
        character.DungeonProgress,
        phase2b_v3.Characters.Slot1.DungeonProgress
    ),
    "Dungeon progress must be preserved exactly."
)
check(
    deep_equal(
        character.RewardHistory,
        phase2b_v3.Characters.Slot1.RewardHistory
    ),
    "Reward history must be preserved exactly."
)

check(
    deep_equal(
        progression.Attributes,
        original_progression.Attributes
    ),
    "Invested legacy attributes must not translate yet."
)
check(
    progression.AttributePointEntitlement == 12,
    "AP entitlement must be preserved."
)
check(
    progression.SkillPointEntitlement == 13,
    "SP entitlement must be preserved."
)

check(
    progression.Skills.ArcSlash.Known == true,
    "Arc Slash knowledge must be preserved."
)
check(
    progression.Skills.ArcSlash.PurchasedRank == 2,
    "Arc Slash rank must be preserved."
)
check(
    progression.Skills.ArcSlash.Proficiency == 420,
    "Arc Slash proficiency must be preserved."
)
check(
    progression.Skills.ArcSlash.CustomSkillField
        == "arc",
    "Unknown skill fields must be preserved."
)

check(
    progression.Skills.ShieldBash.PurchasedRank == 1
        and progression.Skills.ShieldBash.StarterGranted
            == true,
    "Shield Bash starter state must be preserved."
)
check(
    progression.Skills.Mend.PurchasedRank == 1
        and progression.Skills.Mend.StarterGranted
            == true,
    "Mend starter state must be preserved."
)

check(
    progression.Loadout[1] == "Mend"
        and progression.Loadout[2] == nil
        and progression.Loadout[3] == "ArcSlash"
        and progression.Loadout[4] == nil
        and progression.Loadout[5] == nil
        and progression.Loadout[6] == "ShieldBash",
    "Sparse six-slot loadout must remain exact."
)

check(
    progression.OneTimeRewards.ArcSlashFirstClear
        == true,
    "Arc Slash reward state must be preserved."
)
check(
    progression.OneTimeRewards.CustomRewardField
        == "reward",
    "Unknown reward fields must be preserved."
)

check(
    progression.RespecCounters.Attributes == 2
        and progression.RespecCounters.Skills == 3,
    "Respec counters must be preserved."
)
check(
    progression.RespecCounters.CustomRespecField
        == "respec",
    "Unknown respec fields must be preserved."
)

check(
    deep_equal(
        progression.ArchivedSkillKnowledge,
        original_progression.ArchivedSkillKnowledge
    ),
    "Archived skill knowledge must be preserved."
)
check(
    deep_equal(
        progression.CustomProgressionField,
        original_progression.CustomProgressionField
    ),
    "Unknown progression fields must be preserved."
)
check(
    deep_equal(
        character.CustomCharacterField,
        phase2b_v3.Characters.Slot1
            .CustomCharacterField
    ),
    "Unknown character fields must be preserved."
)
check(
    first.Account.CustomAccountField == "account",
    "Unknown Account fields must be preserved."
)
check(
    first.CustomTopLevelField.Preserve == "top",
    "Unknown top-level fields must be preserved."
)

-- With a fully valid v3 fixture, Progression itself should
-- survive byte-for-byte semantically. Identity/schema are the
-- intentional additions.
check(
    deep_equal(
        progression,
        original_progression
    ),
    "Valid Phase 2B progression must be preserved exactly."
)

local second = ProfileMigration.migrate(first)

check(
    deep_equal(first, second),
    "Second migration must be fully idempotent."
)
check(
    second.Characters.Slot1.Identity.RaceId == nil,
    "Re-migration must not invent a race."
)
check(
    second.Characters.Slot1.Identity.CreationStage
        == "LegacyRaceSelection",
    "Re-migration must remain progression-locked."
)
check(
    second.Characters.Slot1
        .Progression.AttributePointEntitlement == 12
        and second.Characters.Slot1
            .Progression.SkillPointEntitlement == 13,
    "Re-migration must not mint AP or SP."
)

print(
    string.format(
        "[Phase 2C.A Profile Migration Tests] PASS: %d assertions.",
        assertion_count
    )
)
