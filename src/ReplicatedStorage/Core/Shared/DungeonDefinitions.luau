--!strict
local LootTableConfig = require(script.Parent:WaitForChild("LootTableConfig"))
local DungeonDefinitions = {}

DungeonDefinitions.TEST_DUNGEON = table.freeze({
    Id = "TestDungeon",
    ContentVersion = 1,
    DisplayName = "Marauder Training Dungeon",
    MinPlayers = 1,
    MaxPlayers = 4,
    SoloEntryEnabled = true,
    RoomSequence = table.freeze({"CombatRoom1", "CombatRoom2", "MarauderCaptain"}),
    RoomPacks = table.freeze({
        CombatRoom1 = table.freeze({MarauderCount = 2}),
        CombatRoom2 = table.freeze({MarauderCount = 3}),
    }),
    RoomCheckpointIds = table.freeze({
        "Room1Start",
        "Room2Start",
        "BossRoomStart",
    }),
    StandardMarauderMaxHealth = 40,
    CompletionGold = 50,
    StandardMarauderReward = table.freeze({XP = 10, GoldMin = 3, GoldMax = 6}),
    MarauderCaptainReward = table.freeze({XP = 40, GoldMin = 15, GoldMax = 25}),
    MarauderCaptain = table.freeze({
        MaxHealth = 120,
        SpawnPosition = Vector3.new(250, 2, -315),
    }),
    CompletionReward = table.freeze({
        Gold = 50,
        LootTable = LootTableConfig.TEST_DUNGEON,
    }),
})

return table.freeze(DungeonDefinitions)
