--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local AttributeConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("AttributeConfig"))
local MendService=require(ServerScriptService:WaitForChild("Combat"):WaitForChild("MendService"))
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Mend Progression Integration Tests] "..m,2) end end
local model=Instance.new("Model"); local humanoid=Instance.new("Humanoid"); humanoid.MaxHealth=100; humanoid.Health=50; humanoid.Parent=model
local base=MendService.apply_heal(humanoid,5*AttributeConfig.heal_multiplier(5)); humanoid.Health=50
local spirit=MendService.apply_heal(humanoid,5*AttributeConfig.heal_multiplier(6))
check(base==5 and spirit>base,"Spirit must scale authoritative Mend healing")
model:Destroy()
print(string.format("[Mend Progression Integration Tests] PASS: %d assertions.",n))
