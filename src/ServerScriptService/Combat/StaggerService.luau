local ATTRIBUTE_NAME = "CombatStaggeredUntil"

local stagger_expiries: {[Model]: number} = {}

local StaggerService = {}


--[[
Returns the time source used by stagger calculations.

Args:
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Supplied timestamp or the current process clock.
]]
local function resolve_now(supplied_now: number?): number
    return supplied_now or os.clock()
end


--[[
Clears an expired real-time stagger if the delayed callback is still current.

Args:
    target (Model): Target whose stagger may have expired.
    expected_expiry (number): Expiry owned by the delayed callback.

Returns:
    None.
]]
local function clear_if_current(
    target: Model,
    expected_expiry: number
)
    if stagger_expiries[target] ~= expected_expiry then
        return
    end

    if os.clock() < expected_expiry then
        return
    end

    StaggerService.clear(target)
end


--[[
Applies stagger without allowing a shorter refresh to reduce remaining time.

Args:
    target (Model): NPC combat target receiving stagger.
    duration (number): Requested stagger duration in seconds.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Absolute stagger expiry stored for the target.
]]
function StaggerService.apply(
    target: Model,
    duration: number,
    supplied_now: number?
): number
    assert(duration >= 0, "Stagger duration cannot be negative.")

    local now = resolve_now(supplied_now)
    local current_expiry = stagger_expiries[target] or 0
    local requested_expiry = now + duration
    local expiry = math.max(current_expiry, requested_expiry)

    stagger_expiries[target] = expiry
    target:SetAttribute(ATTRIBUTE_NAME, expiry)

    if supplied_now == nil and duration > 0 then
        task.delay(math.max(0, expiry - now), function()
            clear_if_current(target, expiry)
        end)
    end

    return expiry
end


--[[
Returns the remaining stagger duration for one target.

Args:
    target (Model): NPC combat target being queried.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Remaining stagger in seconds, clamped to zero.
]]
function StaggerService.get_remaining(
    target: Model,
    supplied_now: number?
): number
    local expiry = stagger_expiries[target]

    if not expiry then
        return 0
    end

    return math.max(0, expiry - resolve_now(supplied_now))
end


--[[
Returns whether one target is currently staggered.

Args:
    target (Model): NPC combat target being queried.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    boolean: True while positive stagger time remains.
]]
function StaggerService.is_staggered(
    target: Model,
    supplied_now: number?
): boolean
    return StaggerService.get_remaining(target, supplied_now) > 0
end


--[[
Clears all runtime stagger state from one NPC target.

Args:
    target (Model): Target whose stagger is removed.

Returns:
    None.
]]
function StaggerService.clear(target: Model)
    stagger_expiries[target] = nil

    if target.Parent then
        target:SetAttribute(ATTRIBUTE_NAME, 0)
    end
end


return table.freeze(StaggerService)
