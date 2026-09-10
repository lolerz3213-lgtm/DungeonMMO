--!strict
local Bridge = {}
local bound:any=nil
local WEIGHTS=table.freeze({[1]=1,[2]=0.5,[3]=0.25})
local PER_ENCOUNTER_SKILL_CAP=100
local awarded:{[string]:{[number]:{[string]:number}}}={}

function Bridge.bind(options:any)
    bound=options
    awarded={}
end

local function eligible(player:any,target:any):boolean
    return bound~=nil
        and bound.encounter_service~=nil
        and bound.encounter_service:is_contribution_eligible(player.UserId,target)==true
end

local function grant_capped(player:any,skill_id:string,requested_units:number,kind:string):any
    if not bound or not bound.encounter_service or not bound.proficiency_service then
        return {ok=true,granted=0,reason="IneligibleContribution"}
    end
    local encounter_id=bound.encounter_service:get_current_id()
    if type(encounter_id)~="string" or encounter_id=="" then
        return {ok=true,granted=0,reason="IneligibleContribution"}
    end
    local encounter_ledger=awarded[encounter_id]
    if not encounter_ledger then encounter_ledger={}; awarded[encounter_id]=encounter_ledger end
    local user_ledger=encounter_ledger[player.UserId]
    if not user_ledger then user_ledger={}; encounter_ledger[player.UserId]=user_ledger end
    local already=user_ledger[skill_id] or 0
    local remaining=math.max(0,PER_ENCOUNTER_SKILL_CAP-already)
    if remaining<=0 then return {ok=true,granted=0,reason="EncounterSkillCapReached"} end
    local requested=math.min(math.max(0,requested_units),remaining)
    local result=bound.proficiency_service:grant(player.UserId,skill_id,requested,{eligible=true,kind=kind,encounter_id=encounter_id})
    if result and result.ok==true then
        local granted=math.max(0,tonumber(result.granted) or 0)
        user_ledger[skill_id]=math.min(PER_ENCOUNTER_SKILL_CAP,already+granted)
    end
    return result
end

function Bridge.award_damage(player:any,skill_id:string,target:any,applied_damage:number,target_index:number?):any
    if not bound or applied_damage<=0 or not eligible(player,target) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    local index=target_index or 1
    local weight=WEIGHTS[index] or 0.1
    local units=math.min(10,math.max(1,applied_damage)*weight)
    return grant_capped(player,skill_id,units,"Damage")
end

function Bridge.award_heal(player:any,skill_id:string,target_player:any,effective_heal:number):any
    if not bound or effective_heal<=0 then return {ok=true,granted=0,reason="IneligibleContribution"} end
    if not bound.encounter_service:is_member_active(player.UserId) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    if not target_player or not bound.encounter_service:is_member_active(target_player.UserId) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    return grant_capped(player,skill_id,math.min(10,effective_heal),"Heal")
end

function Bridge.award_support(player:any,skill_id:string,target_player:any,effective_amount:number):any
    if not bound or effective_amount<=0 then return {ok=true,granted=0,reason="IneligibleContribution"} end
    if not bound.encounter_service:is_member_active(player.UserId) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    if not target_player or not bound.encounter_service:is_member_active(target_player.UserId) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    return grant_capped(player,skill_id,math.min(10,effective_amount),"Support")
end

function Bridge.award_control(player:any,skill_id:string,target:any,_control_kind:string,meaningful:boolean):any
    if not meaningful or not bound or not eligible(player,target) then return {ok=true,granted=0,reason="IneligibleContribution"} end
    return grant_capped(player,skill_id,5,"Control")
end

return Bridge
