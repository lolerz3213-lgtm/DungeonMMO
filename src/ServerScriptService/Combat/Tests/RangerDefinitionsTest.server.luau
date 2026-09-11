--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoreShared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")
local CombatShared = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local AttributeConfig = require(
    CoreShared:WaitForChild("AttributeConfig")
)
local ClassProgressionDefinitions = require(
    CoreShared:WaitForChild("ClassProgressionDefinitions")
)
local ItemDefinitions = require(
    CoreShared:WaitForChild("ItemDefinitions")
)
local SkillProgressionDefinitions = require(
    CoreShared:WaitForChild("SkillProgressionDefinitions")
)
local SkillDefinitions = require(
    CombatShared:WaitForChild("SkillDefinitions")
)

local ranger = assert(ClassProgressionDefinitions.get("Ranger"))
assert(ranger.StarterEquipment.Weapon == "apprentice_longbow")
assert(#ranger.StarterSkills == 3)
assert(ranger.StarterSkills[1] == "PiercingShot")
assert(ranger.StarterSkills[2] == "CripplingShot")
assert(ranger.StarterSkills[3] == "Volley")

local longbow = assert(ItemDefinitions.get("apprentice_longbow"))
assert(longbow.Slot == "Weapon")
assert(longbow.WeaponTags[1] == "Longbow")
assert(longbow.ReservedSlots[1] == "OffHand")

for _, skill_id in ipairs(ranger.StarterSkills) do
    local progression = assert(SkillProgressionDefinitions.get(skill_id))
    local combat = assert(SkillDefinitions.get(skill_id))
    assert(progression.WeaponTags[1] == "Longbow")
    assert(combat.STAMINA_COST > 0)
end

local piercing = assert(SkillDefinitions.get("PiercingShot"))
assert(piercing.MAX_TARGETS == 4)
assert(piercing.DEFAULT_RETENTION == 0.70)
assert(piercing.HUMAN_RETENTION == 0.80)

local crippling = assert(SkillDefinitions.get("CripplingShot"))
assert(crippling.HUMAN_SLOW_FRACTION == 0.30)
assert(crippling.HUMAN_SLOW_SECONDS == 3.0)
assert(crippling.ELF_SLOW_FRACTION == 0.40)
assert(crippling.ELF_SLOW_SECONDS == 4.0)

local volley = assert(SkillDefinitions.get("Volley"))
assert(volley.AIM_RANGE_STUDS == 60)
assert(volley.RADIUS_STUDS == 10)
assert(volley.INITIAL_DAMAGE == 14)
assert(volley.PULSE_DAMAGE == 7)
assert(volley.PULSE_COUNT == 4)
assert(volley.PULSE_INTERVAL_SECONDS == 0.5)

assert(AttributeConfig.ranged_physical_multiplier(5) == 1)
assert(AttributeConfig.ranged_physical_multiplier(6) > 1)

print("[RangerDefinitionsTest] PASS")
