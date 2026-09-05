--!strict
local ServerScriptService=game:GetService("ServerScriptService")
local Dungeon=ServerScriptService:WaitForChild("Dungeon")
local module=Dungeon:FindFirstChild("DungeonProgressionBridge")
if not module then error("[Dungeon Progression Bridge Tests] RED: DungeonProgressionBridge is missing.") end
local Bridge=require(module)
local grants={}
local prof={grant=function(_,uid,skill,units,ctx) table.insert(grants,{uid,skill,units,ctx}); return {ok=true,granted=units} end}
local encounter_id="Room1"
local enc={
    is_contribution_eligible=function(_,uid,_target) return uid==1 end,
    is_member_active=function(_,uid) return uid==1 end,
    get_current_id=function() return encounter_id end,
}
Bridge.bind({proficiency_service=prof,encounter_service=enc})
local target=Instance.new("Model")
local a=Bridge.award_damage({UserId=1},"ShieldBash",target,4,1)
local b=Bridge.award_damage({UserId=2},"ShieldBash",target,4,1)
local c=Bridge.award_heal({UserId=1},"Mend",{UserId=1},5)
if not (a.ok and b.granted==0 and c.ok and #grants==2) then error("[Dungeon Progression Bridge Tests] eligibility routing failed") end
local total=0
for _=1,20 do
    local r=Bridge.award_damage({UserId=1},"ShieldBash",target,10,1)
    total += r.granted or 0
end
if total>100 then error("[Dungeon Progression Bridge Tests] per-encounter skill cap exceeded") end
encounter_id="Room2"
local next_encounter=Bridge.award_damage({UserId=1},"ShieldBash",target,10,1)
if (next_encounter.granted or 0)<=0 then error("[Dungeon Progression Bridge Tests] new encounter must reset the cap") end
target:Destroy()
print("[Dungeon Progression Bridge Tests] PASS: 6 assertions.")
