local ReplicatedStorage = game:GetService("ReplicatedStorage")
local core = ReplicatedStorage:FindFirstChild("Core")
assert(core, "[Core Config Tests] RED: ReplicatedStorage.Core missing")

local shared = core:FindFirstChild("Shared")
assert(shared, "[Core Config Tests] RED: Core.Shared missing")

local EnvironmentConfig = require(shared:WaitForChild("EnvironmentConfig"))
assert(EnvironmentConfig.get_environment() == "DEV", "Studio environment must resolve to DEV")
assert(EnvironmentConfig.get_profile_store_name() == "DEV_PlayerProfile_v1", "DEV profile namespace mismatch")

local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig"))
assert(ProgressionConfig.get_required_xp(1) == 100, "Level 1 threshold must be 100")
assert(ProgressionConfig.get_required_xp(2) == 150, "Level 2 threshold must be 150")
assert(ProgressionConfig.get_required_xp(3) == 200, "Level 3 threshold must be 200")

local ReviveConfig = require(shared:WaitForChild("ReviveConfig"))
assert(ReviveConfig.FREE_REVIVES_PER_RUN == 1, "Exactly one free revive")
assert(ReviveConfig.PAID_PRICES[1] == 9, "First paid revive must be 9 Robux")
assert(ReviveConfig.PAID_PRICES[2] == 49, "Second paid revive must be 49 Robux")
assert(ReviveConfig.PAID_PRICES[3] == 99, "Third paid revive must be 99 Robux")
assert(ReviveConfig.PAID_PRICES[4] == 199, "Fourth paid revive must be 199 Robux")
assert(ReviveConfig.PAID_PRICE_5_PLUS == 399, "Fifth+ paid revive must be 399 Robux")
assert(ReviveConfig.WIPE_DECISION_SECONDS == 30, "Wipe timer must be 30 seconds")
assert(ReviveConfig.COMPLETION_RETURN_SECONDS == 60, "Completion timer must be 60 seconds")
assert(ReviveConfig.RECONNECT_GRACE_SECONDS == 600, "Reconnect grace must be 10 minutes")

local DungeonDefinitions = require(shared:WaitForChild("DungeonDefinitions"))
assert(DungeonDefinitions.TEST_DUNGEON.Id == "TestDungeon", "Test dungeon ID mismatch")
assert(#DungeonDefinitions.TEST_DUNGEON.RoomSequence == 3, "Test dungeon must have two combat rooms plus boss")
assert(DungeonDefinitions.TEST_DUNGEON.RoomPacks.CombatRoom1.MarauderCount == 2, "Room 1 prototype pack must be data-defined as 2 Marauders")
assert(DungeonDefinitions.TEST_DUNGEON.RoomPacks.CombatRoom2.MarauderCount == 3, "Room 2 prototype pack must be data-defined as 3 Marauders")

local LootTableConfig = require(shared:WaitForChild("LootTableConfig"))
local totalWeight = 0
for _, entry in ipairs(LootTableConfig.TEST_DUNGEON) do
    totalWeight += entry.Weight
end
assert(totalWeight == 100, "Test dungeon loot weights must total 100")

local ItemDefinitions = require(shared:WaitForChild("ItemDefinitions"))
assert(ItemDefinitions.get("marauder_sword") ~= nil, "Prototype equipment item missing")
assert(ItemDefinitions.get("skill_book_test") ~= nil, "Prototype Skill Book missing")

-- Phase 2C.A identity definition contract
local RaceDefinitions = require(
    shared:WaitForChild("RaceDefinitions")
)

local CharacterIdentityRules = require(
    shared:WaitForChild("CharacterIdentityRules")
)

local ClassProgressionDefinitions = require(
    shared:WaitForChild("ClassProgressionDefinitions")
)

assert(
    RaceDefinitions.get("Human") ~= nil,
    "Human race definition missing"
)
assert(
    RaceDefinitions.get("Elf") ~= nil,
    "Elf race definition missing"
)
assert(
    CharacterIdentityRules.Stages.RaceSelection ==
        "RaceSelection",
    "RaceSelection stage mismatch"
)
assert(
    CharacterIdentityRules.Stages.ClassSelection ==
        "ClassSelection",
    "ClassSelection stage mismatch"
)
assert(
    CharacterIdentityRules.Stages.LegacyRaceSelection ==
        "LegacyRaceSelection",
    "LegacyRaceSelection stage mismatch"
)
assert(
    CharacterIdentityRules.Stages.Complete ==
        "Complete",
    "Complete stage mismatch"
)
assert(
    ClassProgressionDefinitions.get("Prototype") == nil,
    "Prototype class must be retired"
)
assert(
    ClassProgressionDefinitions.get("Fighter") ~= nil,
    "Fighter class definition missing"
)
assert(
    ClassProgressionDefinitions.can_teach(
        "Fighter",
        "ArcSlash"
    ),
    "Fighter must teach Arc Slash"
)
print("[Core Config Tests] PASS")
