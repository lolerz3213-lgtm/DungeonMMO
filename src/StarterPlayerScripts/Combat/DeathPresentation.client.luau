local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local FADE_SECONDS = 0.35
local DEATH_BACKGROUND_TRANSPARENCY = 0.35

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "Phase1DeathPresentation"
screen_gui.IgnoreGuiInset = true
screen_gui.ResetOnSpawn = false
screen_gui.DisplayOrder = 1000
screen_gui.Parent = player_gui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(32, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Parent = screen_gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.46)
title.Size = UDim2.fromOffset(520, 84)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "DEFEATED"
title.TextColor3 = Color3.fromRGB(240, 225, 225)
title.TextScaled = true
title.TextTransparency = 1
title.Parent = backdrop

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.54)
subtitle.Size = UDim2.fromOffset(520, 38)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Returning to the arena..."
subtitle.TextColor3 = Color3.fromRGB(220, 205, 205)
subtitle.TextScaled = true
subtitle.TextTransparency = 1
subtitle.Parent = backdrop

local death_serial = 0


--[[Shows the minimal Phase 1 death overlay.]]
local function show_death()
    death_serial += 1
    backdrop.BackgroundTransparency = DEATH_BACKGROUND_TRANSPARENCY
    title.TextTransparency = 0
    subtitle.TextTransparency = 0
end


--[[Fades the death overlay away after a fresh character spawns.]]
local function hide_death(expected_serial: number)
    if expected_serial ~= death_serial then
        return
    end

    TweenService:Create(
        backdrop,
        TweenInfo.new(FADE_SECONDS),
        {BackgroundTransparency = 1}
    ):Play()
    TweenService:Create(
        title,
        TweenInfo.new(FADE_SECONDS),
        {TextTransparency = 1}
    ):Play()
    TweenService:Create(
        subtitle,
        TweenInfo.new(FADE_SECONDS),
        {TextTransparency = 1}
    ):Play()
end


--[[Hooks death for one newly spawned local character.]]
local function track_character(character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local spawn_serial = death_serial

    if spawn_serial > 0 then
        hide_death(spawn_serial)
    end

    humanoid.Died:Connect(show_death)
end


player.CharacterAdded:Connect(track_character)

if player.Character then
    track_character(player.Character)
end
