--!strict
-- Functional Longbow draw-tier presentation for Ranger Studio acceptance.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local draw_rules = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("RangerDrawRules")
)

local gui = Instance.new("ScreenGui")
gui.Name = "RangerDrawGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 26
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "DrawTier"
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 0.82, 0)
label.Size = UDim2.fromOffset(250, 42)
label.BackgroundTransparency = 0.25
label.TextScaled = true
label.Visible = false
label.Parent = gui

--[[
Returns the replicated server-time draw duration for the current character.

Args:
    None.

Returns:
    number?: Draw duration when the server marks a draw active.
]]
local function current_draw_elapsed(): number?
    local character = player.Character

    if not character
        or character:GetAttribute("RangerDrawing") ~= true
    then
        return nil
    end

    local started_at = character:GetAttribute("RangerDrawStartedAt")

    if type(started_at) ~= "number" or started_at <= 0 then
        return nil
    end

    return math.max(0, Workspace:GetServerTimeNow() - started_at)
end

--[[
Refreshes the functional Ranger draw-tier indicator.

Args:
    None.

Returns:
    None.
]]
local function refresh()
    local elapsed = current_draw_elapsed()

    if elapsed == nil then
        label.Visible = false
        return
    end

    local tier = draw_rules.classify(elapsed)
    label.Visible = true
    label.Text = string.format(
        "%s  %.2fs",
        tier.Tier,
        elapsed
    )
end

RunService.RenderStepped:Connect(refresh)
refresh()
