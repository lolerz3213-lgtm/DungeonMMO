--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Base = ServerScriptService:WaitForChild("Base")
local routing_module = Base:FindFirstChild("BaseReconnectRouting")
if not routing_module then
    error("[Base Reconnect Routing Tests] RED: BaseReconnectRouting is missing.")
end
local BaseReconnectRouting = require(routing_module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Base Reconnect Routing Tests] " .. message, 2)
    end
end

local now = 1000
local active = {
    SessionId = "active-a",
    DungeonId = "TestDungeon",
    State = "Active",
    ExpiresAt = now + 600,
    Members = {["42"] = {UserId = 42, Connected = false, Mode = "Active"}},
}
local creating = {
    SessionId = "creating-a",
    DungeonId = "TestDungeon",
    State = "Creating",
    ExpiresAt = now + 60,
    Members = {["42"] = {UserId = 42, Connected = false, Mode = "Active"}},
}
local complete = {
    SessionId = "complete-a",
    DungeonId = "TestDungeon",
    State = "Complete",
    ExpiresAt = now + 600,
    CompletionRecipients = {43},
    Members = {["42"] = {UserId = 42, Connected = false, Mode = "Spectating"}},
}

check(BaseReconnectRouting.decide(nil, 42, now).route == "Base", "Missing session must remain in Base.")
check(BaseReconnectRouting.decide(active, 42, now).route == "Dungeon", "Recoverable active member must route back to Dungeon.")
local abandoned = {
    SessionId = "active-abandoned",
    DungeonId = "TestDungeon",
    State = "Active",
    ExpiresAt = now + 600,
    Members = {
        ["42"] = {
            UserId = 42,
            Connected = false,
            Mode = "Spectating",
            Abandoned = true,
        },
    },
}
check(
    BaseReconnectRouting.decide(abandoned, 42, now).route == "Base",
    "An abandoned member must not be routed back into the dungeon."
)
check(BaseReconnectRouting.decide(creating, 42, now).route == "Dungeon", "Recoverable creating session must route to Dungeon.")
check(BaseReconnectRouting.decide(complete, 42, now).route == "Base", "Completed session must remain in Base even when disconnected player was not rewarded.")
check(BaseReconnectRouting.decide({State="Failed", Members=active.Members, ExpiresAt=now+10}, 42, now).route == "Base", "Failed session must remain in Base.")
check(BaseReconnectRouting.decide({State="Expired", Members=active.Members, ExpiresAt=now}, 42, now).route == "Base", "Expired session must remain in Base.")
check(BaseReconnectRouting.decide({State="Active", Members=active.Members, ExpiresAt=now}, 42, now).route == "Base", "Stale active session at expiry boundary must not route.")
check(BaseReconnectRouting.decide(active, 99, now).route == "Base", "Non-member must never route into a session.")

print(string.format("[Base Reconnect Routing Tests] PASS: %d assertions.", assertions))
