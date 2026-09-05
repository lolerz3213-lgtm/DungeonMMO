local Players = game:GetService("Players")

local player = Players.LocalPlayer

local fill: Frame? = nil
local value_label: TextLabel? = nil
local parry_label: TextLabel? = nil


--[[
Updates the prototype Stamina bar from replicated Player attributes.

Args:
    None.

Returns:
    None.
]]
local function update_stamina()
    if not fill or not value_label then
        return
    end

    local current = player:GetAttribute(
        "CombatStamina"
    ) or 0
    local maximum = player:GetAttribute(
        "CombatMaxStamina"
    ) or 100
    local ratio = 0

    if maximum > 0 then
        ratio = math.clamp(
            current / maximum,
            0,
            1
        )
    end

    fill.Size = UDim2.fromScale(
        ratio,
        1
    )
    value_label.Text = string.format(
        "STAMINA  %.0f / %.0f",
        current,
        maximum
    )
end


--[[
Shows a short server-confirmed parry cue.

Args:
    None.

Returns:
    None.
]]
local function show_parry()
    local label = parry_label

    if not label then
        return
    end

    label.Visible = true
    label.Text = "PARRY"

    local pulse = player:GetAttribute(
        "CombatParryPulse"
    )

    task.delay(0.35, function()
        if parry_label == label
            and player:GetAttribute(
                "CombatParryPulse"
            ) == pulse then
            label.Visible = false
        end
    end)
end


--[[
Creates the prototype defensive HUD.

Args:
    None.

Returns:
    None.
]]
local function create_gui()
    local player_gui = player:WaitForChild(
        "PlayerGui"
    )
    local existing = player_gui:FindFirstChild(
        "CombatStaminaGui"
    )

    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")

    gui.Name = "CombatStaminaGui"
    gui.ResetOnSpawn = false
    gui.Parent = player_gui

    local container = Instance.new("Frame")

    container.Name = "StaminaContainer"
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.Position = UDim2.new(
        0.5,
        0,
        1,
        -42
    )
    container.Size = UDim2.fromOffset(300, 24)
    container.BackgroundColor3 = Color3.fromRGB(28, 30, 34)
    container.BackgroundTransparency = 0.2
    container.Parent = gui

    local bar = Instance.new("Frame")

    bar.Name = "Fill"
    bar.Size = UDim2.fromScale(1, 1)
    bar.BackgroundColor3 = Color3.fromRGB(70, 180, 115)
    bar.BackgroundTransparency = 0.1
    bar.BorderSizePixel = 0
    bar.Parent = container

    local label = Instance.new("TextLabel")

    label.Name = "Value"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.TextSize = 15
    label.Parent = container

    local parry = Instance.new("TextLabel")

    parry.Name = "ParryCue"
    parry.AnchorPoint = Vector2.new(0.5, 1)
    parry.Position = UDim2.new(
        0.5,
        0,
        0,
        -6
    )
    parry.Size = UDim2.fromOffset(180, 34)
    parry.BackgroundTransparency = 1
    parry.Font = Enum.Font.GothamBold
    parry.TextColor3 = Color3.fromRGB(255, 230, 120)
    parry.TextSize = 28
    parry.Visible = false
    parry.Parent = container

    fill = bar
    value_label = label
    parry_label = parry

    update_stamina()
end


create_gui()

player:GetAttributeChangedSignal(
    "CombatStamina"
):Connect(update_stamina)
player:GetAttributeChangedSignal(
    "CombatMaxStamina"
):Connect(update_stamina)
player:GetAttributeChangedSignal(
    "CombatParryPulse"
):Connect(show_parry)
