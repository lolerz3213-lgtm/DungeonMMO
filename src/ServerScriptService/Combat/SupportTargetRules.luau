--!strict

export type Candidate = {
    key: any,
    is_self: boolean,
    distance: number,
    health: number,
    max_health: number,
    aim_dot: number?,
    line_of_sight: boolean?,
}

local AIM_EPSILON = 1e-6
local SupportTargetRules = {}

local function is_living_in_range(
    candidate: Candidate,
    range_studs: number
): boolean
    return candidate.max_health > 0
        and candidate.health > 0
        and (
            candidate.is_self
            or candidate.distance <= range_studs
        )
end

local function needs_healing(candidate: Candidate): boolean
    return candidate.health < candidate.max_health
end

function SupportTargetRules.choose_mend_target(
    candidates: {Candidate},
    range_studs: number
): any?
    for _, candidate in candidates do
        if candidate.is_self
            and is_living_in_range(candidate, range_studs)
            and needs_healing(candidate)
        then
            return candidate.key
        end
    end

    return nil
end

function SupportTargetRules.choose_aimed_or_self(
    candidates: {Candidate},
    range_studs: number,
    require_injured: boolean?,
    min_aim_dot: number?
): any?
    local threshold = min_aim_dot or 0.85
    local best_ally: Candidate? = nil
    local self_candidate: Candidate? = nil

    for _, candidate in candidates do
        if not is_living_in_range(candidate, range_studs) then
            continue
        end

        if require_injured == true
            and not needs_healing(candidate)
        then
            continue
        end

        if candidate.is_self then
            self_candidate = candidate
            continue
        end

        if candidate.line_of_sight == false then
            continue
        end

        local aim_dot = candidate.aim_dot or -1

        if aim_dot < threshold then
            continue
        end

        if not best_ally then
            best_ally = candidate
            continue
        end

        local best_dot = best_ally.aim_dot or -1

        if aim_dot > best_dot + AIM_EPSILON
            or (
                math.abs(aim_dot - best_dot) <= AIM_EPSILON
                and candidate.distance < best_ally.distance
            )
        then
            best_ally = candidate
        end
    end

    if best_ally then
        return best_ally.key
    end

    return if self_candidate
        then self_candidate.key
        else nil
end

function SupportTargetRules.choose_ward_target(
    candidates: {Candidate},
    range_studs: number
): any?
    return SupportTargetRules.choose_aimed_or_self(
        candidates,
        range_studs,
        false,
        0.85
    )
end

return table.freeze(SupportTargetRules)
