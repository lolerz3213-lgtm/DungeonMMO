--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local shared=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local SkillProgressionConfig=require(shared:WaitForChild("SkillProgressionConfig"))
local SkillDefinitions=require(shared:WaitForChild("SkillProgressionDefinitions"))
local ClassDefinitions=require(shared:WaitForChild("ClassProgressionDefinitions"))
local ItemDefinitions=require(shared:WaitForChild("ItemDefinitions"))
local InventoryService=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("InventoryService"))
local ProgressionRuntimeState=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProgressionRuntimeState"))
local SkillProgressionService={}; SkillProgressionService.__index=SkillProgressionService
local function allocated(character:any):number
    local total=0
    for id,state in pairs(character.Progression.Skills) do
        if type(state)=="table" and state.Known==true then
            local def=SkillDefinitions.get(id)
            if def then
                local rank=state.PurchasedRank or 0
                for r=1,rank do if not (r==1 and state.StarterGranted==true) then total+=SkillProgressionConfig.get_rank_cost(def.Tier,r) or 0 end end
            end
        end
    end
    return total
end
function SkillProgressionService.get_allocated_sp(character:any):number return allocated(character) end
function SkillProgressionService.get_available_sp_for_character(character:any):number return math.max(0,(character.Progression.SkillPointEntitlement or 0)-allocated(character)) end
function SkillProgressionService.new(profile_service:any,inventory_service:any,loadout_service:any):any assert(profile_service and inventory_service and loadout_service); return setmetatable({_profiles=profile_service,_inventory=inventory_service,_loadout=loadout_service},SkillProgressionService) end
function SkillProgressionService:get_available_sp(user_id:number):number local c=self._profiles:get_character(user_id); return if c then SkillProgressionService.get_available_sp_for_character(c) else 0 end
function SkillProgressionService:learn_skill(user_id:number,class_id:string,skill_id:string,source_item_id:string):any
    local def=SkillDefinitions.get(skill_id); if not def then return {ok=false,reason="UnknownSkill"} end
    if not ClassDefinitions.can_teach(class_id,skill_id) then return {ok=false,reason="ClassCannotTeachSkill"} end
    local item=ItemDefinitions.get(source_item_id); if not item or item.Kind~="SkillBook" or item.SkillId~=skill_id or item.Learnable~=true then return {ok=false,reason="WrongSkillBook"} end
    local result:any=nil; local failure:string?=nil
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local p=c.Progression; local existing=p.Skills[skill_id]
        if existing and existing.Known==true then failure="AlreadyKnown"; error(failure) end
        local cost=SkillProgressionConfig.get_rank_cost(def.Tier,1) or 0
        if SkillProgressionService.get_available_sp_for_character(c)<cost then failure="InsufficientSP"; error(failure) end
        local removed=InventoryService.apply_remove_from_character(c,source_item_id,1)
        if not removed.ok then failure="SkillBookNotOwned"; error(failure) end
        local archived=if existing and type(existing.Proficiency)=="number" then existing.Proficiency else 0
        p.Skills[skill_id]={Known=true,StarterGranted=false,PurchasedRank=1,Proficiency=archived}
        result={ok=true,skill_id=skill_id,rank=1,cost=cost}
    end)
    if not ok then return {ok=false,reason=failure or err or "ProfileMutationFailed"} end
    self._loadout:auto_equip_first_free(user_id,skill_id)
    local c=self._profiles:get_character(user_id); if c then ProgressionRuntimeState.set_character(user_id,c) end
    return result
end
function SkillProgressionService:purchase_rank(user_id:number,skill_id:string):any
    local def=SkillDefinitions.get(skill_id); if not def then return {ok=false,reason="UnknownSkill"} end
    local result:any=nil; local failure:string?=nil
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local state=c.Progression.Skills[skill_id]
        if not state or state.Known~=true then failure="SkillNotKnown"; error(failure) end
        local current=state.PurchasedRank or 0; local target=current+1
        if target>def.MaxRank then failure="MaxRank"; error(failure) end
        local threshold=SkillProgressionConfig.get_threshold(def.Tier,target)
        if threshold and (state.Proficiency or 0)<threshold then failure="ProficiencyThresholdNotMet"; error(failure) end
        local cost=SkillProgressionConfig.get_rank_cost(def.Tier,target) or 0
        if SkillProgressionService.get_available_sp_for_character(c)<cost then failure="InsufficientSP"; error(failure) end
        state.PurchasedRank=target; result={ok=true,skill_id=skill_id,rank=target,cost=cost}
    end)
    if not ok then return {ok=false,reason=failure or err or "ProfileMutationFailed"} end
    if result and result.rank==1 then self._loadout:auto_equip_first_free(user_id,skill_id) end
    local c=self._profiles:get_character(user_id); if c then ProgressionRuntimeState.set_character(user_id,c) end
    return result
end
function SkillProgressionService:respec_skills(user_id:number):any
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local p=c.Progression
        for _,state in pairs(p.Skills) do if type(state)=="table" and state.Known==true then state.PurchasedRank=if state.StarterGranted==true then 1 else 0 end end
        local cleaned={}; for i=1,SkillProgressionConfig.MAX_ACTIVE_SLOTS do local id=p.Loadout[i]; local state=id and p.Skills[id]; if state and (state.PurchasedRank or 0)>=1 then cleaned[i]=id end end; p.Loadout=cleaned
        p.RespecCounters.Skills=(p.RespecCounters.Skills or 0)+1
    end)
    if not ok then return {ok=false,reason=err or "ProfileMutationFailed"} end
    local c=self._profiles:get_character(user_id); if c then ProgressionRuntimeState.set_character(user_id,c) end
    return {ok=true,available_sp=self:get_available_sp(user_id),respec_count=c and c.Progression.RespecCounters.Skills or nil}
end

function SkillProgressionService:grant_arc_slash_first_clear(user_id:number,transaction_id:string):any
    if type(transaction_id)~="string" or transaction_id=="" then return {ok=false,reason="InvalidTransactionId"} end
    local result:any=nil
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]
        local rewards=c.Progression.OneTimeRewards
        if type(rewards)~="table" then rewards={}; c.Progression.OneTimeRewards=rewards end
        if rewards.ArcSlashFirstClear==true then
            result={ok=true,already_applied=true,item_id="arc_slash_book_bound",transaction_id=transaction_id}
            return
        end
        local added=InventoryService.apply_item_to_character(c,"arc_slash_book_bound",1)
        if not added.ok then error(added.reason or "ArcSlashBookGrantFailed") end
        rewards.ArcSlashFirstClear=true
        result={ok=true,already_applied=false,item_id="arc_slash_book_bound",transaction_id=transaction_id,total_quantity=added.total_quantity}
    end)
    if not ok then return {ok=false,reason=err or "ProfileMutationFailed"} end
    local c=self._profiles:get_character(user_id)
    if c then ProgressionRuntimeState.set_character(user_id,c) end
    return result
end
return table.freeze(SkillProgressionService)
