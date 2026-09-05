local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local InputMappingConfig = require(
    shared_folder:WaitForChild("InputMappingConfig")
)

local VIEW_LOCK_CONFIG = CombatConfig.VIEW_LOCK
local Gamepad = InputMappingConfig.GAMEPAD

local existing_state = player:GetAttribute(
    VIEW_LOCK_CONFIG.STATE_ATTRIBUTE
)
local view_lock_enabled = existing_state == true

if existing_state == nil then
    player:SetAttribute(
        VIEW_LOCK_CONFIG.STATE_ATTRIBUTE,
        false
    )
end

local current_humanoid: Humanoid? = nil
local current_root_part: BasePart? = nil


local function apply_view_lock_state()
    if not view_lock_enabled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end

    if not current_humanoid then
        return
    end

    current_humanoid.AutoRotate = not view_lock_enabled

    if view_lock_enabled then
        current_humanoid.CameraOffset = VIEW_LOCK_CONFIG.CAMERA_OFFSET
    else
        current_humanoid.CameraOffset = Vector3.zero
    end
end


local function set_view_lock_enabled(enabled: boolean)
    view_lock_enabled = enabled

    if player:GetAttribute(VIEW_LOCK_CONFIG.STATE_ATTRIBUTE) ~= enabled then
        player:SetAttribute(
            VIEW_LOCK_CONFIG.STATE_ATTRIBUTE,
            enabled
        )
    end

    apply_view_lock_state()

    if view_lock_enabled then
        print("[Combat Prototype] View Lock ON")
    else
        print("[Combat Prototype] View Lock OFF")
    end
end


local function on_toggle_view_lock(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state == Enum.UserInputState.Begin then
        set_view_lock_enabled(not view_lock_enabled)
    end

    return Enum.ContextActionResult.Sink
end


local function on_character_added(character: Model)
    current_humanoid = character:WaitForChild("Humanoid") :: Humanoid
    current_root_part = character:WaitForChild(
        "HumanoidRootPart"
    ) :: BasePart

    current_humanoid.Died:Connect(function()
        set_view_lock_enabled(false)
    end)

    apply_view_lock_state()
end


local function on_character_removing(_character: Model)
    current_humanoid = nil
    current_root_part = nil
end


local function update_view_lock(_delta_time: number)
    if not view_lock_enabled or not current_root_part then
        return
    end

    local character = current_root_part.Parent

    if character
        and character:GetAttribute("CombatState") == "Dodging" then
        return
    end

    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    local look_vector = camera.CFrame.LookVector
    local horizontal_look = Vector3.new(
        look_vector.X,
        0,
        look_vector.Z
    )

    if horizontal_look.Magnitude < VIEW_LOCK_CONFIG.MIN_LOOK_MAGNITUDE then
        return
    end

    local root_position = current_root_part.Position

    current_root_part.CFrame = CFrame.lookAt(
        root_position,
        root_position + horizontal_look.Unit
    )
end


ContextActionService:BindAction(
    VIEW_LOCK_CONFIG.ACTION_NAME,
    on_toggle_view_lock,
    false,
    VIEW_LOCK_CONFIG.TOGGLE_KEY,
    Gamepad.VIEW_LOCK
)

player:GetAttributeChangedSignal(
    VIEW_LOCK_CONFIG.STATE_ATTRIBUTE
):Connect(function()
    local requested = player:GetAttribute(
        VIEW_LOCK_CONFIG.STATE_ATTRIBUTE
    ) == true

    if requested ~= view_lock_enabled then
        set_view_lock_enabled(requested)
    end
end)

RunService:BindToRenderStep(
    "CombatViewLockFacing",
    Enum.RenderPriority.Camera.Value + 1,
    update_view_lock
)

player.CharacterAdded:Connect(on_character_added)
player.CharacterRemoving:Connect(on_character_removing)

if player.Character then
    on_character_added(player.Character)
end
