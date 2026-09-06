--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared")
local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))

export type MeleeSkillDefinition = {
    KIND: "Melee",
    ID: string,
    DISPLAY_NAME: string,
    STAMINA_COST: number,
    COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number,
    ACTIVE_SECONDS: number,
    RECOVERY_SECONDS: number,
    FORWARD_STEP_STUDS: number,
    REACH_STUDS: number,
    ARC_DEGREES: number,
    HITBOX: {SIZE: Vector3, FORWARD_OFFSET: number, SAMPLE_COUNT: number},
    BASE_DAMAGE: number,
    STAGGER_SECONDS: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type SupportSkillDefinition = {
    KIND: "Support",
    ID: string,
    DISPLAY_NAME: string,
    STAMINA_COST: number,
    COOLDOWN_SECONDS: number,
    HEAL_AMOUNT: number,
    RANGE_STUDS: number,
    CHANNEL_SECONDS: number,
    PULSE_COUNT: number,
    PULSE_HEAL: number,
    PULSE_INTERVAL_SECONDS: number,
    RANKS: {[number]: any}?,
}

export type SkillDefinition = MeleeSkillDefinition | SupportSkillDefinition

local SHIELD_BASH: MeleeSkillDefinition = table.freeze({
    KIND = "Melee",
    ID = "ShieldBash",
    DISPLAY_NAME = "Shield Bash",
    STAMINA_COST = 20,
    COOLDOWN_SECONDS = 4.0,
    WIND_UP_SECONDS = 0.16,
    ACTIVE_SECONDS = 0.10,
    RECOVERY_SECONDS = 0.32,
    FORWARD_STEP_STUDS = 1.6,
    REACH_STUDS = 6.0,
    ARC_DEGREES = CombatConfig.DEFENSE.BLOCK_ARC_DEGREES,
    HITBOX = table.freeze({SIZE = Vector3.new(12.0, 5.0, 6.4), FORWARD_OFFSET = 3.2, SAMPLE_COUNT = 3}),
    BASE_DAMAGE = 4,
    STAGGER_SECONDS = 0.9,
    MOVEMENT_SCALE = table.freeze({WIND_UP = 0.35, ACTIVE = 0.15, RECOVERY = 0.65}),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 4, STAGGER_SECONDS = 0.9}),
        [2] = table.freeze({BASE_DAMAGE = 5, STAGGER_SECONDS = 1.0}),
        [3] = table.freeze({BASE_DAMAGE = 6, STAGGER_SECONDS = 1.1}),
    }),
})

local MEND: SupportSkillDefinition = table.freeze({
    KIND = "Support",
    ID = "Mend",
    DISPLAY_NAME = "Mend",
    STAMINA_COST = 0,
    COOLDOWN_SECONDS = 8.0,
    HEAL_AMOUNT = 25,
    RANGE_STUDS = 12,
    CHANNEL_SECONDS = 2.0,
    PULSE_COUNT = 5,
    PULSE_HEAL = 5,
    PULSE_INTERVAL_SECONDS = 0.4,
    RANKS = table.freeze({
        [1] = table.freeze({PULSE_HEAL = 5, HEAL_AMOUNT = 25}),
        [2] = table.freeze({PULSE_HEAL = 6, HEAL_AMOUNT = 30}),
        [3] = table.freeze({PULSE_HEAL = 7, HEAL_AMOUNT = 35}),
    }),
})

local ARC_SLASH: MeleeSkillDefinition = table.freeze({
    KIND = "Melee",
    ID = "ArcSlash",
    DISPLAY_NAME = "Arc Slash",
    STAMINA_COST = 15,
    COOLDOWN_SECONDS = 5.0,
    WIND_UP_SECONDS = 0.22,
    ACTIVE_SECONDS = 0.12,
    RECOVERY_SECONDS = 0.38,
    FORWARD_STEP_STUDS = 2.2,
    REACH_STUDS = 7.0,
    ARC_DEGREES = 100,
    HITBOX = table.freeze({SIZE = Vector3.new(14.0, 5.0, 7.0), FORWARD_OFFSET = 3.5, SAMPLE_COUNT = 4}),
    BASE_DAMAGE = 12,
    STAGGER_SECONDS = 0,
    MOVEMENT_SCALE = table.freeze({WIND_UP = 0.30, ACTIVE = 0.12, RECOVERY = 0.60}),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 12}),
        [2] = table.freeze({BASE_DAMAGE = 15}),
        [3] = table.freeze({BASE_DAMAGE = 18}),
    }),
})

local DEFINITIONS: {[string]: SkillDefinition} = table.freeze({
    ShieldBash = SHIELD_BASH,
    Mend = MEND,
    ArcSlash = ARC_SLASH,
})

local SkillDefinitions = {}

local function clone_definition(definition: any): any
    local copy = {}
    for key, value in pairs(definition) do
        if key ~= "RANKS" then copy[key] = value end
    end
    return copy
end

local function validate_common(definition: SkillDefinition)
    assert(definition.ID ~= "", "Skill id cannot be empty.")
    assert(definition.STAMINA_COST >= 0, "Skill Stamina cannot be negative.")
    assert(definition.COOLDOWN_SECONDS >= 0, "Cooldown cannot be negative.")
end

local function validate_melee(definition: MeleeSkillDefinition)
    assert(definition.WIND_UP_SECONDS >= 0, "Wind-up cannot be negative.")
    assert(definition.ACTIVE_SECONDS > 0, "Active window must be positive.")
    assert(definition.RECOVERY_SECONDS >= 0, "Recovery cannot be negative.")
    assert(definition.REACH_STUDS > 0, "Skill reach must be positive.")
    assert(definition.ARC_DEGREES > 0 and definition.ARC_DEGREES <= 180, "Skill arc must be inside 0-180 degrees.")
    assert(definition.HITBOX.SIZE.Magnitude > 0, "Hitbox must have size.")
    assert(definition.HITBOX.SAMPLE_COUNT >= 1, "Hitbox needs a sample.")
    assert(definition.BASE_DAMAGE >= 0, "Skill damage cannot be negative.")
    assert(definition.STAGGER_SECONDS >= 0, "Stagger cannot be negative.")
end

local function validate_support(definition: SupportSkillDefinition)
    assert(definition.HEAL_AMOUNT > 0, "Support healing must be positive.")
    assert(definition.RANGE_STUDS > 0, "Support range must be positive.")
    assert(definition.CHANNEL_SECONDS > 0, "Support channel must be positive.")
    assert(definition.PULSE_COUNT >= 1 and definition.PULSE_COUNT == math.floor(definition.PULSE_COUNT), "Support skill needs whole-number pulses.")
    assert(definition.PULSE_HEAL > 0, "Support pulse heal must be positive.")
    assert(definition.PULSE_INTERVAL_SECONDS > 0, "Support pulse interval must be positive.")
    assert(definition.PULSE_HEAL * definition.PULSE_COUNT == definition.HEAL_AMOUNT, "Support pulses must equal total healing.")
end

for _, definition in DEFINITIONS do
    validate_common(definition)
    if definition.KIND == "Melee" then validate_melee(definition) else validate_support(definition :: SupportSkillDefinition) end
end

function SkillDefinitions.get(skill_id: string): SkillDefinition?
    return DEFINITIONS[skill_id]
end

function SkillDefinitions.get_for_rank(skill_id: string, rank: number): any?
    local definition = DEFINITIONS[skill_id]
    if not definition then return nil end
    local safe_rank = math.max(1, math.floor(rank))
    local copy = clone_definition(definition)
    local ranks = (definition :: any).RANKS
    if type(ranks) == "table" then
        local overrides = ranks[safe_rank] or ranks[1]
        if type(overrides) == "table" then
            for key, value in pairs(overrides) do copy[key] = value end
        end
    end
    return table.freeze(copy)
end

function SkillDefinitions.is_valid(skill_id: string): boolean
    return DEFINITIONS[skill_id] ~= nil
end

return table.freeze(SkillDefinitions)
