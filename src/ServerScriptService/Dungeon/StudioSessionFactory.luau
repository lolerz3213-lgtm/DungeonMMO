--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DungeonDefinitions = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("DungeonDefinitions")
)

local StudioSessionFactory = {}

function StudioSessionFactory.create_for_players(players: {any}, session_service: any): any
    if not RunService:IsStudio() then
        return {ok = false, reason = "StudioOnly"}
    end
    if #players < 1 or #players > DungeonDefinitions.TEST_DUNGEON.MaxPlayers then
        return {ok = false, reason = "PlayerCountOutOfRange"}
    end

    local member_ids = {}
    for _, player in ipairs(players) do
        if type(player.UserId) ~= "number" or player.UserId <= 0 then
            return {ok = false, reason = "InvalidPlayer"}
        end
        local existing = session_service:get_for_user(player.UserId)
        if existing and (existing.State == "Creating" or existing.State == "Active") then
            return {
                ok = true,
                session = existing,
                teleport_data = {SessionId = existing.SessionId, DungeonId = existing.DungeonId},
                reused = true,
            }
        end
        table.insert(member_ids, player.UserId)
    end

    local session, session_error = session_service:create(
        DungeonDefinitions.TEST_DUNGEON.Id,
        member_ids,
        0,
        "StudioReservedServer"
    )
    if not session then
        return {ok = false, reason = session_error or "SessionCreateFailed"}
    end
    return {
        ok = true,
        session = session,
        teleport_data = {SessionId = session.SessionId, DungeonId = session.DungeonId},
        reused = false,
    }
end

return table.freeze(StudioSessionFactory)
