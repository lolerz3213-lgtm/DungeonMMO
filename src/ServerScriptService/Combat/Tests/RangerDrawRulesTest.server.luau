--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RangerDrawRules = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("RangerDrawRules")
)

local normal = RangerDrawRules.classify(0.44)
assert(normal.Tier == "Normal")
assert(normal.DamageMultiplier == 1.00)
assert(normal.CriticalChanceBonus == 0)

local precision = RangerDrawRules.classify(0.45)
assert(precision.Tier == "Precision")
assert(precision.DamageMultiplier == 1.25)
assert(precision.CriticalChanceBonus == 0.05)

local full_draw = RangerDrawRules.classify(0.80)
assert(full_draw.Tier == "FullDraw")
assert(full_draw.DamageMultiplier == 1.50)
assert(full_draw.CriticalChanceBonus == 0.10)

local overheld = RangerDrawRules.classify(4.0)
assert(overheld.Tier == "FullDraw")
assert(overheld.DamageMultiplier == 1.50)
assert(RangerDrawRules.DRAW_MOVEMENT_SCALE == 0.60)

print("[RangerDrawRulesTest] PASS")
