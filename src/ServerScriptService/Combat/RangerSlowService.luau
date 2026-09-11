--!strict
-- Server-owned non-stacking Ranger movement slow state for NPC targets.

local RangerSlowService = {}

export type SlowRecord = {
    multiplier: number,
    expires_at: number,
}

local records: {[Model]: SlowRecord} = {}

--[[
Clears replicated Ranger slow state from one target.

Args:
    target (Model): NPC target whose slow state is removed.

Returns:
    None.
]]
function RangerSlowService.clear(target: Model)
    records[target] = nil

    if target.Parent then
        target:SetAttribute("RangerSlowMultiplier", 1)
        target:SetAttribute("RangerSlowEndsAt", 0)
    end
end

--[[
Applies or refreshes one non-stacking Ranger slow.

An active stronger slow is never weakened by a later weaker application. The
expiry is refreshed to at least the new effect duration, but multipliers are
never multiplied together.

Args:
    target (Model): Living NPC receiving the slow.
    slow_fraction (number): Requested speed reduction from zero to one.
    duration_seconds (number): Requested positive duration.

Returns:
    boolean: True when a meaningful slow is active after the request.
]]
function RangerSlowService.apply(
    target: Model,
    slow_fraction: number,
    duration_seconds: number
): boolean
    local fraction = math.clamp(
        tonumber(slow_fraction) or 0,
        0,
        0.90
    )
    local duration = math.max(
        0,
        tonumber(duration_seconds) or 0
    )

    if fraction <= 0 or duration <= 0 then
        return false
    end

    local now = os.clock()
    local requested_multiplier = 1 - fraction
    local existing = records[target]
    local multiplier = requested_multiplier
    local expires_at = now + duration

    if existing and existing.expires_at > now then
        multiplier = math.min(
            existing.multiplier,
            requested_multiplier
        )
        expires_at = math.max(
            existing.expires_at,
            expires_at
        )
    end

    local record = {
        multiplier = multiplier,
        expires_at = expires_at,
    }

    records[target] = record
    target:SetAttribute("RangerSlowMultiplier", multiplier)
    target:SetAttribute("RangerSlowEndsAt", expires_at)

    task.delay(math.max(0, expires_at - now), function()
        if records[target] ~= record then
            return
        end

        if os.clock() < record.expires_at then
            return
        end

        RangerSlowService.clear(target)
    end)

    return true
end

--[[
Returns the currently active non-stacking Ranger speed multiplier.

Expired or destroyed targets fail neutral to a multiplier of one.

Args:
    target (Model): NPC target being moved by server AI.

Returns:
    number: Current speed multiplier from 0.1 through 1.0.
]]
function RangerSlowService.get_multiplier(target: Model): number
    local record = records[target]

    if not record then
        return 1
    end

    if not target.Parent or os.clock() >= record.expires_at then
        RangerSlowService.clear(target)
        return 1
    end

    return math.clamp(record.multiplier, 0.1, 1)
end

return table.freeze(RangerSlowService)
