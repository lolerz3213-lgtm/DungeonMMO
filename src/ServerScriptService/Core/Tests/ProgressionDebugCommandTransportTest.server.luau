--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

if not RunService:IsStudio() then
    print("[Progression Debug Command Transport Tests] SKIP: Studio/DEV only.")
    return
end

local assertions = 0
local function expect(condition: boolean, message: string)
    assertions += 1
    assert(condition, message)
end

local level_command = TextChatService:WaitForChild(
    "DungeonMMOLevelDebugCommand",
    2
)
local proficiency_command = TextChatService:WaitForChild(
    "DungeonMMOProficiencyDebugCommand",
    2
)
local debug_request = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Remotes")
    :WaitForChild("ProgressionDebugRequest", 2)

expect(level_command ~= nil, "Level debug TextChatCommand must be registered")
expect(
    level_command ~= nil and level_command:IsA("TextChatCommand"),
    "Level debug command must use TextChatCommand"
)
expect(
    level_command ~= nil and (level_command :: TextChatCommand).PrimaryAlias == "/level",
    "Level command primary alias must be /level"
)
expect(
    level_command ~= nil and (level_command :: TextChatCommand).SecondaryAlias == "!level",
    "Level command secondary alias must remain !level"
)
expect(
    proficiency_command ~= nil,
    "Proficiency debug TextChatCommand must be registered"
)
expect(
    proficiency_command ~= nil and proficiency_command:IsA("TextChatCommand"),
    "Proficiency debug command must use TextChatCommand"
)
expect(
    proficiency_command ~= nil
        and (proficiency_command :: TextChatCommand).PrimaryAlias == "/prof",
    "Proficiency command primary alias must be /prof"
)
expect(
    proficiency_command ~= nil
        and (proficiency_command :: TextChatCommand).SecondaryAlias == "!prof",
    "Proficiency command secondary alias must remain !prof"
)
expect(debug_request ~= nil, "Command-Bar debug RemoteEvent must exist")
expect(
    debug_request ~= nil and debug_request:IsA("RemoteEvent"),
    "Command-Bar debug bridge must use a RemoteEvent"
)

print(string.format(
    "[Progression Debug Command Transport Tests] PASS: %d assertions.",
    assertions
))
