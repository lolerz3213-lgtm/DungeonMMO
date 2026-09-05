--!strict
-- Functional Phase 2A.6-2A.7 UI. Visual polish remains part of the later full Dungeon UI slice.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local core = ReplicatedStorage:WaitForChild("Core")
local PresentationLayers = require(core:WaitForChild("Shared"):WaitForChild("PresentationLayers"))
local remotes = core:WaitForChild("Remotes")
local dungeon_state = remotes:WaitForChild("DungeonStateChanged") :: RemoteEvent
local revive_request = remotes:WaitForChild("ReviveRequest") :: RemoteEvent
local revive_state = remotes:WaitForChild("ReviveStateChanged") :: RemoteEvent
local profile_snapshot = remotes:WaitForChild("ProfileSnapshot") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "DungeonSliceUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = PresentationLayers.DUNGEON_REVIVE
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local objective = Instance.new("TextLabel")
objective.Name = "Objective"
objective.AnchorPoint = Vector2.new(0.5, 0)
objective.Position = UDim2.fromScale(0.5, 0.03)
objective.Size = UDim2.fromOffset(620, 48)
objective.BackgroundTransparency = 0.25
objective.BackgroundColor3 = Color3.fromRGB(24, 26, 31)
objective.TextColor3 = Color3.fromRGB(245, 245, 245)
objective.TextScaled = true
objective.Text = "Dungeon loading..."
objective.Parent = gui

local profile = Instance.new("TextLabel")
profile.Name = "Profile"
profile.Position = UDim2.fromOffset(18, 18)
profile.Size = UDim2.fromOffset(260, 34)
profile.BackgroundTransparency = 0.3
profile.BackgroundColor3 = Color3.fromRGB(24, 26, 31)
profile.TextColor3 = Color3.fromRGB(245, 245, 245)
profile.TextScaled = true
profile.Text = "Level 1 | XP 0 | Gold 0"
profile.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "RevivePanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(420, 220)
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 48)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextScaled = true
title.Text = "DEFEATED"
title.Parent = panel

local timer_label = Instance.new("TextLabel")
timer_label.Size = UDim2.new(1, -20, 0, 34)
timer_label.Position = UDim2.fromOffset(10, 62)
timer_label.BackgroundTransparency = 1
timer_label.TextColor3 = Color3.fromRGB(220, 220, 220)
timer_label.TextScaled = true
timer_label.Text = ""
timer_label.Parent = panel

local free_button = Instance.new("TextButton")
free_button.Size = UDim2.fromOffset(180, 54)
free_button.Position = UDim2.fromOffset(20, 130)
free_button.TextScaled = true
free_button.Text = "Free Revive"
free_button.Parent = panel

local paid_button = Instance.new("TextButton")
paid_button.Size = UDim2.fromOffset(180, 54)
paid_button.Position = UDim2.fromOffset(220, 130)
paid_button.TextScaled = true
paid_button.Text = "Paid Revive"
paid_button.Parent = panel

local wipe_ends_at: number? = nil
local last_server_time = 0
local received_at = 0

free_button.Activated:Connect(function() revive_request:FireServer("Free") end)
paid_button.Activated:Connect(function() revive_request:FireServer("Paid") end)

dungeon_state.OnClientEvent:Connect(function(payload)
    if type(payload) == "table" and type(payload.objective) == "string" then
        objective.Text = payload.objective
    end
end)

profile_snapshot.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    profile.Text = string.format("Level %d | XP %d | Gold %d", payload.Level or 1, payload.XP or 0, payload.Gold or 0)
end)

revive_state.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    if payload.error then
        timer_label.Text = "Revive error: " .. tostring(payload.error)
        return
    end
    local mode = payload.member_mode
    panel.Visible = mode == "Dead" or mode == "Spectating"
    free_button.Visible = payload.free_available == true
    local offer = payload.paid_offer
    paid_button.Visible = type(offer) == "table" and payload.free_available ~= true
    if type(offer) == "table" then
        paid_button.Text = if RunService:IsStudio()
            then string.format("Sim Paid (%d R$)", offer.price or 0)
            else string.format("Paid Revive (%d R$)", offer.price or 0)
    end
    wipe_ends_at = payload.wipe_ends_at
    last_server_time = payload.server_time or 0
    received_at = os.clock()
end)

RunService.RenderStepped:Connect(function()
    if panel.Visible and type(wipe_ends_at) == "number" then
        local estimated_server_now = last_server_time + (os.clock() - received_at)
        local remaining = math.max(0, math.ceil(wipe_ends_at - estimated_server_now))
        timer_label.Text = string.format("Revive window: %ds", remaining)
    elseif panel.Visible then
        timer_label.Text = "Party still fighting — revive when ready"
    end
end)
