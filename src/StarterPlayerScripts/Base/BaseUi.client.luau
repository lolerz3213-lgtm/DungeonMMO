--!strict
-- Functional Starting Base entry UI. Server remains authoritative over admission/teleport state.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local entry_request = remotes:WaitForChild("DungeonEntryRequest") :: RemoteEvent
local entry_result = remotes:WaitForChild("DungeonEntryResult") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "BaseUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = 150
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.fromScale(0.5, 0.96)
panel.Size = UDim2.fromOffset(420, 105)
panel.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
panel.BackgroundTransparency = 0.12
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.fromOffset(10, 6)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245,245,245)
title.TextScaled = true
title.Text = "Marauder Training Dungeon"
title.Parent = panel

local button = Instance.new("TextButton")
button.Name = "EnterDungeon"
button.Position = UDim2.fromOffset(18, 48)
button.Size = UDim2.fromOffset(170, 46)
button.TextScaled = true
button.Text = "Enter Dungeon"
button.Selectable = true
button.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(198, 48)
status.Size = UDim2.fromOffset(205, 46)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220,220,220)
status.TextWrapped = true
status.TextScaled = true
status.Text = "Solo prototype • 1–4 supported by services"
status.Parent = panel

local pending = false
local function set_pending(value: boolean)
    pending = value
    button.Active = not value
    button.AutoButtonColor = not value
    button.Text = if value then "Entering..." else "Enter Dungeon"
end

button.Activated:Connect(function()
    if pending then return end
    set_pending(true)
    status.Text = "Requesting dungeon..."
    entry_request:FireServer("TestDungeon")
end)

entry_result.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    if payload.ok == true then
        status.Text = "Teleporting to reserved dungeon..."
        set_pending(true)
    else
        local reason = tostring(payload.reason or "EntryFailed")
        if reason == "PublishedTeleportRequired" then
            status.Text = "Studio: published teleport required"
        else
            status.Text = "Entry blocked: " .. reason
        end
        set_pending(false)
    end
end)
