--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Combat = ServerScriptService:WaitForChild("Combat")
local MarauderFactory = require(Combat:WaitForChild("MarauderFactory"))
local DungeonDefinitions = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("DungeonDefinitions"))

local MarauderCaptainFactory = {}

MarauderCaptainFactory.MAX_HEALTH = DungeonDefinitions.TEST_DUNGEON.MarauderCaptain.MaxHealth
MarauderCaptainFactory.ATTACKS = table.freeze({
    CaptainSlash = table.freeze({
        DISPLAY_NAME = "Captain Slash",
        PRESENTATION = "Normal",
        ATTACK_REACH_STUDS = 7,
        ATTACK_ARC_DEGREES = 105,
        WIND_UP_SECONDS = 0.38,
        ATTACK_LOCK_SECONDS = 0.14,
        ATTACK_INTERVAL_SECONDS = 1.35,
        HEALTH_DAMAGE = 24,
        STAMINA_DAMAGE = 32,
        TELEGRAPH_COLOR = Color3.fromRGB(218, 86, 76),
        RADIAL = false,
    }),
    CaptainHeavy = table.freeze({
        DISPLAY_NAME = "Captain Heavy",
        PRESENTATION = "Heavy",
        ATTACK_REACH_STUDS = 7.5,
        ATTACK_ARC_DEGREES = 70,
        WIND_UP_SECONDS = 0.82,
        ATTACK_LOCK_SECONDS = 0.18,
        ATTACK_INTERVAL_SECONDS = 1.7,
        HEALTH_DAMAGE = 38,
        STAMINA_DAMAGE = 55,
        TELEGRAPH_COLOR = Color3.fromRGB(244, 172, 61),
        RADIAL = false,
    }),
    CaptainShockwave = table.freeze({
        DISPLAY_NAME = "Captain Shockwave",
        PRESENTATION = "Heavy",
        ATTACK_REACH_STUDS = 11.5,
        ATTACK_ARC_DEGREES = 360,
        WIND_UP_SECONDS = 1.05,
        ATTACK_LOCK_SECONDS = 0.12,
        ATTACK_INTERVAL_SECONDS = 1.9,
        HEALTH_DAMAGE = 28,
        STAMINA_DAMAGE = 42,
        TELEGRAPH_COLOR = Color3.fromRGB(176, 94, 232),
        RADIAL = true,
    }),
})

export type CreateOptions = {
    Parent: Instance,
    SpawnCFrame: CFrame,
    EncounterId: string?,
    RewardXP: number?,
    RewardGoldMin: number?,
    RewardGoldMax: number?,
}

function MarauderCaptainFactory.create(options: CreateOptions): Model
    local captain = MarauderFactory.create({
        Parent = options.Parent,
        Name = "MarauderCaptain",
        SpawnCFrame = options.SpawnCFrame,
        SpawnIndex = 900,
        RespawnEnabled = false,
        ControllerEnabled = false,
        TargetEnabled = true,
        EncounterId = options.EncounterId or "MarauderCaptain",
        EnemyId = "MarauderCaptain",
        LifeIndex = 1,
        RewardXP = options.RewardXP or 0,
        RewardGoldMin = options.RewardGoldMin or 0,
        RewardGoldMax = options.RewardGoldMax or 0,
    })

    captain:SetAttribute("Boss", true)
    captain:SetAttribute("BossId", "MarauderCaptain")
    captain:SetAttribute("AttackTelegraph", false)
    captain:SetAttribute("AttackName", "")
    captain:SetAttribute("MarauderAIState", "Idle")
    CollectionService:AddTag(captain, "DungeonMarauderCaptain")

    local humanoid = captain:FindFirstChildOfClass("Humanoid")
    assert(humanoid ~= nil, "MarauderCaptain requires Humanoid")
    humanoid.MaxHealth = MarauderCaptainFactory.MAX_HEALTH
    humanoid.Health = MarauderCaptainFactory.MAX_HEALTH
    humanoid.DisplayName = "Marauder Captain"

    local body = captain:FindFirstChild("Body")
    if body and body:IsA("BasePart") then
        body.Color = Color3.fromRGB(92, 48, 48)
        body.Material = Enum.Material.Metal
    end
    local head = captain:FindFirstChild("Head")
    if head and head:IsA("BasePart") then head.Color = Color3.fromRGB(181, 126, 94) end

    return captain
end

return table.freeze(MarauderCaptainFactory)
