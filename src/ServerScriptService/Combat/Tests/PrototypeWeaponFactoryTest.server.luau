local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local PrototypeWeaponFactory = require(
    script.Parent.Parent:WaitForChild(
        "PrototypeWeaponFactory"
    )
)

local WeaponConfig = CombatConfig.PROTOTYPE_WEAPON
local assertion_count = 0


--[[
Raises an error when a prototype weapon assertion fails.

Args:
    condition (boolean): Condition that must be true.
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
            "[Combat Weapon Tests] " .. message
        )
    end
end


--[[
Returns whether one Part is welded to the Handle.

Args:
    part (BasePart): Sword Part being inspected.
    handle (BasePart): Tool Handle expected in the weld.

Returns:
    boolean: True when a matching WeldConstraint exists.
]]
local function is_welded_to_handle(
    part: BasePart,
    handle: BasePart
): boolean
    for _, child in part:GetChildren() do
        if child:IsA("WeldConstraint") then
            local forward = child.Part0 == handle
                and child.Part1 == part
            local reverse = child.Part1 == handle
                and child.Part0 == part

            if forward or reverse then
                return true
            end
        end
    end

    return false
end


local tool = PrototypeWeaponFactory.create_tool()
local handle = tool:FindFirstChild(
    WeaponConfig.HANDLE_NAME
)
local blade = tool:FindFirstChild(
    WeaponConfig.BLADE_NAME
)
local guard = tool:FindFirstChild("Guard")
local pommel = tool:FindFirstChild("Pommel")

assert_true(
    tool:IsA("Tool"),
    "Factory must create a Tool."
)
assert_true(
    tool.RequiresHandle,
    "Prototype sword must require a Handle."
)
assert_true(
    tool.ManualActivationOnly,
    "Combat input must own Tool activation."
)
assert_true(
    not tool.CanBeDropped,
    "Prototype sword must not be droppable."
)
assert_true(
    tool.Grip.Position.Magnitude <= 0.01,
    "Grip must be centred on the hilt Handle."
)
assert_true(
    handle ~= nil and handle:IsA("BasePart"),
    "Sword must contain one BasePart named Handle."
)
assert_true(
    handle ~= nil and handle.Transparency < 1,
    "The hilt Handle must be visible."
)
assert_true(
    handle ~= nil
        and handle.Size == WeaponConfig.HILT_SIZE,
    "The Handle must use the configured hilt size."
)
assert_true(
    blade ~= nil and blade:IsA("BasePart"),
    "Sword must contain a blade."
)
assert_true(
    guard ~= nil and guard:IsA("BasePart"),
    "Sword must contain a guard."
)
assert_true(
    pommel ~= nil and pommel:IsA("BasePart"),
    "Sword must contain a pommel."
)

if handle and handle:IsA("BasePart") then
    if blade and blade:IsA("BasePart") then
        assert_true(
            is_welded_to_handle(
                blade,
                handle
            ),
            "Blade must be welded to the hilt Handle."
        )

        local blade_local =
            handle.CFrame:PointToObjectSpace(
                blade.Position
            )

        assert_true(
            blade_local.Z > 1,
            "Blade must extend from the correct hilt end."
        )

        local trail = blade:FindFirstChild(
            WeaponConfig.TRAIL_NAME
        )

        assert_true(
            trail ~= nil and trail:IsA("Trail"),
            "Blade must contain the active-frame Trail."
        )
    end

    if guard and guard:IsA("BasePart") then
        assert_true(
            is_welded_to_handle(
                guard,
                handle
            ),
            "Guard must be welded to the hilt Handle."
        )
    end

    if pommel and pommel:IsA("BasePart") then
        assert_true(
            is_welded_to_handle(
                pommel,
                handle
            ),
            "Pommel must be welded to the hilt Handle."
        )

        local pommel_local =
            handle.CFrame:PointToObjectSpace(
                pommel.Position
            )

        assert_true(
            pommel_local.Z < 0,
            "Pommel must sit opposite the blade."
        )
    end
end

tool:Destroy()

print(
    string.format(
        "[Combat Weapon Tests] PASS: %d assertions.",
        assertion_count
    )
)
