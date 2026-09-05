--!strict
local BaseReturnAdmissionRules = {}

function BaseReturnAdmissionRules.validate(
    session: any,
    teleport_data: any,
    user_id: number
): any
    if type(session) ~= "table" then
        return {ok = false, reason = "SessionNotFound"}
    end
    if type(teleport_data) ~= "table" then
        return {ok = false, reason = "MissingTeleportData"}
    end
    if teleport_data.SessionId ~= session.SessionId then
        return {ok = false, reason = "SessionIdMismatch"}
    end
    if teleport_data.DungeonId ~= session.DungeonId then
        return {ok = false, reason = "DungeonIdMismatch"}
    end
    local member = if type(session.Members) == "table"
        then session.Members[tostring(user_id)]
        else nil
    if member == nil then
        return {ok = false, reason = "NotMember"}
    end
    local terminal = session.State == "Complete"
        or session.State == "Failed"
    local abandoned_active = session.State == "Active"
        and member.Abandoned == true
    if not terminal and not abandoned_active then
        return {ok = false, reason = "SessionNotReturnable"}
    end
    return {ok = true, reason = nil}
end

return table.freeze(BaseReturnAdmissionRules)
