--!strict
-- Hand-authored greybox route for the first real dungeon slice.
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "DungeonRuntime"
local existing = Workspace:FindFirstChild(ROOT_NAME)
if existing then
    existing:Destroy()
end

local root = Instance.new("Folder")
root.Name = ROOT_NAME
root.Parent = Workspace

local function part(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    collide: boolean
): Part
    local created = Instance.new("Part")
    created.Name = name
    created.Anchored = true
    created.Size = size
    created.CFrame = cframe
    created.Color = color
    created.Material = Enum.Material.Slate
    created.CanCollide = collide
    created.CanTouch = true
    created.CanQuery = true
    created.Parent = parent
    return created
end

local function label(parent: BasePart, text: string)
    local gui = Instance.new("BillboardGui")
    gui.Name = "RoomLabel"
    gui.Size = UDim2.fromOffset(280, 54)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = parent

    local text_label = Instance.new("TextLabel")
    text_label.Size = UDim2.fromScale(1, 1)
    text_label.BackgroundTransparency = 1
    text_label.TextScaled = true
    text_label.Text = text
    text_label.TextColor3 = Color3.fromRGB(240, 240, 240)
    text_label.TextStrokeTransparency = 0.45
    text_label.Parent = gui
end

local function room(
    name: string,
    center: Vector3,
    size: Vector3,
    color: Color3
): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = root

    local floor = part(
        model,
        "Floor",
        Vector3.new(size.X, 1, size.Z),
        CFrame.new(center),
        color,
        true
    )
    label(floor, name)

    local wall_height = 12
    part(
        model,
        "WallLeft",
        Vector3.new(1, wall_height, size.Z),
        CFrame.new(
            center + Vector3.new(-size.X / 2, wall_height / 2, 0)
        ),
        Color3.fromRGB(70, 72, 78),
        true
    )
    part(
        model,
        "WallRight",
        Vector3.new(1, wall_height, size.Z),
        CFrame.new(
            center + Vector3.new(size.X / 2, wall_height / 2, 0)
        ),
        Color3.fromRGB(70, 72, 78),
        true
    )
    return model
end

local function trigger(
    parent: Instance,
    name: string,
    position: Vector3,
    size: Vector3
): Part
    local created = part(
        parent,
        name,
        size,
        CFrame.new(position),
        Color3.fromRGB(80, 180, 110),
        false
    )
    created.Transparency = 0.75
    return created
end

local x = 250
local entrance = room(
    "Entrance",
    Vector3.new(x, 0, 35),
    Vector3.new(52, 1, 50),
    Color3.fromRGB(84, 92, 105)
)
local room1 = room(
    "Room1",
    Vector3.new(x, 0, -45),
    Vector3.new(64, 1, 64),
    Color3.fromRGB(92, 84, 82)
)
local room2 = room(
    "Room2",
    Vector3.new(x, 0, -145),
    Vector3.new(72, 1, 72),
    Color3.fromRGB(88, 80, 92)
)
local boss = room(
    "BossRoom",
    Vector3.new(x, 0, -315),
    Vector3.new(80, 1, 80),
    Color3.fromRGB(105, 78, 70)
)

part(
    root,
    "Corridor_Entrance_R1",
    Vector3.new(18, 1, 32),
    CFrame.new(x, 0, -2),
    Color3.fromRGB(74, 76, 82),
    true
)
part(
    root,
    "Corridor_R1_R2",
    Vector3.new(18, 1, 40),
    CFrame.new(x, 0, -95),
    Color3.fromRGB(74, 76, 82),
    true
)
part(
    root,
    "Corridor_R2_Boss",
    Vector3.new(18, 1, 94),
    CFrame.new(x, 0, -228),
    Color3.fromRGB(74, 76, 82),
    true
)

local spawn = part(
    entrance,
    "DungeonSpawn",
    Vector3.new(6, 0.5, 6),
    CFrame.new(x, 1, 50),
    Color3.fromRGB(72, 150, 92),
    false
)
spawn.Transparency = 0.15

trigger(
    room1,
    "Room1StartTrigger",
    Vector3.new(x, 3, -18),
    Vector3.new(50, 6, 5)
)
trigger(
    room2,
    "Room2StartTrigger",
    Vector3.new(x, 3, -112),
    Vector3.new(56, 6, 5)
)
local boss_trigger = trigger(
    boss,
    "BossStartTrigger",
    Vector3.new(x, 3, -284),
    Vector3.new(58, 6, 5)
)
boss_trigger.Color = Color3.fromRGB(210, 122, 70)

local gate1 = part(
    room1,
    "Room1ExitGate",
    Vector3.new(20, 10, 1.5),
    CFrame.new(x, 5, -76),
    Color3.fromRGB(150, 72, 72),
    true
)
local gate2 = part(
    room2,
    "Room2ExitGate",
    Vector3.new(20, 10, 1.5),
    CFrame.new(x, 5, -181),
    Color3.fromRGB(150, 72, 72),
    true
)

for _, gate in ipairs({gate1, gate2}) do
    gate:SetAttribute("DungeonGate", true)
end

print(
    "[Dungeon Builder] Entrance -> Room1 -> Room2 -> BossRoom created."
)
