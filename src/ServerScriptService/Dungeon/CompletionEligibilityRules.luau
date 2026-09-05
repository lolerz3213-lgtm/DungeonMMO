--!strict
-- Authoritative completion snapshot rules. Once a session is Complete the stored snapshot wins forever.
local CompletionEligibilityRules = {}

local function immutable_copy(values: {number}): {number}
    local copied = {}
    for _, value in ipairs(values) do table.insert(copied, value) end
    table.sort(copied)
    return table.freeze(copied)
end

function CompletionEligibilityRules.build_snapshot(session: any, connected_user_ids: {number}): {number}
    if type(session) ~= "table" then return table.freeze({}) end
    if session.State == "Complete" and type(session.CompletionRecipients) == "table" then
        return immutable_copy(session.CompletionRecipients)
    end
    if session.State ~= "Active" or type(session.Members) ~= "table" then
        return table.freeze({})
    end

    local connected: {[number]: boolean} = {}
    for _, user_id in ipairs(connected_user_ids or {}) do
        if type(user_id) == "number" then connected[user_id] = true end
    end

    local recipients = {}
    for _, user_id in ipairs(session.MemberUserIds or {}) do
        local member = session.Members[tostring(user_id)]
        if connected[user_id] == true
            and member
            and member.Connected == true
            and member.Mode == "Active"
        then
            table.insert(recipients, user_id)
        end
    end
    return immutable_copy(recipients)
end

return table.freeze(CompletionEligibilityRules)
