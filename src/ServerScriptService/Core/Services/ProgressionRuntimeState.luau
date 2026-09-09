--!strict
-- Authoritative per-server combat/progression snapshot state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local AttributeConfig = require(
    Shared:WaitForChild("AttributeConfig")
)
local CharacterCombatStats = require(
    Shared:WaitForChild("CharacterCombatStats")
)
local EquipmentStatResolver = require(
    Shared:WaitForChild("EquipmentStatResolver")
)
local EquipmentPresentationRules = require(
    Shared:WaitForChild("EquipmentPresentationRules")
)
local ProfileSchema = require(
    Shared:WaitForChild("ProfileSchema")
)
local SkillProgressionDefinitions = require(
    Shared:WaitForChild("SkillProgressionDefinitions")
)

local ProgressionRuntimeState = {}

local states: {[number]: any} = {}

--[[
Builds a fresh default character used only for neutral runtime fallbacks.

Args:
    None.

Returns:
    any: Mutable default character table.
]]
local function default_character(): any
    return ProfileSchema.create_default(0).Characters.Slot1
end

--[[
Builds a detached default identity for missing runtime state.

Args:
    None.

Returns:
    any: Mutable default Identity table.
]]
local function default_identity(): any
    return ProfileSchema.deep_clone(default_character().Identity)
end

--[[
Builds detached default progression for missing runtime state.

Args:
    None.

Returns:
    any: Mutable default Progression table.
]]
local function default_progression(): any
    return ProfileSchema.deep_clone(default_character().Progression)
end

--[[
Builds detached empty Equipment for missing runtime state.

Args:
    None.

Returns:
    any: Mutable empty Equipment table.
]]
local function default_equipment(): any
    return ProfileSchema.deep_clone(default_character().Equipment)
end

--[[
Returns the current authoritative runtime state or a neutral fallback state.

Fallback state is not persisted into the state registry. It exists only so
readers fail neutral for users that have not been seeded yet.

Args:
    user_id (number): Player user ID.

Returns:
    any: Runtime state wrapper containing identity, progression and Equipment.
]]
local function state_for(user_id: number): any
    local state = states[user_id]

    if state then
        return state
    end

    local equipment = default_equipment()

    return {
        Identity = default_identity(),
        Progression = default_progression(),
        Equipment = equipment,
        EquipmentEffects = EquipmentStatResolver.resolve(equipment),
    }
end

--[[
Returns the progression portion of one runtime state.

Args:
    user_id (number): Player user ID.

Returns:
    any: Progression-shaped runtime table.
]]
local function progression_for(user_id: number): any
    return state_for(user_id).Progression
end

--[[
Returns cached resolved Equipment effects for one runtime state.

Args:
    user_id (number): Player user ID.

Returns:
    any: Frozen EquipmentStatResolver result.
]]
local function equipment_effects_for(user_id: number): any
    local state = state_for(user_id)

    if type(state.EquipmentEffects) == "table" then
        return state.EquipmentEffects
    end

    return EquipmentStatResolver.resolve(state.Equipment)
end

--[[
Seeds the authoritative per-server runtime snapshot for one character.

The character's Identity, Progression and Equipment are deep-cloned. Equipment
is resolved once at seed time so later source Inventory/Equipment mutation
cannot change an active Dungeon run until another authoritative reseed occurs.
Older accepted callers that provide only Progression remain compatible and use
neutral identity/equipment fallbacks.

Args:
    user_id (number): Player user ID whose runtime state is replaced.
    character_or_progression (any): Full character or legacy Progression table.

Returns:
    None.
]]
function ProgressionRuntimeState.set_character(
    user_id: number,
    character_or_progression: any
)
    local identity: any
    local progression: any
    local equipment: any

    if type(character_or_progression) == "table"
        and type(character_or_progression.Progression) == "table"
    then
        identity = if type(character_or_progression.Identity) == "table"
            then character_or_progression.Identity
            else default_identity()
        progression = character_or_progression.Progression
        equipment = if type(character_or_progression.Equipment) == "table"
            then character_or_progression.Equipment
            else default_equipment()
    elseif type(character_or_progression) == "table" then
        identity = default_identity()
        progression = character_or_progression
        equipment = default_equipment()
    else
        identity = default_identity()
        progression = default_progression()
        equipment = default_equipment()
    end

    local equipment_snapshot = ProfileSchema.deep_clone(equipment)

    states[user_id] = {
        Identity = ProfileSchema.deep_clone(identity),
        Progression = ProfileSchema.deep_clone(progression),
        Equipment = equipment_snapshot,
        EquipmentEffects = EquipmentStatResolver.resolve(
            equipment_snapshot
        ),
    }
end

--[[
Removes all runtime snapshot state for one user.

Args:
    user_id (number): Player user ID leaving the current server.

Returns:
    None.
]]
function ProgressionRuntimeState.clear_character(user_id: number)
    states[user_id] = nil
end

--[[
Returns the accepted Progression-shaped public runtime snapshot.

Args:
    user_id (number): Player user ID.

Returns:
    any: Deep-cloned Progression table; internal Equipment state stays
        private.
]]
function ProgressionRuntimeState.get_snapshot(user_id: number): any
    return ProfileSchema.deep_clone(progression_for(user_id))
end

--[[
Returns the authoritative runtime race ID.

Args:
    user_id (number): Player user ID.

Returns:
    string?: Stable race ID, otherwise nil.
]]
function ProgressionRuntimeState.get_race_id(user_id: number): string?
    local identity = state_for(user_id).Identity

    if type(identity) ~= "table" then
        return nil
    end

    return if type(identity.RaceId) == "string"
        then identity.RaceId
        else nil
end

--[[
Returns one authoritative runtime attribute with a neutral fallback.

Args:
    user_id (number): Player user ID.
    name (string): Attribute name.

Returns:
    number: Runtime attribute value or AttributeConfig.BASE_VALUE.
]]
function ProgressionRuntimeState.get_attribute(
    user_id: number,
    name: string
): number
    local progression = progression_for(user_id)
    local value = progression
        and progression.Attributes
        and progression.Attributes[name]

    return if type(value) == "number"
        then value
        else AttributeConfig.BASE_VALUE
end

--[[
Returns the runtime Attributes table for combat-stat calculations.

Args:
    user_id (number): Player user ID.

Returns:
    any: Attribute table or an empty neutral table.
]]
local function attributes_for(user_id: number): any
    local progression = progression_for(user_id)

    return if type(progression.Attributes) == "table"
        then progression.Attributes
        else {}
end

--[[
Returns the cached authoritative Equipment effects for a user.

Args:
    user_id (number): Player user ID.

Returns:
    any: Frozen resolved Equipment effects.
]]
function ProgressionRuntimeState.get_equipment_effects(
    user_id: number
): any
    return equipment_effects_for(user_id)
end

--[[
Returns a detached authoritative weapon-tag set derived from Equipment.

Args:
    user_id (number): Player user ID.

Returns:
    {[string]: boolean}: Copy of active runtime weapon tags.
]]
function ProgressionRuntimeState.get_weapon_tags(
    user_id: number
): {[string]: boolean}
    local effects = equipment_effects_for(user_id)
    local result: {[string]: boolean} = {}

    for tag, enabled in pairs(effects.WeaponTags or {}) do
        if type(tag) == "string" and enabled == true then
            result[tag] = true
        end
    end

    return result
end

--[[
Returns Strength scaling plus the approved Equipment physical-damage bonus.

Args:
    user_id (number): Player user ID.

Returns:
    number: Non-negative authoritative physical-damage multiplier.
]]
function ProgressionRuntimeState.get_physical_multiplier(
    user_id: number
): number
    local base_multiplier = AttributeConfig.physical_multiplier(
        ProgressionRuntimeState.get_attribute(user_id, "Strength")
    )
    local equipment_bonus = equipment_effects_for(user_id)
        .PhysicalDamageBonus

    return math.max(0, base_multiplier + equipment_bonus)
end

--[[
Returns the accepted Spirit-based healing multiplier unchanged by 2C.C gear.

Args:
    user_id (number): Player user ID.

Returns:
    number: Authoritative healing multiplier.
]]
function ProgressionRuntimeState.get_heal_multiplier(
    user_id: number
): number
    return AttributeConfig.heal_multiplier(
        ProgressionRuntimeState.get_attribute(user_id, "Spirit")
    )
end

--[[
Returns race/attribute crit chance plus the approved Equipment crit bonus.

Args:
    user_id (number): Player user ID.

Returns:
    number: Authoritative critical chance clamped from zero to one.
]]
function ProgressionRuntimeState.get_critical_chance(
    user_id: number
): number
    local base_chance = CharacterCombatStats.critical_chance(
        attributes_for(user_id),
        ProgressionRuntimeState.get_race_id(user_id)
    )
    local equipment_bonus = equipment_effects_for(user_id)
        .CriticalChanceBonus

    return math.clamp(base_chance + equipment_bonus, 0, 1)
end

--[[
Returns accepted racial critical-damage behaviour unchanged by 2C.C gear.

Args:
    user_id (number): Player user ID.

Returns:
    number: Authoritative critical-damage multiplier.
]]
function ProgressionRuntimeState.get_critical_damage_multiplier(
    user_id: number
): number
    return CharacterCombatStats.critical_damage_multiplier(
        ProgressionRuntimeState.get_race_id(user_id)
    )
end

--[[
Returns accepted racial basic-attack-rate behaviour unchanged by 2C.C gear.

Args:
    user_id (number): Player user ID.

Returns:
    number: Authoritative basic attack-rate multiplier.
]]
function ProgressionRuntimeState.get_basic_attack_rate(
    user_id: number
): number
    return CharacterCombatStats.basic_attack_rate(
        ProgressionRuntimeState.get_race_id(user_id)
    )
end

--[[
Returns racial/Vitality MaxHealth plus approved flat Equipment health.

Args:
    user_id (number): Player user ID.

Returns:
    number: Authoritative MaxHealth, never lower than one.
]]
function ProgressionRuntimeState.get_max_health(user_id: number): number
    local base_health = CharacterCombatStats.max_health(
        attributes_for(user_id),
        ProgressionRuntimeState.get_race_id(user_id)
    )
    local equipment_health = equipment_effects_for(user_id).MaxHealthFlat

    return math.max(1, base_health + equipment_health)
end

--[[
Returns the purchased rank of a known runtime skill.

Args:
    user_id (number): Player user ID.
    skill_id (string): Stable skill ID.

Returns:
    number: Purchased rank, or zero when unknown/unpurchased.
]]
function ProgressionRuntimeState.get_skill_rank(
    user_id: number,
    skill_id: string
): number
    local progression = progression_for(user_id)
    local state = progression
        and progression.Skills
        and progression.Skills[skill_id]

    if type(state) ~= "table" or state.Known ~= true then
        return 0
    end

    return math.max(
        0,
        math.floor(tonumber(state.PurchasedRank) or 0)
    )
end

--[[
Checks whether one skill ID is present in the authoritative runtime loadout.

Args:
    user_id (number): Player user ID.
    skill_id (string): Stable skill ID.

Returns:
    boolean: True when the skill is equipped in any loadout slot.
]]
function ProgressionRuntimeState.is_skill_equipped(
    user_id: number,
    skill_id: string
): boolean
    local progression = progression_for(user_id)

    if not progression or type(progression.Loadout) ~= "table" then
        return false
    end

    for _, equipped_id in pairs(progression.Loadout) do
        if equipped_id == skill_id then
            return true
        end
    end

    return false
end

--[[
Checks whether a required weapon tag exists in a tag table.

Args:
    tags (any): Authoritative runtime weapon-tag table.
    required (string): Required tag name.

Returns:
    boolean: True when the required tag is represented.
]]
local function has_weapon_tag(tags: any, required: string): boolean
    if type(tags) ~= "table" then
        return false
    end

    for key, value in pairs(tags) do
        if value == required
            or (key == required and value == true)
        then
            return true
        end
    end

    return false
end

--[[
Validates purchased/equipped/weapon requirements for an active skill.

The third argument is retained for compatibility with accepted callers, but it
is deliberately ignored for authority. Weapon-family requirements are derived
only from the server runtime Equipment snapshot.

Args:
    user_id (number): Player user ID.
    skill_id (string): Stable skill ID.
    _weapon_tags (any): Legacy caller observation; ignored for authority.

Returns:
    boolean: True when the skill is usable.
    string?: Stable rejection reason, otherwise nil.
]]
function ProgressionRuntimeState.is_skill_usable(
    user_id: number,
    skill_id: string,
    _weapon_tags: any
): (boolean, string?)
    if ProgressionRuntimeState.get_skill_rank(user_id, skill_id) < 1 then
        return false, "SkillNotPurchased"
    end

    if not ProgressionRuntimeState.is_skill_equipped(user_id, skill_id) then
        return false, "SkillNotEquipped"
    end

    local definition = SkillProgressionDefinitions.get(skill_id)

    if not definition then
        return false, "UnknownSkill"
    end

    local authoritative_tags =
        ProgressionRuntimeState.get_weapon_tags(user_id)

    for _, required in ipairs(definition.WeaponTags or {}) do
        if not has_weapon_tag(authoritative_tags, required) then
            return false, "WrongWeapon"
        end
    end

    return true, nil
end

--[[
Applies authoritative MaxHealth while preserving accepted full-health logic.

Args:
    player (Player): Player whose current Humanoid is updated.

Returns:
    None.
]]
local function apply_health(player: Player)
    local character = player.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    local previous_max = humanoid.MaxHealth
    local new_max = ProgressionRuntimeState.get_max_health(player.UserId)

    humanoid.MaxHealth = new_max

    if humanoid.Health > new_max then
        humanoid.Health = new_max
    elseif humanoid.Health >= previous_max - 0.001 then
        humanoid.Health = new_max
    end
end

--[[
Compatibility wrapper that reapplies authoritative MaxHealth only.

Args:
    player (Player): Player whose Humanoid is updated.

Returns:
    None.
]]
function ProgressionRuntimeState.apply_max_health(player: Player)
    apply_health(player)
end

--[[
Publishes authoritative runtime combat values and presentation item IDs.

Presentation IDs are written to Player attributes so Dungeon visual services
can follow server Equipment without reading profiles or owning combat stats.

Args:
    player (Player): Player receiving current runtime attributes/health.

Returns:
    None.
]]
function ProgressionRuntimeState.apply_runtime_stats(player: Player)
    local effects = equipment_effects_for(player.UserId)

    player:SetAttribute(
        EquipmentPresentationRules.WEAPON_ITEM_ATTRIBUTE,
        effects.WeaponItemId
    )
    player:SetAttribute(
        EquipmentPresentationRules.OFFHAND_ITEM_ATTRIBUTE,
        effects.OffHandItemId
    )

    local character = player.Character

    if not character then
        return
    end

    character:SetAttribute(
        "DungeonMMOBasicAttackRate",
        ProgressionRuntimeState.get_basic_attack_rate(player.UserId)
    )

    apply_health(player)
end

return table.freeze(ProgressionRuntimeState)
