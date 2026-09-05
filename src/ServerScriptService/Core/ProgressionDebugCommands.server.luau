--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local EnvironmentConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("EnvironmentConfig"))
local ProficiencyService=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProficiencyService"))
local function handle(player:Player,message:string)
    local skill,value=string.match(message,"^/prof%s+(%S+)%s+(%S+)$"); if not skill then return end
    local service=ProficiencyService.get_default(); if not service then warn("[Progression Debug] No bound ProficiencyService.") return end
    local parsed:any=value; local n=tonumber(value); if n then parsed=n end
    local environment=EnvironmentConfig.get_environment(); local result=service:set_for_test(player.UserId,skill,parsed,environment)
    if result.ok then print(string.format("[Progression Debug] %s set %s proficiency to %s.",player.Name,skill,tostring(result.new_value))) else warn(string.format("[Progression Debug] %s rejected: %s",player.Name,tostring(result.reason))) end
end
local function bind(player:Player) player.Chatted:Connect(function(message) handle(player,message) end) end
Players.PlayerAdded:Connect(bind); for _,p in ipairs(Players:GetPlayers()) do bind(p) end
