--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("EquipmentStatResolver")
if not module then
    error(
        "[Equipment Stat Resolver Tests] RED: "
            .. "EquipmentStatResolver is missing."
    )
end

local EquipmentStatResolver = require(module)
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Stat Resolver Tests] " .. message, 2)
    end
end

local function close(actual: number, expected: number, message: string)
    check(math.abs(actual - expected) < 0.000001, message)
end

local empty = EquipmentStatResolver.resolve({})
close(empty.PhysicalDamageBonus, 0, "empty physical bonus must be neutral")
close(empty.MaxHealthFlat, 0, "empty health bonus must be neutral")
close(empty.CriticalChanceBonus, 0, "empty crit bonus must be neutral")
check(next(empty.WeaponTags) == nil, "empty WeaponTags must be empty")
check(empty.WeaponItemId == nil, "empty WeaponItemId must be nil")
check(empty.OffHandItemId == nil, "empty OffHandItemId must be nil")

local full = EquipmentStatResolver.resolve({
    Weapon = "marauder_sword",
    OffHand = "marauder_shield",
    Helmet = "marauder_helmet",
    Body = "marauder_armor",
    Gloves = "marauder_gloves",
    Boots = "marauder_boots",
})
close(full.PhysicalDamageBonus, 0.13, "physical bonuses must aggregate")
close(full.MaxHealthFlat, 25, "health bonuses must aggregate")
close(full.CriticalChanceBonus, 0.01, "critical bonuses must aggregate")
check(
    full.WeaponTags.OneHandedSword == true,
    "sword must grant OneHandedSword"
)
check(full.WeaponItemId == "marauder_sword", "weapon item id must be retained")
check(
    full.OffHandItemId == "marauder_shield",
    "offhand item id must be retained"
)

local wrong_slot = EquipmentStatResolver.resolve({
    Helmet = "marauder_sword",
    Weapon = "captain_emblem",
    Body = "missing_item",
})
close(
    wrong_slot.PhysicalDamageBonus,
    0,
    "wrong-slot/non-equipment entries must not contribute"
)
check(
    next(wrong_slot.WeaponTags) == nil,
    "invalid weapon entries must not grant tags"
)

local replaced = EquipmentStatResolver.with_slot(
    {Weapon = "marauder_sword", Body = "marauder_armor"},
    "Weapon",
    nil
)
check(replaced.Weapon == nil, "with_slot must support unequip preview")
check(replaced.Body == "marauder_armor", "with_slot must preserve other slots")

local source = {Weapon = "marauder_sword"}
local candidate = EquipmentStatResolver.with_slot(
    source,
    "Gloves",
    "marauder_gloves"
)
check(source.Gloves == nil, "with_slot must not mutate the source table")
check(
    candidate.Gloves == "marauder_gloves",
    "with_slot must set candidate slot"
)

print(string.format(
    "[Equipment Stat Resolver Tests] PASS: %d assertions.",
    assertions
))
