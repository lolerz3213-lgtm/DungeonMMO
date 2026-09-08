--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local ProfileSchema = require(
    shared:WaitForChild("ProfileSchema")
)

local ProgressionConfig = require(
    shared:WaitForChild("ProgressionConfig")
)

local AttributeConfig = require(
    shared:WaitForChild("AttributeConfig")
)

local SkillProgressionDefinitions = require(
    shared:WaitForChild("SkillProgressionDefinitions")
)

local SkillProgressionConfig = require(
    shared:WaitForChild("SkillProgressionConfig")
)

local RaceDefinitions = require(
    shared:WaitForChild("RaceDefinitions")
)

local CharacterIdentityRules = require(
    shared:WaitForChild("CharacterIdentityRules")
)

local ProfileMigration = {}

local IDENTITY_VERSION = 1
local FIGHTER_ID = "Fighter"

local LEGACY_STARTER_SKILLS = table.freeze({
    ShieldBash = table.freeze({
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 0,
    }),
    Mend = table.freeze({
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 0,
    }),
})

local LEGACY_STARTER_LOADOUT = table.freeze({
    [1] = "ShieldBash",
    [2] = "Mend",
})

local function finite(value: any): boolean
    return (
        type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
    )
end

local function nonnegative_integer(
    value: any,
    fallback: number
): number
    if not finite(value) or value < 0 then
        return fallback
    end

    return math.floor(value)
end

local function positive_integer(
    value: any,
    fallback: number
): number
    if not finite(value) or value < 1 then
        return fallback
    end

    return math.max(1, math.floor(value))
end

local function deep_fill(
    target: any,
    defaults: any
)
    for key, default in pairs(defaults) do
        local current = target[key]

        if current == nil then
            target[key] = ProfileSchema.deep_clone(default)
        elseif type(default) == "table" then
            if type(current) ~= "table" then
                target[key] = ProfileSchema.deep_clone(default)
            else
                deep_fill(current, default)
            end
        end
    end
end

local function known_race_id(value: any): string?
    if type(value) ~= "string" then
        return nil
    end

    if not RaceDefinitions.get(value) then
        return nil
    end

    return value
end

local function identity_copy(value: any): any
    if type(value) == "table" then
        return ProfileSchema.deep_clone(value)
    end

    return {}
end

local function set_identity(
    identity: any,
    race_id: string?,
    base_class_id: string?,
    class_id: string?,
    stage: string
): any
    identity.Version = IDENTITY_VERSION
    identity.RaceId = race_id
    identity.BaseClassId = base_class_id
    identity.ClassId = class_id
    identity.CreationStage = stage

    return identity
end

local function fresh_identity(value: any): any
    return set_identity(
        identity_copy(value),
        nil,
        nil,
        nil,
        CharacterIdentityRules.Stages.RaceSelection
    )
end

local function legacy_identity(value: any): any
    return set_identity(
        identity_copy(value),
        nil,
        FIGHTER_ID,
        FIGHTER_ID,
        CharacterIdentityRules.Stages.LegacyRaceSelection
    )
end

local function sanitize_v4_identity(value: any): any
    local identity = identity_copy(value)

    if identity.Version ~= IDENTITY_VERSION then
        return fresh_identity(identity)
    end

    local stage = identity.CreationStage

    if stage == CharacterIdentityRules.Stages.RaceSelection then
        return fresh_identity(identity)
    end

    if stage == CharacterIdentityRules.Stages.ClassSelection then
        local race_id = known_race_id(identity.RaceId)

        if not race_id then
            return fresh_identity(identity)
        end

        return set_identity(
            identity,
            race_id,
            nil,
            nil,
            CharacterIdentityRules.Stages.ClassSelection
        )
    end

    if (
        stage
        == CharacterIdentityRules.Stages.LegacyRaceSelection
    ) then
        return legacy_identity(identity)
    end

    if stage == CharacterIdentityRules.Stages.Complete then
        local race_id = known_race_id(identity.RaceId)

        if (
            not race_id
            or identity.BaseClassId ~= FIGHTER_ID
            or identity.ClassId ~= FIGHTER_ID
        ) then
            return fresh_identity(identity)
        end

        return set_identity(
            identity,
            race_id,
            FIGHTER_ID,
            FIGHTER_ID,
            CharacterIdentityRules.Stages.Complete
        )
    end

    return fresh_identity(identity)
end

local function attribute_minimum(
    identity: any,
    attribute_name: string,
    legacy_source: boolean
): number
    if legacy_source then
        return AttributeConfig.BASE_VALUE
    end

    local race_id = known_race_id(
        if type(identity) == "table"
            then identity.RaceId
            else nil
    )

    if not race_id then
        return AttributeConfig.BASE_VALUE
    end

    local baseline = RaceDefinitions.get_base_attributes(
        race_id
    )

    if (
        baseline
        and type(baseline[attribute_name]) == "number"
    ) then
        return baseline[attribute_name]
    end

    return AttributeConfig.BASE_VALUE
end

local function sanitize_attribute(
    value: any,
    minimum: number
): number
    if not finite(value) then
        return minimum
    end

    return math.max(minimum, math.floor(value))
end

local function sanitize_skill_state(
    skill_id: string,
    state: any,
    default_state: any
): any
    local cleaned = if type(state) == "table"
        then ProfileSchema.deep_clone(state)
        else ProfileSchema.deep_clone(default_state or {})

    local definition = SkillProgressionDefinitions.get(
        skill_id
    )

    local starter = (
        cleaned.StarterGranted == true
        or (
            default_state ~= nil
            and default_state.StarterGranted == true
        )
    )

    local known = cleaned.Known == true or starter

    local max_rank = if definition
        then definition.MaxRank
        else 99

    local minimum_rank = if starter then 1 else 0

    local rank = nonnegative_integer(
        cleaned.PurchasedRank,
        minimum_rank
    )

    rank = math.clamp(
        rank,
        minimum_rank,
        max_rank
    )

    if not known then
        rank = 0
    end

    local proficiency = nonnegative_integer(
        cleaned.Proficiency,
        0
    )

    if definition then
        proficiency = math.min(
            proficiency,
            SkillProgressionConfig.get_max_threshold(
                definition.Tier
            )
        )
    end

    cleaned.Known = known
    cleaned.StarterGranted = starter
    cleaned.PurchasedRank = rank
    cleaned.Proficiency = proficiency

    return cleaned
end

local function capture_original_loadout(raw: any): any?
    if (
        type(raw) == "table"
        and type(raw.Characters) == "table"
        and type(raw.Characters.Slot1) == "table"
        and type(
            raw.Characters.Slot1.Progression
        ) == "table"
        and type(
            raw.Characters.Slot1.Progression.Loadout
        ) == "table"
    ) then
        return ProfileSchema.deep_clone(
            raw.Characters.Slot1.Progression.Loadout
        )
    end

    return nil
end

local function sanitize_loadout(
    loadout: any
): any
    local source = if type(loadout) == "table"
        then loadout
        else {}

    local cleaned = {}
    local seen = {}

    for slot = 1, SkillProgressionConfig.MAX_ACTIVE_SLOTS do
        local skill_id = source[slot]

        if (
            type(skill_id) == "string"
            and not seen[skill_id]
        ) then
            cleaned[slot] = skill_id
            seen[skill_id] = true
        end
    end

    return cleaned
end

function ProfileMigration.migrate(raw: any): any
    local raw_is_table = type(raw) == "table"

    local raw_version = if raw_is_table
        then raw.SchemaVersion
        else nil

    if (
        type(raw_version) == "number"
        and raw_version > ProfileSchema.VERSION
    ) then
        error(
            string.format(
                "Profile schema %s is newer than " ..
                    "supported schema %d.",
                tostring(raw_version),
                ProfileSchema.VERSION
            )
        )
    end

    -- Only a nil storage value is genuinely new.
    -- An existing pre-v4 table represents a legacy
    -- Phase 2B-or-earlier character.
    local new_source = raw == nil

    local legacy_source = (
        raw_is_table
        and (
            type(raw_version) ~= "number"
            or raw_version < ProfileSchema.VERSION
        )
    )

    local original_loadout = capture_original_loadout(raw)

    local migrated = if raw_is_table
        then ProfileSchema.deep_clone(raw)
        else {}

    local defaults = ProfileSchema.create_default(0)

    deep_fill(migrated, defaults)

    migrated.SchemaVersion = ProfileSchema.VERSION

    if type(migrated.Account) ~= "table" then
        migrated.Account = ProfileSchema.deep_clone(
            defaults.Account
        )
    end

    migrated.Account.SelectedCharacterSlot = 1

    if type(migrated.Characters) ~= "table" then
        migrated.Characters = ProfileSchema.deep_clone(
            defaults.Characters
        )
    end

    if type(migrated.Characters.Slot1) ~= "table" then
        migrated.Characters.Slot1 = ProfileSchema.deep_clone(
            defaults.Characters.Slot1
        )
    end

    local slot1 = migrated.Characters.Slot1

    if legacy_source then
        slot1.Identity = legacy_identity(slot1.Identity)
    elseif new_source then
        slot1.Identity = fresh_identity(slot1.Identity)
    else
        slot1.Identity = sanitize_v4_identity(
            slot1.Identity
        )
    end

    slot1.Level = positive_integer(slot1.Level, 1)

    slot1.XP = if slot1.Level >= ProgressionConfig.MAX_LEVEL
        then 0
        else nonnegative_integer(slot1.XP, 0)

    slot1.Gold = nonnegative_integer(slot1.Gold, 0)

    if type(slot1.Inventory) ~= "table" then
        slot1.Inventory = {}
    end

    if type(slot1.DungeonProgress) ~= "table" then
        slot1.DungeonProgress = {}
    end

    if type(slot1.RewardHistory) ~= "table" then
        slot1.RewardHistory = {
            Completion = {},
            Monster = {},
        }
    end

    if type(slot1.RewardHistory.Completion) ~= "table" then
        slot1.RewardHistory.Completion = {}
    end

    if type(slot1.RewardHistory.Monster) ~= "table" then
        slot1.RewardHistory.Monster = {}
    end

    if type(slot1.Progression) ~= "table" then
        slot1.Progression = ProfileSchema.deep_clone(
            defaults.Characters.Slot1.Progression
        )
    end

    deep_fill(
        slot1.Progression,
        defaults.Characters.Slot1.Progression
    )

    local progression = slot1.Progression

    if type(progression.Attributes) ~= "table" then
        progression.Attributes = {}
    end

    for _, attribute_name in ipairs(
        AttributeConfig.get_names()
    ) do
        local minimum = attribute_minimum(
            slot1.Identity,
            attribute_name,
            legacy_source
        )

        progression.Attributes[attribute_name] =
            sanitize_attribute(
                progression.Attributes[attribute_name],
                minimum
            )
    end

    local entitlement = ProgressionConfig.level_entitlement(
        slot1.Level
    )

    progression.AttributePointEntitlement = math.max(
        nonnegative_integer(
            progression.AttributePointEntitlement,
            0
        ),
        entitlement
    )

    progression.SkillPointEntitlement = math.max(
        nonnegative_integer(
            progression.SkillPointEntitlement,
            0
        ),
        entitlement
    )

    if type(progression.Skills) ~= "table" then
        progression.Skills = {}
    end

    local starter_defaults = if legacy_source
        then LEGACY_STARTER_SKILLS
        else {}

    if legacy_source then
        for skill_id, default_state in pairs(
            LEGACY_STARTER_SKILLS
        ) do
            progression.Skills[skill_id] =
                sanitize_skill_state(
                    skill_id,
                    progression.Skills[skill_id],
                    default_state
                )
        end
    end

    for skill_id, state in pairs(progression.Skills) do
        progression.Skills[skill_id] =
            sanitize_skill_state(
                skill_id,
                state,
                starter_defaults[skill_id]
            )
    end

    if original_loadout ~= nil then
        progression.Loadout = original_loadout
    elseif legacy_source then
        progression.Loadout = ProfileSchema.deep_clone(
            LEGACY_STARTER_LOADOUT
        )
    elseif type(progression.Loadout) ~= "table" then
        progression.Loadout = {}
    end

    progression.Loadout = sanitize_loadout(
        progression.Loadout
    )

    if type(progression.RespecCounters) ~= "table" then
        progression.RespecCounters = {}
    end

    progression.RespecCounters.Attributes =
        nonnegative_integer(
            progression.RespecCounters.Attributes,
            0
        )

    progression.RespecCounters.Skills =
        nonnegative_integer(
            progression.RespecCounters.Skills,
            0
        )

    if type(progression.OneTimeRewards) ~= "table" then
        progression.OneTimeRewards = {}
    end

    progression.OneTimeRewards.ArcSlashFirstClear =
        progression.OneTimeRewards.ArcSlashFirstClear == true

    if (
        type(progression.ArchivedSkillKnowledge)
        ~= "table"
    ) then
        progression.ArchivedSkillKnowledge = {}
    end

    return migrated
end

return table.freeze(ProfileMigration)