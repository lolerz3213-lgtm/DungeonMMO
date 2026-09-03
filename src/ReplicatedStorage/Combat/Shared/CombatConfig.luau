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

    BASIC_ATTACK = {
        ACTION_NAME = "CombatBasicAttack",
        COMBO_BUFFER_SECONDS = 0.20,
        COMBO_RESET_SECONDS = 0.85,

        ATTACK_ORDER = {
            "Slash1",
            "Slash2",
            "Finisher",
        },

        ATTACKS = {
            Slash1 = {
                DISPLAY_NAME = "Slash 1",
                WIND_UP_SECONDS = 0.18,
                ACTIVE_SECONDS = 0.10,
                RECOVERY_SECONDS = 0.28,
                FORWARD_STEP_STUDS = 1.20,
                REACH_STUDS = 6.0,
                ARC_DEGREES = 90,
                POWER_MULTIPLIER = 1.00,
                MOVEMENT_SCALE = {
                    WIND_UP = 0.65,
                    ACTIVE = 0.40,
                    RECOVERY = 0.75,
                },
            },

            Slash2 = {
                DISPLAY_NAME = "Slash 2",
                WIND_UP_SECONDS = 0.20,
                ACTIVE_SECONDS = 0.10,
                RECOVERY_SECONDS = 0.30,
                FORWARD_STEP_STUDS = 1.40,
                REACH_STUDS = 6.2,
                ARC_DEGREES = 100,
                POWER_MULTIPLIER = 1.05,
                MOVEMENT_SCALE = {
                    WIND_UP = 0.65,
                    ACTIVE = 0.40,
                    RECOVERY = 0.75,
                },
            },

            Finisher = {
                DISPLAY_NAME = "Finisher",
                WIND_UP_SECONDS = 0.28,
                ACTIVE_SECONDS = 0.12,
                RECOVERY_SECONDS = 0.38,
                FORWARD_STEP_STUDS = 1.80,
                REACH_STUDS = 6.5,
                ARC_DEGREES = 110,
                POWER_MULTIPLIER = 1.35,
                MOVEMENT_SCALE = {
                    WIND_UP = 0.65,
                    ACTIVE = 0.40,
                    RECOVERY = 0.75,
                },
            },
        },
    },

    PROTOTYPE_WEAPON = {
        BASE_DAMAGE = 10,
        TOOL_NAME = "PrototypeSword",
        HANDLE_NAME = "Handle",
        BLADE_NAME = "Blade",
        TRAIL_NAME = "ActiveFrameTrail",

        -- Baseline derived from Roblox's classic sword grip.
        GRIP_CFRAME = CFrame.new(
            0,
            0,
            -1.7,
            0,
            0,
            1,
            1,
            0,
            0,
            0,
            1,
            0
        ),

        HANDLE_SIZE = Vector3.new(1, 0.8, 4),
        BLADE_SIZE = Vector3.new(0.28, 0.14, 3.15),
        BLADE_OFFSET = CFrame.new(0, 0, -0.38),

        GUARD_SIZE = Vector3.new(1.55, 0.22, 0.28),
        GUARD_OFFSET = CFrame.new(0, 0, 1.08),

        HILT_SIZE = Vector3.new(0.34, 0.34, 0.92),
        HILT_OFFSET = CFrame.new(0, 0, 1.56),

        POMMEL_SIZE = Vector3.new(0.48, 0.48, 0.38),
        POMMEL_OFFSET = CFrame.new(0, 0, 2.04),
    },

    REMOTES = {
        ATTACK_REQUEST = "AttackRequest",
        STATE_CHANGED = "CombatStateChanged",
    },

    TARGETS = {
        NPC_TAG = "CombatTarget",
    },
    DEBUG = {
        STATE_GUI_NAME = "CombatDebugGui",
    },
}

return CombatConfig
