local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local combat_folder = ServerScriptService:WaitForChild("Combat")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local module_script = combat_folder:FindFirstChild("CombatValidationService")
if not module_script then
    error("[Combat Validation Service Tests] RED: CombatValidationService is missing.")
end

local CombatValidationService = require(module_script)
local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    assertion_count += 1
    if not condition then
        error("[Combat Validation Service Tests] " .. message, 2)
    end
end

local payload = CombatValidationService.make_payload(
    "ATTACK",
    "ACCEPT",
    "Slash1",
    17,
    123.5
)

assert_true(payload.event == "ATTACK", "Payload must preserve event name.")
assert_true(payload.outcome == "ACCEPT", "Payload must preserve outcome.")
assert_true(payload.detail == "Slash1", "Payload must preserve detail.")
assert_true(payload.sequence_id == 17, "Payload must preserve sequence id.")
assert_true(payload.server_time == 123.5, "Payload must preserve explicit server time.")
assert_true(
    CombatConfig.REMOTES.VALIDATION_EVENT == "CombatValidationEvent",
    "Validation remote must be configured centrally."
)

local formatted = CombatValidationService.format_payload(payload)
assert_true(string.find(formatted, "ATTACK", 1, true) ~= nil, "Formatted line needs event name.")
assert_true(string.find(formatted, "ACCEPT", 1, true) ~= nil, "Formatted line needs outcome.")
assert_true(string.find(formatted, "#17", 1, true) ~= nil, "Formatted line needs sequence id.")

print(string.format("[Combat Validation Service Tests] PASS: %d assertions.", assertion_count))
