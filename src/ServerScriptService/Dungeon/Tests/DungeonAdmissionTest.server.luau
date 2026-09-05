--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local module = Dungeon:FindFirstChild("DungeonAdmissionRules")
if not module then
    error("[Dungeon Admission Tests] RED: DungeonAdmissionRules is missing.")
end

local DungeonAdmissionRules = require(module)
local DungeonDefinitions = require(Shared:WaitForChild("DungeonDefinitions"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Dungeon Admission Tests] " .. message, 2)
    end
end

local base_session = {
    SessionId = "session-a",
    DungeonId = DungeonDefinitions.TEST_DUNGEON.Id,
    State = "Active",
    Members = {
        ["101"] = {UserId = 101, Connected = false, Mode = "Active"},
    },
}

check(DungeonAdmissionRules.validate(nil, {SessionId = "session-a", DungeonId = "TestDungeon"}, 101, "TestDungeon").reason == "SessionNotFound", "Missing session must be rejected.")
check(DungeonAdmissionRules.validate(base_session, nil, 101, "TestDungeon").reason == "MissingTeleportData", "Missing TeleportData must be rejected.")
check(DungeonAdmissionRules.validate(base_session, {SessionId = "wrong", DungeonId = "TestDungeon"}, 101, "TestDungeon").reason == "SessionIdMismatch", "Wrong SessionId must be rejected.")
check(DungeonAdmissionRules.validate(base_session, {SessionId = "session-a", DungeonId = "Other"}, 101, "TestDungeon").reason == "DungeonIdMismatch", "Wrong DungeonId must be rejected.")
check(DungeonAdmissionRules.validate(base_session, {SessionId = "session-a", DungeonId = "TestDungeon"}, 999, "TestDungeon").reason == "NotMember", "Non-member must be rejected.")

for _, terminal_state in ipairs({"Complete", "Failed", "Expired"}) do
    local session = table.clone(base_session)
    session.State = terminal_state
    check(DungeonAdmissionRules.validate(session, {SessionId = "session-a", DungeonId = "TestDungeon"}, 101, "TestDungeon").reason == "SessionNotActive", terminal_state .. " session must be rejected.")
end

local accepted = DungeonAdmissionRules.validate(base_session, {SessionId = "session-a", DungeonId = "TestDungeon"}, 101, "TestDungeon")
check(accepted.ok == true, "Valid active member admission must succeed.")

print(string.format("[Dungeon Admission Tests] PASS: %d assertions.", assertions))
