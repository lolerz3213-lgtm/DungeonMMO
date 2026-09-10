--!strict
-- Authoritative race and base-class selection.
-- Fresh characters select Race -> Base Class -> Complete. Legacy pre-race
-- characters keep the accepted one-time race translation and remain Fighter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local RaceDefinitions = require(Shared:WaitForChild("RaceDefinitions"))
local ClassProgressionDefinitions = require(Shared:WaitForChild("ClassProgressionDefinitions"))
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))

local IdentityService = {}
IdentityService.__index = IdentityService

local NEUTRAL_ATTRIBUTE_BASE = 5
local FIGHTER_CLASS_ID = "Fighter"
local ATTRIBUTE_NAMES = {"Strength", "Dexterity", "Vitality", "Intellect", "Spirit"}

local function rejected(reason: string): any
    return {ok = false, reason = reason}
end

local function succeeded(): any
    return {ok = true}
end

local function selected_character(profile: any): any
    local selected_slot = profile.Account.SelectedCharacterSlot
    return profile.Characters["Slot" .. tostring(selected_slot)]
end

local function list_contains(values: any, expected: string): boolean
    if type(values) ~= "table" then return false end
    for _, value in ipairs(values) do
        if value == expected then return true end
    end
    return false
end

local function race_is_eligible(race_id: string, class_id: string): boolean
    local class_definition = ClassProgressionDefinitions.get(class_id)
    return class_definition ~= nil
        and list_contains(class_definition.AllowedRaces, race_id)
end

local function copy_attributes(attributes: any): any
    return {
        Strength = attributes.Strength,
        Dexterity = attributes.Dexterity,
        Vitality = attributes.Vitality,
        Intellect = attributes.Intellect,
        Spirit = attributes.Spirit,
    }
end

local function translate_legacy_attributes(old_attributes: any, race_baseline: any): any
    local translated = {}
    for _, attribute_name in ipairs(ATTRIBUTE_NAMES) do
        local old_value = old_attributes[attribute_name] or NEUTRAL_ATTRIBUTE_BASE
        translated[attribute_name] = race_baseline[attribute_name]
            + (old_value - NEUTRAL_ATTRIBUTE_BASE)
    end
    return translated
end

local function starter_skill_state(): any
    return {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 0,
    }
end

local function inventory_has_item(inventory: any, item_id: string): boolean
    if type(inventory) ~= "table" then return false end
    for _, entry in ipairs(inventory) do
        if type(entry) == "table"
            and entry.ItemId == item_id
            and (tonumber(entry.Quantity) or 0) > 0 then
            return true
        end
    end
    return false
end

local function grant_class_starters(character: any, class_id: string, class_definition: any)
    local progression = character.Progression
    if type(progression.Skills) ~= "table" then progression.Skills = {} end
    if type(progression.Loadout) ~= "table" then progression.Loadout = {} end

    for index, skill_id in ipairs(class_definition.StarterSkills or {}) do
        progression.Skills[skill_id] = starter_skill_state()
        progression.Loadout[index] = skill_id
    end

    local starter_equipment = class_definition.StarterEquipment
    if type(starter_equipment) ~= "table" then return end
    if type(character.Inventory) ~= "table" then character.Inventory = {} end
    if type(character.Equipment) ~= "table" then character.Equipment = {} end

    for slot, item_id in pairs(starter_equipment) do
        if type(slot) ~= "string" or type(item_id) ~= "string" then
            error("InvalidStarterEquipment")
        end
        local definition = ItemDefinitions.get(item_id)
        if not definition or definition.Kind ~= "Equipment" or definition.Slot ~= slot then
            error("InvalidStarterEquipment")
        end
        if definition.AllowedBaseClasses
            and not list_contains(definition.AllowedBaseClasses, class_id) then
            error("InvalidStarterEquipmentClass")
        end
        if not inventory_has_item(character.Inventory, item_id) then
            table.insert(character.Inventory, {ItemId = item_id, Quantity = 1})
        end
        character.Equipment[slot] = item_id
    end
end

function IdentityService.new(profile_service: any): any
    assert(profile_service ~= nil, "IdentityService requires ProfileService.")
    local self = setmetatable({}, IdentityService)
    self._profiles = profile_service
    return self
end

function IdentityService:select_race(user_id: number, race_id: string): any
    if not RaceDefinitions.get(race_id) then return rejected("UnknownRace") end
    local character = self._profiles:get_character(user_id)
    if not character then return rejected("ProfileNotLoaded") end

    local identity = character.Identity
    local stage = if identity then identity.CreationStage else nil
    local is_fresh = stage == "RaceSelection"
    local is_legacy = stage == "LegacyRaceSelection"
    if not is_fresh and not is_legacy then return rejected("RaceSelectionNotAllowed") end

    local race_baseline = RaceDefinitions.get_base_attributes(race_id)
    if not race_baseline then return rejected("UnknownRace") end

    local mutation_ok, mutation_error = self._profiles:mutate(user_id, function(profile: any)
        local live_character = selected_character(profile)
        local live_identity = live_character.Identity
        if live_identity.CreationStage ~= stage then error("CreationStageChanged") end

        if is_legacy then
            live_character.Progression.Attributes = translate_legacy_attributes(
                live_character.Progression.Attributes,
                race_baseline
            )
            live_identity.RaceId = race_id
            live_identity.BaseClassId = FIGHTER_CLASS_ID
            live_identity.ClassId = FIGHTER_CLASS_ID
            live_identity.CreationStage = "Complete"
            return
        end

        live_character.Progression.Attributes = copy_attributes(race_baseline)
        live_identity.RaceId = race_id
        live_identity.BaseClassId = nil
        live_identity.ClassId = nil
        live_identity.CreationStage = "ClassSelection"
    end)

    if not mutation_ok then
        if mutation_error == "ProfileNotLoaded" then return rejected("ProfileNotLoaded") end
        return rejected(mutation_error or "ProfileMutationFailed")
    end
    return succeeded()
end

function IdentityService:select_base_class(user_id: number, class_id: string): any
    local class_definition = ClassProgressionDefinitions.get(class_id)
    if not class_definition then return rejected("UnknownClass") end
    local character = self._profiles:get_character(user_id)
    if not character then return rejected("ProfileNotLoaded") end

    local identity = character.Identity
    if not identity or identity.CreationStage ~= "ClassSelection" then
        return rejected("ClassSelectionNotAllowed")
    end

    local race_id = identity.RaceId
    if type(race_id) ~= "string"
        or RaceDefinitions.get(race_id) == nil
        or not race_is_eligible(race_id, class_id) then
        return rejected("RaceNotEligibleForClass")
    end

    local mutation_ok, mutation_error = self._profiles:mutate(user_id, function(profile: any)
        local live_character = selected_character(profile)
        local live_identity = live_character.Identity
        if live_identity.CreationStage ~= "ClassSelection" then error("CreationStageChanged") end
        if live_identity.RaceId ~= race_id then error("RaceChanged") end
        if not race_is_eligible(race_id, class_id) then error("RaceNotEligibleForClass") end

        grant_class_starters(live_character, class_id, class_definition)
        live_identity.BaseClassId = class_id
        live_identity.ClassId = class_id
        live_identity.CreationStage = "Complete"
    end)

    if not mutation_ok then
        if mutation_error == "ProfileNotLoaded" then return rejected("ProfileNotLoaded") end
        return rejected(mutation_error or "ProfileMutationFailed")
    end
    return succeeded()
end

return table.freeze(IdentityService)
