local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared")
local InputMappingConfig = require(shared:WaitForChild("InputMappingConfig"))

local mobile = InputMappingConfig.MOBILE

assert(mobile.GUI_NAME == "CombatMobileControls")
assert(mobile.CORE_ACTIONS.Attack ~= nil)
assert(mobile.CORE_ACTIONS.Block ~= nil)
assert(mobile.CORE_ACTIONS.Dodge ~= nil)
assert(mobile.CORE_ACTIONS.ViewLock ~= nil)
assert(mobile.SKILL_SLOT_COUNT == 8)
assert(mobile.BLOCK_IS_HOLD == true)
assert(mobile.MIN_TOUCH_TARGET_PIXELS >= 48)

print("[Mobile Control Layout Tests] PASS")
