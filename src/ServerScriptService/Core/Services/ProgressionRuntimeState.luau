--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local AttributeConfig = require(
    Shared:WaitForChild(
        "AttributeConfig"
    )
)

local CharacterCombatStats = require(
    Shared:WaitForChild(
        "CharacterCombatStats"
    )
)

local ProfileSchema = require(
    Shared:WaitForChild(
        "ProfileSchema"
    )
)

local SkillProgressionDefinitions = require(
    Shared:WaitForChild(
        "SkillProgressionDefinitions"
    )
)

local ProgressionRuntimeState = {}

local states: {
    [number]: any
} = {}

local function default_character(): any
    return ProfileSchema
        .create_default(0)
        .Characters
        .Slot1
end

local function default_identity(): any
    return ProfileSchema.deep_clone(
        default_character().Identity
    )
end

local function default_progression(): any
    return ProfileSchema.deep_clone(
        default_character().Progression
    )
end

local function state_for(
    user_id: number
): any
    local state =
        states[user_id]

    if state then
        return state
    end

    return {
        Identity = default_identity(),
        Progression = default_progression(),
    }
end

local function progression_for(
    user_id: number
): any
    return state_for(user_id).Progression
end

function ProgressionRuntimeState.set_character(
    user_id: number,
    character_or_progression: any
)
    local identity: any
    local progression: any

    if (
        type(character_or_progression)
            == "table"
        and type(
            character_or_progression.Progression
        ) == "table"
    ) then
        identity =
            if type(
                character_or_progression.Identity
            ) == "table"
                then character_or_progression.Identity
                else default_identity()

        progression =
            character_or_progression.Progression
    elseif type(character_or_progression)
        == "table"
    then
        -- Compatibility for accepted tests and older callers
        -- that passed only the Progression table.
        identity = default_identity()
        progression =
            character_or_progression
    else
        identity = default_identity()
        progression = default_progression()
    end

    states[user_id] = {
        Identity =
            ProfileSchema.deep_clone(
                identity
            ),

        Progression =
            ProfileSchema.deep_clone(
                progression
            ),
    }
end

function ProgressionRuntimeState.clear_character(
    user_id: number
)
    states[user_id] = nil
end

function ProgressionRuntimeState.get_snapshot(
    user_id: number
): any
    -- Preserve the accepted public contract:
    -- callers receive a Progression-shaped snapshot,
    -- not the new internal state wrapper.
    return ProfileSchema.deep_clone(
        progression_for(user_id)
    )
end

function ProgressionRuntimeState.get_race_id(
    user_id: number
): string?
    local identity =
        state_for(user_id).Identity

    if type(identity) ~= "table" then
        return nil
    end

    return if type(identity.RaceId) == "string"
        then identity.RaceId
        else nil
end

function ProgressionRuntimeState.get_attribute(
    user_id: number,
    name: string
): number
    local progression =
        progression_for(user_id)

    local value =
        progression
        and progression.Attributes
        and progression.Attributes[name]

    return if type(value) == "number"
        then value
        else AttributeConfig.BASE_VALUE
end

local function attributes_for(
    user_id: number
): any
    local progression =
        progression_for(user_id)

    return if type(progression.Attributes)
        == "table"
        then progression.Attributes
        else {}
end

function ProgressionRuntimeState
    .get_physical_multiplier(
        user_id: number
    ): number

    return AttributeConfig
        .physical_multiplier(
            ProgressionRuntimeState
                .get_attribute(
                    user_id,
                    "Strength"
                )
        )
end

function ProgressionRuntimeState
    .get_heal_multiplier(
        user_id: number
    ): number

    return AttributeConfig
        .heal_multiplier(
            ProgressionRuntimeState
                .get_attribute(
                    user_id,
                    "Spirit"
                )
        )
end

function ProgressionRuntimeState
    .get_critical_chance(
        user_id: number
    ): number

    return CharacterCombatStats
        .critical_chance(
            attributes_for(user_id),
            ProgressionRuntimeState
                .get_race_id(
                    user_id
                )
        )
end

function ProgressionRuntimeState
    .get_critical_damage_multiplier(
        user_id: number
    ): number

    return CharacterCombatStats
        .critical_damage_multiplier(
            ProgressionRuntimeState
                .get_race_id(
                    user_id
                )
        )
end

function ProgressionRuntimeState
    .get_basic_attack_rate(
        user_id: number
    ): number

    return CharacterCombatStats
        .basic_attack_rate(
            ProgressionRuntimeState
                .get_race_id(
                    user_id
                )
        )
end

function ProgressionRuntimeState.get_max_health(
    user_id: number
): number
    return CharacterCombatStats
        .max_health(
            attributes_for(user_id),
            ProgressionRuntimeState
                .get_race_id(
                    user_id
                )
        )
end

function ProgressionRuntimeState.get_skill_rank(
    user_id: number,
    skill_id: string
): number
    local progression =
        progression_for(user_id)

    local state =
        progression
        and progression.Skills
        and progression.Skills[skill_id]

    if (
        type(state) ~= "table"
        or state.Known ~= true
    ) then
        return 0
    end

    return math.max(
        0,
        math.floor(
            tonumber(state.PurchasedRank)
                or 0
        )
    )
end

function ProgressionRuntimeState.is_skill_equipped(
    user_id: number,
    skill_id: string
): boolean
    local progression =
        progression_for(user_id)

    if (
        not progression
        or type(progression.Loadout)
            ~= "table"
    ) then
        return false
    end

    for _, equipped_id in pairs(
        progression.Loadout
    ) do
        if equipped_id == skill_id then
            return true
        end
    end

    return false
end

local function has_weapon_tag(
    tags: any,
    required: string
): boolean
    if type(tags) ~= "table" then
        return false
    end

    for key, value in pairs(tags) do
        if (
            value == required
            or (
                key == required
                and value == true
            )
        ) then
            return true
        end
    end

    return false
end

function ProgressionRuntimeState.is_skill_usable(
    user_id: number,
    skill_id: string,
    weapon_tags: any
): (boolean, string?)
    if (
        ProgressionRuntimeState
            .get_skill_rank(
                user_id,
                skill_id
            )
        < 1
    ) then
        return false, "SkillNotPurchased"
    end

    if not ProgressionRuntimeState
        .is_skill_equipped(
            user_id,
            skill_id
        )
    then
        return false, "SkillNotEquipped"
    end

    local definition =
        SkillProgressionDefinitions.get(
            skill_id
        )

    if not definition then
        return false, "UnknownSkill"
    end

    for _, required in ipairs(
        definition.WeaponTags or {}
    ) do
        if not has_weapon_tag(
            weapon_tags,
            required
        ) then
            return false, "WrongWeapon"
        end
    end

    return true, nil
end

local function apply_health(
    player: Player
)
    local character =
        player.Character

    if not character then
        return
    end

    local humanoid =
        character
            :FindFirstChildOfClass(
                "Humanoid"
            )

    if not humanoid then
        return
    end

    local previous_max =
        humanoid.MaxHealth

    local new_max =
        ProgressionRuntimeState
            .get_max_health(
                player.UserId
            )

    humanoid.MaxHealth =
        new_max

    if humanoid.Health > new_max then
        humanoid.Health =
            new_max
    elseif (
        humanoid.Health
        >= previous_max - 0.001
    ) then
        -- Preserve the accepted full-health behaviour:
        -- a character that was full stays full when MaxHealth
        -- increases or decreases.
        humanoid.Health =
            new_max
    end
end

function ProgressionRuntimeState.apply_max_health(
    player: Player
)
    -- Compatibility wrapper for existing consumers/tests.
    apply_health(player)
end

function ProgressionRuntimeState.apply_runtime_stats(
    player: Player
)
    local character =
        player.Character

    if not character then
        return
    end

    character:SetAttribute(
        "DungeonMMOBasicAttackRate",
        ProgressionRuntimeState
            .get_basic_attack_rate(
                player.UserId
            )
    )

    apply_health(player)
end

return table.freeze(
    ProgressionRuntimeState
)