local CombatValidationDedupeRules = {}

export type Tracker = {
    sequence_id: number?,
    details: {[string]: boolean},
}


--[[Creates an empty per-player validation rejection tracker.]]
function CombatValidationDedupeRules.new_tracker(): Tracker
    return {
        sequence_id = nil,
        details = {},
    }
end


--[[
Returns whether a validation event should be published.

Only identical melee HIT/REJECT details are collapsed, and only within the
same authoritative attack sequence. All other diagnostics stay visible.
]]
function CombatValidationDedupeRules.should_publish(
    tracker: Tracker,
    event_name: string,
    outcome: string,
    detail: string,
    sequence_id: number?
): boolean
    if sequence_id ~= nil and tracker.sequence_id ~= sequence_id then
        tracker.sequence_id = sequence_id
        table.clear(tracker.details)
    end

    if event_name ~= "HIT"
        or outcome ~= "REJECT"
        or sequence_id == nil then
        return true
    end

    if tracker.details[detail] then
        return false
    end

    tracker.details[detail] = true
    return true
end


return table.freeze(CombatValidationDedupeRules)
