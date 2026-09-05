--!strict
-- Canonical persistent player-profile schema. Phase 2B progression is character-specific.
local ProfileSchema = {}
ProfileSchema.VERSION = 3

local function deep_clone(value: any, seen: {[table]: table}?): any
    if type(value) ~= "table" then return value end
    local existing_seen = seen or {}
    local cached = existing_seen[value]
    if cached then return cached end
    local clone = {}
    existing_seen[value] = clone
    for key, child in pairs(value) do clone[key] = deep_clone(child, existing_seen) end
    return clone
end

function ProfileSchema.deep_clone(value: any): any return deep_clone(value, nil) end

local function default_progression(): any
    return {
        Attributes = {Strength = 5, Dexterity = 5, Vitality = 5, Intellect = 5, Spirit = 5},
        AttributePointEntitlement = 0,
        SkillPointEntitlement = 0,
        Skills = {
            ShieldBash = {Known = true, StarterGranted = true, PurchasedRank = 1, Proficiency = 0},
            Mend = {Known = true, StarterGranted = true, PurchasedRank = 1, Proficiency = 0},
        },
        Loadout = {[1] = "ShieldBash", [2] = "Mend"},
        RespecCounters = {Attributes = 0, Skills = 0},
        OneTimeRewards = {ArcSlashFirstClear = false},
        ArchivedSkillKnowledge = {},
    }
end

function ProfileSchema.create_default(_user_id: number): any
    return {
        SchemaVersion = ProfileSchema.VERSION,
        Account = {SelectedCharacterSlot = 1},
        Characters = {Slot1 = {
            Level = 1, XP = 0, Gold = 0, Inventory = {}, DungeonProgress = {},
            RewardHistory = {Completion = {}, Monster = {}},
            Progression = default_progression(),
        }},
    }
end

return table.freeze(ProfileSchema)
