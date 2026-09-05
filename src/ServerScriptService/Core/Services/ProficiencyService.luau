--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local shared=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local SkillConfig=require(shared:WaitForChild("SkillProgressionConfig"))
local SkillDefs=require(shared:WaitForChild("SkillProgressionDefinitions"))
local ProficiencyService={}; ProficiencyService.__index=ProficiencyService
local default_service:any=nil
local function finite(v:any):boolean return type(v)=="number" and v==v and v>=0 and v<math.huge end
function ProficiencyService.bind_default(service:any) default_service=service end
function ProficiencyService.get_default():any return default_service end
function ProficiencyService.new(profile_service:any):any assert(profile_service); return setmetatable({_profiles=profile_service},ProficiencyService) end
function ProficiencyService.get_current_cap(character:any,skill_id:string):number
    local state=character.Progression.Skills[skill_id]; local def=SkillDefs.get(skill_id); if not state or not def then return 0 end
    local current=state.PurchasedRank or 0
    if current<1 then return state.Proficiency or 0 end
    local next_threshold=SkillConfig.get_threshold(def.Tier,current+1)
    return next_threshold or SkillConfig.get_max_threshold(def.Tier)
end
function ProficiencyService:grant(user_id:number,skill_id:string,units:number,context:any):any
    if not finite(units) or units<=0 then return {ok=false,reason="InvalidContribution",granted=0} end
    if type(context)~="table" or context.eligible~=true then return {ok=true,granted=0,reason="IneligibleContribution"} end
    local result:any=nil; local fail:string?=nil
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local state=c.Progression.Skills[skill_id]; local def=SkillDefs.get(skill_id)
        if not state or state.Known~=true or not def then fail="SkillNotKnown"; error(fail) end
        if (state.PurchasedRank or 0)<1 then result={ok=true,granted=0,new_value=state.Proficiency or 0,reason="SkillNotPurchased"}; return end
        local cap=ProficiencyService.get_current_cap(c,skill_id); local before=state.Proficiency or 0; local after=math.max(before,math.min(cap,before+units)); state.Proficiency=after
        result={ok=true,granted=after-before,new_value=after,cap=cap}
    end)
    if not ok then return {ok=false,reason=fail or err or "ProfileMutationFailed",granted=0} end
    return result
end
function ProficiencyService:set_for_test(user_id:number,skill_id:string,mode_or_value:any,environment:string):any
    if environment~="DEV" and environment~="TEST" then return {ok=false,reason="CommandDisabledInProd"} end
    local def=SkillDefs.get(skill_id); if not def then return {ok=false,reason="UnknownSkill"} end
    local result:any=nil; local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local state=c.Progression.Skills[skill_id]
        if not state then state={Known=false,StarterGranted=false,PurchasedRank=0,Proficiency=0}; c.Progression.Skills[skill_id]=state end
        local value:number
        if mode_or_value=="next" then value=ProficiencyService.get_current_cap(c,skill_id)
        elseif mode_or_value=="max" then value=SkillConfig.get_max_threshold(def.Tier)
        elseif type(mode_or_value)=="number" and finite(mode_or_value) then value=math.floor(mode_or_value)
        else return error("InvalidDebugValue") end
        value=math.clamp(value,0,SkillConfig.get_max_threshold(def.Tier)); state.Proficiency=value; result={ok=true,new_value=value}
    end)
    return if ok then result else {ok=false,reason=err or "ProfileMutationFailed"}
end
return table.freeze(ProficiencyService)
