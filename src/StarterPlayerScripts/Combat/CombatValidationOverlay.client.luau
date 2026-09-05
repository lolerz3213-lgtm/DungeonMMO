local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsStudio() then
    return
end

local player = Players.LocalPlayer
local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local shared_folder = combat_folder:WaitForChild("Shared")
local remotes_folder = combat_folder:WaitForChild("Remotes")

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local validation_event = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.VALIDATION_EVENT
) :: RemoteEvent

local MAX_LINES = 10
local lines: {string} = {}

local gui = Instance.new("ScreenGui")
gui.Name = CombatConfig.DEBUG.VALIDATION_GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 95
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(10, 10)
panel.Size = UDim2.new(0.42, 0, 0, 205)
panel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
panel.BackgroundTransparency = 0.18
panel.BorderSizePixel = 0
panel.Parent = gui

local size_constraint = Instance.new("UISizeConstraint")
size_constraint.MinSize = Vector2.new(260, 205)
size_constraint.MaxSize = Vector2.new(520, 205)
size_constraint.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(8, 4)
title.Size = UDim2.new(1, -16, 0, 22)
title.Font = Enum.Font.Code
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(225, 235, 245)
title.Text = "SERVER COMBAT VALIDATION  [F8 hide/show]"
title.Parent = panel

local feed = Instance.new("TextLabel")
feed.Name = "Feed"
feed.BackgroundTransparency = 1
feed.Position = UDim2.fromOffset(8, 28)
feed.Size = UDim2.new(1, -16, 1, -34)
feed.Font = Enum.Font.Code
feed.TextSize = 13
feed.TextXAlignment = Enum.TextXAlignment.Left
feed.TextYAlignment = Enum.TextYAlignment.Top
feed.TextWrapped = false
feed.TextColor3 = Color3.fromRGB(170, 255, 185)
feed.Text = "Waiting for authoritative combat events..."
feed.Parent = panel

local function format_payload(payload: any): string
    local server_time = type(payload.server_time) == "number"
        and payload.server_time
        or 0
    local event_name = tostring(payload.event or "EVENT")
    local outcome = tostring(payload.outcome or "")
    local detail = tostring(payload.detail or "")
    local sequence_text = ""

    if type(payload.sequence_id) == "number" then
        sequence_text = string.format(" #%d", payload.sequence_id)
    end

    return string.format(
        "%.2f%s %-14s %-10s %s",
        server_time,
        sequence_text,
        event_name,
        outcome,
        detail
    )
end

local function refresh()
    feed.Text = table.concat(lines, "\n")
end

validation_event.OnClientEvent:Connect(function(payload)
    table.insert(lines, format_payload(payload))

    while #lines > MAX_LINES do
        table.remove(lines, 1)
    end

    refresh()
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F8 then
        panel.Visible = not panel.Visible
    end
end)
