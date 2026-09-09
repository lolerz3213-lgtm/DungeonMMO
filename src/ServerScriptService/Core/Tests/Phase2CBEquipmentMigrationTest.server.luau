--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local Services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")

local ProfileSchema = require(Shared:WaitForChild("ProfileSchema"))
local ProfileMigration = require(Services:WaitForChild("ProfileMigration"))

if ProfileSchema.VERSION ~= 5 then
    error(
        "[Phase 2C.B Equipment Migration Tests] RED: expected schema v5; current schema is "
            .. tostring(ProfileSchema.VERSION)
            .. "."
    )
end

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Phase 2C.B Equipment Migration Tests] " .. message, 2)
    end
end

local v4 = {
    SchemaVersion = 4,
    Account = {SelectedCharacterSlot = 1},
    Characters = {
        Slot1 = {
            Level = 10,
            XP = 77,
            Gold = 123,
            Inventory = {
                {ItemId = "marauder_sword", Quantity = 1},
                {ItemId = "arc_slash_book_bound", Quantity = 1},
            },
            DungeonProgress = {TestDungeon = "BossRoomStart"},
            RewardHistory = {Completion = {}, Monster = {}},
            Identity = {
                Version = 1,
                RaceId = "Elf",
                BaseClassId = "Fighter",
                ClassId = "Fighter",
                CreationStage = "Complete",
            },
            Progression = {
                Attributes = {
                    Strength = 5, Dexterity = 6, Vitality = 4,
                    Intellect = 5, Spirit = 5,
                },
                AttributePointEntitlement = 9,
                SkillPointEntitlement = 9,
                Skills = {
                    ShieldBash = {
                        Known = true, StarterGranted = true,
                        PurchasedRank = 1, Proficiency = 25,
                    },
                    Mend = {
                        Known = true, StarterGranted = true,
                        PurchasedRank = 1, Proficiency = 10,
                    },
                },
                Loadout = {[1] = "ShieldBash", [2] = "Mend"},
                RespecCounters = {Attributes = 1, Skills = 2},
                OneTimeRewards = {ArcSlashFirstClear = true},
                ArchivedSkillKnowledge = {},
            },
        },
    },
}

local migrated = ProfileMigration.migrate(v4)
local c = migrated.Characters.Slot1

check(migrated.SchemaVersion == 5, "v4 must migrate to schema v5.")
check(c.Identity.RaceId == "Elf", "schema-v4 Elf identity must NOT be reclassified as legacy.")
check(c.Identity.BaseClassId == "Fighter" and c.Identity.ClassId == "Fighter", "Fighter identity must remain complete.")
check(c.Identity.CreationStage == "Complete", "accepted v4 creation stage must remain complete.")
check(c.Level == 10 and c.XP == 77 and c.Gold == 123, "level/xp/gold must survive.")
check(type(c.Equipment) == "table", "schema-v5 Equipment table must exist.")
for _, slot in ipairs({"Weapon","OffHand","Helmet","Body","Gloves","Boots"}) do
    check(c.Equipment[slot] == nil, slot .. " must migrate empty.")
end
check(c.Progression.Attributes.Dexterity == 6 and c.Progression.Attributes.Vitality == 4, "racial attributes must survive.")
check(c.Progression.AttributePointEntitlement == 9 and c.Progression.SkillPointEntitlement == 9, "entitlements must survive.")
check(c.Progression.Skills.ShieldBash.Proficiency == 25, "proficiency must survive.")
check(c.Progression.RespecCounters.Attributes == 1 and c.Progression.RespecCounters.Skills == 2, "respec counters must survive.")
check(c.Progression.OneTimeRewards.ArcSlashFirstClear == true, "one-time rewards must survive.")

local twice = ProfileMigration.migrate(migrated)
check(twice.SchemaVersion == 5, "repeat migration must remain v5.")
check(twice.Characters.Slot1.Identity.RaceId == "Elf", "repeat migration must preserve identity.")
check(type(twice.Characters.Slot1.Equipment) == "table", "repeat migration must preserve Equipment.")

print(string.format("[Phase 2C.B Equipment Migration Tests] PASS: %d assertions.", assertions))
