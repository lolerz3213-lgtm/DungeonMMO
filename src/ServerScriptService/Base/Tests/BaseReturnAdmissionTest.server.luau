--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Base = ServerScriptService:WaitForChild("Base")
local module = Base:FindFirstChild("BaseReturnAdmissionRules")
if not module then error("[Base Return Admission Tests] RED: BaseReturnAdmissionRules is missing.") end
local Rules = require(module)
local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Base Return Admission Tests] " .. message, 2) end
end
local session = {SessionId="s", DungeonId="TestDungeon", State="Complete", Members={["101"]={UserId=101}}}
check(Rules.validate(session, {SessionId="s", DungeonId="TestDungeon"}, 101).ok == true, "Completed member return must validate.")
check(Rules.validate(session, {SessionId="wrong", DungeonId="TestDungeon"}, 101).ok == false, "Session mismatch must reject.")
check(Rules.validate(session, {SessionId="s", DungeonId="TestDungeon"}, 999).ok == false, "Non-member must reject.")
session.State = "Active"
check(
    Rules.validate(
        session,
        {SessionId = "s", DungeonId = "TestDungeon"},
        101
    ).ok == false,
    "A non-abandoned Active session is not a Base return handoff."
)
session.Members["101"].Abandoned = true
check(
    Rules.validate(
        session,
        {SessionId = "s", DungeonId = "TestDungeon"},
        101
    ).ok == true,
    "An abandoned member may return to Base while the party "
    .. "session stays Active."
)
print(string.format("[Base Return Admission Tests] PASS: %d assertions.", assertions))
