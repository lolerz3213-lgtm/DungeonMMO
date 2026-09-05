local MarauderSpacingRules = {}

local AVOIDANCE_ANGLES_DEGREES = {
    45,
    -45,
    75,
    -75,
    110,
    -110,
}
local CLEARANCE_EPSILON = 0.01


--[[Returns planar XZ distance between two world positions.]]
local function planar_distance(first: Vector3, second: Vector3): number
    local offset = Vector3.new(
        second.X - first.X,
        0,
        second.Z - first.Z
    )

    return offset.Magnitude
end


--[[Returns the nearest planar clearance to another Marauder position.]]
local function nearest_clearance(position: Vector3, others: {Vector3}): number
    local nearest = math.huge

    for _, other_position in others do
        nearest = math.min(nearest, planar_distance(position, other_position))
    end

    return nearest
end


--[[Rotates one planar movement vector around the vertical axis.]]
local function rotate_planar(movement: Vector3, degrees: number): Vector3
    local radians = math.rad(degrees)
    local cosine = math.cos(radians)
    local sine = math.sin(radians)

    return Vector3.new(
        movement.X * cosine - movement.Z * sine,
        0,
        movement.X * sine + movement.Z * cosine
    )
end


--[[
Returns chase movement candidates ordered from direct to wider side steps.

Args:
    desired_movement (Vector3): Direct planar chase movement for this tick.

Returns:
    {Vector3}: Direct movement followed by left/right avoidance candidates.
]]
function MarauderSpacingRules.get_movement_candidates(
    desired_movement: Vector3
): {Vector3}
    local candidates = {desired_movement}

    for _, degrees in AVOIDANCE_ANGLES_DEGREES do
        table.insert(candidates, rotate_planar(desired_movement, degrees))
    end

    return candidates
end


--[[
Returns candidate indices with an active sidestep commitment first.

The direct chase candidate remains the first fallback, then every remaining
candidate is preserved exactly once.
]]
function MarauderSpacingRules.get_candidate_order(
    candidate_count: number,
    committed_index: number?
): {number}
    local order = {}
    local valid_commit = committed_index ~= nil
        and committed_index >= 2
        and committed_index <= candidate_count

    if valid_commit then
        table.insert(order, committed_index :: number)
    end

    for index = 1, candidate_count do
        if index ~= committed_index then
            table.insert(order, index)
        end
    end

    return order
end


--[[
Returns whether a proposed position preserves or improves enemy spacing.

When already overlapped, movement is allowed only if it increases clearance.
This lets bad starting positions recover instead of permanently deadlocking.

Args:
    current_position (Vector3): Current Marauder root position.
    candidate_position (Vector3): Proposed root position after one tick.
    other_positions ({Vector3}): Living Marauder root positions.
    minimum_separation (number): Required planar centre-to-centre spacing.

Returns:
    boolean: True when the candidate is safe or repairs an existing overlap.
]]
function MarauderSpacingRules.is_position_allowed(
    current_position: Vector3,
    candidate_position: Vector3,
    other_positions: {Vector3},
    minimum_separation: number
): boolean
    if #other_positions == 0 then
        return true
    end

    local current_clearance = nearest_clearance(
        current_position,
        other_positions
    )
    local candidate_clearance = nearest_clearance(
        candidate_position,
        other_positions
    )

    if candidate_clearance >= minimum_separation then
        return true
    end

    return current_clearance < minimum_separation
        and candidate_clearance > current_clearance + CLEARANCE_EPSILON
end


return table.freeze(MarauderSpacingRules)
