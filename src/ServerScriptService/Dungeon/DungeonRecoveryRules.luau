--!strict
-- Pure mapping from persisted room-start checkpoints to reconstructed dungeon flow.
local DungeonRecoveryRules = {}

local PLANS = table.freeze({
    Entrance = table.freeze({
        valid_checkpoint = true,
        spawn_checkpoint_id = "Entrance",
        room1_cleared = false,
        room2_cleared = false,
        runtime_room_id = "Entrance",
        objective = "Enter Combat Room 1 to begin the dungeon.",
        objective_state = "Active",
    }),
    Room1Start = table.freeze({
        valid_checkpoint = true,
        spawn_checkpoint_id = "Room1Start",
        room1_cleared = false,
        room2_cleared = false,
        runtime_room_id = "Room1Ready",
        objective = "Combat Room 1 reset after reconnect. Defeat both Marauders.",
        objective_state = "Active",
    }),
    Room2Start = table.freeze({
        valid_checkpoint = true,
        spawn_checkpoint_id = "Room2Start",
        room1_cleared = true,
        room2_cleared = false,
        runtime_room_id = "Room2Ready",
        objective = "Combat Room 2 reset after reconnect. Defeat the Marauder pack.",
        objective_state = "Active",
    }),
    BossRoomStart = table.freeze({
        valid_checkpoint = true,
        spawn_checkpoint_id = "BossRoomStart",
        room1_cleared = true,
        room2_cleared = true,
        runtime_room_id = "BossReady",
        objective = "Boss encounter reset after reconnect. Defeat the Marauder Captain.",
        objective_state = "Boss",
    }),
})

local INVALID_PLAN = table.freeze({
    valid_checkpoint = false,
    spawn_checkpoint_id = "Entrance",
    room1_cleared = false,
    room2_cleared = false,
    runtime_room_id = "Entrance",
    objective = "Enter Combat Room 1 to begin the dungeon.",
    objective_state = "Active",
})

function DungeonRecoveryRules.from_checkpoint(checkpoint_id: any): any
    if type(checkpoint_id) ~= "string" then
        return INVALID_PLAN
    end
    return PLANS[checkpoint_id] or INVALID_PLAN
end

return table.freeze(DungeonRecoveryRules)
