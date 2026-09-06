--!strict
local ServerScriptService=game:GetService("ServerScriptService")
local Core=ServerScriptService:WaitForChild("Core")
local Adapters=Core:WaitForChild("Adapters")
local Services=Core:WaitForChild("Services")
local InMemoryProfileAdapter=require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService=require(Services:WaitForChild("ProfileService"))
local LoadoutService=require(Services:WaitForChild("LoadoutService"))
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Loadout Service Tests] "..m,2) end end
local profiles=ProfileService.new(InMemoryProfileAdapter.new()); assert(profiles:load(9401))
local service=LoadoutService.new(profiles)
local c=assert(profiles:get_character(9401,1))
check(c.Progression.Loadout[1]=="ShieldBash" and c.Progression.Loadout[2]=="Mend","starter loadout must be present")
assert(profiles:mutate(9401,function(profile) local s=profile.Characters.Slot1.Progression.Skills; s.ArcSlash={Known=true,StarterGranted=false,PurchasedRank=1,Proficiency=0} end))
local equipped=service:auto_equip_first_free(9401,"ArcSlash"); c=assert(profiles:get_character(9401,1))
check(equipped==true and c.Progression.Loadout[3]=="ArcSlash","new learned skill must fill first free slot")
local invalid=service:set(9401,{"Mend","Mend"},"Base"); c=assert(profiles:get_character(9401,1))
check(invalid.ok==false and c.Progression.Loadout[1]=="ShieldBash","invalid duplicate request must preserve prior loadout")
local moved=service:move_to_slot(9401,"ShieldBash",3,"Base"); c=assert(profiles:get_character(9401,1))
check(moved.ok==true and c.Progression.Loadout[3]=="ShieldBash" and c.Progression.Loadout[1]==nil,"move must relocate a skill without duplicating it")
check(c.Progression.Loadout[2]=="Mend" and c.Progression.Loadout[3]=="ShieldBash","moving onto Arc Slash must replace the destination skill")
local moved_again=service:move_to_slot(9401,"Mend",3,"Base"); c=assert(profiles:get_character(9401,1))
check(moved_again.ok==true and c.Progression.Loadout[3]=="Mend" and c.Progression.Loadout[2]==nil,"move must use current server loadout and replace occupied destination")
local bad_slot=service:move_to_slot(9401,"ShieldBash",7,"Base")
check(bad_slot.ok==false and bad_slot.reason=="InvalidSlot","slots outside the active range must reject")
local active=service:move_to_slot(9401,"ShieldBash",1,"DungeonActive")
check(active.ok==false and active.reason=="LoadoutLockedDuringEncounter","active encounter must reject swapping")
-- Exact targets, including leading/interior gaps, must survive profile migration.
for slot=1,6 do
    local placed=service:move_to_slot(9401,"ShieldBash",slot,"Base")
    c=assert(profiles:get_character(9401,1))
    local count=0
    for _,id in pairs(c.Progression.Loadout) do if id=="ShieldBash" then count+=1 end end
    check(placed.ok and c.Progression.Loadout[slot]=="ShieldBash" and count==1,"every target must be exact and unique")
end
check(service:set(9401,{[1]="ShieldBash"},"Base").ok,"prepare deliberate gap")
check(service:move_to_slot(9401,"Mend",3,"Base").ok,"place learned skill after gap")
c=assert(profiles:get_character(9401,1))
check(c.Progression.Loadout[1]=="ShieldBash" and c.Progression.Loadout[2]==nil and c.Progression.Loadout[3]=="Mend","Slot 3 placement must preserve Slot 2 gap")
for _,slot in ipairs({0,-1,7,1.5,"3",false,math.huge,-math.huge,0/0}) do
    local rejected=service:move_to_slot(9401,"Mend",slot,"Base")
    c=assert(profiles:get_character(9401,1))
    check(not rejected.ok and rejected.reason=="InvalidSlot" and c.Progression.Loadout[3]=="Mend" and c.Progression.Loadout[1]=="ShieldBash","invalid slots must fail closed without mutation")
end
check(service:move_to_slot(9401,"Mend",nil,"Base").reason=="InvalidSlot","missing target must fail closed")
check(service:move_to_slot(9401,"Mend",6,"DungeonClear").ok,"cleared Dungeon supports atomic moves")
print(string.format("[Loadout Service Tests] PASS: %d assertions.",n))
