--!strict
local DungeonBossSpawnGuard = {}

local SESSION_ATTRIBUTE = "DungeonMMOBossSpawnSessionId"

function DungeonBossSpawnGuard.claim(
    root: Instance,
    session_id: string
): boolean
    if session_id == "" then
        return false
    end

    if root:GetAttribute(SESSION_ATTRIBUTE) == session_id then
        return false
    end

    root:SetAttribute(SESSION_ATTRIBUTE, session_id)
    return true
end

return table.freeze(DungeonBossSpawnGuard)
