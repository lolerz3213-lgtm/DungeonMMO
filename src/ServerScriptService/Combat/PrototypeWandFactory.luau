--!strict
local PrototypeWandFactory = {}

local function part(
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

local function weld(
    handle: BasePart,
    child: BasePart,
    offset: CFrame
)
    child.CFrame = handle.CFrame * offset

    local constraint =
        Instance.new("WeldConstraint")
    constraint.Part0 = handle
    constraint.Part1 = child
    constraint.Parent = child
end

function PrototypeWandFactory.create_tool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "PrototypeArcaneWand"
    tool.RequiresHandle = true
    tool.ManualActivationOnly = true
    tool.CanBeDropped = false
    tool.Enabled = true
    tool.ToolTip = "Prototype Apprentice Arcane Wand"
    tool.Grip =
        CFrame.new(0, -0.45, 0)
        * CFrame.Angles(
            0,
            0,
            math.rad(-18)
        )

    local handle = part(
        tool,
        "Handle",
        Vector3.new(0.26, 2.15, 0.26),
        Color3.fromRGB(82, 57, 38),
        Enum.Material.Wood
    )
    local collar = part(
        tool,
        "Collar",
        Vector3.new(0.48, 0.24, 0.48),
        Color3.fromRGB(186, 151, 78),
        Enum.Material.Metal
    )
    local focus = part(
        tool,
        "ArcaneFocus",
        Vector3.new(0.58, 0.58, 0.58),
        Color3.fromRGB(112, 174, 255),
        Enum.Material.Neon
    )
    focus.Shape = Enum.PartType.Ball

    weld(
        handle,
        collar,
        CFrame.new(0, 0.92, 0)
    )
    weld(
        handle,
        focus,
        CFrame.new(0, 1.24, 0)
    )

    local light = Instance.new("PointLight")
    light.Name = "ArcaneFocusGlow"
    light.Brightness = 1.2
    light.Range = 5
    light.Color = focus.Color
    light.Parent = focus

    return tool
end

return table.freeze(PrototypeWandFactory)
