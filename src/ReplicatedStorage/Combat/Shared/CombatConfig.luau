local CombatConfig = {
    ARENA = {
        ROOT_NAME = "CombatPrototype",

        FLOOR_SIZE = Vector3.new(80, 1, 80),
        FLOOR_POSITION = Vector3.new(0, -0.5, 0),
        FLOOR_COLOR = Color3.fromRGB(83, 88, 94),

        PILLAR_SIZE = Vector3.new(4, 10, 4),
        PILLAR_POSITIONS = {
            Vector3.new(-16, 5, 0),
            Vector3.new(16, 5, 0),
        },
        PILLAR_COLOR = Color3.fromRGB(108, 113, 120),

        SPAWN_POSITION = Vector3.new(0, 0.25, 32),
        SPAWN_SIZE = Vector3.new(6, 0.5, 6),
        SPAWN_COLOR = Color3.fromRGB(72, 140, 86),

        MARKER_DISTANCES = {
            10,
            20,
            30,
            40,
            50,
            60,
            70,
        },
        MARKER_COLOR = Color3.fromRGB(181, 186, 193),
    },

    VIEW_LOCK = {
        ACTION_NAME = "ToggleCombatViewLock",
        TOGGLE_KEY = Enum.KeyCode.LeftShift,

        CAMERA_OFFSET = Vector3.new(1.75, 0.5, 0),

        MIN_LOOK_MAGNITUDE = 0.001,
    },
}

return CombatConfig
