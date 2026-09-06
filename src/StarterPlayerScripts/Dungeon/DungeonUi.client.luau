--!strict
-- Functional Phase 2A Dungeon HUD: objective, boss bar, revive,
-- completion and return.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local combat = ReplicatedStorage:WaitForChild("Combat")
local core = ReplicatedStorage:WaitForChild("Core")
local CombatConfig = require(
    combat:WaitForChild("Shared"):WaitForChild("CombatConfig")
)
local shared = core:WaitForChild("Shared")
local PresentationLayers = require(
    shared:WaitForChild("PresentationLayers")
)
local UiStateRules = require(shared:WaitForChild("UiStateRules"))
local remotes = core:WaitForChild("Remotes")
local dungeon_state = remotes:WaitForChild(
    "DungeonStateChanged"
) :: RemoteEvent
local revive_request = remotes:WaitForChild("ReviveRequest") :: RemoteEvent
local revive_state = remotes:WaitForChild("ReviveStateChanged") :: RemoteEvent
local return_request = remotes:WaitForChild("ReturnRequest") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "DungeonUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = PresentationLayers.DUNGEON_REVIVE
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local objective = Instance.new("TextLabel")
objective.AnchorPoint = Vector2.new(0.5,0)
objective.Position = UDim2.fromScale(0.5,0.025)
objective.Size = UDim2.fromOffset(650,46)
objective.BackgroundColor3 = Color3.fromRGB(22,24,30)
objective.BackgroundTransparency = 0.15
objective.TextColor3 = Color3.fromRGB(245,245,245)
objective.TextScaled = true
objective.Text = "Dungeon loading..."
objective.Parent = gui

local boss_frame = Instance.new("Frame")
boss_frame.AnchorPoint = Vector2.new(0.5,0)
boss_frame.Position = UDim2.fromScale(0.5,0.085)
boss_frame.Size = UDim2.fromOffset(520,54)
boss_frame.BackgroundColor3 = Color3.fromRGB(28,20,22)
boss_frame.Visible = false
boss_frame.Parent = gui
local boss_name = Instance.new("TextLabel")
boss_name.Size = UDim2.new(1,0,0,24)
boss_name.BackgroundTransparency = 1
boss_name.TextColor3 = Color3.fromRGB(255,230,220)
boss_name.TextScaled = true
boss_name.Text = "Marauder Captain"
boss_name.Parent = boss_frame
local boss_back = Instance.new("Frame")
boss_back.Position = UDim2.fromOffset(12,30)
boss_back.Size = UDim2.new(1,-24,0,16)
boss_back.BackgroundColor3 = Color3.fromRGB(65,45,48)
boss_back.Parent = boss_frame
local boss_fill = Instance.new("Frame")
boss_fill.Size = UDim2.fromScale(1,1)
boss_fill.BackgroundColor3 = Color3.fromRGB(190,62,62)
boss_fill.BorderSizePixel = 0
boss_fill.Parent = boss_back

local revive_panel = Instance.new("Frame")
revive_panel.AnchorPoint = Vector2.new(0.5,0.5)
revive_panel.Position = UDim2.fromScale(0.5,0.5)
revive_panel.Size = UDim2.fromOffset(440,230)
revive_panel.BackgroundColor3 = Color3.fromRGB(28,28,34)
revive_panel.Visible = false
revive_panel.Parent = gui
local revive_title = Instance.new("TextLabel")
revive_title.Size = UDim2.new(1,-20,0,48)
revive_title.Position = UDim2.fromOffset(10,10)
revive_title.BackgroundTransparency = 1
revive_title.TextColor3 = Color3.fromRGB(245,245,245)
revive_title.TextScaled = true
revive_title.Text = "DEFEATED"
revive_title.Parent = revive_panel
local revive_timer = Instance.new("TextLabel")
revive_timer.Size = UDim2.new(1,-20,0,36)
revive_timer.Position = UDim2.fromOffset(10,62)
revive_timer.BackgroundTransparency = 1
revive_timer.TextColor3 = Color3.fromRGB(220,220,220)
revive_timer.TextScaled = true
revive_timer.Parent = revive_panel
local revive_button = Instance.new("TextButton")
revive_button.Position = UDim2.fromOffset(20,136)
revive_button.Size = UDim2.fromOffset(190,56)
revive_button.TextScaled = true
revive_button.Text = "Free Revive"
revive_button.Selectable = true
revive_button.Parent = revive_panel
local lobby_button = Instance.new("TextButton")
lobby_button.Position = UDim2.fromOffset(230,136)
lobby_button.Size = UDim2.fromOffset(190,56)
lobby_button.TextScaled = true
lobby_button.Text = "Return to Lobby"
lobby_button.Selectable = true
lobby_button.Parent = revive_panel

local complete_panel = Instance.new("Frame")
complete_panel.AnchorPoint = Vector2.new(0.5,0.5)
complete_panel.Position = UDim2.fromScale(0.5,0.52)
complete_panel.Size = UDim2.fromOffset(520,260)
complete_panel.BackgroundColor3 = Color3.fromRGB(24,34,31)
complete_panel.Visible = false
complete_panel.Parent = gui
local complete_title = Instance.new("TextLabel")
complete_title.Position = UDim2.fromOffset(12,12)
complete_title.Size = UDim2.new(1,-24,0,52)
complete_title.BackgroundTransparency = 1
complete_title.TextColor3 = Color3.fromRGB(220,255,232)
complete_title.TextScaled = true
complete_title.Text = "DUNGEON COMPLETE"
complete_title.Parent = complete_panel
local reward_label = Instance.new("TextLabel")
reward_label.Position = UDim2.fromOffset(18,74)
reward_label.Size = UDim2.new(1,-36,0,82)
reward_label.BackgroundTransparency = 1
reward_label.TextColor3 = Color3.fromRGB(235,235,235)
reward_label.TextWrapped = true
reward_label.TextScaled = true
reward_label.Parent = complete_panel
local return_button = Instance.new("TextButton")
return_button.AnchorPoint = Vector2.new(0.5,0)
return_button.Position = UDim2.new(0.5,0,0,172)
return_button.Size = UDim2.fromOffset(240,58)
return_button.TextScaled = true
return_button.Text = "Return to Base"
return_button.Selectable = true
return_button.Parent = complete_panel

local wipe_ends_at: number? = nil
local revive_at: number? = nil
local current_member_mode: string? = nil
local revive_server_time = 0
local revive_received_at = 0
local return_at: number? = nil
local return_server_time = 0
local return_received_at = 0
local revive_action: string? = nil


--[[Forces the local combat camera back to unlocked mode.]]
local function force_view_lock_off()
    player:SetAttribute(
        CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE,
        false
    )
end


revive_button.Activated:Connect(function()
    if revive_action then
        revive_request:FireServer(revive_action)
    end
end)
lobby_button.Activated:Connect(function()
    return_request:FireServer("Abandon")
end)
return_button.Activated:Connect(function()
    return_request:FireServer("Complete")
end)

revive_state.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    if payload.error then
        revive_timer.Text = "Revive error: " .. tostring(payload.error)
        return
    end
    local mode = payload.member_mode
    current_member_mode = if type(mode) == "string" then mode else nil
    local state_name = if mode == "Dead" then "ReviveChoice" else tostring(mode)
    local projected = UiStateRules.for_state(state_name, payload)
    if projected.force_view_lock_off == true then force_view_lock_off() end
    revive_panel.Visible = mode == "Dead" or mode == "Reviving" or mode == "Spectating"
    local offer = payload.paid_offer
    if mode == "Reviving" then
        revive_title.Text = "REVIVING"
        revive_action = nil
        revive_button.Text = "Free Revive Consumed"
        revive_button.Active = false
        revive_button.AutoButtonColor = false
    elseif payload.free_available == true then
        revive_title.Text = "DEFEATED"
        revive_action = "Free"
        revive_button.Text = "Free Revive"
        revive_button.Active = true
        revive_button.AutoButtonColor = true
    elseif type(offer) == "table" then
        revive_title.Text = "DEFEATED"
        revive_action = "Paid"
        revive_button.Text = if RunService:IsStudio()
            then string.format("Sim Revive (%d R$)", offer.price or 0)
            else string.format("Revive (%d R$)", offer.price or 0)
        revive_button.Active = RunService:IsStudio() or offer.live_enabled == true
        revive_button.AutoButtonColor = revive_button.Active
    else
        revive_title.Text = "DEFEATED"
        revive_action = nil
        revive_button.Text = "Revive unavailable"
        revive_button.Active = false
        revive_button.AutoButtonColor = false
    end
    lobby_button.Active = true
    lobby_button.AutoButtonColor = true
    wipe_ends_at = payload.wipe_ends_at
    revive_at = payload.revive_at
    revive_server_time = payload.server_time or 0
    revive_received_at = os.clock()
end)

dungeon_state.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    if type(payload.objective) == "string" then
        objective.Text = payload.objective
    end
    local state = payload.state
    local projected = UiStateRules.for_state(tostring(state), payload)
    if projected.force_view_lock_off == true then
        force_view_lock_off()
    end
    boss_frame.Visible = state == "Boss"
    if state == "Boss" then
        boss_name.Text = tostring(payload.boss_name or "Marauder Captain")
        local health = tonumber(payload.boss_health) or 0
        local max_health = math.max(1, tonumber(payload.boss_max_health) or 1)
        boss_fill.Size = UDim2.fromScale(math.clamp(health / max_health,0,1),1)
    end
    if state == "Complete" then
        revive_panel.Visible = false
        boss_frame.Visible = false
        complete_panel.Visible = true
        if payload.completion_eligible == false then
            reward_label.Text = "No completion reward - you were not "
                .. "Active/eligible when the Captain was defeated."
        elseif type(payload.completion) == "table" then
            local item = payload.completion.item_id
            reward_label.Text = string.format(
                "Completion Gold: +%d\nPersonal loot: %s",
                payload.completion.gold_granted or 0,
                item or "Nothing"
            )
        elseif payload.return_simulated == true then
            reward_label.Text = "Studio return simulated. Your "
                .. "committed reward remains saved."
        end
        if type(payload.return_at) == "number" then
            return_at = payload.return_at
            return_server_time = payload.server_time or 0
            return_received_at = os.clock()
        end
    elseif state == "Failed" then
        revive_panel.Visible = false
        boss_frame.Visible = false
        complete_panel.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if revive_panel.Visible and current_member_mode == "Reviving" and type(revive_at) == "number" then
        local now = revive_server_time + (os.clock() - revive_received_at)
        revive_timer.Text = string.format("Reviving... %d", math.max(1, math.ceil(revive_at - now)))
    elseif revive_panel.Visible and type(wipe_ends_at) == "number" then
        local now = revive_server_time + (os.clock() - revive_received_at)
        revive_timer.Text = string.format("Revive window: %ds", math.max(0, math.ceil(wipe_ends_at - now)))
    elseif revive_panel.Visible then
        revive_timer.Text = "Party still fighting — revive when ready"
    end
    if complete_panel.Visible and type(return_at) == "number" then
        local now = return_server_time + (os.clock() - return_received_at)
        return_button.Text = string.format(
            "Return to Base (%ds)",
            math.max(0, math.ceil(return_at - now))
        )
    end
end)
