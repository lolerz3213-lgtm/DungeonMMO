--!strict
local ServerScriptService=game:GetService("ServerScriptService")
local WardService=require(ServerScriptService:WaitForChild("Combat"):WaitForChild("WardService"))
local assertions=0
local function check(v:boolean,m:string) assertions+=1 if not v then error("[Ward Service Tests] "..m,2) end end
check(type(WardService.apply_ward)=="function","WardService must own authoritative ward application")
check(type(WardService.absorb_damage)=="function","WardService must own damage absorption")
local next_remaining,health_damage,absorbed=WardService.calculate_absorption(30,12)
check(next_remaining==18 and health_damage==0 and absorbed==12,"partial hit must be fully absorbed from ward")
next_remaining,health_damage,absorbed=WardService.calculate_absorption(10,25)
check(next_remaining==0 and health_damage==15 and absorbed==10,"overflow damage must reach health")
next_remaining,health_damage,absorbed=WardService.calculate_absorption(0,25)
check(next_remaining==0 and health_damage==25 and absorbed==0,"empty ward must absorb nothing")
print(string.format("[Ward Service Tests] PASS: %d assertions.",assertions))
