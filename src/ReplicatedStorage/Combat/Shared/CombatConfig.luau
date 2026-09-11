local CombatConfig = {
    ARENA = {
        ROOT_NAME = "CombatPrototype",

        FLOOR_SIZE = Vector3.new(120, 1, 120),
        FLOOR_POSITION = Vector3.new(0, -0.5, 0),
        FLOOR_COLOR = Color3.fromRGB(83, 88, 94),

        PILLAR_SIZE = Vector3.new(4, 10, 4),
        PILLAR_POSITIONS = {
            Vector3.new(-24, 5, -18),
            Vector3.new(24, 5, -18),
            Vector3.new(-24, 5, 18),
            Vector3.new(24, 5, 18),
        },
        PILLAR_COLOR = Color3.fromRGB(108, 113, 120),

        SPAWN_POSITION = Vector3.new(0, 0.25, 52),
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
            80,
            90,
            100,
        },
        MARKER_COLOR = Color3.fromRGB(181, 186, 193),
    },

    VIEW_LOCK = {
        ACTION_NAME = "ToggleCombatViewLock",
        TOGGLE_KEY = Enum.KeyCode.LeftControl,
        STATE_ATTRIBUTE = "CombatViewLocked",

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
                HITBOX = {
                    SIZE = Vector3.new(12, 5, 6),
                    FORWARD_OFFSET = 3,
                    SAMPLE_COUNT = 4,
                },
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
                HITBOX = {
                    SIZE = Vector3.new(15, 5, 6.2),
                    FORWARD_OFFSET = 3.1,
                    SAMPLE_COUNT = 4,
                },
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
                REACH_STUDS = 7.2,
                ARC_DEGREES = 45,
                HITBOX = {
                    SIZE = Vector3.new(5.5, 5, 7.2),
                    FORWARD_OFFSET = 3.6,
                    SAMPLE_COUNT = 4,
                },
                POWER_MULTIPLIER = 1.35,
                MOVEMENT_SCALE = {
                    WIND_UP = 0.65,
                    ACTIVE = 0.40,
                    RECOVERY = 0.75,
                },
            },
        },
    },

    STAMINA = {
        MAX = 100,
        DODGE_COST = 25,
        REGEN_DELAY_SECONDS = 1.0,
        REGEN_PER_SECOND = 25,
        GUARD_BREAK_REGEN_DELAY_SECONDS = 1.5,
    },

    MANA = {
        REGEN_DELAY_SECONDS = 1.0,
    },

    SPIRIT_ORB = {
        BASE_DAMAGE = 10,
        SPEED_STUDS_PER_SECOND = 70,
        MAX_RANGE_STUDS = 50,
        NORMAL_DIAMETER = 1.25,
        FINISHER_DIAMETER = 2.5,
        FINISHER_AOE_RADIUS = 6,
    },

    RANGER_LONGBOW = {
        BASE_DAMAGE = 16,
        PROJECTILE_SPEED = 110,
        MAX_RANGE_STUDS = 80,
        RELEASE = {
            WIND_UP_SECONDS = 0.08,
            ACTIVE_SECONDS = 0.04,
            RECOVERY_SECONDS = 0.28,
            MOVEMENT_SCALE = {
                WIND_UP = 0.60,
                ACTIVE = 0.50,
                RECOVERY = 0.80,
            },
        },
    },

    DEFENSE = {
        REQUEST_ACTION_NAME = "CombatDefenseRequest",
        BLOCK_ACTION_NAME = "CombatBlock",
        DODGE_ACTION_NAME = "CombatDodge",
        DODGE_KEY = Enum.KeyCode.LeftShift,
        BLOCK_ARC_DEGREES = 120,
        PARRY_WINDOW_SECONDS = 0.18,
        GUARD_BREAK_SECONDS = 0.8,
        PARRY_ATTACKER_STAGGER_SECONDS = 1.0,
        DODGE_DISTANCE_STUDS = 12,
        DODGE_DURATION_SECONDS = 0.55,
        DODGE_START_SPEED_MULTIPLIER = 1.35,
        DODGE_END_SPEED_MULTIPLIER = 0.65,
        SIDE_DASH_DISTANCE_STUDS = 8,
        SIDE_DASH_DURATION_SECONDS = 0.30,
        SIDE_DASH_START_SPEED_MULTIPLIER = 1.55,
        SIDE_DASH_END_SPEED_MULTIPLIER = 0.45,
        DODGE_IFRAME_SECONDS = 0.22,
        DODGE_WALL_CLEARANCE_STUDS = 1.25,
        UNLOCKED_DODGE_TURN_SECONDS = 0.075,
        DODGE_DIRECTION_ATTRIBUTE = "CombatDodgeDirection",
        DODGE_STYLE_ATTRIBUTE = "CombatDodgeStyle",
        DODGE_VIEW_LOCKED_ATTRIBUTE = "CombatDodgeViewLocked",
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

    PROTOTYPE_SHIELD = {
        PART_NAME = "PrototypeShield",
        GRIP_NAME = "PrototypeShieldGrip",
        ATTACH_PART_NAME = "HumanoidRootPart",
        IDLE_REFERENCE_PART_NAME = "LeftLowerArm",
        BLOCK_REFERENCE_PART_NAME = "UpperTorso",
        PRESENTATION_GRIP_REPLICATION_WAIT_SECONDS = 0.50,
        SIZE = Vector3.new(2.7, 3.3, 0.35),

        IDLE_OUTWARD_STUDS = 0.42,
        IDLE_FORWARD_STUDS = 0.08,
        IDLE_DOWN_STUDS = 0.20,
        IDLE_FACE_FORWARD_BLEND = 0.16,

        BLOCK_LEFT_STUDS = 0.28,
        BLOCK_FORWARD_STUDS = 1.35,
        BLOCK_DOWN_STUDS = 0.20,

        BLOCK_IK_NAME = "PrototypeShieldArmIK",
        BLOCK_IK_TARGET_NAME = "PrototypeShieldArmTarget",
        BLOCK_IK_POLE_NAME = "PrototypeShieldArmPole",

        IDLE_HAND_LEFT_STUDS = 0.72,
        IDLE_HAND_FORWARD_STUDS = 0.06,
        IDLE_HAND_DOWN_STUDS = 0.88,
        IDLE_POLE_LEFT_STUDS = 1.28,
        IDLE_POLE_FORWARD_STUDS = 0.02,
        IDLE_POLE_DOWN_STUDS = 0.55,

        BLOCK_HAND_LEFT_STUDS = 0.34,
        BLOCK_HAND_FORWARD_STUDS = 0.72,
        BLOCK_HAND_DOWN_STUDS = 0.24,
        BLOCK_POLE_LEFT_STUDS = 0.95,
        BLOCK_POLE_FORWARD_STUDS = 0.05,
        BLOCK_POLE_DOWN_STUDS = 0.32,

        IK_SMOOTH_TIME = 0.045,
        WALK_BOB_FREQUENCY_HZ = 1.85,
        WALK_ARM_BOB_STUDS = 0.045,
        WALK_SHIELD_EXTRA_BOB_STUDS = 0.055,
        WALK_FORWARD_BOB_STUDS = 0.025,
        WALK_SHIELD_ROLL_DEGREES = 2.0,
        BLOCK_BOB_FREQUENCY_HZ = 1.10,
        BLOCK_BOB_STUDS = 0.012,

        BASH_LEFT_STUDS = 0.18,
        BASH_FORWARD_STUDS = 1.95,
        BASH_DOWN_STUDS = 0.10,
        BASH_HAND_LEFT_STUDS = 0.20,
        BASH_HAND_FORWARD_STUDS = 1.35,
        BASH_HAND_DOWN_STUDS = 0.14,
        BASH_POLE_LEFT_STUDS = 0.82,
        BASH_POLE_FORWARD_STUDS = 0.22,
        BASH_POLE_DOWN_STUDS = 0.26,
        BASH_TORSO_LEAN_DEGREES = 8,
    },

    TRAINING_MARAUDER = {
        MODEL_NAME = "TrainingMarauder",
        MODEL_NAMES = {
            "TrainingMarauder",
            "TrainingMarauder_2",
            "TrainingMarauder_3",
            "TrainingMarauder_4",
        },
        SPAWN_POSITIONS = {
            Vector3.new(-34, 2, -30),
            Vector3.new(34, 2, -30),
            Vector3.new(-34, 2, 12),
            Vector3.new(34, 2, 12),
        },
        MAX_HEALTH = 200,
        ROOM_WIDE_AGGRO = true,
        CHASE_SPEED_STUDS_PER_SECOND = 14,
        CHASE_STOP_RANGE_STUDS = 4.75,
        MIN_CENTER_SEPARATION_STUDS = 4.0,
        COLLISION_BODY_SIZE = Vector3.new(3.6, 4.8, 2.8),
        AI_TICK_SECONDS = 0.05,
        AI_STATE_ATTRIBUTE = "MarauderAIState",
        AGGRO_TARGET_ATTRIBUTE = "MarauderAggroTargetUserId",
        ATTACK_NAME_ATTRIBUTE = "MarauderAttackName",
        SPAWN_INDEX_ATTRIBUTE = "MarauderSpawnIndex",
        RESPAWN_SECONDS = 3,
        RESPAWN_ATTACK_DELAY_SECONDS = 1.0,
        RESPAWN_AGGRO_GRACE_SECONDS = 3,
        AGGRO_SUPPRESSED_ATTRIBUTE = "CombatAggroSuppressed",
        STEERING_COMMIT_SECONDS = 0.40,
        CONTROLLER_TAG = "DungeonMMOMarauderController",
        RUN_PARTICIPANT_ATTRIBUTE = "DungeonRunParticipant",
        ENCOUNTER_ATTRIBUTE = "DungeonEncounterId",
        ATTACK_PATTERN = {
            "Normal",
            "Normal",
            "Heavy",
        },
        ATTACKS = {
            Normal = {
                DISPLAY_NAME = "Normal Strike",
                ATTACK_REACH_STUDS = 5.5,
                ATTACK_ARC_DEGREES = 80,
                WIND_UP_SECONDS = 0.45,
                ATTACK_LOCK_SECONDS = 0.12,
                ATTACK_INTERVAL_SECONDS = 1.6,
                HEALTH_DAMAGE = 20,
                STAMINA_DAMAGE = 30,
                TELEGRAPH_COLOR = Color3.fromRGB(225, 92, 72),
            },
            Heavy = {
                DISPLAY_NAME = "Heavy Overhead",
                ATTACK_REACH_STUDS = 5.5,
                ATTACK_ARC_DEGREES = 55,
                WIND_UP_SECONDS = 0.75,
                ATTACK_LOCK_SECONDS = 0.12,
                ATTACK_INTERVAL_SECONDS = 1.6,
                HEALTH_DAMAGE = 32,
                STAMINA_DAMAGE = 45,
                TELEGRAPH_COLOR = Color3.fromRGB(235, 177, 67),
            },
        },
        ATTACK_REACH_STUDS = 5.5,
        ATTACK_ARC_DEGREES = 80,
        WIND_UP_SECONDS = 0.45,
        ATTACK_LOCK_SECONDS = 0.12,
        ATTACK_INTERVAL_SECONDS = 1.6,
        HEALTH_DAMAGE = 20,
        STAMINA_DAMAGE = 30,
    },

    REMOTES = {
        ATTACK_REQUEST = "AttackRequest",
        DEFENSE_REQUEST = "DefenseRequest",
        SKILL_REQUEST = "SkillRequest",
        STATE_CHANGED = "CombatStateChanged",
        VALIDATION_EVENT = "CombatValidationEvent",
    },

    TARGETS = {
        NPC_TAG = "CombatTarget",
    },

    DEBUG = {
        STATE_GUI_NAME = "CombatDebugGui",
        SHOW_MELEE_HITBOX = true,
        PRINT_MELEE_HITS = true,
        PRINT_DAMAGE = true,
        PRINT_DEFENSE = true,
        COMBAT_VALIDATION = false,
        VALIDATION_GUI_NAME = "CombatValidationGui",
    },
}

return CombatConfig
