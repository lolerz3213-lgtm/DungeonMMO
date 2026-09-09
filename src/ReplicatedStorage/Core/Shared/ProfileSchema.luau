--!strict
-- Canonical persistent player-profile schema.
-- Phase 2C.B adds persistent six-slot equipment.

local ProfileSchema = {}

ProfileSchema.VERSION = 5

local function deep_clone(
    value: any,
    seen: {[table]: table}?
): any
    if type(value) ~= "table" then
        return value
    end

    local existing_seen = seen or {}
    local cached = existing_seen[value]

    if cached then
        return cached
    end

    local clone = {}
    existing_seen[value] = clone

    for key, child in pairs(value) do
        clone[key] = deep_clone(child, existing_seen)
    end

    return clone
end

function ProfileSchema.deep_clone(value: any): any
    return deep_clone(value, nil)
end

local function default_identity(): any
    return {
        Version = 1,
        RaceId = nil,
        BaseClassId = nil,
        ClassId = nil,
        CreationStage = "RaceSelection",
    }
end

local function default_progression(): any
    return {
        Attributes = {
            Strength = 5,
            Dexterity = 5,
            Vitality = 5,
            Intellect = 5,
            Spirit = 5,
        },
        AttributePointEntitlement = 0,
        SkillPointEntitlement = 0,
        Skills = {},
        Loadout = {},
        RespecCounters = {
            Attributes = 0,
            Skills = 0,
        },
        OneTimeRewards = {
            ArcSlashFirstClear = false,
        },
        ArchivedSkillKnowledge = {},
    }
end

function ProfileSchema.create_default(_user_id: number): any
    return {
        SchemaVersion = ProfileSchema.VERSION,
        Account = {
            SelectedCharacterSlot = 1,
        },
        Characters = {
            Slot1 = {
                Level = 1,
                XP = 0,
                Gold = 0,
                Inventory = {},
                Equipment = {},
                DungeonProgress = {},
                RewardHistory = {
                    Completion = {},
                    Monster = {},
                },
                Identity = default_identity(),
                Progression = default_progression(),
            },
        },
    }
end

return table.freeze(ProfileSchema)
