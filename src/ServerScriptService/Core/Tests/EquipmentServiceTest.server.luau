--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local InMemoryProfileAdapter = require(
    Adapters:WaitForChild("InMemoryProfileAdapter")
)
local ProfileService = require(Services:WaitForChild("ProfileService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local EquipmentService = require(Services:WaitForChild("EquipmentService"))

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Service Tests] " .. message, 2)
    end
end

local function complete_fighter(
    profiles: any,
    user_id: number,
    race_id: string
)
    assert(profiles:mutate(user_id, function(profile: any)
        profile.Characters.Slot1.Identity = {
            Version = 1,
            RaceId = race_id,
            BaseClassId = "Fighter",
            ClassId = "Fighter",
            CreationStage = "Complete",
        }
    end))
end

local adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(adapter)
assert(profiles:load(7201))
complete_fighter(profiles, 7201, "Human")

local inventory = InventoryService.new(profiles)
local equipment = EquipmentService.new(profiles, "Base")

local gear = {
    {"marauder_sword", "Weapon"},
    {"marauder_shield", "OffHand"},
    {"marauder_helmet", "Helmet"},
    {"marauder_armor", "Body"},
    {"marauder_gloves", "Gloves"},
    {"marauder_boots", "Boots"},
}

for _, pair in ipairs(gear) do
    check(
        inventory:add_item(7201, pair[1], 1).ok == true,
        pair[1] .. " must be grantable."
    )

    local before = InventoryService.count_item(
        assert(profiles:get_character(7201, 1)),
        pair[1]
    )

    local result = equipment:equip(7201, pair[1], pair[2])
    check(result.ok == true, pair[1] .. " must equip in " .. pair[2] .. ".")

    local after = InventoryService.count_item(
        assert(profiles:get_character(7201, 1)),
        pair[1]
    )

    check(before == after, "equip must not consume " .. pair[1])
end

local snapshot = equipment:build_snapshot(7201)
check(snapshot.ok == true, "snapshot must build.")

for _, pair in ipairs(gear) do
    check(
        snapshot.Slots[pair[2]] == pair[1],
        pair[2] .. " snapshot mismatch."
    )
end

check(
    equipment:equip(7201, "marauder_sword", "Body").reason == "WrongSlot",
    "wrong-slot equip must reject."
)
check(
    equipment:equip(7201, "missing_item", "Weapon").reason == "UnknownItem",
    "unknown item must reject."
)
check(
    equipment:equip(7201, "arc_slash_book_bound", "Weapon").reason == "NotEquipment",
    "Skill Book must not equip."
)

assert(inventory:add_item(7201, "test_elf_helmet", 1).ok)
check(
    equipment:equip(7201, "test_elf_helmet", "Helmet").reason == "RaceRestricted",
    "Human must reject Elf-only helmet."
)

check(equipment:unequip(7201, "Helmet").ok == true, "Base unequip must succeed.")
check(
    equipment:build_snapshot(7201).Slots.Helmet == nil,
    "unequip must clear Helmet."
)

assert(profiles:save(7201, "EquipmentTest"))
assert(profiles:release(7201, "EquipmentTest"))
assert(profiles:load(7201))

local reloaded = equipment:build_snapshot(7201)
check(reloaded.Slots.Weapon == "marauder_sword", "Weapon must persist across reload.")
check(reloaded.Slots.OffHand == "marauder_shield", "OffHand must persist across reload.")
check(reloaded.Slots.Body == "marauder_armor", "Body must persist across reload.")

local dungeon_equipment = EquipmentService.new(profiles, "Dungeon")
check(
    dungeon_equipment:equip(7201, "marauder_sword", "Weapon").reason == "BaseOnlyAction",
    "Dungeon equip must reject."
)
check(
    dungeon_equipment:unequip(7201, "Weapon").reason == "BaseOnlyAction",
    "Dungeon unequip must reject."
)

assert(profiles:load(7202))
assert(inventory:add_item(7202, "marauder_sword", 1).ok)
check(
    equipment:equip(7202, "marauder_sword", "Weapon").reason == "IdentityIncomplete",
    "unresolved identity must reject equipment."
)

assert(profiles:load(7203))
complete_fighter(profiles, 7203, "Elf")
assert(inventory:add_item(7203, "test_elf_helmet", 1).ok)
check(
    equipment:equip(7203, "test_elf_helmet", "Helmet").ok == true,
    "Elf must equip Elf-only helmet."
)

print(string.format(
    "[Equipment Service Tests] PASS: %d assertions.",
    assertions
))
