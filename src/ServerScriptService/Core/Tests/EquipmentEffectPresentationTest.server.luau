--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("EquipmentEffectPresentation")
if not module then
    error("[Equipment Effect Presentation Tests] RED: module is missing.")
end

local EquipmentEffectPresentation = require(module)
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Effect Presentation Tests] " .. message, 2)
    end
end

local item_text = EquipmentEffectPresentation.format_effects({
    PhysicalDamageBonus = 0.10,
    MaxHealthFlat = 8,
    CriticalChanceBonus = 0.01,
})
check(
    string.find(item_text, "+10% Physical Damage", 1, true) ~= nil,
    "physical damage effect must be readable"
)
check(
    string.find(item_text, "+8 Max Health", 1, true) ~= nil,
    "max-health effect must be readable"
)
check(
    string.find(item_text, "+1% Critical Chance", 1, true) ~= nil,
    "critical effect must be readable"
)

local neutral = EquipmentEffectPresentation.format_effects({})
check(neutral == "No combat effect", "neutral effects need explicit text")

local delta = EquipmentEffectPresentation.format_delta({
    PhysicalDamageBonus = 0.03,
    MaxHealthFlat = -4,
    CriticalChanceBonus = 0,
})
check(
    string.find(delta, "+3% Physical Damage", 1, true) ~= nil,
    "positive preview delta must include plus sign"
)
check(
    string.find(delta, "-4 Max Health", 1, true) ~= nil,
    "negative preview delta must include minus sign"
)

print(string.format(
    "[Equipment Effect Presentation Tests] PASS: %d assertions.",
    assertions
))
