--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local module = Core:FindFirstChild("TestFailureSwitches")
if not module then
    error("[TEST Failure Switch Tests] RED: TestFailureSwitches is missing.")
end
local TestFailureSwitches = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[TEST Failure Switch Tests] " .. message, 2)
    end
end

check(
    TestFailureSwitches.is_enabled_for("TEST", true) == true,
    "TEST + true must enable a failure switch."
)
check(
    TestFailureSwitches.is_enabled_for("TEST", false) == false,
    "TEST + false must leave a failure switch disabled."
)
check(
    TestFailureSwitches.is_enabled_for("TEST", "true") == false,
    "Only a Boolean true attribute may enable a failure switch."
)
check(
    TestFailureSwitches.is_enabled_for("DEV", true) == false,
    "DEV must never enable published failure injection."
)
check(
    TestFailureSwitches.is_enabled_for("PROD", true) == false,
    "PROD must ignore TEST failure switches."
)
check(
    TestFailureSwitches.OUTBOUND_ATTRIBUTE == "DungeonMMOForceOutboundTeleportFailure",
    "Outbound failure attribute name changed unexpectedly."
)
check(
    TestFailureSwitches.RETURN_ATTRIBUTE == "DungeonMMOForceReturnTeleportFailure",
    "Return failure attribute name changed unexpectedly."
)

print(string.format("[TEST Failure Switch Tests] PASS: %d assertions.", assertions))
