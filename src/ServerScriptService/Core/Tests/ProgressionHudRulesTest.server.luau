--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local module=Shared:FindFirstChild("ProgressionHudRules")
if not module then error("[Progression HUD Rules Tests] RED: ProgressionHudRules is missing.") end
local Rules=require(module)
local assertions=0
local function check(value:boolean,message:string) assertions+=1 if not value then error("[Progression HUD Rules Tests] "..message,2) end end
check(Rules.format_summary(1,0,0,0,0,100)=="Level 1 | XP 0/100 | Gold 0 | AP 0 | SP 0","normal levels must show XP progress.")
check(Rules.format_summary(10,0,25,9,9,nil)=="Level 10 | XP MAX | Gold 25 | AP 9 | SP 9","level cap must show XP MAX without formatting nil.")
print(string.format("[Progression HUD Rules Tests] PASS: %d assertions.",assertions))
