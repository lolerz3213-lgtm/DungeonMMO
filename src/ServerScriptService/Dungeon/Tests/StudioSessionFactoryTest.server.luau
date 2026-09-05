--!strict
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("StudioSessionFactory")
if not module then
    error("[Studio Session Factory Tests] RED: StudioSessionFactory is missing.")
end
local StudioSessionFactory = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Studio Session Factory Tests] " .. message, 2) end
end

if RunService:IsStudio() then
    local created_members = nil
    local fake_sessions: any = {}
    function fake_sessions:create(dungeon_id: string, member_ids: {number}, return_place_id: number, reserved_code: string): any
        created_members = table.clone(member_ids)
        return {
            SessionId = "studio-session",
            DungeonId = dungeon_id,
            State = "Creating",
            Members = {[tostring(member_ids[1])] = {UserId = member_ids[1], Connected = false, Mode = "Active"}},
            ReturnPlaceId = return_place_id,
            ReservedAccessCode = reserved_code,
        }
    end
    function fake_sessions:get_for_user(_user_id: number): any return nil end

    local fake_player: any = {UserId = 777}
    local created = StudioSessionFactory.create_for_players({fake_player}, fake_sessions)
    check(created.ok == true and created.session.SessionId == "studio-session", "Studio factory must create a generated DEV session.")
    check(created.teleport_data.SessionId == "studio-session" and created.teleport_data.DungeonId == "TestDungeon", "Studio routing data must mirror published routing IDs only.")
    check(created_members ~= nil and #created_members == 1 and created_members[1] == 777, "Studio factory must use supplied player UserIds.")
else
    check(true, "Published mode intentionally skips Studio factory execution.")
end

print(string.format("[Studio Session Factory Tests] PASS: %d assertions.", assertions))
