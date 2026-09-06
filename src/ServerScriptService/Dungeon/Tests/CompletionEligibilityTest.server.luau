--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local module = Dungeon:FindFirstChild("CompletionEligibilityRules")
if not module then error("[Completion Eligibility Tests] RED: CompletionEligibilityRules is missing.") end
local Rules = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Completion Eligibility Tests] " .. message, 2) end
end

local session = {
    State = "Active",
    MemberUserIds = {101, 102, 103, 104, 105},
    Members = {
        ["101"] = {UserId = 101, Connected = true, Mode = "Active"},
        ["102"] = {UserId = 102, Connected = true, Mode = "Spectating"},
        ["103"] = {UserId = 103, Connected = true, Mode = "Dead"},
        ["104"] = {UserId = 104, Connected = false, Mode = "Active"},
        ["105"] = {UserId = 105, Connected = true, Mode = "Reviving", CompletionEligibleBeforeDeath = true},
    },
}
local snapshot = Rules.build_snapshot(session, {101, 102, 103, 104, 105, 999})
check(#snapshot == 2 and snapshot[1] == 101 and snapshot[2] == 105, "Connected Active members and forced eligible Reviving members may enter completion snapshot.")
local ok_mutate = pcall(function() snapshot[2] = 999 end)
check(ok_mutate == false, "Completion snapshot must be immutable.")

session.State = "Complete"
session.CompletionRecipients = {101}
session.Members["102"].Mode = "Active"
local after_complete = Rules.build_snapshot(session, {101, 102})
check(#after_complete == 1 and after_complete[1] == 101, "Completed session must return the locked recipient snapshot, not recompute eligibility.")
print(string.format("[Completion Eligibility Tests] PASS: %d assertions.", assertions))
