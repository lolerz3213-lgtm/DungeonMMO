local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then
    return
end

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatTypes = require(shared_folder:WaitForChild("CombatTypes"))
local HotbarConfig = require(shared_folder:WaitForChild("HotbarConfig"))
local InputMappingConfig = require(
    shared_folder:WaitForChild("InputMappingConfig")
)
local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)
local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)
local CombatInputActions = require(
    script.Parent:WaitForChild("CombatInputActions")
)

local State = CombatTypes.State
local Mobile = InputMappingConfig.MOBILE

local skill_buttons: {[number]: TextButton} = {}
local cooldown_ends: {[number]: number} = {}
local block_held = false


local function style_button(button: TextButton, enabled: boolean)
    button.Active = enabled
    button.AutoButtonColor = enabled
    button.BackgroundTransparency = enabled and 0.15 or 0.55
    button.TextTransparency = enabled and 0 or 0.45
end


local function create_button(
    parent: Instance,
    name: string,
    label: string,
    position: UDim2,
    size: UDim2
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = position
    button.Size = size
    button.Text = label
    button.TextScaled = true
    button.TextWrapped = true
    button.BackgroundTransparency = 0.15
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.22, 0)
    corner.Parent = button

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = button

    return button
end


local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = Mobile.GUI_NAME
screen_gui.ResetOnSpawn = false
screen_gui.IgnoreGuiInset = false
screen_gui.DisplayOrder = 20
screen_gui.Parent = player_gui

local action_buttons = {}

for action_name, definition in Mobile.CORE_ACTIONS do
    action_buttons[action_name] = create_button(
        screen_gui,
        action_name .. "Button",
        definition.LABEL,
        definition.POSITION,
        definition.SIZE
    )
end

local skill_bar = Instance.new("Frame")
skill_bar.Name = "SkillBar"
skill_bar.AnchorPoint = Vector2.new(0.5, 1)
skill_bar.Position = UDim2.new(
    0.5,
    0,
    1,
    -Mobile.SKILL_BAR_BOTTOM_PIXELS
)
skill_bar.Size = UDim2.fromOffset(
    (Mobile.SKILL_BUTTON_SIZE * Mobile.SKILL_SLOT_COUNT)
        + (Mobile.SKILL_BUTTON_GAP * (Mobile.SKILL_SLOT_COUNT - 1)),
    Mobile.SKILL_BUTTON_SIZE
)
skill_bar.BackgroundTransparency = 1
skill_bar.Parent = screen_gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, Mobile.SKILL_BUTTON_GAP)
layout.Parent = skill_bar

for slot = 1, Mobile.SKILL_SLOT_COUNT do
    local skill_id = HotbarConfig.get_skill_for_slot(slot)
    local definition = skill_id and SkillDefinitions.get(skill_id)
    local label = tostring(slot)

    if definition then
        label = string.format("%d\n%s", slot, definition.DISPLAY_NAME)
    end

    local button = create_button(
        skill_bar,
        "SkillSlot" .. tostring(slot),
        label,
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(
            Mobile.SKILL_BUTTON_SIZE,
            Mobile.SKILL_BUTTON_SIZE
        )
    )
    button.AnchorPoint = Vector2.zero
    button.Position = UDim2.fromScale(0, 0)
    skill_buttons[slot] = button

    button.Activated:Connect(function()
        CombatInputActions.request_skill_slot(slot)
    end)
end


action_buttons.Attack.Activated:Connect(function()
    CombatInputActions.request_attack()
end)

action_buttons.Dodge.Activated:Connect(function()
    CombatInputActions.request_dodge()
end)

action_buttons.ViewLock.Activated:Connect(function()
    CombatInputActions.toggle_view_lock()
end)

local function is_primary_touch(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
end

action_buttons.Block.InputBegan:Connect(function(input: InputObject)
    if not is_primary_touch(input) or block_held then
        return
    end

    block_held = CombatInputActions.set_block(true)
end)

action_buttons.Block.InputEnded:Connect(function(input: InputObject)
    if not is_primary_touch(input) or not block_held then
        return
    end

    block_held = false
    CombatInputActions.set_block(false)
end)


local function begin_skill_cooldown(skill_id: string)
    for slot = 1, Mobile.SKILL_SLOT_COUNT do
        if HotbarConfig.get_skill_for_slot(slot) == skill_id then
            local definition = SkillDefinitions.get(skill_id)

            if definition then
                cooldown_ends[slot] = os.clock()
                    + definition.COOLDOWN_SECONDS
            end

            return
        end
    end
end


local function refresh_controls()
    local state = ClientCombatController.get_state()
    local dead = state == State.DEAD
    local guard_broken = state == State.GUARD_BREAK
    local mending = state == State.MENDING

    style_button(
        action_buttons.Attack,
        not dead and not mending and not guard_broken
    )
    style_button(
        action_buttons.Block,
        not dead and state ~= State.DODGING and not guard_broken
    )
    style_button(
        action_buttons.Dodge,
        not dead and not guard_broken
    )
    style_button(action_buttons.ViewLock, not dead)

    local now = os.clock()

    for slot, button in skill_buttons do
        local skill_id = HotbarConfig.get_skill_for_slot(slot)
        local cooldown_end = cooldown_ends[slot] or 0
        local remaining = math.max(0, cooldown_end - now)
        local enabled = skill_id ~= nil
            and not dead
            and not mending
            and not guard_broken
            and state == State.LOCOMOTION
            and remaining <= 0

        style_button(button, enabled)

        if skill_id then
            local definition = SkillDefinitions.get(skill_id)
            local display_name = definition
                and definition.DISPLAY_NAME
                or skill_id

            if remaining > 0 then
                button.Text = string.format(
                    "%d\n%s\n%.1f",
                    slot,
                    display_name,
                    remaining
                )
            else
                button.Text = string.format(
                    "%d\n%s",
                    slot,
                    display_name
                )
            end
        else
            button.Text = tostring(slot)
        end
    end

    action_buttons.ViewLock.Text = CombatInputActions.is_view_lock_enabled()
        and "LOCK\nON"
        or "LOCK"

    if block_held and not action_buttons.Block.Active then
        block_held = false
        CombatInputActions.set_block(false)
    end
end


ClientCombatController.on_server_state_changed(function(
    server_state: string,
    skill_or_attack_id: string,
    _server_timestamp: number
)
    if server_state == State.DEAD then
        table.clear(cooldown_ends)
        return
    end

    local definition = SkillDefinitions.get(skill_or_attack_id)

    if not definition then
        return
    end

    local is_skill_start = server_state == State.MENDING
        or server_state == State.WIND_UP

    if is_skill_start then
        begin_skill_cooldown(skill_or_attack_id)
    end
end)

RunService.RenderStepped:Connect(refresh_controls)
refresh_controls()
