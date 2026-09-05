--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local ProgressionConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local ProgressionRuntimeState=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProgressionRuntimeState"))
local ProgressionService={}; ProgressionService.__index=ProgressionService
local function integer(v:any):boolean return type(v)=="number" and v==v and v>-math.huge and v<math.huge and v%1==0 end
local function invalid(reason:string):any return {ok=false,reason=reason,xp_granted=0,levels_gained=0} end
local function sync_entitlement(character:any)
    if type(character.Progression)~="table" then return end
    local entitlement=ProgressionConfig.level_entitlement(character.Level)
    character.Progression.AttributePointEntitlement=math.max(tonumber(character.Progression.AttributePointEntitlement) or 0,entitlement)
    character.Progression.SkillPointEntitlement=math.max(tonumber(character.Progression.SkillPointEntitlement) or 0,entitlement)
end
function ProgressionService.apply_xp_to_character(character:any,amount:number):any
    if not integer(amount) or amount<=0 then return invalid("InvalidXPAmount") end
    if type(character)~="table" or type(character.Level)~="number" or type(character.XP)~="number" then return invalid("InvalidCharacter") end
    local old=character.Level
    if character.Level>=ProgressionConfig.MAX_LEVEL then character.XP=0; sync_entitlement(character); return {ok=true,xp_granted=0,old_level=old,new_level=character.Level,levels_gained=0,carried_xp=0,at_cap=true} end
    character.XP+=amount; local gained=0
    while character.Level<ProgressionConfig.MAX_LEVEL do
        local required=ProgressionConfig.get_required_xp(character.Level); if not required or character.XP<required then break end
        character.XP-=required; character.Level+=1; gained+=1; sync_entitlement(character)
    end
    if character.Level>=ProgressionConfig.MAX_LEVEL then character.XP=0 end
    sync_entitlement(character)
    return {ok=true,reason=nil,xp_granted=amount,old_level=old,new_level=character.Level,levels_gained=gained,carried_xp=character.XP,at_cap=character.Level>=ProgressionConfig.MAX_LEVEL}
end
function ProgressionService.new(profile_service:any):any assert(profile_service,"ProgressionService requires ProfileService."); return setmetatable({_profiles=profile_service},ProgressionService) end
function ProgressionService:grant_xp(user_id:number,amount:number):any
    if not integer(amount) or amount<=0 then return invalid("InvalidXPAmount") end
    local result:any=nil
    local ok,err=self._profiles:mutate(user_id,function(profile:any)
        local character=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; if not character then error("Selected character slot is missing") end
        result=ProgressionService.apply_xp_to_character(character,amount); if result.ok~=true then error(result.reason or "XPApplyFailed") end
    end)
    if not ok then return invalid(err or "ProfileMutationFailed") end
    local character=self._profiles:get_character(user_id); if character then ProgressionRuntimeState.set_character(user_id,character) end
    return result
end
return table.freeze(ProgressionService)
