--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local SkillProgressionConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("SkillProgressionConfig"))
local LoadoutService={}; LoadoutService.__index=LoadoutService
local function validate_character(character:any,slots:any):any
    if type(slots)~="table" then return {ok=false,reason="InvalidLoadout"} end
    local seen:{[string]:boolean}={}; local cleaned={}
    for i=1,SkillProgressionConfig.MAX_ACTIVE_SLOTS do
        local id=slots[i]
        if id~=nil then
            if type(id)~="string" or id=="" then return {ok=false,reason="InvalidSkillId"} end
            if seen[id] then return {ok=false,reason="DuplicateSkill"} end
            local state=character.Progression.Skills[id]
            if type(state)~="table" or state.Known~=true or (state.PurchasedRank or 0)<1 then return {ok=false,reason="SkillNotPurchased"} end
            seen[id]=true; cleaned[i]=id
        end
    end
    for key in pairs(slots) do if type(key)=="number" and key>SkillProgressionConfig.MAX_ACTIVE_SLOTS and slots[key]~=nil then return {ok=false,reason="TooManySlots"} end end
    return {ok=true,slots=cleaned}
end
function LoadoutService.new(profile_service:any):any assert(profile_service); return setmetatable({_profiles=profile_service},LoadoutService) end
function LoadoutService.validate(character:any,requested_slots:any,_max_slots:number?):any return validate_character(character,requested_slots) end
function LoadoutService:auto_equip_first_free(user_id:number,skill_id:string):boolean
    local equipped=false; self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local state=c.Progression.Skills[skill_id]
        if not state or state.Known~=true or (state.PurchasedRank or 0)<1 then return end
        for _,id in pairs(c.Progression.Loadout) do if id==skill_id then equipped=true return end end
        for i=1,SkillProgressionConfig.MAX_ACTIVE_SLOTS do if c.Progression.Loadout[i]==nil then c.Progression.Loadout[i]=skill_id; equipped=true; return end end
    end); return equipped
end
function LoadoutService:set(user_id:number,requested_slots:any,context:string):any
    if context=="DungeonActive" then return {ok=false,reason="LoadoutLockedDuringEncounter"} end
    if context~="Base" and context~="DungeonClear" then return {ok=false,reason="InvalidLoadoutContext"} end
    local c=self._profiles:get_character(user_id); if not c then return {ok=false,reason="ProfileNotLoaded"} end
    local checked=validate_character(c,requested_slots); if not checked.ok then return checked end
    local ok,err=self._profiles:mutate(user_id,function(profile:any) profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)].Progression.Loadout=checked.slots end)
    return if ok then {ok=true,slots=checked.slots} else {ok=false,reason=err or "ProfileMutationFailed"}
end
return table.freeze(LoadoutService)
