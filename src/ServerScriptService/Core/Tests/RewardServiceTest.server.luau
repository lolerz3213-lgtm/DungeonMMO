--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local service_module = Services:FindFirstChild("RewardService")
if not service_module then
    error("[Reward Service Tests] RED: RewardService is missing.")
end

local InMemoryProfileAdapter = require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local ProgressionService = require(Services:WaitForChild("ProgressionService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local RewardService = require(service_module)
local LootTableConfig = require(Shared:WaitForChild("LootTableConfig"))
local DungeonDefinitions = require(Shared:WaitForChild("DungeonDefinitions"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Reward Service Tests] " .. message, 2)
    end
end

local rng: any = {}
function rng:NextNumber(_minimum: number?, _maximum: number?): number
    return 97
end
function rng:NextInteger(minimum: number, _maximum: number): number
    return minimum
end

local adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(adapter)
assert(profiles:load(3001))
assert(profiles:load(3002))
local progression = ProgressionService.new(profiles)
local inventory = InventoryService.new(profiles)
local rewards = RewardService.new(profiles, progression, inventory, nil, rng, function() return 5000 end)

local gold = rewards:grant_gold(3001, 12, "TestGold:1")
check(gold.ok == true and gold.gold_granted == 12, "Gold grant must succeed.")
local gold_repeat = rewards:grant_gold(3001, 12, "TestGold:1")
check(gold_repeat.ok == true and gold_repeat.already_applied == true, "Repeated source ID must not grant Gold twice in one runtime.")
check(assert(profiles:get_character(3001, 1)).Gold == 12, "Repeated Gold source must leave total at 12.")

local monster = rewards:grant_monster_reward({3001, 3002}, {XP = 10, GoldMin = 3, GoldMax = 6}, "Monster:session:1")
check(monster.ok == true, "Monster reward must grant to all supplied eligible members.")
check(assert(profiles:get_character(3001, 1)).XP == 10, "Monster XP must be granted to first member.")
check(assert(profiles:get_character(3002, 1)).XP == 10, "Monster XP must be granted to second member.")
check(assert(profiles:get_character(3001, 1)).Gold == 15, "Individual monster Gold roll must be added to first member.")
check(assert(profiles:get_character(3002, 1)).Gold == 3, "Individual monster Gold roll must be added to second member.")
local monster_repeat = rewards:grant_monster_reward({3001, 3002}, {XP = 10, GoldMin = 3, GoldMax = 6}, "Monster:session:1")
check(monster_repeat.ok == true and monster_repeat.already_applied == true, "Repeated monster transaction must be runtime-idempotent.")
check(assert(profiles:get_character(3001, 1)).XP == 10, "Repeated monster transaction must not duplicate XP.")

local reward_definition = {
    Gold = DungeonDefinitions.TEST_DUNGEON.CompletionGold,
    LootTable = LootTableConfig.TEST_DUNGEON,
}
local completion = rewards:grant_completion("session-complete-a", 1, 3001, reward_definition, rng)
check(completion.ok == true and completion.already_applied == false, "First completion must apply exactly once.")
check(completion.gold_granted == 50, "Completion Gold must match dungeon definition.")
check(completion.item_id == "skill_book_test", "Deterministic 97/100 roll must award the Skill Book entry.")
local after_completion = assert(profiles:get_character(3001, 1))
check(after_completion.Gold == 65, "Completion Gold must be added exactly once.")

local duplicate = rewards:grant_completion("session-complete-a", 1, 3001, reward_definition, rng)
check(duplicate.ok == true and duplicate.already_applied == true, "Duplicate completion call must return stored result.")
check(assert(profiles:get_character(3001, 1)).Gold == 65, "Duplicate completion must not add Gold twice.")

assert(profiles:save(3001, "CompletionTest"))
assert(profiles:release(3001, "CompletionTest"))
assert(profiles:load(3001))
local rewards_after_reload = RewardService.new(
    profiles,
    ProgressionService.new(profiles),
    InventoryService.new(profiles),
    nil,
    rng,
    function() return 5001 end
)
local monster_duplicate_after_reload = rewards_after_reload:grant_monster_reward({3001}, {XP = 10, GoldMin = 3, GoldMax = 6}, "Monster:session:1")
check(monster_duplicate_after_reload.ok == true and monster_duplicate_after_reload.already_applied == true, "Monster idempotency must survive profile reload.")
check(assert(profiles:get_character(3001, 1)).XP == 10, "Reloaded duplicate monster reward must not duplicate XP.")
check(assert(profiles:get_character(3001, 1)).Gold == 65, "Reloaded duplicate monster reward must not duplicate Gold.")
local duplicate_after_reload = rewards_after_reload:grant_completion("session-complete-a", 1, 3001, reward_definition, rng)
check(duplicate_after_reload.ok == true and duplicate_after_reload.already_applied == true, "Completion idempotency must survive profile reload.")
check(assert(profiles:get_character(3001, 1)).Gold == 65, "Reloaded duplicate completion must not add Gold.")

local book_quantity = 0
for _, entry in ipairs(assert(profiles:get_character(3001, 1)).Inventory) do
    if entry.ItemId == "skill_book_test" then
        book_quantity += entry.Quantity
    end
end
check(book_quantity == 1, "Completion Skill Book must persist exactly once.")

print(string.format("[Reward Service Tests] PASS: %d assertions.", assertions))
