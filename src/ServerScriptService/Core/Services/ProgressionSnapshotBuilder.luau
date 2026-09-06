--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local Services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")

local SkillProgressionConfig = require(Shared:WaitForChild("SkillProgressionConfig"))
local SkillDefinitions = require(Shared:WaitForChild("SkillProgressionDefinitions"))
local LoadoutSnapshot = require(Shared:WaitForChild("LoadoutSnapshot"))

local AttributeService = require(Services:WaitForChild("AttributeService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local SkillProgressionService = require(Services:WaitForChild("SkillProgressionService"))

local ProgressionSnapshotBuilder = {}

local function empty_snapshot(): any
    return {
        Level = 1,
        XP = 0,
        Gold = 0,
        APAvailable = 0,
        SPAvailable = 0,
        Attributes = {
            Strength = 5,
            Dexterity = 5,
            Vitality = 5,
            Intellect = 5,
            Spirit = 5,
        },
        Skills = {},
        Loadout = LoadoutSnapshot.encode({}),
        RespecCounters = {
            Attributes = 0,
            Skills = 0,
        },
        OneTimeRewards = {
            ArcSlashFirstClear = false,
        },
    }
end

function ProgressionSnapshotBuilder.build(character: any): any
    if type(character) ~= "table" or type(character.Progression) ~= "table" then
        return empty_snapshot()
    end

    local progression = character.Progression
    local attributes = if type(progression.Attributes) == "table"
        then progression.Attributes
        else {}
    local respec_counters = if type(progression.RespecCounters) == "table"
        then progression.RespecCounters
        else {}
    local one_time_rewards = if type(progression.OneTimeRewards) == "table"
        then progression.OneTimeRewards
        else {}

    local skill_payload: any = {}
    local skill_states = if type(progression.Skills) == "table"
        then progression.Skills
        else {}

    for skill_id, definition in pairs(SkillDefinitions.all()) do
        local state = skill_states[skill_id]
        local known = type(state) == "table" and state.Known == true
        local rank = if known
            then math.max(0, math.floor(tonumber(state.PurchasedRank) or 0))
            else 0
        local proficiency = if type(state) == "table"
            then math.max(0, tonumber(state.Proficiency) or 0)
            else 0
        local target_rank = rank + 1

        skill_payload[skill_id] = {
            Id = skill_id,
            Known = known,
            StarterGranted = type(state) == "table" and state.StarterGranted == true,
            Rank = rank,
            MaxRank = definition.MaxRank,
            Tier = definition.Tier,
            Proficiency = proficiency,
            NextThreshold = if target_rank <= definition.MaxRank
                then SkillProgressionConfig.get_threshold(definition.Tier, target_rank)
                else nil,
            NextCost = if target_rank <= definition.MaxRank
                then SkillProgressionConfig.get_rank_cost(definition.Tier, target_rank)
                else nil,
            WeaponTags = definition.WeaponTags,
            BookOwned = if skill_id == "ArcSlash"
                then InventoryService.count_item(character, "arc_slash_book_bound") > 0
                else false,
        }
    end

    return {
        Level = math.max(1, math.floor(tonumber(character.Level) or 1)),
        XP = math.max(0, math.floor(tonumber(character.XP) or 0)),
        Gold = math.max(0, math.floor(tonumber(character.Gold) or 0)),
        APAvailable = AttributeService.get_available_points(character),
        SPAvailable = SkillProgressionService.get_available_sp_for_character(character),
        Attributes = {
            Strength = tonumber(attributes.Strength) or 5,
            Dexterity = tonumber(attributes.Dexterity) or 5,
            Vitality = tonumber(attributes.Vitality) or 5,
            Intellect = tonumber(attributes.Intellect) or 5,
            Spirit = tonumber(attributes.Spirit) or 5,
        },
        Skills = skill_payload,
        Loadout = LoadoutSnapshot.encode(progression.Loadout),
        RespecCounters = {
            Attributes = math.max(0, math.floor(tonumber(respec_counters.Attributes) or 0)),
            Skills = math.max(0, math.floor(tonumber(respec_counters.Skills) or 0)),
        },
        OneTimeRewards = {
            ArcSlashFirstClear = one_time_rewards.ArcSlashFirstClear == true,
        },
    }
end

return table.freeze(ProgressionSnapshotBuilder)
