--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local Shared=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local SkillProgressionConfig=require(Shared:WaitForChild("SkillProgressionConfig"))
local SkillDefinitions=require(Shared:WaitForChild("SkillProgressionDefinitions"))
local InventoryService=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("InventoryService"))
local ProgressionRuntimeState=require(ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProgressionRuntimeState"))

local LoadoutSnapshot=require(Shared:WaitForChild("LoadoutSnapshot"))

local BaseProgressionController={}; BaseProgressionController.__index=BaseProgressionController
local function failure(reason:string):any return {ok=false,reason=reason} end

function BaseProgressionController.new(options:any):any
    assert(type(options)=="table","BaseProgressionController options are required")
    assert(options.profiles and options.inventory and options.attributes and options.loadout and options.skills,"BaseProgressionController services are required")
    return setmetatable({
        _context=options.context or "Base",
        _profiles=options.profiles,
        _inventory=options.inventory,
        _attributes=options.attributes,
        _loadout=options.loadout,
        _skills=options.skills,
    },BaseProgressionController)
end

function BaseProgressionController:_base_only():any?
    if self._context~="Base" then return failure("BaseOnlyAction") end
    return nil
end

function BaseProgressionController:build_snapshot(user_id:number):any
    local c=self._profiles:get_character(user_id,1)
    if not c then return {Level=1,XP=0,APAvailable=0,SPAvailable=0,Attributes={},Skills={},Loadout={},RespecCounters={Attributes=0,Skills=0}} end
    local skill_payload:any={}
    for skill_id,definition in pairs(SkillDefinitions.all()) do
        local state=c.Progression.Skills[skill_id]
        local known=type(state)=="table" and state.Known==true
        local rank=if known then math.max(0,math.floor(tonumber(state.PurchasedRank) or 0)) else 0
        local proficiency=if type(state)=="table" then math.max(0,tonumber(state.Proficiency) or 0) else 0
        local target_rank=rank+1
        local next_threshold=if target_rank<=definition.MaxRank then SkillProgressionConfig.get_threshold(definition.Tier,target_rank) else nil
        local next_cost=if target_rank<=definition.MaxRank then SkillProgressionConfig.get_rank_cost(definition.Tier,target_rank) else nil
        skill_payload[skill_id]={
            Id=skill_id,
            Known=known,
            StarterGranted=type(state)=="table" and state.StarterGranted==true,
            Rank=rank,
            MaxRank=definition.MaxRank,
            Tier=definition.Tier,
            Proficiency=proficiency,
            NextThreshold=next_threshold,
            NextCost=next_cost,
            WeaponTags=definition.WeaponTags,
            BookOwned=if skill_id=="ArcSlash" then InventoryService.count_item(c,"arc_slash_book_bound")>0 else false,
        }
    end
    return {
        Level=c.Level,
        XP=c.XP,
        Gold=c.Gold,
        APAvailable=self._attributes.get_available_points(c),
        SPAvailable=self._skills.get_available_sp_for_character(c),
        Attributes={
            Strength=c.Progression.Attributes.Strength,
            Dexterity=c.Progression.Attributes.Dexterity,
            Vitality=c.Progression.Attributes.Vitality,
            Intellect=c.Progression.Attributes.Intellect,
            Spirit=c.Progression.Attributes.Spirit,
        },
        Skills=skill_payload,
        Loadout=LoadoutSnapshot.encode(c.Progression.Loadout),
        RespecCounters={
            Attributes=c.Progression.RespecCounters.Attributes or 0,
            Skills=c.Progression.RespecCounters.Skills or 0,
        },
        OneTimeRewards={ArcSlashFirstClear=c.Progression.OneTimeRewards.ArcSlashFirstClear==true},
    }
end

function BaseProgressionController:commit_attributes(user_id:number,desired:any):any
    local blocked=self:_base_only(); if blocked then return blocked end
    return self._attributes:commit(user_id,desired)
end
function BaseProgressionController:respec_attributes(user_id:number):any
    local blocked=self:_base_only(); if blocked then return blocked end
    return self._attributes:respec(user_id)
end
function BaseProgressionController:learn_skill(user_id:number,skill_id:string):any
    local blocked=self:_base_only(); if blocked then return blocked end
    if skill_id~="ArcSlash" then return failure("SkillNotTeachableHere") end
    return self._skills:learn_skill(user_id,"Prototype",skill_id,"arc_slash_book_bound")
end
function BaseProgressionController:purchase_rank(user_id:number,skill_id:string):any
    local blocked=self:_base_only(); if blocked then return blocked end
    return self._skills:purchase_rank(user_id,skill_id)
end
function BaseProgressionController:respec_skills(user_id:number):any
    local blocked=self:_base_only(); if blocked then return blocked end
    return self._skills:respec_skills(user_id)
end
function BaseProgressionController:set_loadout(user_id:number,slots:any):any
    local blocked=self:_base_only(); if blocked then return blocked end
    local result=self._loadout:set(user_id,slots,"Base")
    if result.ok then
        local c=self._profiles:get_character(user_id,1)
        if c then ProgressionRuntimeState.set_character(user_id,c) end
    end
    return result
end
function BaseProgressionController:move_skill_to_slot(user_id:number,skill_id:any,slot:any):any
    local blocked=self:_base_only(); if blocked then return blocked end
    local result=self._loadout:move_to_slot(user_id,skill_id,slot,"Base")
    if result.ok then
        local c=self._profiles:get_character(user_id,1)
        if c then ProgressionRuntimeState.set_character(user_id,c) end
    end
    return result
end
return table.freeze(BaseProgressionController)
