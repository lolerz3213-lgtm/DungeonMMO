--!strict
local ServerScriptService=game:GetService("ServerScriptService")
local Core=ServerScriptService:WaitForChild("Core")
local Adapters=Core:WaitForChild("Adapters")
local Services=Core:WaitForChild("Services")
local InMemoryProfileAdapter=require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService=require(Services:WaitForChild("ProfileService"))
local ProficiencyService=require(Services:WaitForChild("ProficiencyService"))
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Proficiency Service Tests] "..m,2) end end
local profiles=ProfileService.new(InMemoryProfileAdapter.new()); assert(profiles:load(9501))
local service=ProficiencyService.new(profiles)
local a=service:grant(9501,"Mend",90,{eligible=true}); check(a.ok and a.new_value==90,"eligible contribution must grant proficiency")
local b=service:grant(9501,"Mend",20,{eligible=true}); check(b.new_value==100 and b.granted==10,"grant must clamp to next rank threshold")
local c=service:grant(9501,"Mend",20,{eligible=true}); check(c.granted==0 and c.new_value==100,"proficiency must remain capped until rank purchase")
local d=service:grant(9501,"Mend",20,{eligible=false}); check(d.granted==0,"ineligible context must grant zero")
local prod=service:set_for_test(9501,"Mend","max","PROD"); check(prod.ok==false and prod.reason=="CommandDisabledInProd","PROD test command must fail closed")
local test=service:set_for_test(9501,"Mend",0,"TEST"); check(test.ok and test.new_value==0,"TEST command must set proficiency only")
print(string.format("[Proficiency Service Tests] PASS: %d assertions.",n))
