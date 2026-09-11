--!strict
-- Functional placeholder Longbow presentation for Ranger acceptance testing.

local PrototypeLongbowFactory = {}

--[[
Creates one non-colliding massless bow part.

Args:
    parent (Instance): Parent for the new part.
    name (string): Part name.
    size (Vector3): Part dimensions.
    color (Color3): Part colour.
    material (Enum.Material): Roblox material.

Returns:
    Part: Configured bow part.
]]
local function create_part(
    parent: Instance,
    name: string,
    size: Vector3,
    color: Color3,
    material: Enum.Material
): Part
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.Color = color
    value.Material = material
    value.Anchored = false
    value.CanCollide = false
    value.CanQuery = false
    value.CanTouch = false
    value.Massless = true
    value.CastShadow = false
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

--[[
Welds one decorative part to the Tool Handle.

Args:
    handle (BasePart): Longbow Handle.
    child (BasePart): Decorative part to attach.
    offset (CFrame): Child pose relative to Handle.

Returns:
    None.
]]
local function weld(
    handle: BasePart,
    child: BasePart,
    offset: CFrame
)
    child.CFrame = handle.CFrame * offset

    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = handle
    constraint.Part1 = child
    constraint.Parent = child
end

--[[
Creates the functional prototype Apprentice Longbow Tool.

Args:
    None.

Returns:
    Tool: Equip-ready placeholder Longbow presentation.
]]
function PrototypeLongbowFactory.create_tool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "PrototypeLongbow"
    tool.RequiresHandle = true
    tool.ManualActivationOnly = true
    tool.CanBeDropped = false
    tool.Enabled = true
    tool.ToolTip = "Prototype Apprentice Longbow"
    tool.Grip = CFrame.new(0, -0.25, -0.35)
        * CFrame.Angles(
            math.rad(-10),
            math.rad(90),
            math.rad(90)
        )

    local wood = Color3.fromRGB(105, 67, 40)
    local string_color = Color3.fromRGB(220, 215, 195)
    local handle = create_part(
        tool,
        "Handle",
        Vector3.new(0.24, 1.65, 0.24),
        wood,
        Enum.Material.Wood
    )
    local upper = create_part(
        tool,
        "UpperLimb",
        Vector3.new(0.20, 2.8, 0.20),
        wood,
        Enum.Material.Wood
    )
    local lower = create_part(
        tool,
        "LowerLimb",
        Vector3.new(0.20, 2.8, 0.20),
        wood,
        Enum.Material.Wood
    )
    local string = create_part(
        tool,
        "BowString",
        Vector3.new(0.06, 6.7, 0.06),
        string_color,
        Enum.Material.SmoothPlastic
    )

    weld(
        handle,
        upper,
        CFrame.new(0, 2.05, -0.18)
            * CFrame.Angles(0, 0, math.rad(-10))
    )
    weld(
        handle,
        lower,
        CFrame.new(0, -2.05, -0.18)
            * CFrame.Angles(0, 0, math.rad(10))
    )
    weld(handle, string, CFrame.new(0, 0, 0.12))

    tool:SetAttribute("WeaponTagLongbow", true)
    return tool
end

return table.freeze(PrototypeLongbowFactory)
