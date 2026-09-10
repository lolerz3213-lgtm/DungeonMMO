--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ward_highlights: {[Model]: Highlight} = {}
local wind_charge_orbs: {[Model]: Part} = {}

local function clear_wind_charge(character: Model)
    local orb = wind_charge_orbs[character]
    if orb then
        orb:Destroy()
        wind_charge_orbs[character] = nil
    end
end

local function update_wind_charge(character: Model)
    local charging = character:GetAttribute("WindStrikeCharging") == true
    if not charging then
        clear_wind_charge(character)
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end

    local existing = wind_charge_orbs[character]
    if existing and existing.Parent then return end

    local orb = Instance.new("Part")
    orb.Name = "WindStrikeChargeOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(0.8, 0.8, 0.8)
    orb.Material = Enum.Material.Neon
    orb.Color = Color3.fromRGB(195, 240, 255)
    orb.Transparency = 0.15
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.Massless = true
    orb.CastShadow = false
    orb.CFrame = root.CFrame * CFrame.new(0.9, 0.8, -1.35)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = orb
    weld.Parent = orb

    local light = Instance.new("PointLight")
    light.Brightness = 2.6
    light.Range = 10
    light.Color = orb.Color
    light.Parent = orb

    orb.Parent = character
    wind_charge_orbs[character] = orb

    local ends_at = tonumber(character:GetAttribute("WindStrikeChargeEndsAt")) or 0
    task.spawn(function()
        while wind_charge_orbs[character] == orb
            and orb.Parent
            and character:GetAttribute("WindStrikeCharging") == true do
            local remaining = math.max(0, ends_at - workspace:GetServerTimeNow())
            local progress = math.clamp(1 - remaining, 0, 1)
            local diameter = 0.8 + progress * 0.9
            orb.Size = Vector3.new(diameter, diameter, diameter)
            light.Brightness = 2.6 + progress * 2.2
            task.wait(0.05)
        end
    end)
end

local function update_ward(character: Model)
    local active =
        character:GetAttribute(
            "ArcaneWardActive"
        ) == true
    local existing =
        ward_highlights[character]

    if active then
        if existing and existing.Parent then
            return
        end

        local highlight =
            Instance.new("Highlight")
        highlight.Name = "ArcaneWardHighlight"
        highlight.Adornee = character
        highlight.DepthMode =
            Enum.HighlightDepthMode.Occluded
        highlight.FillColor =
            Color3.fromRGB(105, 170, 255)
        highlight.OutlineColor =
            Color3.fromRGB(190, 225, 255)
        highlight.FillTransparency = 0.78
        highlight.OutlineTransparency = 0.10
        highlight.Parent = character
        ward_highlights[character] = highlight
    elseif existing then
        existing:Destroy()
        ward_highlights[character] = nil
    end
end

local function show_heal_pulse(character: Model)
    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root or not root:IsA("BasePart") then
        return
    end

    local amount = tonumber(
        character:GetAttribute(
            "MageHealLastAmount"
        )
    ) or 0

    if amount <= 0 then
        return
    end

    local pulse = Instance.new("Part")
    pulse.Name = "MageHealPulse"
    pulse.Shape = Enum.PartType.Ball
    pulse.Size = Vector3.new(2.2, 2.2, 2.2)
    pulse.CFrame = root.CFrame
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.Material = Enum.Material.Neon
    pulse.Color = Color3.fromRGB(
        132,
        255,
        183
    )
    pulse.Transparency = 0.58
    pulse.CastShadow = false
    pulse.Parent = workspace
    Debris:AddItem(pulse, 0.25)

    local billboard =
        Instance.new("BillboardGui")
    billboard.Name = "MageHealAmount"
    billboard.Size =
        UDim2.fromOffset(120, 36)
    billboard.StudsOffset =
        Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = root
    billboard.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 =
        Color3.fromRGB(160, 255, 194)
    label.TextStrokeTransparency = 0.4
    label.TextScaled = true
    label.Text = string.format(
        "+%.0f",
        amount
    )
    label.Parent = billboard

    Debris:AddItem(billboard, 0.75)
end

local function connect_character(
    character: Model
)
    character:GetAttributeChangedSignal(
        "ArcaneWardActive"
    ):Connect(function()
        update_ward(character)
    end)

    character:GetAttributeChangedSignal(
        "MageHealPulse"
    ):Connect(function()
        show_heal_pulse(character)
    end)

    character:GetAttributeChangedSignal(
        "WindStrikeCharging"
    ):Connect(function()
        update_wind_charge(character)
    end)

    character:GetAttributeChangedSignal(
        "WindStrikeChargeEndsAt"
    ):Connect(function()
        update_wind_charge(character)
    end)

    update_ward(character)
    update_wind_charge(character)
end

local function connect_player(
    player: Player
)
    player.CharacterAdded:Connect(
        connect_character
    )

    if player.Character then
        connect_character(player.Character)
    end
end

Players.PlayerAdded:Connect(connect_player)

for _, player in Players:GetPlayers() do
    connect_player(player)
end

Players.PlayerRemoving:Connect(
    function(player)
        local character = player.Character

        if character
            and ward_highlights[character]
        then
            ward_highlights[character]:Destroy()
            ward_highlights[character] = nil
        end
        if character then
            clear_wind_charge(character)
        end
    end
)
