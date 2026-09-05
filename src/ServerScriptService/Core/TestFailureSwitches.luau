--!strict
-- TEST-only published failure injection. DEV and PROD always ignore these switches.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnvironmentConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("EnvironmentConfig")
)

local TestFailureSwitches = {}

TestFailureSwitches.OUTBOUND_ATTRIBUTE = "DungeonMMOForceOutboundTeleportFailure"
TestFailureSwitches.RETURN_ATTRIBUTE = "DungeonMMOForceReturnTeleportFailure"

function TestFailureSwitches.is_enabled_for(environment: string, attribute_value: any): boolean
    return environment == "TEST" and attribute_value == true
end

function TestFailureSwitches.is_enabled(attribute_name: string): boolean
    return TestFailureSwitches.is_enabled_for(
        EnvironmentConfig.get_environment(),
        ServerScriptService:GetAttribute(attribute_name)
    )
end

return table.freeze(TestFailureSwitches)
