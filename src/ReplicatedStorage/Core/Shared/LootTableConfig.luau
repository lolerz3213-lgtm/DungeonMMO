--!strict
local LootTableConfig = {}

LootTableConfig.TEST_DUNGEON = table.freeze({
    table.freeze({Weight = 50, Kind = "Nothing"}),
    table.freeze({Weight = 30, Kind = "ItemPool", ItemIds = table.freeze({"marauder_sword", "marauder_shield", "marauder_armor"})}),
    table.freeze({Weight = 15, Kind = "Item", ItemId = "captain_emblem"}),
    table.freeze({Weight = 5, Kind = "Item", ItemId = "skill_book_test"}),
})

return table.freeze(LootTableConfig)
