local GAMEPAD = table.freeze({
    ATTACK = Enum.KeyCode.ButtonR2,
    BLOCK = Enum.KeyCode.ButtonL2,
    DODGE = Enum.KeyCode.ButtonB,
    VIEW_LOCK = Enum.KeyCode.ButtonR3,
})

local MOBILE_CORE_ACTIONS = table.freeze({
    Attack = table.freeze({
        LABEL = "ATK",
        POSITION = UDim2.fromScale(0.88, 0.62),
        SIZE = UDim2.fromOffset(92, 92),
    }),
    Block = table.freeze({
        LABEL = "BLOCK",
        POSITION = UDim2.fromScale(0.74, 0.68),
        SIZE = UDim2.fromOffset(82, 82),
    }),
    Dodge = table.freeze({
        LABEL = "DODGE",
        POSITION = UDim2.fromScale(0.82, 0.46),
        SIZE = UDim2.fromOffset(78, 78),
    }),
    ViewLock = table.freeze({
        LABEL = "LOCK",
        POSITION = UDim2.fromScale(0.93, 0.36),
        SIZE = UDim2.fromOffset(64, 64),
    }),
})

local MOBILE = table.freeze({
    GUI_NAME = "CombatMobileControls",
    CORE_ACTIONS = MOBILE_CORE_ACTIONS,
    SKILL_SLOT_COUNT = 8,
    BLOCK_IS_HOLD = true,
    MIN_TOUCH_TARGET_PIXELS = 48,
    SKILL_BUTTON_SIZE = 50,
    SKILL_BUTTON_GAP = 4,
    SKILL_BAR_BOTTOM_PIXELS = 12,
})

return table.freeze({
    GAMEPAD = GAMEPAD,
    MOBILE = MOBILE,
})
