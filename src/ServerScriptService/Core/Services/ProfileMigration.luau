--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileSchema = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema"))
local ProgressionConfig = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local AttributeConfig = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("AttributeConfig"))
local SkillProgressionDefinitions = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("SkillProgressionDefinitions"))
local SkillProgressionConfig = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("SkillProgressionConfig"))
local ProfileMigration = {}

local function finite(v:any): boolean return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function nonneg(v:any,f:number): number if not finite(v) or v<0 then return f end return math.floor(v) end
local function positive(v:any,f:number): number if not finite(v) or v<1 then return f end return math.max(1,math.floor(v)) end
local function deep_fill(target:any, defaults:any)
    for key, default in pairs(defaults) do
        local current=target[key]
        if current==nil then target[key]=ProfileSchema.deep_clone(default)
        elseif type(default)=="table" then
            if type(current)~="table" then target[key]=ProfileSchema.deep_clone(default) else deep_fill(current,default) end
        end
    end
end
local function sanitize_attribute(v:any): number
    if not finite(v) then return AttributeConfig.BASE_VALUE end
    return math.max(AttributeConfig.BASE_VALUE, math.floor(v))
end
local function sanitize_skill_state(skill_id:string, state:any, default_state:any): any
    if type(state)~="table" then state=ProfileSchema.deep_clone(default_state or {}) end
    local def=SkillProgressionDefinitions.get(skill_id)
    local starter=state.StarterGranted==true or (default_state and default_state.StarterGranted==true)
    local known=state.Known==true or starter
    local max_rank=if def then def.MaxRank else 99
    local rank=nonneg(state.PurchasedRank, if starter then 1 else 0)
    rank=math.clamp(rank, if starter then 1 else 0, max_rank)
    if not known then rank = 0 end
    local prof=nonneg(state.Proficiency,0)
    if def then prof=math.min(prof, SkillProgressionConfig.get_max_threshold(def.Tier)) end
    return {Known=known, StarterGranted=starter, PurchasedRank=rank, Proficiency=prof}
end

function ProfileMigration.migrate(raw:any): any
    if type(raw)=="table" and type(raw.SchemaVersion)=="number" and raw.SchemaVersion>ProfileSchema.VERSION then
        error(string.format("Profile schema %s is newer than supported schema %d.",tostring(raw.SchemaVersion),ProfileSchema.VERSION))
    end
    local original_loadout = nil
    if type(raw) == "table"
        and type(raw.Characters) == "table"
        and type(raw.Characters.Slot1) == "table"
        and type(raw.Characters.Slot1.Progression) == "table"
        and type(raw.Characters.Slot1.Progression.Loadout) == "table"
    then
        original_loadout = ProfileSchema.deep_clone(raw.Characters.Slot1.Progression.Loadout)
    end
    local migrated=if type(raw)=="table" then ProfileSchema.deep_clone(raw) else {}
    local defaults=ProfileSchema.create_default(0)
    deep_fill(migrated,defaults)
    migrated.SchemaVersion=ProfileSchema.VERSION
    if type(migrated.Account)~="table" then migrated.Account=ProfileSchema.deep_clone(defaults.Account) end
    migrated.Account.SelectedCharacterSlot=1
    if type(migrated.Characters)~="table" then migrated.Characters=ProfileSchema.deep_clone(defaults.Characters) end
    if type(migrated.Characters.Slot1)~="table" then migrated.Characters.Slot1=ProfileSchema.deep_clone(defaults.Characters.Slot1) end
    local slot1=migrated.Characters.Slot1
    slot1.Level=positive(slot1.Level,1)
    slot1.XP=if slot1.Level>=ProgressionConfig.MAX_LEVEL then 0 else nonneg(slot1.XP,0)
    slot1.Gold=nonneg(slot1.Gold,0)
    if type(slot1.Inventory)~="table" then slot1.Inventory={} end
    if type(slot1.DungeonProgress)~="table" then slot1.DungeonProgress={} end
    if type(slot1.RewardHistory)~="table" then slot1.RewardHistory={Completion={},Monster={}} end
    if type(slot1.RewardHistory.Completion)~="table" then slot1.RewardHistory.Completion={} end
    if type(slot1.RewardHistory.Monster)~="table" then slot1.RewardHistory.Monster={} end
    if type(slot1.Progression)~="table" then slot1.Progression=ProfileSchema.deep_clone(defaults.Characters.Slot1.Progression) end
    deep_fill(slot1.Progression, defaults.Characters.Slot1.Progression)
    local p=slot1.Progression
    if type(p.Attributes)~="table" then p.Attributes={} end
    for _,name in ipairs(AttributeConfig.get_names()) do p.Attributes[name]=sanitize_attribute(p.Attributes[name]) end
    local entitled=ProgressionConfig.level_entitlement(slot1.Level)
    p.AttributePointEntitlement=math.max(nonneg(p.AttributePointEntitlement,0),entitled)
    p.SkillPointEntitlement=math.max(nonneg(p.SkillPointEntitlement,0),entitled)
    if type(p.Skills)~="table" then p.Skills={} end
    local default_skills=defaults.Characters.Slot1.Progression.Skills
    for skill_id,default_state in pairs(default_skills) do p.Skills[skill_id]=sanitize_skill_state(skill_id,p.Skills[skill_id],default_state) end
    for skill_id,state in pairs(p.Skills) do p.Skills[skill_id]=sanitize_skill_state(skill_id,state,default_skills[skill_id]) end
    if original_loadout ~= nil then
        p.Loadout = original_loadout
    elseif type(p.Loadout) ~= "table" then
        p.Loadout = {[1] = "ShieldBash", [2] = "Mend"}
    end
    local sanitized_loadout = {}
    local seen_loadout = {}
    for i = 1, SkillProgressionConfig.MAX_ACTIVE_SLOTS do
        local skill_id = p.Loadout[i]
        if type(skill_id) == "string" and not seen_loadout[skill_id] then
            sanitized_loadout[i] = skill_id
            seen_loadout[skill_id] = true
        end
    end
    p.Loadout = sanitized_loadout
    if type(p.RespecCounters)~="table" then p.RespecCounters={} end
    p.RespecCounters.Attributes=nonneg(p.RespecCounters.Attributes,0)
    p.RespecCounters.Skills=nonneg(p.RespecCounters.Skills,0)
    if type(p.OneTimeRewards)~="table" then p.OneTimeRewards={} end
    p.OneTimeRewards.ArcSlashFirstClear=p.OneTimeRewards.ArcSlashFirstClear==true
    if type(p.ArchivedSkillKnowledge)~="table" then p.ArchivedSkillKnowledge={} end
    return migrated
end
return table.freeze(ProfileMigration)
