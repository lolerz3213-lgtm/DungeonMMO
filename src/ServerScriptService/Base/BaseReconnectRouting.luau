--!strict
-- Pure reconnect decision rules used by BaseRuntime and contract tests.
local BaseReconnectRouting = {}

function BaseReconnectRouting.decide(session: any?, user_id: number, now: number?): any
    local current_time = now or os.time()
    if type(session) ~= "table" then
        return {route = "Base", reason = "NoSession"}
    end
    if type(session.Members) ~= "table" then
        return {route = "Base", reason = "NotMember"}
    end
    local member = session.Members[tostring(user_id)]
    if member == nil then
        return {route = "Base", reason = "NotMember"}
    end
    if member.Abandoned == true then
        return {route = "Base", reason = "MemberAbandoned"}
    end
    if session.State ~= "Creating" and session.State ~= "Active" then
        return {route = "Base", reason = "SessionTerminal"}
    end
    if type(session.ExpiresAt) == "number" and session.ExpiresAt <= current_time then
        return {route = "Base", reason = "SessionExpired"}
    end

    return {
        route = "Dungeon",
        reason = "RecoverableSession",
        session_id = session.SessionId,
        dungeon_id = session.DungeonId,
    }
end

return table.freeze(BaseReconnectRouting)
