local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local combat_folder = ReplicatedStorage
    :WaitForChild("Combat")
local shared_folder = combat_folder
    :WaitForChild("Shared")

local converter = require(
    shared_folder:WaitForChild(
        "OneHandedAnimationConverter"
    )
)
local weapon_factory = require(
    script.Parent.Parent:WaitForChild(
        "PrototypeWeaponFactory"
    )
)

local assertion_count = 0


--[[
Raises an error when an assertion fails.

Args:
    condition (boolean): Required condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Sword Carry/Grip Tests] " .. message
        )
    end
end


assert_true(
    converter.convert_carry ~= nil,
    "Converter must expose convert_carry."
)

local tool = weapon_factory.create_tool()
local handle = tool:FindFirstChild("Handle")
local blade = tool:FindFirstChild("Blade")
local pommel = tool:FindFirstChild("Pommel")

assert_true(
    handle ~= nil and handle:IsA("BasePart"),
    "Sword must contain a hilt Handle."
)
assert_true(
    handle ~= nil and handle.Transparency < 1,
    "Hilt Handle must remain visible."
)

if handle and handle:IsA("BasePart") then
    if blade and blade:IsA("BasePart") then
        local blade_local =
            handle.CFrame:PointToObjectSpace(
                blade.Position
            )

        assert_true(
            blade_local.Z > 1,
            "Blade must point from the correct end of the hilt."
        )
    end

    if pommel and pommel:IsA("BasePart") then
        local pommel_local =
            handle.CFrame:PointToObjectSpace(
                pommel.Position
            )

        assert_true(
            pommel_local.Z < 0,
            "Pommel must remain opposite the blade."
        )
    end
end

local imported = combat_folder:WaitForChild(
    "PrototypeAnimations",
    5
)

assert_true(
    imported ~= nil,
    "Converted animation folder must exist."
)
assert_true(
    imported ~= nil
        and imported:FindFirstChild(
            "SwordCarry"
        ) ~= nil,
    "SwordCarry overlay must be imported."
)

tool:Destroy()

print(
    string.format(
        "[Sword Carry/Grip Tests] PASS: %d assertions.",
        assertion_count
    )
)
