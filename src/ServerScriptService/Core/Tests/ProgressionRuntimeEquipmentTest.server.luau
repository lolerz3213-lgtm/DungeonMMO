--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local ProgressionRuntimeState = require(
    Services:WaitForChild("ProgressionRuntimeState")
)

local assertions = 0
local user_id = 928401

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Progression Runtime Equipment Tests] " .. message, 2)
    end
end

local function close(actual: number, expected: number, message: string)
    check(math.abs(actual - expected) < 0.000001, message)
end

local function character(equipment: any): any
    return {
        Identity = {
            RaceId = "Human",
        },
        Inventory = {},
        Equipment = equipment,
        Progression = {
            Attributes = {
                Strength = 5,
                Dexterity = 4,
                Vitality = 6,
                Intellect = 5,
                Spirit = 5,
            },
            Skills = {},
            Loadout = {},
        },
    }
end

ProgressionRuntimeState.set_character(user_id, character({}))
close(
    ProgressionRuntimeState.get_physical_multiplier(user_id),
    1,
    "empty equipment must preserve physical baseline"
)
close(
    ProgressionRuntimeState.get_max_health(user_id),
    113.4,
    "empty equipment must preserve Human max-health baseline"
)
close(
    ProgressionRuntimeState.get_critical_chance(user_id),
    0.045,
    "empty equipment must preserve Human critical baseline"
)

local source = character({
    Weapon = "marauder_sword",
    OffHand = "marauder_shield",
    Helmet = "marauder_helmet",
    Body = "marauder_armor",
    Gloves = "marauder_gloves",
    Boots = "marauder_boots",
})
ProgressionRuntimeState.set_character(user_id, source)

close(
    ProgressionRuntimeState.get_physical_multiplier(user_id),
    1.13,
    "sword and gloves must add physical damage"
)
close(
    ProgressionRuntimeState.get_max_health(user_id),
    138.4,
    "shield and armour pieces must add flat max health"
)
close(
    ProgressionRuntimeState.get_critical_chance(user_id),
    0.055,
    "gloves must compose with accepted critical chance"
)
close(
    ProgressionRuntimeState.get_basic_attack_rate(user_id),
    0.95,
    "equipment must not change Human attack rate"
)
close(
    ProgressionRuntimeState.get_critical_damage_multiplier(user_id),
    1.65,
    "equipment must not change Human critical damage"
)
close(
    ProgressionRuntimeState.get_heal_multiplier(user_id),
    1,
    "representative equipment must not change Mend scaling"
)

local tags = ProgressionRuntimeState.get_weapon_tags(user_id)
check(tags.OneHandedSword == true, "runtime sword must provide OneHandedSword")

table.insert(source.Inventory, {
    ItemId = "marauder_gloves",
    Quantity = 1,
})
source.Equipment.Weapon = nil
source.Equipment.Gloves = nil
close(
    ProgressionRuntimeState.get_physical_multiplier(user_id),
    1.13,
    "runtime equipment must be deep-cloned and run-locked"
)
check(
    ProgressionRuntimeState.get_weapon_tags(user_id).OneHandedSword == true,
    "source Equipment mutation must not change runtime weapon tags"
)

ProgressionRuntimeState.set_character(user_id, source)
close(
    ProgressionRuntimeState.get_physical_multiplier(user_id),
    1,
    "explicit authoritative reseed must pick up later equipment changes"
)


local high_crit = character({Gloves = "marauder_gloves"})
high_crit.Progression.Attributes.Dexterity = 500
ProgressionRuntimeState.set_character(user_id, high_crit)
close(
    ProgressionRuntimeState.get_critical_chance(user_id),
    1,
    "equipment critical chance must preserve the accepted 0..1 clamp"
)

ProgressionRuntimeState.clear_character(user_id)

print(string.format(
    "[Progression Runtime Equipment Tests] PASS: %d assertions.",
    assertions
))
