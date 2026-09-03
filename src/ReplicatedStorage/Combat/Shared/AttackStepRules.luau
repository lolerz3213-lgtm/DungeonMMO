local AttackStepRules = {}

local MIN_STEP_SECONDS = 0.14
local MAX_STEP_SECONDS = 0.22
local RECOVERY_SHARE = 0.20
local WALL_MARGIN_STUDS = 0.35


--[[
Returns the smooth movement duration for one attack step.

Args:
    attack_definition (table): Configured attack timing values.

Returns:
    number: Step duration in seconds.
]]
function AttackStepRules.get_step_duration(
    attack_definition: any
): number
    local raw_duration =
        attack_definition.ACTIVE_SECONDS
        + (
            attack_definition.RECOVERY_SECONDS
            * RECOVERY_SHARE
        )

    return math.clamp(
        raw_duration,
        MIN_STEP_SECONDS,
        MAX_STEP_SECONDS
    )
end


--[[
Returns the horizontal speed needed to cover a step distance.

Args:
    distance (number): Step distance in studs.
    duration (number): Step duration in seconds.

Returns:
    number: Required speed in studs per second.
]]
function AttackStepRules.get_step_speed(
    distance: number,
    duration: number
): number
    if duration <= 0 then
        return 0
    end

    return math.max(0, distance) / duration
end


--[[
Clamps forward travel against a detected obstacle.

Args:
    requested_distance (number): Desired movement distance.
    obstacle_distance (number?): Raycast distance when blocked.

Returns:
    number: Safe movement distance in studs.
]]
function AttackStepRules.get_allowed_distance(
    requested_distance: number,
    obstacle_distance: number?
): number
    local requested = math.max(
        0,
        requested_distance
    )

    if obstacle_distance == nil then
        return requested
    end

    local obstacle_limit = math.max(
        0,
        obstacle_distance - WALL_MARGIN_STUDS
    )

    return math.min(
        requested,
        obstacle_limit
    )
end


return table.freeze(AttackStepRules)
