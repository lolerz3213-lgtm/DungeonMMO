--!strict
-- Functional Base-only six-slot equipment panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local core = ReplicatedStorage:WaitForChild("Core")
local shared = core:WaitForChild("Shared")
local remotes = core:WaitForChild("Remotes")

local EquipmentSlots = require(shared:WaitForChild("EquipmentSlots"))
local ItemDefinitions = require(shared:WaitForChild("ItemDefinitions"))

local equipment_snapshot = remotes:WaitForChild("EquipmentSnapshot") :: RemoteEvent
local equip_request = remotes:WaitForChild("EquipmentEquipRequest") :: RemoteEvent
local unequip_request = remotes:WaitForChild("EquipmentUnequipRequest") :: RemoteEvent
local action_result = remotes:WaitForChild("EquipmentActionResult") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "EquipmentPanelUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = 181
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(780, 560)
panel.BackgroundColor3 = Color3.fromRGB(23, 25, 31)
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.fromOffset(650, 42)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Text = "Equipment"
title.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.fromOffset(716, 10)
close.Size = UDim2.fromOffset(46, 40)
close.Text = "X"
close.Parent = panel

local slot_heading = Instance.new("TextLabel")
slot_heading.Position = UDim2.fromOffset(18, 64)
slot_heading.Size = UDim2.fromOffset(300, 28)
slot_heading.BackgroundTransparency = 1
slot_heading.TextXAlignment = Enum.TextXAlignment.Left
slot_heading.Text = "EQUIPPED SLOTS"
slot_heading.Parent = panel

local owned_heading = Instance.new("TextLabel")
owned_heading.Position = UDim2.fromOffset(336, 64)
owned_heading.Size = UDim2.fromOffset(426, 28)
owned_heading.BackgroundTransparency = 1
owned_heading.TextXAlignment = Enum.TextXAlignment.Left
owned_heading.Text = "OWNED ITEMS FOR SELECTED SLOT"
owned_heading.Parent = panel

local slot_buttons = {}

for index, slot in ipairs(EquipmentSlots.ORDER) do
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(18, 100 + (index - 1) * 58)
    button.Size = UDim2.fromOffset(300, 48)
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Text = "  " .. slot .. ": Empty"
    button.Parent = panel
    slot_buttons[slot] = button
end

local owned_container = Instance.new("ScrollingFrame")
owned_container.Position = UDim2.fromOffset(336, 100)
owned_container.Size = UDim2.fromOffset(426, 300)
owned_container.BackgroundTransparency = 0.15
owned_container.BorderSizePixel = 0
owned_container.ScrollBarThickness = 8
owned_container.CanvasSize = UDim2.fromOffset(0, 0)
owned_container.Parent = panel

local owned_layout = Instance.new("UIListLayout")
owned_layout.Padding = UDim.new(0, 6)
owned_layout.Parent = owned_container

local selected_label = Instance.new("TextLabel")
selected_label.Position = UDim2.fromOffset(336, 410)
selected_label.Size = UDim2.fromOffset(426, 34)
selected_label.BackgroundTransparency = 1
selected_label.TextXAlignment = Enum.TextXAlignment.Left
selected_label.Text = "Selected: none"
selected_label.Parent = panel

local equip_button = Instance.new("TextButton")
equip_button.Position = UDim2.fromOffset(336, 452)
equip_button.Size = UDim2.fromOffset(204, 42)
equip_button.Text = "Equip"
equip_button.Active = false
equip_button.AutoButtonColor = false
equip_button.Parent = panel

local unequip_button = Instance.new("TextButton")
unequip_button.Position = UDim2.fromOffset(558, 452)
unequip_button.Size = UDim2.fromOffset(204, 42)
unequip_button.Text = "Unequip Slot"
unequip_button.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 512)
status.Size = UDim2.fromOffset(744, 32)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Base-only server-authoritative equipment"
status.Parent = panel

local latest = {
    Slots = {},
    Owned = {},
}
local selected_slot = "Weapon"
local selected_item_id = nil
local selected_eligible = false

local function item_name(item_id: any): string
    if type(item_id) ~= "string" then
        return "Empty"
    end

    local definition = ItemDefinitions.get(item_id)
    return if definition then tostring(definition.Name) else item_id
end

local function clear_owned_rows()
    for _, child in ipairs(owned_container:GetChildren()) do
        if child ~= owned_layout then
            child:Destroy()
        end
    end
end

local function render()
    local slots = if type(latest.Slots) == "table"
        then latest.Slots
        else {}

    for _, slot in ipairs(EquipmentSlots.ORDER) do
        slot_buttons[slot].Text = string.format(
            "  %s: %s%s",
            slot,
            item_name(slots[slot]),
            if slot == selected_slot then "   <" else ""
        )
    end

    clear_owned_rows()
    selected_item_id = nil
    selected_eligible = false
    selected_label.Text = "Selected: none"
    equip_button.Active = false
    equip_button.AutoButtonColor = false

    local shown = 0
    local owned = if type(latest.Owned) == "table"
        then latest.Owned
        else {}

    for _, entry in ipairs(owned) do
        if entry.Slot == selected_slot then
            shown += 1

            local row = Instance.new("TextButton")
            row.Size = UDim2.fromOffset(408, 56)
            row.TextWrapped = true
            row.TextXAlignment = Enum.TextXAlignment.Left

            local suffix = if entry.Eligible == true
                then "eligible"
                else "blocked: " .. tostring(entry.Reason or "Unknown")

            row.Text = string.format(
                "  %s x%d\n  %s • %s",
                tostring(entry.Name or entry.ItemId),
                tonumber(entry.Quantity) or 1,
                tostring(entry.Category or "Equipment"),
                suffix
            )
            row.Parent = owned_container

            row.Activated:Connect(function()
                selected_item_id = tostring(entry.ItemId)
                selected_eligible = entry.Eligible == true
                selected_label.Text = "Selected: " .. tostring(entry.Name or entry.ItemId)

                if selected_eligible then
                    status.Text = "Ready to equip " .. tostring(entry.Name or entry.ItemId)
                else
                    status.Text = "Cannot equip: " .. tostring(entry.Reason or "Unknown")
                end

                equip_button.Active = selected_eligible
                equip_button.AutoButtonColor = selected_eligible
            end)
        end
    end

    if shown == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.fromOffset(408, 48)
        empty.BackgroundTransparency = 1
        empty.TextXAlignment = Enum.TextXAlignment.Left
        empty.Text = "  No owned equipment for " .. selected_slot
        empty.Parent = owned_container
    end

    task.defer(function()
        owned_container.CanvasSize = UDim2.fromOffset(
            0,
            owned_layout.AbsoluteContentSize.Y + 10
        )
    end)
end

for slot, button in pairs(slot_buttons) do
    button.Activated:Connect(function()
        selected_slot = slot
        status.Text = "Selected slot: " .. slot
        render()
    end)
end

equip_button.Activated:Connect(function()
    if not selected_eligible or not selected_item_id then
        return
    end

    status.Text = "Equipping..."
    equip_request:FireServer(selected_item_id, selected_slot)
end)

unequip_button.Activated:Connect(function()
    status.Text = "Unequipping " .. selected_slot .. "..."
    unequip_request:FireServer(selected_slot)
end)

close.Activated:Connect(function()
    panel.Visible = false
end)

equipment_snapshot.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    latest = payload

    if payload.ok == false then
        status.Text = "Equipment unavailable: " .. tostring(payload.reason or "Unknown")
    end

    render()
end)

action_result.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    status.Text = if payload.ok == true
        then tostring(payload.action) .. " complete."
        else tostring(payload.action)
            .. " blocked: "
            .. tostring(payload.reason or "Unknown")

    equipment_snapshot:FireServer("Request")
end)

task.spawn(function()
    local root = Workspace:WaitForChild("BasePrototype", 15)
    if not root then
        return
    end

    local manager = root:WaitForChild("EquipmentManager", 10)
    if not manager then
        return
    end

    local prompt = manager:WaitForChild("EquipmentManagerPrompt", 5)

    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Triggered:Connect(function()
            panel.Visible = true
            status.Text = "Loading equipment..."
            equipment_snapshot:FireServer("Request")
        end)
    end
end)
