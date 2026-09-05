local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local combat_folder = script.Parent.Parent

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local module_script = combat_folder:FindFirstChild("AggroGraceRules")
if not module_script then
    error("[Respawn Aggro Grace Tests] RED: AggroGraceRules is missing.")
end

local AggroGraceRules = require(module_script)
local MarauderConfig = CombatConfig.TRAINING_MARAUDER

assert(
    MarauderConfig.RESPAWN_AGGRO_GRACE_SECONDS == 3,
    "respawn aggro grace must be exactly 3 seconds for Phase 1"
)
assert(
    AggroGraceRules.can_target(false) == true,
    "ordinary living characters must remain targetable"
)
assert(
    AggroGraceRules.can_target(true) == false,
    "aggro-suppressed respawned characters must not be targetable"
)

print("[Respawn Aggro Grace Tests] PASS")
