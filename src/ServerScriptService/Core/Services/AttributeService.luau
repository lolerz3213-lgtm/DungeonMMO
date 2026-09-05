--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local AttributeConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("AttributeConfig"))
local ProgressionRuntimeState=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProgressionRuntimeState"))
local AttributeService={}; AttributeService.__index=AttributeService
local allowed:{[string]:boolean}={Strength=true,Dexterity=true,Vitality=true,Intellect=true,Spirit=true}
local function integer(v:any):boolean return type(v)=="number" and v==v and v>-math.huge and v<math.huge and v%1==0 end
local function evaluate(character:any, desired:any, allow_decrease:boolean):any
    if type(desired)~="table" then return {ok=false,reason="InvalidAttributes"} end
    local current=character.Progression.Attributes; local spent=0
    for name in pairs(allowed) do
        local value=desired[name]
        if not integer(value) or value<AttributeConfig.BASE_VALUE then return {ok=false,reason="InvalidAttributeValue"} end
        if not allow_decrease and value<(current[name] or AttributeConfig.BASE_VALUE) then return {ok=false,reason="DecreaseRequiresRespec"} end
        spent+=value-AttributeConfig.BASE_VALUE
    end
    for name in pairs(desired) do if not allowed[name] then return {ok=false,reason="UnknownAttribute"} end end
    local entitlement=character.Progression.AttributePointEntitlement or 0
    if spent>entitlement then return {ok=false,reason="InsufficientAttributePoints"} end
    return {ok=true,spent_points=spent,available_points=entitlement-spent,attributes=desired}
end
function AttributeService.new(profile_service:any):any assert(profile_service); return setmetatable({_profiles=profile_service},AttributeService) end
function AttributeService.get_available_points(character:any):number
    local spent=0; for _,name in ipairs(AttributeConfig.get_names()) do spent+=math.max(0,(character.Progression.Attributes[name] or 5)-5) end
    return math.max(0,(character.Progression.AttributePointEntitlement or 0)-spent)
end
function AttributeService:preview(user_id:number,desired:any):any local c=self._profiles:get_character(user_id); if not c then return {ok=false,reason="ProfileNotLoaded"} end return evaluate(c,desired,false) end
function AttributeService:commit(user_id:number,desired:any):any
    local preview=self:preview(user_id,desired); if not preview.ok then return preview end
    local result:any=nil; local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local checked=evaluate(c,desired,false); if not checked.ok then error(checked.reason) end
        c.Progression.Attributes={Strength=desired.Strength,Dexterity=desired.Dexterity,Vitality=desired.Vitality,Intellect=desired.Intellect,Spirit=desired.Spirit}; result=checked
    end)
    if not ok then return {ok=false,reason=err or "ProfileMutationFailed"} end
    local c=self._profiles:get_character(user_id); if c then ProgressionRuntimeState.set_character(user_id,c) end
    return result
end
function AttributeService:respec(user_id:number):any
    local result:any=nil; local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; local p=c.Progression
        p.Attributes={Strength=5,Dexterity=5,Vitality=5,Intellect=5,Spirit=5}; p.RespecCounters.Attributes=(p.RespecCounters.Attributes or 0)+1
        result={ok=true,available_points=p.AttributePointEntitlement,respec_count=p.RespecCounters.Attributes}
    end)
    if not ok then return {ok=false,reason=err or "ProfileMutationFailed"} end
    local c=self._profiles:get_character(user_id); if c then ProgressionRuntimeState.set_character(user_id,c) end
    return result
end
return table.freeze(AttributeService)
