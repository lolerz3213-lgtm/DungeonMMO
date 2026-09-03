local CollectionService = game:GetService(
    "CollectionService"
)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local CombatTargetRules = {}


--[[
Determines whether a target Model may receive combat damage.

This layer owns target legality only. It deliberately does not know
anything about melee hitboxes, projectiles, area effects, or damage
formulas so future delivery systems can reuse it.

Args:
    attacker_character (Model?): Character causing the damage.
    target_model (Model?): Candidate target Model.

Returns:
    boolean: True when the target is damageable in the current PvE rules.
    string: Stable validation reason for diagnostics and tests.
]]
function CombatTargetRules.is_damageable(
    attacker_character: Model?,
    target_model: Model?
): (boolean, string)
    if not target_model then
        return false, "MissingTarget"
    end

    if target_model == attacker_character then
        return false, "Self"
    end

    if Players:GetPlayerFromCharacter(
        target_model
    ) then
        return false, "PlayerTargetDisabled"
    end

    if not CollectionService:HasTag(
        target_model,
        CombatConfig.TARGETS.NPC_TAG
    ) then
        return false, "NotCombatTarget"
    end

    local humanoid =
        target_model:FindFirstChildOfClass(
            "Humanoid"
        )

    if not humanoid then
        return false, "MissingHumanoid"
    end

    if humanoid.Health <= 0 then
        return false, "Dead"
    end

    return true, "Accepted"
end


return table.freeze(CombatTargetRules)
