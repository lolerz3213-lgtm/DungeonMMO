--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("EquipmentSlots")
if not module then
    error("[Equipment Slots Tests] RED: EquipmentSlots is missing.")
end

local EquipmentSlots = require(module)
local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Slots Tests] " .. message, 2)
    end
end

local expected = {"Weapon", "OffHand", "Helmet", "Body", "Gloves", "Boots"}
check(type(EquipmentSlots.ORDER) == "table", "ORDER must exist.")
check(#EquipmentSlots.ORDER == #expected, "ORDER must contain exactly six slots.")
for index, slot in ipairs(expected) do
    check(EquipmentSlots.ORDER[index] == slot, "slot order mismatch at " .. tostring(index))
    check(EquipmentSlots.is_valid(slot) == true, slot .. " must be valid.")
end
check(EquipmentSlots.is_valid("Ring") == false, "Ring must not be a Phase 2C.B slot.")
check(EquipmentSlots.is_valid("") == false, "empty slot must be rejected.")
check(EquipmentSlots.is_valid(nil) == false, "nil slot must be rejected.")

local empty = EquipmentSlots.empty()
check(type(empty) == "table", "empty equipment snapshot must be a table.")
for _, slot in ipairs(expected) do
    check(empty[slot] == nil, slot .. " must start empty.")
end

print(string.format("[Equipment Slots Tests] PASS: %d assertions.", assertions))
