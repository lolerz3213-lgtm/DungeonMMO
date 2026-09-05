--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local service_module = Services:FindFirstChild("InventoryService")
if not service_module then
    error("[Inventory Service Tests] RED: InventoryService is missing.")
end

local InMemoryProfileAdapter = require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local InventoryService = require(service_module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Inventory Service Tests] " .. message, 2)
    end
end

local adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(adapter)
assert(profiles:load(2001))
local inventory = InventoryService.new(profiles)

local book = inventory:add_item(2001, "skill_book_test", 2)
check(book.ok == true and book.total_quantity == 2, "Stackable Skill Book must store quantity 2.")
check(type(InventoryService.consume_item) == "function", "Phase 2B inventory must expose atomic item consumption.")
check(InventoryService.learn_item == nil, "Skill Books must not expose a learn API yet.")

local swords = inventory:add_item(2001, "marauder_sword", 2)
check(swords.ok == true, "Two non-stackable swords must be accepted as separate entries.")
local character = assert(profiles:get_character(2001, 1))
local sword_entries = 0
local book_quantity = 0
for _, entry in ipairs(character.Inventory) do
    if entry.ItemId == "marauder_sword" then
        sword_entries += 1
    elseif entry.ItemId == "skill_book_test" then
        book_quantity += entry.Quantity
    end
end
check(sword_entries == 2, "Non-stackable equipment must create separate inventory entries.")
check(book_quantity == 2, "Skill Book stack must retain both copies.")
check(inventory:add_item(2001, "missing_item", 1).ok == false, "Unknown item IDs must fail closed.")
check(inventory:add_item(2001, "captain_emblem", 0).ok == false, "Zero quantity must be rejected.")

assert(profiles:save(2001, "InventoryTest"))
assert(profiles:release(2001, "InventoryTest"))
assert(profiles:load(2001))
character = assert(profiles:get_character(2001, 1))
book_quantity = 0
for _, entry in ipairs(character.Inventory) do
    if entry.ItemId == "skill_book_test" then
        book_quantity += entry.Quantity
    end
end
check(book_quantity == 2, "Skill Book inventory must survive save/release/reload.")

print(string.format("[Inventory Service Tests] PASS: %d assertions.", assertions))
