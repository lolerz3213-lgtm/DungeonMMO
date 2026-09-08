--!strict
-- Central runtime composition for Base/Dungeon Places. Studio uses deterministic in-memory
-- adapters by default; published TEST/PROD uses DataStore + shared MemoryStore namespaces.
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local DataStoreProfileAdapter = require(Adapters:WaitForChild("DataStoreProfileAdapter"))
local InMemoryMapAdapter = require(Adapters:WaitForChild("InMemoryMapAdapter"))
local InMemoryProfileAdapter = require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local MemoryStoreMapAdapter = require(Adapters:WaitForChild("MemoryStoreMapAdapter"))

local ProfileLeaseService = require(Services:WaitForChild("ProfileLeaseService"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local DungeonSessionService = require(Services:WaitForChild("DungeonSessionService"))
local ProgressionService = require(Services:WaitForChild("ProgressionService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local RewardService = require(Services:WaitForChild("RewardService"))
local AttributeService = require(Services:WaitForChild("AttributeService"))
local LoadoutService = require(Services:WaitForChild("LoadoutService"))
local SkillProgressionService = require(Services:WaitForChild("SkillProgressionService"))
local ProficiencyService = require(Services:WaitForChild("ProficiencyService"))
local IdentityService = require(Services:WaitForChild("IdentityService"))

local RuntimeServices = {}

function RuntimeServices.new(place_kind: string): any
    assert(place_kind == "Base" or place_kind == "Dungeon", "place_kind must be Base or Dungeon")

    local studio = RunService:IsStudio()
    local profile_adapter = if studio then InMemoryProfileAdapter.new() else DataStoreProfileAdapter.new()
    local lease_map = if studio then InMemoryMapAdapter.new() else MemoryStoreMapAdapter.new("ProfileLeases")
    local session_map = if studio then InMemoryMapAdapter.new() else MemoryStoreMapAdapter.new("DungeonSessions")

    local job_id = game.JobId
    local server_id = if type(job_id) == "string" and job_id ~= ""
        then place_kind .. ":" .. job_id
        else place_kind .. ":Studio:" .. HttpService:GenerateGUID(false)

    local leases = ProfileLeaseService.new(lease_map, server_id)
    local profiles = ProfileService.new(profile_adapter, leases)
    local sessions = DungeonSessionService.new(session_map)
    local progression = ProgressionService.new(profiles)
    ProgressionService.bind_default(progression)
    local inventory = InventoryService.new(profiles)
    local rewards = RewardService.new(profiles, progression, inventory, sessions)
    local attributes = AttributeService.new(profiles)
    local loadout = LoadoutService.new(profiles)
    local skills = SkillProgressionService.new(profiles, inventory, loadout)
    local proficiency = ProficiencyService.new(profiles)
    ProficiencyService.bind_default(proficiency)
    local identity = IdentityService.new(profiles)

    return {
        IsStudio = studio,
        ServerId = server_id,
        LeaseService = leases,
        ProfileService = profiles,
        SessionService = sessions,
        ProgressionService = progression,
        InventoryService = inventory,
        RewardService = rewards,
        AttributeService = attributes,
        LoadoutService = loadout,
        SkillProgressionService = skills,
        ProficiencyService = proficiency,
        IdentityService = identity,
    }
end

return table.freeze(RuntimeServices)
