local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared")
local InputMappingConfig = require(shared:WaitForChild("InputMappingConfig"))
local HotbarConfig = require(shared:WaitForChild("HotbarConfig"))

assert(InputMappingConfig.GAMEPAD.ATTACK == Enum.KeyCode.ButtonR2)
assert(InputMappingConfig.GAMEPAD.BLOCK == Enum.KeyCode.ButtonL2)
assert(InputMappingConfig.GAMEPAD.DODGE == Enum.KeyCode.ButtonB)
assert(InputMappingConfig.GAMEPAD.VIEW_LOCK == Enum.KeyCode.ButtonR3)

local expected_skill_keys = {
    [1] = Enum.KeyCode.ButtonR1,
    [2] = Enum.KeyCode.ButtonL1,
    [3] = Enum.KeyCode.DPadUp,
    [4] = Enum.KeyCode.DPadRight,
    [5] = Enum.KeyCode.DPadDown,
    [6] = Enum.KeyCode.DPadLeft,
    [7] = Enum.KeyCode.ButtonX,
    [8] = Enum.KeyCode.ButtonY,
}

for slot = 1, HotbarConfig.SLOT_COUNT do
    assert(
        HotbarConfig.get_default_gamepad_key(slot)
            == expected_skill_keys[slot],
        string.format("Unexpected gamepad mapping for SkillSlot%d", slot)
    )
end

print("[Input Mapping Config Tests] PASS")
