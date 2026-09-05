local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local MarauderBehaviorRules = {}


--[[
Returns whether a living player in the active prototype room may be acquired.

The Phase 1 arena is treated as one activated combat room. Distance does not
de-aggro a living target; later dungeon-room ownership will replace this
prototype room-wide flag.

Args:
    distance (number): Planar distance to the candidate in studs.

Returns:
    boolean: True for any non-negative distance while room-wide aggro is on.
]]
function MarauderBehaviorRules.can_acquire(distance: number): boolean
    return distance >= 0
        and MarauderConfig.ROOM_WIDE_AGGRO == true
end


--[[
Returns whether an already-acquired living room target remains retained.

Args:
    distance (number): Planar distance to the retained target in studs.

Returns:
    boolean: True for any non-negative distance while room-wide aggro is on.
]]
function MarauderBehaviorRules.can_retain(distance: number): boolean
    return distance >= 0
        and MarauderConfig.ROOM_WIDE_AGGRO == true
end


--[[
Classifies a valid retained target by its distance from the Marauder.

Args:
    distance (number): Planar distance to the retained target in studs.

Returns:
    string: `Ready` inside stop distance, otherwise `Chasing`.
]]
function MarauderBehaviorRules.get_range_state(distance: number): string
    if distance <= MarauderConfig.CHASE_STOP_RANGE_STUDS then
        return "Ready"
    end

    return "Chasing"
end


--[[
Calculates how far the Marauder may advance during one chase tick.

The result is capped so movement cannot step through the configured stop
range, even after a delayed or unusually long tick.

Args:
    distance (number): Current planar target distance in studs.
    delta_seconds (number): Elapsed server time for this movement tick.

Returns:
    number: Non-negative movement distance for this tick in studs.
]]
function MarauderBehaviorRules.get_chase_step(
    distance: number,
    delta_seconds: number
): number
    if delta_seconds <= 0
        or distance <= MarauderConfig.CHASE_STOP_RANGE_STUDS then
        return 0
    end

    local remaining_distance = distance
        - MarauderConfig.CHASE_STOP_RANGE_STUDS
    local speed_limited_distance =
        MarauderConfig.CHASE_SPEED_STUDS_PER_SECOND
        * delta_seconds

    return math.max(
        0,
        math.min(
            remaining_distance,
            speed_limited_distance
        )
    )
end


return table.freeze(MarauderBehaviorRules)
