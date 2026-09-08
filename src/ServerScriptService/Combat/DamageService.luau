--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild(
        "CombatConfig"
    )
)

local CriticalHitRules = require(
    shared_folder:WaitForChild(
        "CriticalHitRules"
    )
)

local CombatValidationService = require(
    script.Parent:WaitForChild(
        "CombatValidationService"
    )
)

local DamageService = {}

local critical_random =
    Random.new()

export type DamageContext = {
    attacker: Player?,
    attacker_character: Model?,
    target: Model,
    source_kind: string,
    source_id: string,
    attack_id: string?,
    base_damage: number,
    multiplier: number,
    sequence_id: number?,

    critical_chance: number?,
    critical_damage_multiplier: number?,

    -- Test injection only.
    -- Live basic-melee callers never provide this value.
    critical_roll: number?,
}

function DamageService.calculate_damage(
    base_damage: number,
    multiplier: number
): number
    return math.max(
        0,
        base_damage * multiplier
    )
end

local function resolve_critical_multiplier(
    context: DamageContext
): number
    if (
        type(context.critical_chance)
            ~= "number"
        or type(
            context
                .critical_damage_multiplier
        ) ~= "number"
    ) then
        return 1
    end

    local roll =
        context.critical_roll

    if type(roll) ~= "number" then
        roll =
            critical_random:NextNumber()
    end

    local result =
        CriticalHitRules.resolve(
            context.critical_chance,
            context
                .critical_damage_multiplier,
            roll
        )

    return result.multiplier
end

function DamageService.apply_damage(
    context: DamageContext
): number
    local humanoid =
        context.target
            :FindFirstChildOfClass(
                "Humanoid"
            )

    if (
        not humanoid
        or humanoid.Health <= 0
    ) then
        return 0
    end

    local normal_damage =
        DamageService.calculate_damage(
            context.base_damage,
            context.multiplier
        )

    if normal_damage <= 0 then
        return 0
    end

    local critical_multiplier =
        resolve_critical_multiplier(
            context
        )

    local damage =
        normal_damage
        * critical_multiplier

    humanoid:TakeDamage(damage)

    local observer =
        context.attacker

    if not observer then
        observer =
            Players:GetPlayerFromCharacter(
                context.target
            )
    end

    CombatValidationService.emit(
        observer,
        "DAMAGE",
        "APPLIED",
        string.format(
            "%s %.1fHP -> %s",
            context.attack_id
                or context.source_id,
            damage,
            context.target.Name
        ),
        context.sequence_id
    )

    if CombatConfig.DEBUG.PRINT_DAMAGE then
        print(
            string.format(
                "[Damage] %s -%.1f HP",
                context.target.Name,
                damage
            )
        )
    end

    return damage
end

return table.freeze(
    DamageService
)