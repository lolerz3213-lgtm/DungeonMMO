--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local module = Shared:FindFirstChild("EquipmentPresentationRules")
if not module then
    error("[Equipment Presentation Rules Tests] RED: module is missing.")
end

local EquipmentPresentationRules = require(module)
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Presentation Rules Tests] " .. message, 2)
    end
end

check(
    EquipmentPresentationRules.show_sword("marauder_sword") == true,
    "representative sword must render"
)
check(
    EquipmentPresentationRules.show_sword(nil) == false,
    "empty Weapon must hide sword"
)
check(
    EquipmentPresentationRules.show_sword("missing_item") == false,
    "unsupported Weapon must not render prototype sword"
)
check(
    EquipmentPresentationRules.show_shield("marauder_shield") == true,
    "representative shield must render"
)
check(
    EquipmentPresentationRules.show_shield(nil) == false,
    "empty OffHand must hide shield"
)
check(
    EquipmentPresentationRules.show_shield("marauder_sword") == false,
    "wrong item must not render shield"
)

print(string.format(
    "[Equipment Presentation Rules Tests] PASS: %d assertions.",
    assertions
))
