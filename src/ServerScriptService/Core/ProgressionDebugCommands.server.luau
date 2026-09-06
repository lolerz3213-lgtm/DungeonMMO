--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local EnvironmentConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("EnvironmentConfig")
)
local Services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")
local ProficiencyService = require(Services:WaitForChild("ProficiencyService"))
local ProgressionService = require(Services:WaitForChild("ProgressionService"))
local Remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local ProgressionDebugRequest = Remotes:WaitForChild("ProgressionDebugRequest") :: RemoteEvent

local function handle_level(player: Player, target_level: any)
    local service = ProgressionService.get_default()
    if not service then
        warn("[Progression Debug] No bound ProgressionService in runtime server context.")
        return
    end

    local environment = EnvironmentConfig.get_environment()
    local result = service:set_level_for_test(
        player.UserId,
        tonumber(target_level) or 0,
        environment
    )
    if result.ok then
        print(string.format(
            "[Progression Debug] %s set prototype level to %d (AP/SP entitlement %d/%d).",
            player.Name,
            result.new_level,
            result.attribute_entitlement,
            result.skill_entitlement
        ))
    else
        warn(string.format(
            "[Progression Debug] %s level command rejected: %s",
            player.Name,
            tostring(result.reason)
        ))
    end
end

local function handle_proficiency(player: Player, skill: any, value: any)
    if type(skill) ~= "string" or skill == "" then
        warn("[Progression Debug] Proficiency request rejected: invalid skill id.")
        return
    end

    local service = ProficiencyService.get_default()
    if not service then
        warn("[Progression Debug] No bound ProficiencyService in runtime server context.")
        return
    end

    local parsed: any = value
    if type(value) == "string" then
        local number_value = tonumber(value)
        if number_value then
            parsed = number_value
        end
    end

    local environment = EnvironmentConfig.get_environment()
    local result = service:set_for_test(player.UserId, skill, parsed, environment)
    if result.ok then
        print(string.format(
            "[Progression Debug] %s set %s proficiency to %s.",
            player.Name,
            skill,
            tostring(result.new_value)
        ))
    else
        warn(string.format(
            "[Progression Debug] %s rejected: %s",
            player.Name,
            tostring(result.reason)
        ))
    end
end

local function handle_chat(player: Player, message: string)
    local level_text = string.match(message, "^[/!]level%s+(%d+)$")
    if level_text then
        handle_level(player, level_text)
        return
    end

    local skill, value = string.match(message, "^[/!]prof%s+(%S+)%s+(%S+)$")
    if skill then
        handle_proficiency(player, skill, value)
    end
end

local function get_or_create_command(
    name: string,
    primary_alias: string,
    secondary_alias: string
): TextChatCommand
    local existing = TextChatService:FindFirstChild(name)
    if existing then
        assert(existing:IsA("TextChatCommand"), name .. " must be a TextChatCommand")
        existing.PrimaryAlias = primary_alias
        existing.SecondaryAlias = secondary_alias
        existing.AutocompleteVisible = false
        existing.Enabled = true
        return existing
    end

    local command = Instance.new("TextChatCommand")
    command.Name = name
    command.PrimaryAlias = primary_alias
    command.SecondaryAlias = secondary_alias
    command.AutocompleteVisible = false
    command.Enabled = true
    command.Parent = TextChatService
    return command
end

local function connect_command(command: TextChatCommand)
    command.Triggered:Connect(function(origin_text_source: TextSource, message: string)
        local player = Players:GetPlayerByUserId(origin_text_source.UserId)
        if player then
            handle_chat(player, message)
        end
    end)
end

local environment = EnvironmentConfig.get_environment()
if environment ~= "PROD" then
    -- Primary Studio acceptance path. The client Command Bar fires this RemoteEvent,
    -- which crosses into the same runtime server context that owns the bound services.
    ProgressionDebugRequest.OnServerEvent:Connect(function(
        player: Player,
        action: any,
        first: any,
        second: any
    )
        if type(action) ~= "string" then
            warn("[Progression Debug] Command bridge rejected: invalid action.")
            return
        end

        local normalized = string.lower(action)
        if normalized == "level" then
            handle_level(player, first)
        elseif normalized == "prof" or normalized == "proficiency" then
            handle_proficiency(player, first, second)
        else
            warn(string.format(
                "[Progression Debug] Command bridge rejected unknown action: %s",
                tostring(action)
            ))
        end
    end)

    -- Retain TextChatService support for future migration away from LegacyChatService.
    connect_command(get_or_create_command(
        "DungeonMMOLevelDebugCommand",
        "/level",
        "!level"
    ))
    connect_command(get_or_create_command(
        "DungeonMMOProficiencyDebugCommand",
        "/prof",
        "!prof"
    ))

    print("[Progression Debug] DEV/TEST command bridge ready.")
end
