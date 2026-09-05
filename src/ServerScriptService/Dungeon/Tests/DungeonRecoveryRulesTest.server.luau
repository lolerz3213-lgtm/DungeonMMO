--!strict
-- Phase 2A reconnect reconstruction contract: a vanished runtime resumes from
-- the last activated room-start checkpoint while resetting only the current encounter.
local ServerScriptService = game:GetService("ServerScriptService")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local DungeonRecoveryRules = require(Dungeon:WaitForChild("DungeonRecoveryRules"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    assert(condition, message)
end

local room1 = DungeonRecoveryRules.from_checkpoint("Room1Start")
check(room1.spawn_checkpoint_id == "Room1Start", "Room1 recovery must spawn at Room1Start.")
check(room1.room1_cleared == false, "Room1 recovery must replay Room1.")
check(room1.room2_cleared == false, "Room1 recovery must not unlock the boss.")

local room2 = DungeonRecoveryRules.from_checkpoint("Room2Start")
check(room2.spawn_checkpoint_id == "Room2Start", "Room2 recovery must spawn at Room2Start.")
check(room2.room1_cleared == true, "Room2 recovery must preserve Room1 clear.")
check(room2.room2_cleared == false, "Room2 recovery must replay Room2.")

local boss = DungeonRecoveryRules.from_checkpoint("BossRoomStart")
check(boss.spawn_checkpoint_id == "BossRoomStart", "Boss recovery must spawn at BossRoomStart.")
check(boss.room1_cleared == true and boss.room2_cleared == true, "Boss recovery must preserve both room clears.")
check(boss.objective_state == "Boss", "Boss recovery must restore boss objective state.")

local entrance = DungeonRecoveryRules.from_checkpoint("Entrance")
check(entrance.spawn_checkpoint_id == "Entrance", "Fresh admission starts at Entrance.")
check(entrance.room1_cleared == false and entrance.room2_cleared == false, "Entrance has no cleared rooms.")

local unknown = DungeonRecoveryRules.from_checkpoint("NotARealCheckpoint")
check(unknown.spawn_checkpoint_id == "Entrance", "Unknown checkpoints must fail safe to Entrance.")
check(unknown.valid_checkpoint == false, "Unknown checkpoints must be flagged invalid.")

print(string.format("[Dungeon Recovery Rules Tests] PASS: %d assertions.", assertions))
