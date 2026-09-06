local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local WeaponConfig = CombatConfig.PROTOTYPE_WEAPON

local PrototypeWeaponFactory = {}

local HILT_GRIP = CFrame.new(
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    0,
    0,
    0,
    1,
    0
)

-- Positive local Z is the direction that visually points away from the
-- character with the current Tool grip rotation.
local GUARD_OFFSET = CFrame.new(
    0,
    0,
    0.60
)
local BLADE_OFFSET = CFrame.new(
    0,
    0,
    2.18
)
local POMMEL_OFFSET = CFrame.new(
    0,
    0,
    -0.65
)


--[[
Creates one unanchored sword Part.

Args:
    parent (Instance): Parent that receives the Part.
    name (string): Instance name.
    size (Vector3): Part dimensions.
    color (Color3): Part colour.
    material (Enum.Material): Part material.

Returns:
    Part: Configured Part.
]]
local function create_part(
    parent: Instance,
    name: string,
    size: Vector3,
    color: Color3,
    material: Enum.Material
): Part
    local part = Instance.new("Part")

    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent

    return part
end


--[[
Rigidly attaches one visual sword Part to the hilt Handle.

Args:
    handle (BasePart): Hilt Handle that owns weapon motion.
    part (BasePart): Visual Part to attach.
    local_offset (CFrame): Part transform relative to Handle.

Returns:
    WeldConstraint: Constraint joining the Part to Handle.
]]
local function weld_to_handle(
    handle: BasePart,
    part: BasePart,
    local_offset: CFrame
): WeldConstraint
    part.CFrame = handle.CFrame * local_offset

    local weld = Instance.new("WeldConstraint")

    weld.Name = part.Name .. "Weld"
    weld.Part0 = handle
    weld.Part1 = part
    weld.Parent = part

    return weld
end


--[[
Adds the active-frame Trail to the visible blade.

Args:
    blade (BasePart): Visible sword blade.

Returns:
    Trail: Disabled Trail used during Active frames.
]]
local function create_blade_trail(
    blade: BasePart
): Trail
    local half_length = blade.Size.Z / 2

    local base_attachment = Instance.new(
        "Attachment"
    )

    base_attachment.Name = "TrailBase"
    base_attachment.Position = Vector3.new(
        0,
        0,
        half_length
    )
    base_attachment.Parent = blade

    local tip_attachment = Instance.new(
        "Attachment"
    )

    tip_attachment.Name = "TrailTip"
    tip_attachment.Position = Vector3.new(
        0,
        0,
        -half_length
    )
    tip_attachment.Parent = blade

    local trail = Instance.new("Trail")

    trail.Name = WeaponConfig.TRAIL_NAME
    trail.Attachment0 = base_attachment
    trail.Attachment1 = tip_attachment
    trail.Enabled = false
    trail.Lifetime = 0.08
    trail.FaceCamera = true
    trail.Parent = blade

    return trail
end


--[[
Creates the visible wooden hilt as the Tool Handle.

Args:
    tool (Tool): Tool receiving the hilt Handle.

Returns:
    Part: Visible Tool Handle.
]]
local function create_hilt_handle(
    tool: Tool
): Part
    return create_part(
        tool,
        WeaponConfig.HANDLE_NAME,
        WeaponConfig.HILT_SIZE,
        Color3.fromRGB(62, 42, 28),
        Enum.Material.Wood
    )
end


--[[
Builds blade, guard, and pommel around the hilt Handle.

Args:
    tool (Tool): Tool receiving sword geometry.
    handle (BasePart): Visible hilt Handle.

Returns:
    Trail: Trail attached to the blade.
]]
local function create_sword_geometry(
    tool: Tool,
    handle: BasePart
): Trail
    local blade = create_part(
        tool,
        WeaponConfig.BLADE_NAME,
        WeaponConfig.BLADE_SIZE,
        Color3.fromRGB(205, 210, 220),
        Enum.Material.Metal
    )
    local guard = create_part(
        tool,
        "Guard",
        WeaponConfig.GUARD_SIZE,
        Color3.fromRGB(92, 72, 42),
        Enum.Material.Metal
    )
    local pommel = create_part(
        tool,
        "Pommel",
        WeaponConfig.POMMEL_SIZE,
        Color3.fromRGB(92, 72, 42),
        Enum.Material.Metal
    )

    weld_to_handle(
        handle,
        blade,
        BLADE_OFFSET
    )
    weld_to_handle(
        handle,
        guard,
        GUARD_OFFSET
    )
    weld_to_handle(
        handle,
        pommel,
        POMMEL_OFFSET
    )

    return create_blade_trail(blade)
end


--[[
Creates one complete prototype sword Tool.

Args:
    None.

Returns:
    Tool: Complete prototype sword ready to equip.
]]
function PrototypeWeaponFactory.create_tool(): Tool
    local tool = Instance.new("Tool")

    tool.Name = WeaponConfig.TOOL_NAME
    tool.RequiresHandle = true
    tool.ManualActivationOnly = true
    tool.CanBeDropped = false
    tool.Enabled = true
    tool.Grip = HILT_GRIP
    tool.ToolTip = "Prototype sword"
    tool:SetAttribute("WeaponTagOneHandedSword", true)

    local handle = create_hilt_handle(tool)

    create_sword_geometry(
        tool,
        handle
    )

    return tool
end


return PrototypeWeaponFactory
