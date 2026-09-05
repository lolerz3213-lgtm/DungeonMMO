local cooldowns: {[Instance]: {[string]: number}} = {}

local SkillCooldownService = {}


--[[
Returns the time source used by cooldown calculations.

Args:
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Supplied timestamp or the current process clock.
]]
local function resolve_now(supplied_now: number?): number
    return supplied_now or os.clock()
end


--[[
Returns whether one owner's skill cooldown has expired.

Args:
    owner (Instance): Runtime owner of the cooldown record.
    skill_id (string): Skill identifier.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    boolean: True when the skill may begin a new cooldown.
]]
function SkillCooldownService.is_ready(
    owner: Instance,
    skill_id: string,
    supplied_now: number?
): boolean
    return SkillCooldownService.get_remaining(
        owner,
        skill_id,
        supplied_now
    ) <= 0
end


--[[
Starts or replaces one server-owned skill cooldown.

Args:
    owner (Instance): Runtime owner of the cooldown record.
    skill_id (string): Skill identifier.
    duration (number): Cooldown duration in seconds.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Absolute process-clock expiry used by the record.
]]
function SkillCooldownService.start(
    owner: Instance,
    skill_id: string,
    duration: number,
    supplied_now: number?
): number
    assert(duration >= 0, "Cooldown duration cannot be negative.")

    local now = resolve_now(supplied_now)
    local owner_cooldowns = cooldowns[owner]

    if not owner_cooldowns then
        owner_cooldowns = {}
        cooldowns[owner] = owner_cooldowns
    end

    local expiry = now + duration
    owner_cooldowns[skill_id] = expiry

    return expiry
end


--[[
Returns the remaining server-owned cooldown for one skill.

Args:
    owner (Instance): Runtime owner of the cooldown record.
    skill_id (string): Skill identifier.
    supplied_now (number?): Optional deterministic test timestamp.

Returns:
    number: Remaining cooldown in seconds, clamped to zero.
]]
function SkillCooldownService.get_remaining(
    owner: Instance,
    skill_id: string,
    supplied_now: number?
): number
    local owner_cooldowns = cooldowns[owner]

    if not owner_cooldowns then
        return 0
    end

    local expiry = owner_cooldowns[skill_id]

    if not expiry then
        return 0
    end

    return math.max(0, expiry - resolve_now(supplied_now))
end


--[[
Removes every runtime skill cooldown owned by one instance.

Args:
    owner (Instance): Owner whose runtime cooldown data is discarded.

Returns:
    None.
]]
function SkillCooldownService.remove_owner(owner: Instance)
    cooldowns[owner] = nil
end


return table.freeze(SkillCooldownService)
