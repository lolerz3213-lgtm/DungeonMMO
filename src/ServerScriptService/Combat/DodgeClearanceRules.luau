--!strict
local DodgeClearanceRules = {}


function DodgeClearanceRules.get_probe_size(
    root_size: Vector3,
    configured_clearance: number
): Vector3
    local padding = math.clamp(
        configured_clearance * 0.4,
        0.35,
        0.65
    )

    return Vector3.new(
        math.max(root_size.X + (padding * 2), 2.4),
        math.clamp(root_size.Y * 0.65, 1.0, 1.4),
        math.max(root_size.Z + (padding * 2), 1.8)
    )
end


function DodgeClearanceRules.get_safety_margin(
    configured_clearance: number
): number
    return math.clamp(
        configured_clearance * 0.25,
        0.15,
        0.35
    )
end


function DodgeClearanceRules.limit_speed(
    requested_speed: number,
    delta_time: number,
    hit_distance: number?,
    configured_clearance: number,
    initially_blocked: boolean
): number
    if initially_blocked then
        return 0
    end

    if hit_distance == nil then
        return requested_speed
    end

    local safe_delta = math.max(delta_time, 1 / 240)
    local allowed_distance = math.max(
        0,
        hit_distance
            - DodgeClearanceRules.get_safety_margin(
                configured_clearance
            )
    )

    return math.min(
        requested_speed,
        allowed_distance / safe_delta
    )
end


return table.freeze(DodgeClearanceRules)
