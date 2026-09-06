local SLOT_COUNT = 8
local ACTIVE_SLOT_COUNT = 6

local DEFAULT_KEYS = table.freeze({
    [1] = Enum.KeyCode.One,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four,
    [5] = Enum.KeyCode.Five,
    [6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven,
    [8] = Enum.KeyCode.Eight,
})

local DEFAULT_GAMEPAD_KEYS = table.freeze({
    [1] = Enum.KeyCode.ButtonR1,
    [2] = Enum.KeyCode.ButtonL1,
    [3] = Enum.KeyCode.DPadUp,
    [4] = Enum.KeyCode.DPadRight,
    [5] = Enum.KeyCode.DPadDown,
    [6] = Enum.KeyCode.DPadLeft,
    [7] = Enum.KeyCode.ButtonX,
    [8] = Enum.KeyCode.ButtonY,
})

local ACTION_NAMES = table.freeze({
    [1] = "SkillSlot1",
    [2] = "SkillSlot2",
    [3] = "SkillSlot3",
    [4] = "SkillSlot4",
    [5] = "SkillSlot5",
    [6] = "SkillSlot6",
    [7] = "SkillSlot7",
    [8] = "SkillSlot8",
})

local PROTOTYPE_LOADOUT = table.freeze({
    [1] = "ShieldBash",
    [2] = "Mend",
})

local HotbarConfig = {}


--[[
Returns the logical action name assigned to one hotbar slot.

Args:
    slot (number): One-based hotbar slot number.

Returns:
    string?: Logical action name, or nil when the slot is invalid.
]]
function HotbarConfig.get_action_name(slot: number): string?
    return ACTION_NAMES[slot]
end


--[[
Returns the default keyboard key assigned to one hotbar slot.

Args:
    slot (number): One-based hotbar slot number.

Returns:
    Enum.KeyCode?: Default keyboard key, or nil when the slot is invalid.
]]
function HotbarConfig.get_default_key(slot: number): Enum.KeyCode?
    return DEFAULT_KEYS[slot]
end


--[[
Returns the prototype gamepad key assigned to one hotbar slot.

Args:
    slot (number): One-based hotbar slot number.

Returns:
    Enum.KeyCode?: Prototype gamepad key when one is configured.
]]
function HotbarConfig.get_default_gamepad_key(
    slot: number
): Enum.KeyCode?
    return DEFAULT_GAMEPAD_KEYS[slot]
end


--[[
Returns the skill equipped in one prototype hotbar slot.

Args:
    slot (number): One-based hotbar slot number.

Returns:
    string?: Skill id equipped in the slot, or nil when the slot is empty.
]]
function HotbarConfig.get_skill_for_slot(slot: number): string?
    return PROTOTYPE_LOADOUT[slot]
end


return table.freeze({
    SLOT_COUNT = SLOT_COUNT,
    ACTIVE_SLOT_COUNT = ACTIVE_SLOT_COUNT,
    DEFAULT_KEYS = DEFAULT_KEYS,
    DEFAULT_GAMEPAD_KEYS = DEFAULT_GAMEPAD_KEYS,
    ACTION_NAMES = ACTION_NAMES,
    PROTOTYPE_LOADOUT = PROTOTYPE_LOADOUT,
    get_action_name = HotbarConfig.get_action_name,
    get_default_key = HotbarConfig.get_default_key,
    get_default_gamepad_key = HotbarConfig.get_default_gamepad_key,
    get_skill_for_slot = HotbarConfig.get_skill_for_slot,
})
