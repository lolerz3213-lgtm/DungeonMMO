local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local DamageService = {}

export type DamageContext = {
    attacker: Player?,
    attacker_character: Model?,
    target: Model,
    source_kind: string,
    source_id: string,
    attack_id: string?,
    base_damage: number,
    multiplier: number,
}


--[[
Calculates final prototype damage from a base value and multiplier.

This function deliberately does not know how a target was acquired.
Melee, projectiles, area effects, traps, and enemy attacks can all
reuse the same damage calculation boundary later.

Args:
    base_damage (number): Raw damage supplied by the damage source.
    multiplier (number): Attack or skill damage multiplier.

Returns:
    number: Non-negative final damage without rounding.
]]
function DamageService.calculate_damage(
    base_damage: number,
    multiplier: number
): number
    return math.max(
        0,
        base_damage * multiplier
    )
end


--[[
Applies already-authorized damage to a target Humanoid.

Target legality is intentionally handled elsewhere by
CombatTargetRules. This service only calculates and applies damage.

Args:
    context (DamageContext): Generic damage-source information.

Returns:
    number: Damage applied, or zero when the target cannot receive it.
]]
function DamageService.apply_damage(
    context: DamageContext
): number
    local humanoid =
        context.target:FindFirstChildOfClass(
            "Humanoid"
        )

    if not humanoid
        or humanoid.Health <= 0 then
        return 0
    end

    local damage =
        DamageService.calculate_damage(
            context.base_damage,
            context.multiplier
        )

    if damage <= 0 then
        return 0
    end

    humanoid:TakeDamage(damage)

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


return table.freeze(DamageService)
