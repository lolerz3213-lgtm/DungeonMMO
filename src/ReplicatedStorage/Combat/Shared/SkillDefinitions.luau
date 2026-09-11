--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))

export type MeleeSkillDefinition = {
    KIND: "Melee", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    FORWARD_STEP_STUDS: number, REACH_STUDS: number, ARC_DEGREES: number,
    HITBOX: {SIZE: Vector3, FORWARD_OFFSET: number, SAMPLE_COUNT: number},
    BASE_DAMAGE: number, STAGGER_SECONDS: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type SupportSkillDefinition = {
    KIND: "Support", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, COOLDOWN_SECONDS: number,
    HEAL_AMOUNT: number, RANGE_STUDS: number, CHANNEL_SECONDS: number,
    PULSE_COUNT: number, PULSE_HEAL: number, PULSE_INTERVAL_SECONDS: number,
    RANKS: {[number]: any}?,
}

export type MageHealSkillDefinition = {
    KIND: "MageHeal", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, MANA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    RANGE_STUDS: number, TOTAL_HEAL: number,
    HUMAN_INSTANT_FRACTION: number, HUMAN_HOT_SECONDS: number,
    ELF_INSTANT_FRACTION: number, ELF_HOT_SECONDS: number,
    HOT_TICK_SECONDS: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type MagicProjectileSkillDefinition = {
    KIND: "MagicProjectile", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, MANA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    RANGE_STUDS: number, PROJECTILE_SPEED: number, BASE_DAMAGE: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type WardSkillDefinition = {
    KIND: "Ward", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, MANA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    RANGE_STUDS: number, WARD_AMOUNT: number, DURATION_SECONDS: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type RangerProjectileSkillDefinition = {
    KIND: "RangerProjectile", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    RANGE_STUDS: number, PROJECTILE_SPEED: number, BASE_DAMAGE: number,
    MAX_TARGETS: number, DEFAULT_RETENTION: number, HUMAN_RETENTION: number,
    HUMAN_SLOW_FRACTION: number?, HUMAN_SLOW_SECONDS: number?,
    ELF_SLOW_FRACTION: number?, ELF_SLOW_SECONDS: number?,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type RangerVolleySkillDefinition = {
    KIND: "RangerVolley", ID: string, DISPLAY_NAME: string,
    STAMINA_COST: number, COOLDOWN_SECONDS: number,
    WIND_UP_SECONDS: number, ACTIVE_SECONDS: number, RECOVERY_SECONDS: number,
    AIM_RANGE_STUDS: number, RADIUS_STUDS: number,
    INITIAL_DAMAGE: number, PULSE_DAMAGE: number,
    PULSE_COUNT: number, PULSE_INTERVAL_SECONDS: number,
    MOVEMENT_SCALE: {WIND_UP: number, ACTIVE: number, RECOVERY: number},
    RANKS: {[number]: any}?,
}

export type SkillDefinition = MeleeSkillDefinition
    | SupportSkillDefinition
    | MageHealSkillDefinition
    | MagicProjectileSkillDefinition
    | WardSkillDefinition
    | RangerProjectileSkillDefinition
    | RangerVolleySkillDefinition

local SHIELD_BASH: MeleeSkillDefinition = table.freeze({
    KIND = "Melee", ID = "ShieldBash", DISPLAY_NAME = "Shield Bash",
    STAMINA_COST = 20, COOLDOWN_SECONDS = 4.0,
    WIND_UP_SECONDS = 0.16, ACTIVE_SECONDS = 0.10, RECOVERY_SECONDS = 0.32,
    FORWARD_STEP_STUDS = 1.6, REACH_STUDS = 6.0,
    ARC_DEGREES = CombatConfig.DEFENSE.BLOCK_ARC_DEGREES,
    HITBOX = table.freeze({
        SIZE = Vector3.new(12.0, 5.0, 6.4),
        FORWARD_OFFSET = 3.2,
        SAMPLE_COUNT = 3,
    }),
    BASE_DAMAGE = 4, STAGGER_SECONDS = 0.9,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.35,
        ACTIVE = 0.15,
        RECOVERY = 0.65,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 4, STAGGER_SECONDS = 0.9}),
        [2] = table.freeze({BASE_DAMAGE = 5, STAGGER_SECONDS = 1.0}),
        [3] = table.freeze({BASE_DAMAGE = 6, STAGGER_SECONDS = 1.1}),
    }),
})

local MEND: SupportSkillDefinition = table.freeze({
    KIND = "Support", ID = "Mend", DISPLAY_NAME = "Mend",
    STAMINA_COST = 20, COOLDOWN_SECONDS = 8.0,
    HEAL_AMOUNT = 25, RANGE_STUDS = 12, CHANNEL_SECONDS = 2.0,
    PULSE_COUNT = 5, PULSE_HEAL = 5, PULSE_INTERVAL_SECONDS = 0.4,
    RANKS = table.freeze({
        [1] = table.freeze({PULSE_HEAL = 5, HEAL_AMOUNT = 25}),
        [2] = table.freeze({PULSE_HEAL = 6, HEAL_AMOUNT = 30}),
        [3] = table.freeze({PULSE_HEAL = 7, HEAL_AMOUNT = 35}),
    }),
})

local ARC_SLASH: MeleeSkillDefinition = table.freeze({
    KIND = "Melee", ID = "ArcSlash", DISPLAY_NAME = "Arc Slash",
    STAMINA_COST = 15, COOLDOWN_SECONDS = 5.0,
    WIND_UP_SECONDS = 0.22, ACTIVE_SECONDS = 0.12, RECOVERY_SECONDS = 0.38,
    FORWARD_STEP_STUDS = 2.2, REACH_STUDS = 7.0, ARC_DEGREES = 100,
    HITBOX = table.freeze({
        SIZE = Vector3.new(14.0, 5.0, 7.0),
        FORWARD_OFFSET = 3.5,
        SAMPLE_COUNT = 4,
    }),
    BASE_DAMAGE = 12, STAGGER_SECONDS = 0,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.30,
        ACTIVE = 0.12,
        RECOVERY = 0.60,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 12}),
        [2] = table.freeze({BASE_DAMAGE = 15}),
        [3] = table.freeze({BASE_DAMAGE = 18}),
    }),
})

local WIND_STRIKE: MagicProjectileSkillDefinition = table.freeze({
    KIND = "MagicProjectile", ID = "WindStrike", DISPLAY_NAME = "Wind Strike",
    STAMINA_COST = 0, MANA_COST = 25, COOLDOWN_SECONDS = 5.0,
    WIND_UP_SECONDS = 1.0, ACTIVE_SECONDS = 0.08, RECOVERY_SECONDS = 0.35,
    RANGE_STUDS = 60, PROJECTILE_SPEED = 78, BASE_DAMAGE = 30,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0,
        ACTIVE = 0,
        RECOVERY = 0,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 30}),
        [2] = table.freeze({BASE_DAMAGE = 36}),
        [3] = table.freeze({BASE_DAMAGE = 42}),
    }),
})

local ARCANE_WARD: WardSkillDefinition = table.freeze({
    KIND = "Ward", ID = "ArcaneWard", DISPLAY_NAME = "Arcane Ward",
    STAMINA_COST = 0, MANA_COST = 25, COOLDOWN_SECONDS = 8.0,
    WIND_UP_SECONDS = 0.25, ACTIVE_SECONDS = 0.05, RECOVERY_SECONDS = 0.25,
    RANGE_STUDS = 22, WARD_AMOUNT = 30, DURATION_SECONDS = 6.0,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.50,
        ACTIVE = 0.30,
        RECOVERY = 0.70,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({WARD_AMOUNT = 30}),
        [2] = table.freeze({WARD_AMOUNT = 36}),
        [3] = table.freeze({WARD_AMOUNT = 42}),
    }),
})

local MAGE_HEAL: MageHealSkillDefinition = table.freeze({
    KIND = "MageHeal", ID = "MageHeal", DISPLAY_NAME = "Mage Heal",
    STAMINA_COST = 0, MANA_COST = 30, COOLDOWN_SECONDS = 6.0,
    WIND_UP_SECONDS = 0.25, ACTIVE_SECONDS = 0.05, RECOVERY_SECONDS = 0.25,
    RANGE_STUDS = 22, TOTAL_HEAL = 40,
    HUMAN_INSTANT_FRACTION = 0.80,
    HUMAN_HOT_SECONDS = 4.0,
    ELF_INSTANT_FRACTION = 0.30,
    ELF_HOT_SECONDS = 6.0,
    HOT_TICK_SECONDS = 1.0,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.50,
        ACTIVE = 0.30,
        RECOVERY = 0.70,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({TOTAL_HEAL = 40}),
        [2] = table.freeze({TOTAL_HEAL = 46}),
        [3] = table.freeze({TOTAL_HEAL = 52}),
    }),
})

local PIERCING_SHOT: RangerProjectileSkillDefinition = table.freeze({
    KIND = "RangerProjectile",
    ID = "PiercingShot",
    DISPLAY_NAME = "Piercing Shot",
    STAMINA_COST = 20,
    COOLDOWN_SECONDS = 6.0,
    WIND_UP_SECONDS = 0.24,
    ACTIVE_SECONDS = 0.06,
    RECOVERY_SECONDS = 0.30,
    RANGE_STUDS = 80,
    PROJECTILE_SPEED = 125,
    BASE_DAMAGE = 28,
    MAX_TARGETS = 4,
    DEFAULT_RETENTION = 0.70,
    HUMAN_RETENTION = 0.80,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.55,
        ACTIVE = 0.45,
        RECOVERY = 0.80,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 28}),
        [2] = table.freeze({BASE_DAMAGE = 33}),
        [3] = table.freeze({BASE_DAMAGE = 38}),
    }),
})

local CRIPPLING_SHOT: RangerProjectileSkillDefinition = table.freeze({
    KIND = "RangerProjectile",
    ID = "CripplingShot",
    DISPLAY_NAME = "Crippling Shot",
    STAMINA_COST = 20,
    COOLDOWN_SECONDS = 7.0,
    WIND_UP_SECONDS = 0.20,
    ACTIVE_SECONDS = 0.06,
    RECOVERY_SECONDS = 0.30,
    RANGE_STUDS = 75,
    PROJECTILE_SPEED = 115,
    BASE_DAMAGE = 18,
    MAX_TARGETS = 1,
    DEFAULT_RETENTION = 1.00,
    HUMAN_RETENTION = 1.00,
    HUMAN_SLOW_FRACTION = 0.30,
    HUMAN_SLOW_SECONDS = 3.0,
    ELF_SLOW_FRACTION = 0.40,
    ELF_SLOW_SECONDS = 4.0,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.60,
        ACTIVE = 0.45,
        RECOVERY = 0.82,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({BASE_DAMAGE = 18}),
        [2] = table.freeze({BASE_DAMAGE = 22}),
        [3] = table.freeze({BASE_DAMAGE = 26}),
    }),
})

local VOLLEY: RangerVolleySkillDefinition = table.freeze({
    KIND = "RangerVolley",
    ID = "Volley",
    DISPLAY_NAME = "Volley",
    STAMINA_COST = 30,
    COOLDOWN_SECONDS = 10.0,
    WIND_UP_SECONDS = 0.28,
    ACTIVE_SECONDS = 0.06,
    RECOVERY_SECONDS = 0.36,
    AIM_RANGE_STUDS = 60,
    RADIUS_STUDS = 10,
    INITIAL_DAMAGE = 14,
    PULSE_DAMAGE = 7,
    PULSE_COUNT = 4,
    PULSE_INTERVAL_SECONDS = 0.5,
    MOVEMENT_SCALE = table.freeze({
        WIND_UP = 0.45,
        ACTIVE = 0.35,
        RECOVERY = 0.75,
    }),
    RANKS = table.freeze({
        [1] = table.freeze({INITIAL_DAMAGE = 14, PULSE_DAMAGE = 7}),
        [2] = table.freeze({INITIAL_DAMAGE = 16, PULSE_DAMAGE = 8}),
        [3] = table.freeze({INITIAL_DAMAGE = 18, PULSE_DAMAGE = 9}),
    }),
})

local DEFINITIONS: {[string]: SkillDefinition} = table.freeze({
    ShieldBash = SHIELD_BASH,
    Mend = MEND,
    ArcSlash = ARC_SLASH,
    WindStrike = WIND_STRIKE,
    ArcaneWard = ARCANE_WARD,
    MageHeal = MAGE_HEAL,
    PiercingShot = PIERCING_SHOT,
    CripplingShot = CRIPPLING_SHOT,
    Volley = VOLLEY,
})

local SkillDefinitions = {}

local function clone_definition(definition: any): any
    local copy = {}
    for key, value in pairs(definition) do
        if key ~= "RANKS" then
            copy[key] = value
        end
    end
    return copy
end

local function validate_common(definition: SkillDefinition)
    assert(definition.ID ~= "", "Skill id cannot be empty.")
    assert(definition.STAMINA_COST >= 0, "Skill Stamina cannot be negative.")
    assert(definition.COOLDOWN_SECONDS >= 0, "Cooldown cannot be negative.")
end

local function validate_timed(definition: any)
    assert(definition.WIND_UP_SECONDS >= 0, "Wind-up cannot be negative.")
    assert(definition.ACTIVE_SECONDS > 0, "Active window must be positive.")
    assert(definition.RECOVERY_SECONDS >= 0, "Recovery cannot be negative.")
    assert(
        definition.MOVEMENT_SCALE ~= nil,
        "Timed skill needs movement scale."
    )
end

local function validate_melee(definition: MeleeSkillDefinition)
    validate_timed(definition)
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
    assert(
        definition.PULSE_COUNT >= 1
            and definition.PULSE_COUNT == math.floor(definition.PULSE_COUNT),
        "Support skill needs whole-number pulses."
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
end

local function validate_mage_heal(definition: MageHealSkillDefinition)
    validate_timed(definition)
    assert(definition.MANA_COST > 0, "Mage Heal must cost Mana.")
    assert(definition.RANGE_STUDS > 0, "Mage Heal range must be positive.")
    assert(definition.TOTAL_HEAL > 0, "Mage Heal total must be positive.")
    assert(
        definition.HUMAN_INSTANT_FRACTION >= 0
            and definition.HUMAN_INSTANT_FRACTION <= 1,
        "Human heal split must be normalized."
    )
    assert(
        definition.ELF_INSTANT_FRACTION >= 0
            and definition.ELF_INSTANT_FRACTION <= 1,
        "Elf heal split must be normalized."
    )
    assert(
        definition.HOT_TICK_SECONDS > 0,
        "Heal-over-time tick must be positive."
    )
end

local function validate_magic_projectile(
    definition: MagicProjectileSkillDefinition
)
    validate_timed(definition)
    assert(definition.MANA_COST > 0, "Magic projectile must cost Mana.")
    assert(
        definition.RANGE_STUDS > 0,
        "Magic projectile range must be positive."
    )
    assert(
        definition.PROJECTILE_SPEED > 0,
        "Magic projectile speed must be positive."
    )
    assert(
        definition.BASE_DAMAGE > 0,
        "Magic projectile damage must be positive."
    )
end

local function validate_ward(definition: WardSkillDefinition)
    validate_timed(definition)
    assert(definition.MANA_COST > 0, "Ward must cost Mana.")
    assert(definition.RANGE_STUDS > 0, "Ward range must be positive.")
    assert(definition.WARD_AMOUNT > 0, "Ward amount must be positive.")
    assert(definition.DURATION_SECONDS > 0, "Ward duration must be positive.")
end

local function validate_ranger_projectile(
    definition: RangerProjectileSkillDefinition
)
    validate_timed(definition)
    assert(definition.STAMINA_COST > 0, "Ranger projectile must cost Stamina.")
    assert(
        definition.RANGE_STUDS > 0,
        "Ranger projectile range must be positive."
    )
    assert(
        definition.PROJECTILE_SPEED > 0,
        "Ranger projectile speed must be positive."
    )
    assert(
        definition.BASE_DAMAGE > 0,
        "Ranger projectile damage must be positive."
    )
    assert(definition.MAX_TARGETS >= 1, "Ranger projectile needs a target.")
    assert(
        definition.DEFAULT_RETENTION >= 0
            and definition.DEFAULT_RETENTION <= 1,
        "Ranger projectile retention must be normalized."
    )
    assert(
        definition.HUMAN_RETENTION >= 0
            and definition.HUMAN_RETENTION <= 1,
        "Human Ranger projectile retention must be normalized."
    )
end

local function validate_ranger_volley(
    definition: RangerVolleySkillDefinition
)
    validate_timed(definition)
    assert(definition.STAMINA_COST > 0, "Volley must cost Stamina.")
    assert(
        definition.AIM_RANGE_STUDS > 0,
        "Volley aim range must be positive."
    )
    assert(definition.RADIUS_STUDS > 0, "Volley radius must be positive.")
    assert(
        definition.INITIAL_DAMAGE > 0,
        "Volley initial damage must be positive."
    )
    assert(
        definition.PULSE_DAMAGE > 0,
        "Volley pulse damage must be positive."
    )
    assert(
        definition.PULSE_COUNT == 4,
        "Volley must contain initial plus three pulses."
    )
    assert(
        definition.PULSE_INTERVAL_SECONDS > 0,
        "Volley pulse interval must be positive."
    )
end

for _, definition in DEFINITIONS do
    validate_common(definition)
    if definition.KIND == "Melee" then
        validate_melee(definition)
    elseif definition.KIND == "Support" then
        validate_support(definition :: SupportSkillDefinition)
    elseif definition.KIND == "MageHeal" then
        validate_mage_heal(definition :: MageHealSkillDefinition)
    elseif definition.KIND == "MagicProjectile" then
        validate_magic_projectile(definition :: MagicProjectileSkillDefinition)
    elseif definition.KIND == "Ward" then
        validate_ward(definition :: WardSkillDefinition)
    elseif definition.KIND == "RangerProjectile" then
        validate_ranger_projectile(
            definition :: RangerProjectileSkillDefinition
        )
    elseif definition.KIND == "RangerVolley" then
        validate_ranger_volley(
            definition :: RangerVolleySkillDefinition
        )
    else
        error("Unknown skill kind: " .. tostring((definition :: any).KIND))
    end
end

function SkillDefinitions.get(skill_id: string): SkillDefinition?
    return DEFINITIONS[skill_id]
end

function SkillDefinitions.get_for_rank(
    skill_id: string,
    rank: number
): any?
    local definition = DEFINITIONS[skill_id]
    if not definition then
        return nil
    end

    local safe_rank = math.max(1, math.floor(rank))
    local copy = clone_definition(definition)
    local ranks = (definition :: any).RANKS

    if type(ranks) == "table" then
        local overrides = ranks[safe_rank] or ranks[1]
        if type(overrides) == "table" then
            for key, value in pairs(overrides) do
                copy[key] = value
            end
        end
    end

    return table.freeze(copy)
end

function SkillDefinitions.is_valid(skill_id: string): boolean
    return DEFINITIONS[skill_id] ~= nil
end

function SkillDefinitions.all(): {[string]: SkillDefinition}
    return DEFINITIONS
end

return table.freeze(SkillDefinitions)
