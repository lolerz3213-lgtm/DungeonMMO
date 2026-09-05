--!strict
-- Read-only Phase 2A profile HUD shared by Base and Dungeon Places.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local core = ReplicatedStorage:WaitForChild("Core")
local shared = core:WaitForChild("Shared")
local remotes = core:WaitForChild("Remotes")
local ProgressionConfig = require(shared:WaitForChild("ProgressionConfig"))
local ItemDefinitions = require(shared:WaitForChild("ItemDefinitions"))
local profile_snapshot = remotes:WaitForChild("ProfileSnapshot") :: RemoteEvent
local inventory_snapshot = remotes:WaitForChild("InventorySnapshot") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "ProfileHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 120
gui.Parent = player:WaitForChild("PlayerGui")

local summary = Instance.new("TextLabel")
summary.Name = "Summary"
summary.Position = UDim2.fromOffset(16, 16)
summary.Size = UDim2.fromOffset(320, 42)
summary.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
summary.BackgroundTransparency = 0.18
summary.TextColor3 = Color3.fromRGB(245, 245, 245)
summary.TextXAlignment = Enum.TextXAlignment.Left
summary.TextScaled = true
summary.Text = "Level 1 | XP 0/100 | Gold 0"
summary.Parent = gui

local inventory = Instance.new("TextLabel")
inventory.Name = "Inventory"
inventory.Position = UDim2.fromOffset(16, 64)
inventory.Size = UDim2.fromOffset(320, 120)
inventory.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
inventory.BackgroundTransparency = 0.25
inventory.TextColor3 = Color3.fromRGB(225, 225, 225)
inventory.TextXAlignment = Enum.TextXAlignment.Left
inventory.TextYAlignment = Enum.TextYAlignment.Top
inventory.TextSize = 16
inventory.TextWrapped = true
inventory.Text = "Inventory\n(empty)"
inventory.Parent = gui

profile_snapshot.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    local level = tonumber(payload.Level) or 1
    local xp = tonumber(payload.XP) or 0
    local gold = tonumber(payload.Gold) or 0
    local required = ProgressionConfig.get_required_xp(level)
    summary.Text = string.format("Level %d | XP %d/%d | Gold %d", level, xp, required, gold)
end)

inventory_snapshot.OnClientEvent:Connect(function(entries)
    if type(entries) ~= "table" or #entries == 0 then
        inventory.Text = "Inventory\n(empty)"
        return
    end
    local lines = {"Inventory"}
    local shown = 0
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.ItemId) == "string" then
            local definition = ItemDefinitions.get(entry.ItemId)
            local name = if definition then definition.Name else entry.ItemId
            table.insert(lines, string.format("• %s  x%d", name, tonumber(entry.Quantity) or 1))
            shown += 1
            if shown >= 5 then break end
        end
    end
    inventory.Text = table.concat(lines, "\n")
end)

-- Request a fresh server snapshot so joining clients cannot miss an early PlayerAdded push.
task.defer(function() profile_snapshot:FireServer("Request") end)
