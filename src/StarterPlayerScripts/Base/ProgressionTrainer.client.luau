--!strict
-- Functional catalogue-driven trainer UI for Phase 2C.B.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local core = ReplicatedStorage:WaitForChild("Core")
local shared = core:WaitForChild("Shared")
local remotes = core:WaitForChild("Remotes")

local progression_snapshot = remotes:WaitForChild("ProgressionSnapshot") :: RemoteEvent
local progression_result = remotes:WaitForChild("ProgressionActionResult") :: RemoteEvent
local trainer_snapshot = remotes:WaitForChild("TrainerSnapshot") :: RemoteEvent
local trainer_request = remotes:WaitForChild("TrainerSnapshotRequest") :: RemoteEvent
local attribute_commit = remotes:WaitForChild("AttributeCommitRequest") :: RemoteEvent
local attribute_respec = remotes:WaitForChild("AttributeRespecRequest") :: RemoteEvent
local skill_respec = remotes:WaitForChild("SkillRespecRequest") :: RemoteEvent
local skill_learn = remotes:WaitForChild("SkillLearnRequest") :: RemoteEvent
local skill_rank = remotes:WaitForChild("SkillRankRequest") :: RemoteEvent

local ProgressionClientState = require(
    script.Parent.Parent
        :WaitForChild("Core")
        :WaitForChild("ProgressionClientState")
)
local ProgressionTrainerRules = require(
    shared:WaitForChild("ProgressionTrainerRules")
)

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionTrainerUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = 180
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(780, 580)
panel.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
panel.BackgroundTransparency = 0.04
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.fromOffset(650, 42)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Text = "Fighter Trainer"
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(716, 10)
close.Size = UDim2.fromOffset(46, 40)
close.Text = "X"
close.Parent = panel

local summary = Instance.new("TextLabel")
summary.Position = UDim2.fromOffset(18, 58)
summary.Size = UDim2.fromOffset(744, 30)
summary.BackgroundTransparency = 1
summary.TextXAlignment = Enum.TextXAlignment.Left
summary.Text = "Level 1 | AP 0 | SP 0"
summary.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 536)
status.Size = UDim2.fromOffset(744, 30)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Server-authoritative trainer catalogue"
status.Parent = panel

local attr_names = {
    "Strength",
    "Dexterity",
    "Vitality",
    "Intellect",
    "Spirit",
}

local attr_labels = {}
local plus_buttons = {}

local attr_heading = Instance.new("TextLabel")
attr_heading.Position = UDim2.fromOffset(18, 96)
attr_heading.Size = UDim2.fromOffset(270, 28)
attr_heading.BackgroundTransparency = 1
attr_heading.TextXAlignment = Enum.TextXAlignment.Left
attr_heading.Text = "ATTRIBUTES"
attr_heading.Parent = panel

for index, name in ipairs(attr_names) do
    local y = 132 + (index - 1) * 48

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(18, y)
    label.Size = UDim2.fromOffset(210, 38)
    label.BackgroundTransparency = 0.25
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "  " .. name .. ": 5"
    label.Parent = panel
    attr_labels[name] = label

    local plus = Instance.new("TextButton")
    plus.Position = UDim2.fromOffset(234, y)
    plus.Size = UDim2.fromOffset(44, 38)
    plus.Text = "+"
    plus.Parent = panel
    plus_buttons[name] = plus
end

local confirm = Instance.new("TextButton")
confirm.Position = UDim2.fromOffset(18, 382)
confirm.Size = UDim2.fromOffset(124, 40)
confirm.Text = "Confirm"
confirm.Parent = panel

local cancel = Instance.new("TextButton")
cancel.Position = UDim2.fromOffset(150, 382)
cancel.Size = UDim2.fromOffset(128, 40)
cancel.Text = "Cancel"
cancel.Parent = panel

local attr_respec_button = Instance.new("TextButton")
attr_respec_button.Position = UDim2.fromOffset(18, 432)
attr_respec_button.Size = UDim2.fromOffset(260, 42)
attr_respec_button.Text = "Attribute Respec • Free (TEST)"
attr_respec_button.Parent = panel

local skill_heading = Instance.new("TextLabel")
skill_heading.Position = UDim2.fromOffset(310, 96)
skill_heading.Size = UDim2.fromOffset(452, 28)
skill_heading.BackgroundTransparency = 1
skill_heading.TextXAlignment = Enum.TextXAlignment.Left
skill_heading.Text = "TRAINER CATALOGUE"
skill_heading.Parent = panel

local skill_scroller = Instance.new("ScrollingFrame")
skill_scroller.Position = UDim2.fromOffset(310, 132)
skill_scroller.Size = UDim2.fromOffset(452, 292)
skill_scroller.BackgroundTransparency = 0.12
skill_scroller.BorderSizePixel = 0
skill_scroller.ScrollBarThickness = 8
skill_scroller.CanvasSize = UDim2.fromOffset(0, 0)
skill_scroller.Parent = panel

local skill_layout = Instance.new("UIListLayout")
skill_layout.Padding = UDim.new(0, 8)
skill_layout.Parent = skill_scroller

local skill_respec_button = Instance.new("TextButton")
skill_respec_button.Position = UDim2.fromOffset(310, 432)
skill_respec_button.Size = UDim2.fromOffset(452, 42)
skill_respec_button.Text = "Skill/SP Respec • Free (TEST)"
skill_respec_button.Parent = panel

local latest = {}
local preview = {}
local active_trainer_id = "FighterTrainer"
local trainer_entries = {}

local function identity_complete(snapshot: any): boolean
    if type(snapshot) ~= "table" then
        return false
    end

    local identity = snapshot.Identity
    return type(identity) == "table"
        and identity.CreationStage == "Complete"
end

local function reset_preview(snapshot: any?)
    if snapshot ~= nil then
        latest = snapshot or {}
    end

    preview = ProgressionTrainerRules.create_attribute_preview(latest)
end

local function clear_skill_rows()
    for _, child in ipairs(skill_scroller:GetChildren()) do
        if child ~= skill_layout then
            child:Destroy()
        end
    end
end

local function render_skills()
    clear_skill_rows()

    local skills = if type(latest.Skills) == "table"
        then latest.Skills
        else {}

    if #trainer_entries == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.fromOffset(430, 42)
        empty.BackgroundTransparency = 1
        empty.TextXAlignment = Enum.TextXAlignment.Left
        empty.Text = "  Waiting for trainer catalogue..."
        empty.Parent = skill_scroller
        return
    end

    for _, entry in ipairs(trainer_entries) do
        local skill_id = tostring(entry.SkillId)
        local state = skills[skill_id] or {}

        local row = Instance.new("Frame")
        row.Size = UDim2.fromOffset(430, 86)
        row.BackgroundTransparency = 0.12
        row.Parent = skill_scroller

        local label = Instance.new("TextLabel")
        label.Position = UDim2.fromOffset(8, 4)
        label.Size = UDim2.fromOffset(414, 44)
        label.BackgroundTransparency = 1
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left

        local rank = tonumber(state.Rank) or 0
        local max_rank = tonumber(state.MaxRank) or 3
        local proficiency = tonumber(state.Proficiency) or 0
        local threshold = tonumber(state.NextThreshold)

        local requirement = if threshold
            then string.format(
                "%d/%d proficiency",
                math.floor(proficiency),
                math.floor(threshold)
            )
            else "no proficiency gate"

        label.Text = string.format(
            "%s • Rank %d/%d\n%s",
            skill_id,
            rank,
            max_rank,
            requirement
        )
        label.Parent = row

        local button = Instance.new("TextButton")
        button.Position = UDim2.fromOffset(8, 52)
        button.Size = UDim2.fromOffset(414, 28)
        button.Parent = row

        local mode = tostring(entry.Mode or "")
        local known = state.Known == true
        local can_learn = mode == "Learn" or mode == "LearnOrRank"
        local can_rank = mode == "Rank" or mode == "LearnOrRank"

        if not known and can_learn then
            local cost = tonumber(state.NextCost) or 0
            local source_ok = true

            if type(entry.SourceItemId) == "string" then
                source_ok = state.BookOwned == true
            end

            if source_ok then
                button.Text = string.format(
                    "Learn • %d SP%s",
                    cost,
                    if entry.SourceItemId then " + Book" else ""
                )
            else
                button.Text = "Required Skill Book not owned"
            end

            button.Active = source_ok
                and (tonumber(latest.SPAvailable) or 0) >= cost

        elseif known and can_rank and rank < max_rank then
            local cost = tonumber(state.NextCost) or 0
            local eligible = threshold == nil or proficiency >= threshold

            button.Text = string.format(
                "Purchase Rank %d • %d SP",
                rank + 1,
                cost
            )

            button.Active = eligible
                and (tonumber(latest.SPAvailable) or 0) >= cost

        elseif rank >= max_rank then
            button.Text = "Max Rank"
            button.Active = false
        else
            button.Text = "Not available from this trainer"
            button.Active = false
        end

        button.AutoButtonColor = button.Active

        button.Activated:Connect(function()
            if not button.Active then
                return
            end

            local fresh_state = latest.Skills and latest.Skills[skill_id]
            if not fresh_state then
                return
            end

            if fresh_state.Known ~= true then
                skill_learn:FireServer(active_trainer_id, skill_id)
            else
                skill_rank:FireServer(active_trainer_id, skill_id)
            end
        end)
    end

    task.defer(function()
        skill_scroller.CanvasSize = UDim2.fromOffset(
            0,
            skill_layout.AbsoluteContentSize.Y + 10
        )
    end)
end

local function render(snapshot: any)
    latest = snapshot or {}

    if not identity_complete(latest) then
        panel.Visible = false
        return
    end

    if next(preview) == nil then
        reset_preview()
    end

    summary.Text = string.format(
        "Level %d | AP %d | SP %d",
        tonumber(latest.Level) or 1,
        tonumber(latest.APAvailable) or 0,
        tonumber(latest.SPAvailable) or 0
    )

    for _, name in ipairs(attr_names) do
        attr_labels[name].Text = string.format(
            "  %s: %d",
            name,
            tonumber(preview[name]) or 5
        )
    end

    render_skills()
end

for name, button in pairs(plus_buttons) do
    button.Activated:Connect(function()
        if not identity_complete(latest) then
            panel.Visible = false
            return
        end

        if not ProgressionTrainerRules.can_add_attribute_point(
            latest,
            preview
        ) then
            status.Text = "No more Attribute Points available."
            return
        end

        preview[name] = (tonumber(preview[name]) or 5) + 1
        render(latest)
    end)
end

confirm.Activated:Connect(function()
    if identity_complete(latest) then
        status.Text = "Saving attributes..."
        attribute_commit:FireServer(preview)
    end
end)

cancel.Activated:Connect(function()
    reset_preview()
    render(latest)
    status.Text = "Attribute preview cancelled."
end)

attr_respec_button.Activated:Connect(function()
    if identity_complete(latest) then
        attribute_respec:FireServer()
    end
end)

skill_respec_button.Activated:Connect(function()
    if identity_complete(latest) then
        skill_respec:FireServer()
    end
end)

close.Activated:Connect(function()
    panel.Visible = false
end)

ProgressionClientState.subscribe(function(snapshot)
    reset_preview(snapshot)
    render(latest)
end)

trainer_snapshot.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.ok ~= true then
        trainer_entries = {}
        status.Text = "Trainer blocked: " .. tostring(payload.reason or "Unknown")
        render_skills()
        return
    end

    active_trainer_id = tostring(payload.TrainerId or "FighterTrainer")
    title.Text = tostring(payload.DisplayName or "Trainer")
    trainer_entries = if type(payload.Skills) == "table"
        then payload.Skills
        else {}
    status.Text = "Catalogue loaded from server."
    render_skills()
end)

progression_result.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    status.Text = if payload.ok == true
        then tostring(payload.action) .. " complete."
        else tostring(payload.action)
            .. " blocked: "
            .. tostring(payload.reason or "Unknown")
end)

local connected_trainers: {[Instance]: boolean} = {}

local function connect_trainer(trainer: Instance)
    if connected_trainers[trainer] then
        return
    end

    local prompt = trainer:FindFirstChild("ProgressionTrainerPrompt")

    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end

    connected_trainers[trainer] = true

    prompt.Triggered:Connect(function()
        local snapshot = ProgressionClientState.get_snapshot()

        if not identity_complete(snapshot) then
            panel.Visible = false
            progression_snapshot:FireServer("Request")
            return
        end

        local trainer_id = trainer:GetAttribute("TrainerId")

        if type(trainer_id) ~= "string" then
            return
        end

        active_trainer_id = trainer_id
        trainer_entries = {}
        panel.Visible = true
        status.Text = "Loading trainer catalogue..."
        reset_preview(snapshot)
        render(latest)
        progression_snapshot:FireServer("Request")
        trainer_request:FireServer(active_trainer_id)
    end)
end

task.spawn(function()
    local root = Workspace:WaitForChild("BasePrototype", 15)

    if not root then
        return
    end

    root.ChildAdded:Connect(function(child)
        if type(child:GetAttribute("TrainerId")) == "string" then
            connect_trainer(child)
        end
    end)

    for _, child in ipairs(root:GetChildren()) do
        if type(child:GetAttribute("TrainerId")) == "string" then
            connect_trainer(child)
        end
    end
end)
