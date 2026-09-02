local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local ARENA_CONFIG = CombatConfig.ARENA


--[[
Creates one anchored Part used by the combat prototype.

Args:
    parent (Instance): Parent that receives the new Part.
    name (string): Name assigned to the Part.
    size (Vector3): Dimensions of the Part.
    position (Vector3): World position of the Part.
    color (Color3): Display colour for the Part.
    can_collide (boolean): Whether characters collide with the Part.

Returns:
    Part: The configured Part instance.
]]
local function create_part(
    parent: Instance,
    name: string,
    size: Vector3,
    position: Vector3,
    color: Color3,
    can_collide: boolean
): Part
    local part = Instance.new("Part")

    part.Name = name
    part.Anchored = true
    part.CanCollide = can_collide
    part.CanQuery = true
    part.CanTouch = false
    part.Material = Enum.Material.SmoothPlastic
    part.Color = color
    part.Size = size
    part.Position = position
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent

    return part
end


--[[
Adds a floating measurement label to a distance marker.

Args:
    marker (Part): Marker Part that owns the label.
    distance (number): Distance in studs displayed to the player.

Returns:
    BillboardGui: The configured floating label.
]]
local function add_distance_label(
    marker: Part,
    distance: number
): BillboardGui
    local attachment = Instance.new("Attachment")

    attachment.Name = "LabelAttachment"
    attachment.Position = Vector3.new(
        -(ARENA_CONFIG.FLOOR_SIZE.X / 2) + 5,
        1.4,
        0
    )
    attachment.Parent = marker

    local billboard = Instance.new("BillboardGui")

    billboard.Name = "DistanceLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(90, 28)
    billboard.StudsOffset = Vector3.new(0, 0.2, 0)
    billboard.Adornee = attachment
    billboard.Parent = marker

    local label = Instance.new("TextLabel")

    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = string.format("%d studs", distance)
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.TextScaled = true
    label.TextStrokeTransparency = 0.35
    label.Parent = billboard

    return billboard
end


--[[
Creates one floor line showing distance from the reset point.

Args:
    parent (Instance): Arena container receiving the marker.
    distance (number): Distance from the reset point in studs.

Returns:
    Part: The created distance marker.
]]
local function create_distance_marker(
    parent: Instance,
    distance: number
): Part
    local marker_z = ARENA_CONFIG.SPAWN_POSITION.Z - distance

    local marker = create_part(
        parent,
        string.format("Distance_%d", distance),
        Vector3.new(
            ARENA_CONFIG.FLOOR_SIZE.X - 4,
            0.04,
            0.12
        ),
        Vector3.new(0, 0.03, marker_z),
        ARENA_CONFIG.MARKER_COLOR,
        false
    )

    marker.Material = Enum.Material.Neon
    marker.CastShadow = false

    add_distance_label(marker, distance)

    return marker
end


--[[
Creates the reset/spawn pad used by the combat prototype.

Args:
    parent (Instance): Arena container receiving the spawn.

Returns:
    SpawnLocation: The configured prototype spawn location.
]]
local function create_spawn(
    parent: Instance
): SpawnLocation
    local spawn = Instance.new("SpawnLocation")

    spawn.Name = "CombatResetPoint"
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Neutral = true
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0

    spawn.Material = Enum.Material.SmoothPlastic
    spawn.Color = ARENA_CONFIG.SPAWN_COLOR
    spawn.Size = ARENA_CONFIG.SPAWN_SIZE
    spawn.Position = ARENA_CONFIG.SPAWN_POSITION

    spawn.TopSurface = Enum.SurfaceType.Smooth
    spawn.BottomSurface = Enum.SurfaceType.Smooth

    spawn.Parent = parent

    return spawn
end


--[[
Removes only the runtime arena previously created by this script.

Args:
    None.

Returns:
    None.
]]
local function remove_existing_arena()
    local existing = Workspace:FindFirstChild(
        ARENA_CONFIG.ROOT_NAME
    )

    if existing then
        existing:Destroy()
    end
end


--[[
Builds the deterministic greybox combat prototype arena.

Args:
    None.

Returns:
    Folder: Container holding all generated arena geometry.
]]
local function build_arena(): Folder
    remove_existing_arena()

    local arena = Instance.new("Folder")

    arena.Name = ARENA_CONFIG.ROOT_NAME
    arena.Parent = Workspace

    create_part(
        arena,
        "Floor",
        ARENA_CONFIG.FLOOR_SIZE,
        ARENA_CONFIG.FLOOR_POSITION,
        ARENA_CONFIG.FLOOR_COLOR,
        true
    )

    for index, position in ARENA_CONFIG.PILLAR_POSITIONS do
        create_part(
            arena,
            string.format("Pillar_%d", index),
            ARENA_CONFIG.PILLAR_SIZE,
            position,
            ARENA_CONFIG.PILLAR_COLOR,
            true
        )
    end

    for _, distance in ARENA_CONFIG.MARKER_DISTANCES do
        create_distance_marker(arena, distance)
    end

    create_spawn(arena)

    print("[Combat Prototype] Greybox arena created.")

    return arena
end


build_arena()
