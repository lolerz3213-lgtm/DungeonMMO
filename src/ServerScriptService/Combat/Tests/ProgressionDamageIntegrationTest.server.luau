--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local AttributeConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("AttributeConfig"))
local DamageService=require(ServerScriptService:WaitForChild("Combat"):WaitForChild("DamageService"))
local CombatConfig=require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig"))
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Progression Damage Integration Tests] "..m,2) end end
local base=DamageService.calculate_damage(10,AttributeConfig.physical_multiplier(5))
local strong=DamageService.calculate_damage(10,AttributeConfig.physical_multiplier(6))
check(base==10 and strong>base,"Strength must scale authoritative physical damage")
check(CombatConfig.DEFENSE.DODGE_IFRAME_SECONDS==0.22,"attribute system must not change dodge i-frames")
check(CombatConfig.DEFENSE.PARRY_WINDOW_SECONDS==0.18,"attribute system must not change parry timing")
print(string.format("[Progression Damage Integration Tests] PASS: %d assertions.",n))
