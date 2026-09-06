--!strict
local ATTRIBUTE_NAMES = table.freeze({"Strength", "Dexterity", "Vitality", "Intellect", "Spirit"})
local ProgressionTrainerRules = {}

function ProgressionTrainerRules.create_attribute_preview(snapshot: any): any
    local attributes = if type(snapshot) == "table" and type(snapshot.Attributes) == "table"
        then snapshot.Attributes
        else {}
    local preview = {}
    for _, name in ipairs(ATTRIBUTE_NAMES) do
        preview[name] = math.max(5, math.floor(tonumber(attributes[name]) or 5))
    end
    return preview
end

function ProgressionTrainerRules.pending_attribute_spend(snapshot: any, preview: any): number
    local attributes = if type(snapshot) == "table" and type(snapshot.Attributes) == "table"
        then snapshot.Attributes
        else {}
    local pending = 0
    for _, name in ipairs(ATTRIBUTE_NAMES) do
        local current = math.max(5, math.floor(tonumber(attributes[name]) or 5))
        local desired = if type(preview) == "table"
            then math.max(5, math.floor(tonumber(preview[name]) or current))
            else current
        pending += math.max(0, desired - current)
    end
    return pending
end

function ProgressionTrainerRules.can_add_attribute_point(snapshot: any, preview: any): boolean
    local available = if type(snapshot) == "table" then math.max(0, math.floor(tonumber(snapshot.APAvailable) or 0)) else 0
    return ProgressionTrainerRules.pending_attribute_spend(snapshot, preview) < available
end

return table.freeze(ProgressionTrainerRules)
