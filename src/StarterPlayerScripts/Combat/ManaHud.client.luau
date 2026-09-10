--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ProgressionClientState = require(
    script.Parent.Parent
        :WaitForChild("Core")
        :WaitForChild("ProgressionClientState")
)

local gui: ScreenGui? = nil
local fill: Frame? = nil
local label: TextLabel? = nil
local mage = false

local function update_visibility()
    if gui then
        gui.Enabled = mage
    end
end

local function update_value()
    if not fill or not label then
        return
    end

    local current = tonumber(
        player:GetAttribute("CombatMana")
    ) or 0
    local maximum = tonumber(
        player:GetAttribute("CombatMaxMana")
    ) or 100
    local regen = tonumber(
        player:GetAttribute(
            "CombatManaRegenPerSecond"
        )
    ) or 0
    local ratio = if maximum > 0
        then math.clamp(
            current / maximum,
            0,
            1
        )
        else 0

    fill.Size = UDim2.fromScale(
        ratio,
        1
    )
    label.Text = string.format(
        "MANA  %.0f / %.0f  (+%.1f/s)",
        current,
        maximum,
        regen
    )
end

local function create_gui()
    local player_gui =
        player:WaitForChild("PlayerGui")
    local old =
        player_gui:FindFirstChild(
            "CombatManaGui"
        )

    if old then
        old:Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "CombatManaGui"
    screen.ResetOnSpawn = false
    screen.Parent = player_gui

    local container =
        Instance.new("Frame")
    container.AnchorPoint =
        Vector2.new(0.5, 1)
    container.Position =
        UDim2.new(0.5, 0, 1, -72)
    container.Size =
        UDim2.fromOffset(300, 22)
    container.BackgroundColor3 =
        Color3.fromRGB(28, 30, 34)
    container.BackgroundTransparency = 0.2
    container.Parent = screen

    local value = Instance.new("Frame")
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundColor3 =
        Color3.fromRGB(90, 120, 230)
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
    update_visibility()
end

local function apply_identity_snapshot(
    snapshot: any
)
    local identity =
        type(snapshot) == "table"
        and snapshot.Identity
        or nil

    mage =
        type(identity) == "table"
        and identity.BaseClassId == "Mage"

    update_visibility()
end

create_gui()
apply_identity_snapshot(
    ProgressionClientState.get_snapshot()
)
ProgressionClientState.subscribe(
    apply_identity_snapshot
)

for _, name in {
    "CombatMana",
    "CombatMaxMana",
    "CombatManaRegenPerSecond",
} do
    player:GetAttributeChangedSignal(name)
        :Connect(update_value)
end
