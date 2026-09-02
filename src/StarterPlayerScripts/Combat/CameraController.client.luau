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

local VIEW_LOCK_CONFIG = CombatConfig.VIEW_LOCK

local view_lock_enabled = false

local current_humanoid: Humanoid? = nil
local current_root_part: BasePart? = nil


--[[
Applies the current View Lock state to the active character.

Args:
    None.

Returns:
    None.
]]
local function apply_view_lock_state()
    if not current_humanoid then
        return
    end

    current_humanoid.AutoRotate = not view_lock_enabled

    if view_lock_enabled then
        current_humanoid.CameraOffset =
            VIEW_LOCK_CONFIG.CAMERA_OFFSET
    else
        current_humanoid.CameraOffset = Vector3.zero
        UserInputService.MouseBehavior =
            Enum.MouseBehavior.Default
    end
end


--[[
Changes whether custom combat View Lock is enabled.

Args:
    enabled (boolean): True to enable View Lock.

Returns:
    None.
]]
local function set_view_lock_enabled(enabled: boolean)
    view_lock_enabled = enabled

    apply_view_lock_state()

    if view_lock_enabled then
        print("[Combat Prototype] View Lock ON")
    else
        print("[Combat Prototype] View Lock OFF")
    end
end


--[[
Handles the Left Shift View Lock action.

Args:
    action_name (string): ContextActionService action identifier.
    input_state (Enum.UserInputState): Current action input state.
    input_object (InputObject): Input event that triggered the action.

Returns:
    Enum.ContextActionResult: Whether this action consumes the input.
]]
local function on_toggle_view_lock(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Sink
    end

    set_view_lock_enabled(not view_lock_enabled)

    return Enum.ContextActionResult.Sink
end


--[[
Stores the character components required by View Lock.

Args:
    character (Model): Newly spawned local player character.

Returns:
    None.
]]
local function on_character_added(character: Model)
    current_humanoid = character:WaitForChild(
        "Humanoid"
    ) :: Humanoid

    current_root_part = character:WaitForChild(
        "HumanoidRootPart"
    ) :: BasePart

    apply_view_lock_state()
end


--[[
Clears references when the local character is removed.

Args:
    character (Model): Character being removed.

Returns:
    None.
]]
local function on_character_removing(_character: Model)
    current_humanoid = nil
    current_root_part = nil
end


--[[
Synchronises character yaw with camera yaw while View Lock is active.

Args:
    delta_time (number): Time elapsed since the previous render frame.

Returns:
    None.
]]
local function update_view_lock(_delta_time: number)
    if not view_lock_enabled then
        return
    end

    if not current_root_part then
        return
    end

    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    UserInputService.MouseBehavior =
        Enum.MouseBehavior.LockCenter

    local look_vector = camera.CFrame.LookVector

    local horizontal_look = Vector3.new(
        look_vector.X,
        0,
        look_vector.Z
    )

    if horizontal_look.Magnitude <
        VIEW_LOCK_CONFIG.MIN_LOOK_MAGNITUDE then
        return
    end

    local facing_direction = horizontal_look.Unit
    local root_position = current_root_part.Position

    current_root_part.CFrame = CFrame.lookAt(
        root_position,
        root_position + facing_direction
    )
end


ContextActionService:BindAction(
    VIEW_LOCK_CONFIG.ACTION_NAME,
    on_toggle_view_lock,
    false,
    VIEW_LOCK_CONFIG.TOGGLE_KEY
)

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
