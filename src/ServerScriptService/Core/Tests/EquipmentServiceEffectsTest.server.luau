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
local user_id = 928403

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Service Effects Tests] " .. message, 2)
    end
end

local function close(actual: number, expected: number, message: string)
    check(math.abs(actual - expected) < 0.000001, message)
end

local function find_owned(snapshot: any, item_id: string): any?
    for _, entry in ipairs(snapshot.Owned or {}) do
        if entry.ItemId == item_id then
            return entry
        end
    end

    return nil
end

local adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(adapter)
assert(profiles:load(user_id))
assert(profiles:mutate(user_id, function(profile: any)
    profile.Characters.Slot1.Identity = {
        Version = 1,
        RaceId = "Human",
        BaseClassId = "Fighter",
        ClassId = "Fighter",
        CreationStage = "Complete",
    }
end))

local inventory = InventoryService.new(profiles)
local equipment = EquipmentService.new(profiles, "Base")

assert(inventory:add_item(user_id, "marauder_sword", 1).ok)
assert(inventory:add_item(user_id, "marauder_gloves", 1).ok)
assert(inventory:add_item(user_id, "marauder_armor", 1).ok)
assert(equipment:equip(user_id, "marauder_sword", "Weapon").ok)

local snapshot = equipment:build_snapshot(user_id)
check(snapshot.ok == true, "equipment snapshot must build")
check(
    type(snapshot.EquippedEffects) == "table",
    "snapshot must expose server-resolved equipped effects"
)
close(
    snapshot.EquippedEffects.PhysicalDamageBonus,
    0.10,
    "equipped sword must contribute current physical bonus"
)
close(
    snapshot.EquippedEffects.MaxHealthFlat,
    0,
    "unequipped armour must not contribute current health"
)

local gloves = find_owned(snapshot, "marauder_gloves")
check(gloves ~= nil, "owned gloves row must exist")
check(type(gloves.Effects) == "table", "owned row must expose item effects")
close(
    gloves.Effects.PhysicalDamageBonus,
    0.03,
    "gloves physical effect mismatch"
)
close(gloves.Effects.CriticalChanceBonus, 0.01, "gloves crit effect mismatch")
close(gloves.Effects.MaxHealthFlat, 0, "gloves health effect must be neutral")

check(
    type(gloves.PreviewEffects) == "table",
    "candidate row must expose server preview effects"
)
close(
    gloves.PreviewEffects.PhysicalDamageBonus,
    0.13,
    "gloves preview must replace only Gloves slot"
)
close(
    gloves.PreviewEffects.CriticalChanceBonus,
    0.01,
    "gloves preview must include crit effect"
)
close(
    gloves.DeltaEffects.PhysicalDamageBonus,
    0.03,
    "gloves preview physical delta mismatch"
)
close(
    gloves.DeltaEffects.CriticalChanceBonus,
    0.01,
    "gloves preview crit delta mismatch"
)

local armor = find_owned(snapshot, "marauder_armor")
check(armor ~= nil, "owned armour row must exist")
close(armor.Effects.MaxHealthFlat, 10, "armour item health effect mismatch")
close(
    armor.DeltaEffects.MaxHealthFlat,
    10,
    "unequipped armour preview must add its health effect"
)

print(string.format(
    "[Equipment Service Effects Tests] PASS: %d assertions.",
    assertions
))
