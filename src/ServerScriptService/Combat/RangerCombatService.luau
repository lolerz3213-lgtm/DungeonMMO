--!strict
-- Ranger-specific combat delivery layered on shared authoritative services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)
local ProgressionRuntimeState = require(
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")
        :WaitForChild("ProgressionRuntimeState")
)
local DungeonProgressionBridge = require(
    ServerScriptService
        :WaitForChild("Dungeon")
        :WaitForChild("DungeonProgressionBridge")
)
local RangerProjectileService = require(
    script.Parent:WaitForChild("RangerProjectileService")
)
local RangerSlowService = require(
    script.Parent:WaitForChild("RangerSlowService")
)
local RangerVolleyService = require(
    script.Parent:WaitForChild("RangerVolleyService")
)

local RangerCombatService = {}

--[[
Returns authoritative Ranger ranged physical scaling.

Args:
    player (Player): Ranger whose runtime attributes are read.

Returns:
    number: Non-negative Dexterity-led ranged damage multiplier.
]]
local function ranged_multiplier(player: Player): number
    return ProgressionRuntimeState.get_ranged_physical_multiplier(
        player.UserId
    )
end

--[[
Returns the critical values used by a Ranger projectile.

Args:
    player (Player): Ranger whose runtime critical stats are read.
    bonus_chance (number): Shot-specific additional critical chance.

Returns:
    number: Authoritative critical chance clamped from zero through one.
    number: Authoritative critical-damage multiplier.
]]
local function critical_values(
    player: Player,
    bonus_chance: number
): (number, number)
    local chance = math.clamp(
        ProgressionRuntimeState.get_critical_chance(player.UserId)
            + bonus_chance,
        0,
        1
    )
    local multiplier =
        ProgressionRuntimeState.get_critical_damage_multiplier(
            player.UserId
        )

    return chance, multiplier
end

--[[
Returns Crippling Shot slow values for the authoritative race.

Args:
    player (Player): Ranger whose race is read from runtime identity.
    definition (any): Authoritative Crippling Shot definition.

Returns:
    number: Slow fraction from zero through one.
    number: Slow duration in seconds.
]]
local function crippling_slow_values(
    player: Player,
    definition: any
): (number, number)
    local race_id = ProgressionRuntimeState.get_race_id(player.UserId)

    if race_id == "Elf" then
        return tonumber(definition.ELF_SLOW_FRACTION) or 0,
            tonumber(definition.ELF_SLOW_SECONDS) or 0
    end

    return tonumber(definition.HUMAN_SLOW_FRACTION) or 0,
        tonumber(definition.HUMAN_SLOW_SECONDS) or 0
end

--[[
Handles progression and optional slow after one Ranger skill arrow lands.

Args:
    player (Player): Ranger who fired the projectile.
    definition (any): Authoritative Ranger projectile skill definition.
    target (Model): Accepted NPC target.
    target_index (number): One-based penetration index.
    applied_damage (number): Effective health damage applied.

Returns:
    None.
]]
local function handle_projectile_skill_hit(
    player: Player,
    definition: any,
    target: Model,
    target_index: number,
    applied_damage: number
)
    DungeonProgressionBridge.award_damage(
        player,
        definition.ID,
        target,
        applied_damage,
        target_index
    )

    if definition.ID ~= "CripplingShot" then
        return
    end

    local before_multiplier = RangerSlowService.get_multiplier(target)
    local slow_fraction, slow_seconds = crippling_slow_values(
        player,
        definition
    )
    local applied = RangerSlowService.apply(
        target,
        slow_fraction,
        slow_seconds
    )
    local after_multiplier = RangerSlowService.get_multiplier(target)
    local meaningful = applied
        and (
            before_multiplier >= 0.999
            or after_multiplier < before_multiplier - 0.001
        )

    DungeonProgressionBridge.award_control(
        player,
        definition.ID,
        target,
        "Slow",
        meaningful
    )
end

--[[
Fires one server-authoritative Longbow basic shot.

Args:
    player (Player): Ranger releasing the Longbow.
    character (Model): Current authoritative character.
    draw_tier (any): Server-classified draw tier.
    sequence_id (number): Combat sequence identifier.

Returns:
    boolean: True when the projectile was created.
]]
function RangerCombatService.fire_basic(
    player: Player,
    character: Model,
    draw_tier: any,
    sequence_id: number
): boolean
    local config = CombatConfig.RANGER_LONGBOW
    local critical_chance, critical_multiplier = critical_values(
        player,
        tonumber(draw_tier.CriticalChanceBonus) or 0
    )

    return RangerProjectileService.fire({
        attacker = player,
        character = character,
        source_id = "RangerArrow",
        base_damage = config.BASE_DAMAGE,
        damage_multiplier = ranged_multiplier(player)
            * (tonumber(draw_tier.DamageMultiplier) or 1),
        speed = config.PROJECTILE_SPEED,
        max_range = config.MAX_RANGE_STUDS,
        max_targets = 1,
        retention = 1,
        critical_chance = critical_chance,
        critical_damage_multiplier = critical_multiplier,
        sequence_id = sequence_id,
    })
end

--[[
Fires Piercing Shot or Crippling Shot from authoritative definitions.

Args:
    player (Player): Ranger using the skill.
    character (Model): Current authoritative character.
    definition (any): Rank-resolved Ranger projectile definition.
    sequence_id (number): Combat sequence identifier.

Returns:
    boolean: True when the projectile was created.
]]
function RangerCombatService.fire_projectile_skill(
    player: Player,
    character: Model,
    definition: any,
    sequence_id: number
): boolean
    local race_id = ProgressionRuntimeState.get_race_id(player.UserId)
    local retention = tonumber(definition.DEFAULT_RETENTION) or 1

    if race_id == "Human" then
        retention = tonumber(definition.HUMAN_RETENTION) or retention
    end

    local critical_chance, critical_multiplier = critical_values(
        player,
        0
    )

    return RangerProjectileService.fire({
        attacker = player,
        character = character,
        source_id = definition.ID,
        base_damage = definition.BASE_DAMAGE,
        damage_multiplier = ranged_multiplier(player),
        speed = definition.PROJECTILE_SPEED,
        max_range = definition.RANGE_STUDS,
        max_targets = definition.MAX_TARGETS,
        retention = retention,
        critical_chance = critical_chance,
        critical_damage_multiplier = critical_multiplier,
        sequence_id = sequence_id,
        on_hit = function(target, target_index, applied_damage)
            handle_projectile_skill_hit(
                player,
                definition,
                target,
                target_index,
                applied_damage
            )
        end,
    })
end

--[[
Validates client Volley aim against the server-observed character and ground.

Args:
    character (Model): Current authoritative Ranger character.
    aim_intent (any): Client world aim intent only.
    max_range (number): Maximum planar target distance.

Returns:
    Vector3?: Validated/clamped ground centre, otherwise nil.
]]
function RangerCombatService.resolve_volley_ground(
    character: Model,
    aim_intent: any,
    max_range: number
): Vector3?
    return RangerVolleyService.resolve_ground(
        character,
        aim_intent,
        max_range
    )
end

--[[
Starts server-owned Volley pulses at a previously validated ground centre.

Args:
    player (Player): Ranger casting Volley.
    character (Model): Current authoritative character.
    definition (any): Rank-resolved Volley definition.
    center (Vector3): Server-validated ground centre.
    sequence_id (number): Combat sequence identifier.

Returns:
    boolean: True when pulse scheduling started.
]]
function RangerCombatService.cast_volley(
    player: Player,
    character: Model,
    definition: any,
    center: Vector3,
    sequence_id: number
): boolean
    return RangerVolleyService.cast({
        attacker = player,
        character = character,
        skill_definition = definition,
        ranged_multiplier = ranged_multiplier(player),
        sequence_id = sequence_id,
        on_hit = function(target, pulse_index, applied_damage)
            DungeonProgressionBridge.award_damage(
                player,
                definition.ID,
                target,
                applied_damage,
                pulse_index
            )
        end,
    }, center)
end

return table.freeze(RangerCombatService)
