--!strict
local DungeonAdmissionRules = {}

local function result(ok: boolean, reason: string?): any
    return {ok = ok, reason = reason}
end

function DungeonAdmissionRules.validate(
    session: any,
    teleport_data: any,
    user_id: number,
    expected_dungeon_id: string
): any
    if type(session) ~= "table" then
        return result(false, "SessionNotFound")
    end
    if type(teleport_data) ~= "table" then
        return result(false, "MissingTeleportData")
    end
    if teleport_data.SessionId ~= session.SessionId then
        return result(false, "SessionIdMismatch")
    end
    if teleport_data.DungeonId ~= expected_dungeon_id or session.DungeonId ~= expected_dungeon_id then
        return result(false, "DungeonIdMismatch")
    end
    if session.State ~= "Creating" and session.State ~= "Active" then
        return result(false, "SessionNotActive")
    end
    if type(session.Members) ~= "table" or session.Members[tostring(user_id)] == nil then
        return result(false, "NotMember")
    end
    return result(true, nil)
end

return table.freeze(DungeonAdmissionRules)
