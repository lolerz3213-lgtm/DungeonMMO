local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

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
    HITBOX: {
        SIZE: Vector3,
        FORWARD_OFFSET: number,
        SAMPLE_COUNT: number,
    },
    BASE_DAMAGE: number,
    STAGGER_SECONDS: number,
    MOVEMENT_SCALE: {
        WIND_UP: number,
        ACTIVE: number,
        RECOVERY: number,
    },
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
    HITBOX = table.freeze({
        SIZE = Vector3.new(12.0, 5.0, 6.4),
        FORWARD_OFFSET = 3.2,
        SAMPLE_COUNT = 3,
    }),
    BASE_DAMAGE = 4,
    STAGGER_SECONDS = 0.9,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.35,
        ACTIVE = 0.15,
        RECOVERY = 0.65,
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
})

local DEFINITIONS: {[string]: SkillDefinition} = table.freeze({
    ShieldBash = SHIELD_BASH,
    Mend = MEND,
})

local SkillDefinitions = {}


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
    assert(
        definition.ARC_DEGREES > 0 and definition.ARC_DEGREES <= 180,
        "Skill arc must be inside 0-180 degrees."
    )
    assert(definition.HITBOX.SIZE.Magnitude > 0, "Hitbox must have size.")
    assert(definition.HITBOX.SAMPLE_COUNT >= 1, "Hitbox needs a sample.")
    assert(definition.BASE_DAMAGE >= 0, "Skill damage cannot be negative.")
    assert(definition.STAGGER_SECONDS >= 0, "Stagger cannot be negative.")
end


local function validate_support(definition: SupportSkillDefinition)
    assert(definition.HEAL_AMOUNT > 0, "Support healing must be positive.")
    assert(definition.RANGE_STUDS > 0, "Support range must be positive.")
    assert(definition.CHANNEL_SECONDS > 0, "Support channel must be positive.")
    assert(definition.PULSE_COUNT >= 1, "Support skill needs a pulse.")
    assert(
        definition.PULSE_COUNT == math.floor(definition.PULSE_COUNT),
        "Support pulse count must be a whole number."
    )
    assert(definition.PULSE_HEAL > 0, "Support pulse heal must be positive.")
    assert(
        definition.PULSE_INTERVAL_SECONDS > 0,
        "Support pulse interval must be positive."
    )
    assert(
        definition.PULSE_HEAL * definition.PULSE_COUNT
            == definition.HEAL_AMOUNT,
        "Support pulses must equal total healing."
    )
    assert(
        math.abs(
            definition.PULSE_INTERVAL_SECONDS * definition.PULSE_COUNT
                - definition.CHANNEL_SECONDS
        ) < 1e-6,
        "Support pulse timing must fill the channel."
    )
end


local function validate_definition(definition: SkillDefinition)
    validate_common(definition)

    if definition.KIND == "Melee" then
        validate_melee(definition)
        return
    end

    assert(definition.KIND == "Support", "Unsupported skill kind.")
    validate_support(definition)
end


for _, definition in DEFINITIONS do
    validate_definition(definition)
end


--[[
Returns one immutable active-skill definition by id.

Args:
    skill_id (string): Server-recognised skill identifier.

Returns:
    SkillDefinition?: Matching definition when the id is known.
]]
function SkillDefinitions.get(skill_id: string): SkillDefinition?
    return DEFINITIONS[skill_id]
end


--[[
Returns whether an id maps to a server-recognised active skill.

Args:
    skill_id (string): Candidate skill identifier.

Returns:
    boolean: True when a matching definition exists.
]]
function SkillDefinitions.is_valid(skill_id: string): boolean
    return DEFINITIONS[skill_id] ~= nil
end


return table.freeze(SkillDefinitions)
