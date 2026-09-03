export type StateName =
    "Locomotion"
    | "WindUp"
    | "Active"
    | "Recovery"

export type MovementScale = {
    WIND_UP: number,
    ACTIVE: number,
    RECOVERY: number,
}

export type AttackDefinition = {
    DISPLAY_NAME: string,
    WIND_UP_SECONDS: number,
    ACTIVE_SECONDS: number,
    RECOVERY_SECONDS: number,
    FORWARD_STEP_STUDS: number,
    REACH_STUDS: number,
    ARC_DEGREES: number,
    POWER_MULTIPLIER: number,
    MOVEMENT_SCALE: MovementScale,
}

local State = table.freeze({
    LOCOMOTION = "Locomotion",
    WIND_UP = "WindUp",
    ACTIVE = "Active",
    RECOVERY = "Recovery",
})

local CombatTypes = table.freeze({
    State = State,
})

return CombatTypes
