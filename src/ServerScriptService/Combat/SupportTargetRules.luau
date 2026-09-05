export type Candidate = {
    key: any,
    is_self: boolean,
    distance: number,
    health: number,
    max_health: number,
}

local HEALTH_EPSILON = 1e-6

local SupportTargetRules = {}


--[[
Returns whether one candidate can receive Mend.

Args:
    candidate (Candidate): Candidate support target.
    range_studs (number): Maximum ally range from the caster.

Returns:
    boolean: True when the candidate is alive, injured, and in range.
]]
local function is_valid_candidate(
    candidate: Candidate,
    range_studs: number
): boolean
    if candidate.max_health <= 0 or candidate.health <= 0 then
        return false
    end

    if candidate.health >= candidate.max_health then
        return false
    end

    return candidate.is_self or candidate.distance <= range_studs
end


--[[
Returns whether candidate should replace current best ally.

Args:
    candidate (Candidate): New ally candidate.
    best (Candidate?): Current best ally candidate.

Returns:
    boolean: True when candidate has higher Mend priority.
]]
local function should_prefer_ally(
    candidate: Candidate,
    best: Candidate?
): boolean
    if not best then
        return true
    end

    local candidate_ratio = candidate.health / candidate.max_health
    local best_ratio = best.health / best.max_health

    if math.abs(candidate_ratio - best_ratio) > HEALTH_EPSILON then
        return candidate_ratio < best_ratio
    end

    return candidate.distance < best.distance
end


--[[
Chooses the Phase 1 Mend target from server-built candidate data.

Injured nearby allies are always preferred over the caster. Among allies,
lowest health percentage wins; equal health percentage resolves to nearest.
The caster is used only when no valid ally exists.

Args:
    candidates ({Candidate}): Server-built support candidates.
    range_studs (number): Maximum ally range from the caster.

Returns:
    any?: Candidate key selected for Mend, or nil when nobody needs healing.
]]
function SupportTargetRules.choose_mend_target(
    candidates: {Candidate},
    range_studs: number
): any?
    local best_ally: Candidate? = nil
    local self_candidate: Candidate? = nil

    for _, candidate in candidates do
        if is_valid_candidate(candidate, range_studs) then
            if candidate.is_self then
                self_candidate = candidate
            elseif should_prefer_ally(candidate, best_ally) then
                best_ally = candidate
            end
        end
    end

    if best_ally then
        return best_ally.key
    end

    return self_candidate and self_candidate.key or nil
end


return table.freeze(SupportTargetRules)
