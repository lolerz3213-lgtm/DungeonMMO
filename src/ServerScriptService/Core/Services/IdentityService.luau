--!strict
-- Authoritative Phase 2C.A race and base-class selection.
--
-- Selection is intentionally narrow:
--   fresh: RaceSelection -> ClassSelection -> Complete
--   legacy: LegacyRaceSelection -> Complete
--
-- Existing progression is preserved during legacy race translation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local RaceDefinitions = require(
    Shared:WaitForChild("RaceDefinitions")
)

local ClassProgressionDefinitions = require(
    Shared:WaitForChild("ClassProgressionDefinitions")
)

local IdentityService = {}
IdentityService.__index = IdentityService

local NEUTRAL_ATTRIBUTE_BASE = 5
local FIGHTER_CLASS_ID = "Fighter"

local ALLOWED_RACES_BY_CLASS: {
    [string]: {[string]: boolean}
} = {
    Fighter = {
        Human = true,
        Elf = true,
    },
}

local ATTRIBUTE_NAMES = {
    "Strength",
    "Dexterity",
    "Vitality",
    "Intellect",
    "Spirit",
}

local function rejected(reason: string): any
    return {
        ok = false,
        reason = reason,
    }
end

local function succeeded(): any
    return {
        ok = true,
    }
end

local function selected_character(profile: any): any
    local selected_slot =
        profile.Account.SelectedCharacterSlot

    local slot_key =
        "Slot" .. tostring(selected_slot)

    return profile.Characters[slot_key]
end

local function race_is_eligible(
    race_id: string,
    class_id: string
): boolean
    local allowed_races =
        ALLOWED_RACES_BY_CLASS[class_id]

    if not allowed_races then
        return false
    end

    return allowed_races[race_id] == true
end

local function copy_attributes(
    attributes: any
): any
    return {
        Strength = attributes.Strength,
        Dexterity = attributes.Dexterity,
        Vitality = attributes.Vitality,
        Intellect = attributes.Intellect,
        Spirit = attributes.Spirit,
    }
end

local function translate_legacy_attributes(
    old_attributes: any,
    race_baseline: any
): any
    local translated = {}

    for _, attribute_name in ipairs(ATTRIBUTE_NAMES) do
        local old_value =
            old_attributes[attribute_name]
                or NEUTRAL_ATTRIBUTE_BASE

        local earned_delta =
            old_value - NEUTRAL_ATTRIBUTE_BASE

        translated[attribute_name] =
            race_baseline[attribute_name]
                + earned_delta
    end

    return translated
end

local function fighter_starter_skill(): any
    return {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 0,
    }
end

function IdentityService.new(
    profile_service: any
): any
    assert(
        profile_service ~= nil,
        "IdentityService requires ProfileService."
    )

    local self = setmetatable({}, IdentityService)
    self._profiles = profile_service

    return self
end

function IdentityService:select_race(
    user_id: number,
    race_id: string
): any
    local race_definition =
        RaceDefinitions.get(race_id)

    if not race_definition then
        return rejected("UnknownRace")
    end

    local character =
        self._profiles:get_character(user_id)

    if not character then
        return rejected("ProfileNotLoaded")
    end

    local identity = character.Identity
    local stage =
        if identity then
            identity.CreationStage
        else
            nil

    local is_fresh =
        stage == "RaceSelection"

    local is_legacy =
        stage == "LegacyRaceSelection"

    if not is_fresh and not is_legacy then
        return rejected("RaceSelectionNotAllowed")
    end

    local race_baseline =
        RaceDefinitions.get_base_attributes(
            race_id
        )

    if not race_baseline then
        return rejected("UnknownRace")
    end

    local mutation_ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local live_character =
                    selected_character(profile)

                local live_identity =
                    live_character.Identity

                local live_stage =
                    live_identity.CreationStage

                if live_stage ~= stage then
                    error("CreationStageChanged")
                end

                if is_legacy then
                    local old_attributes =
                        live_character
                            .Progression
                            .Attributes

                    live_character
                        .Progression
                        .Attributes =
                        translate_legacy_attributes(
                            old_attributes,
                            race_baseline
                        )

                    live_identity.RaceId =
                        race_id

                    live_identity.BaseClassId =
                        FIGHTER_CLASS_ID

                    live_identity.ClassId =
                        FIGHTER_CLASS_ID

                    live_identity.CreationStage =
                        "Complete"

                    return
                end

                live_character
                    .Progression
                    .Attributes =
                    copy_attributes(
                        race_baseline
                    )

                live_identity.RaceId =
                    race_id

                live_identity.BaseClassId =
                    nil

                live_identity.ClassId =
                    nil

                live_identity.CreationStage =
                    "ClassSelection"
            end
        )

    if not mutation_ok then
        if mutation_error == "ProfileNotLoaded" then
            return rejected("ProfileNotLoaded")
        end

        return rejected(
            mutation_error
                or "ProfileMutationFailed"
        )
    end

    return succeeded()
end

function IdentityService:select_base_class(
    user_id: number,
    class_id: string
): any
    local class_definition =
        ClassProgressionDefinitions.get(
            class_id
        )

    if not class_definition then
        return rejected("UnknownClass")
    end

    local character =
        self._profiles:get_character(user_id)

    if not character then
        return rejected("ProfileNotLoaded")
    end

    local identity = character.Identity

    if (
        not identity
        or identity.CreationStage
            ~= "ClassSelection"
    ) then
        return rejected(
            "ClassSelectionNotAllowed"
        )
    end

    local race_id = identity.RaceId

    if (
        type(race_id) ~= "string"
        or RaceDefinitions.get(race_id)
            == nil
        or not race_is_eligible(
            race_id,
            class_id
        )
    ) then
        return rejected(
            "RaceNotEligibleForClass"
        )
    end

    local mutation_ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local live_character =
                    selected_character(profile)

                local live_identity =
                    live_character.Identity

                if (
                    live_identity.CreationStage
                        ~= "ClassSelection"
                ) then
                    error(
                        "CreationStageChanged"
                    )
                end

                if (
                    live_identity.RaceId
                        ~= race_id
                ) then
                    error("RaceChanged")
                end

                if not race_is_eligible(
                    race_id,
                    class_id
                ) then
                    error(
                        "RaceNotEligibleForClass"
                    )
                end

                local progression =
                    live_character.Progression

                progression.Skills.ShieldBash =
                    fighter_starter_skill()

                progression.Skills.Mend =
                    fighter_starter_skill()

                progression.Loadout[1] =
                    "ShieldBash"

                progression.Loadout[2] =
                    "Mend"

                live_identity.BaseClassId =
                    class_id

                live_identity.ClassId =
                    class_id

                live_identity.CreationStage =
                    "Complete"
            end
        )

    if not mutation_ok then
        if mutation_error == "ProfileNotLoaded" then
            return rejected("ProfileNotLoaded")
        end

        return rejected(
            mutation_error
                or "ProfileMutationFailed"
        )
    end

    return succeeded()
end

return table.freeze(IdentityService)