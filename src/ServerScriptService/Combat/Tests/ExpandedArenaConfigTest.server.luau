local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local ArenaConfig = CombatConfig.ARENA
local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local assertions = 0

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Expanded Arena Config Tests] " .. message, 2)
    end
    assertions += 1
end

assert_true(ArenaConfig.FLOOR_SIZE == Vector3.new(120, 1, 120), "Arena must be 120x120.")
assert_true(#ArenaConfig.PILLAR_POSITIONS == 4, "Arena must contain four configured pillars.")
assert_true(#MarauderConfig.MODEL_NAMES == 4, "Exactly four Marauders must be configured.")
assert_true(#MarauderConfig.SPAWN_POSITIONS == 4, "Every Marauder must have its own spawn.")
assert_true(MarauderConfig.CHASE_SPEED_STUDS_PER_SECOND == 14, "Marauder speed must remain fixed at 14.")
assert_true(MarauderConfig.RESPAWN_SECONDS == 3, "Marauder respawn must be 3 seconds.")
assert_true(MarauderConfig.ROOM_WIDE_AGGRO == true, "Room-wide aggro must remain enabled.")

print(string.format("[Expanded Arena Config Tests] PASS: %d assertions.", assertions))
