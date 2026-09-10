--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local fill: Frame? = nil
local label: TextLabel? = nil
local character_connections: {RBXScriptConnection} = {}

local function disconnect_character()
    for _, connection in character_connections do
        connection:Disconnect()
    end
    table.clear(character_connections)
end

local function update_value()
    local character = player.Character

    if not gui or not fill or not label
        or not character
    then
        if gui then
            gui.Enabled = false
        end
        return
    end

    local active =
        character:GetAttribute(
            "ArcaneWardActive"
        ) == true
    local current = tonumber(
        character:GetAttribute(
            "ArcaneWardCurrent"
        )
    ) or 0
    local maximum = tonumber(
        character:GetAttribute(
            "ArcaneWardMax"
        )
    ) or 0

    gui.Enabled =
        active
        and current > 0
        and maximum > 0

    if not gui.Enabled then
        return
    end

    local ratio = math.clamp(
        current / maximum,
        0,
        1
    )
    fill.Size = UDim2.fromScale(
        ratio,
        1
    )
    label.Text = string.format(
        "WARD  %.0f / %.0f",
        current,
        maximum
    )
end

local function create_gui()
    local player_gui =
        player:WaitForChild("PlayerGui")
    local old =
        player_gui:FindFirstChild(
            "ArcaneWardGui"
        )

    if old then
        old:Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "ArcaneWardGui"
    screen.ResetOnSpawn = false
    screen.Enabled = false
    screen.Parent = player_gui

    local container =
        Instance.new("Frame")
    container.AnchorPoint =
        Vector2.new(0.5, 1)
    container.Position =
        UDim2.new(0.5, 0, 1, -100)
    container.Size =
        UDim2.fromOffset(300, 20)
    container.BackgroundColor3 =
        Color3.fromRGB(28, 30, 34)
    container.BackgroundTransparency = 0.2
    container.Parent = screen

    local value = Instance.new("Frame")
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundColor3 =
        Color3.fromRGB(115, 185, 255)
    value.BackgroundTransparency = 0.08
    value.BorderSizePixel = 0
    value.Parent = container

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.Code
    text.TextColor3 =
        Color3.fromRGB(245, 245, 245)
    text.TextSize = 14
    text.Parent = container

    gui = screen
    fill = value
    label = text
    update_value()
end

local function bind_character(
    character: Model
)
    disconnect_character()

    for _, name in {
        "ArcaneWardActive",
        "ArcaneWardCurrent",
        "ArcaneWardMax",
    } do
        table.insert(
            character_connections,
            character
                :GetAttributeChangedSignal(name)
                :Connect(update_value)
        )
    end

    update_value()
end

create_gui()

player.CharacterAdded:Connect(
    bind_character
)
player.CharacterRemoving:Connect(
    function()
        disconnect_character()
        update_value()
    end
)

if player.Character then
    bind_character(player.Character)
else
    update_value()
end
