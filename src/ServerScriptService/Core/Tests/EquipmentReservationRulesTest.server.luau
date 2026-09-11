--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")
local EquipmentReservationRules = require(
    Shared:WaitForChild("EquipmentReservationRules")
)
local EquipmentStatResolver = require(
    Shared:WaitForChild("EquipmentStatResolver")
)
local ItemDefinitions = require(
    Shared:WaitForChild("ItemDefinitions")
)

local longbow = assert(ItemDefinitions.get("apprentice_longbow"))
local shield = assert(ItemDefinitions.get("marauder_shield"))

local can_longbow, longbow_reason = EquipmentReservationRules.can_equip(
    {OffHand = "marauder_shield"},
    longbow,
    "Weapon"
)
assert(can_longbow == false)
assert(longbow_reason == "ReservedSlotOccupied")

local can_shield, shield_reason = EquipmentReservationRules.can_equip(
    {Weapon = "apprentice_longbow"},
    shield,
    "OffHand"
)
assert(can_shield == false)
assert(shield_reason == "SlotReserved")

local malformed = EquipmentStatResolver.resolve({
    Weapon = "apprentice_longbow",
    OffHand = "marauder_shield",
})
assert(malformed.WeaponTags.Longbow == true)
assert(malformed.OffHandItemId == nil)
assert(malformed.Reservations.OffHand == "apprentice_longbow")
assert(malformed.MaxHealthFlat == 0)

local released = EquipmentReservationRules.resolve({
    Weapon = "marauder_sword",
})
assert(released.OffHand == nil)

print("[EquipmentReservationRulesTest] PASS")
