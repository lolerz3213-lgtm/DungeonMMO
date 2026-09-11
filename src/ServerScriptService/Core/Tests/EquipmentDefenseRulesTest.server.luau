--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")
local EquipmentDefenseRules = require(
    Shared:WaitForChild("EquipmentDefenseRules")
)

local assertions = 0

local function check(value: boolean, message: string)
    assertions += 1

    if not value then
        error("[Equipment Defense Rules Tests] " .. message, 2)
    end
end

check(
    EquipmentDefenseRules.can_block_with_weapon("apprentice_longbow") == false,
    "Apprentice Longbow must disable Block."
)
check(
    EquipmentDefenseRules.can_block_with_weapon("marauder_sword") == true,
    "One-handed sword must preserve accepted Block behaviour."
)
check(
    EquipmentDefenseRules.can_block_with_weapon("apprentice_arcane_wand")
        == true,
    "Mage wand must preserve accepted Block behaviour for this gate."
)
check(
    EquipmentDefenseRules.can_block_with_weapon(nil) == true,
    "Empty weapon state must preserve accepted neutral behaviour."
)

print(
    string.format(
        "[Equipment Defense Rules Tests] PASS: %d assertions.",
        assertions
    )
)
