local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local remotes_folder = combat_folder:WaitForChild("Remotes")
local shared_folder = combat_folder:WaitForChild("Shared")

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local CombatTypes = require(shared_folder:WaitForChild("CombatTypes"))
local HotbarConfig = require(shared_folder:WaitForChild("HotbarConfig"))
local ProgressionClientState = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ProgressionClientState"))
local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)

local defense_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.DEFENSE_REQUEST
) :: RemoteEvent
local skill_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.SKILL_REQUEST
) :: RemoteEvent

local State = CombatTypes.State

local CombatInputActions = {}


--[[
Returns whether the current local character may send combat input.

Returns:
    boolean: False only while the authoritative/predicted state is Dead.
]]
function CombatInputActions.can_send_combat_input(): boolean
    return ClientCombatController.get_state() ~= State.DEAD
end


--[[
Requests the prototype basic attack through the existing prediction layer.

Returns:
    boolean: True when local prediction accepted or buffered the attack.
]]
function CombatInputActions.request_attack(): boolean
    if not CombatInputActions.can_send_combat_input() then
        return false
    end

    return ClientCombatController.request_attack()
end


--[[
Requests whichever skill is equipped in one logical hotbar slot.

Args:
    slot (number): One-based logical skill slot.

Returns:
    boolean: True when a configured skill request was sent.
]]
function CombatInputActions.request_skill_slot(slot: number): boolean
    if not CombatInputActions.can_send_combat_input() then
        return false
    end

    if slot < 1 or slot > HotbarConfig.ACTIVE_SLOT_COUNT then
        return false
    end

    local skill_id = ProgressionClientState.get_skill_for_slot(slot)

    if not skill_id then
        return false
    end

    skill_request:FireServer(skill_id)
    return true
end


--[[
Starts or ends held Block intent.

Args:
    active (boolean): True for BlockStart, false for BlockEnd.

Returns:
    boolean: True when an intent was sent.
]]
function CombatInputActions.set_block(active: boolean): boolean
    if active and not CombatInputActions.can_send_combat_input() then
        return false
    end

    defense_request:FireServer(active and "BlockStart" or "BlockEnd")
    return true
end


local function get_horizontal_move_direction(): Vector3?
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return nil
    end

    local direction = humanoid.MoveDirection
    local horizontal = Vector3.new(direction.X, 0, direction.Z)

    if horizontal.Magnitude < 0.05 then
        return nil
    end

    return horizontal.Unit
end


local function get_camera_forward(): Vector3
    local camera = Workspace.CurrentCamera

    if camera then
        local look = camera.CFrame.LookVector
        local horizontal = Vector3.new(look.X, 0, look.Z)

        if horizontal.Magnitude >= 0.001 then
            return horizontal.Unit
        end
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        local look = root.CFrame.LookVector
        return Vector3.new(look.X, 0, look.Z).Unit
    end

    return Vector3.new(0, 0, -1)
end


local function get_dodge_input_code(world_direction: Vector3?): string
    if not world_direction then
        return "Forward"
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return "Forward"
    end

    local local_direction = root.CFrame:VectorToObjectSpace(world_direction)
    local horizontal = local_direction.X
    local forward = -local_direction.Z
    local threshold = 0.35

    local left = horizontal < -threshold
    local right = horizontal > threshold
    local ahead = forward > threshold
    local behind = forward < -threshold

    if ahead and left then
        return "ForwardLeft"
    elseif ahead and right then
        return "ForwardRight"
    elseif behind and left then
        return "BackwardLeft"
    elseif behind and right then
        return "BackwardRight"
    elseif behind then
        return "Backward"
    elseif left then
        return "Left"
    elseif right then
        return "Right"
    end

    return "Forward"
end


--[[
Requests a dodge using the character's current universal movement direction.

Humanoid.MoveDirection is populated by keyboard, gamepad thumbstick and mobile
joystick input, so all three device families share this path.

Returns:
    boolean: True when a dodge request was sent.
]]
function CombatInputActions.request_dodge(): boolean
    if not CombatInputActions.can_send_combat_input() then
        return false
    end

    local move_direction = get_horizontal_move_direction()
    local world_direction = move_direction or get_camera_forward()
    local view_locked = CombatInputActions.is_view_lock_enabled()

    defense_request:FireServer(
        "Dodge",
        get_dodge_input_code(move_direction),
        view_locked,
        world_direction
    )

    return true
end


--[[
Returns whether the local View Lock flag is active.

Returns:
    boolean: Current local View Lock state.
]]
function CombatInputActions.is_view_lock_enabled(): boolean
    return player:GetAttribute(
        CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE
    ) == true
end


--[[
Toggles the shared local View Lock attribute.

CameraController owns the actual camera/facing behaviour and listens to this
attribute, allowing keyboard, controller and touch UI to share one state.

Returns:
    boolean: New View Lock state.
]]
function CombatInputActions.toggle_view_lock(): boolean
    local enabled = not CombatInputActions.is_view_lock_enabled()

    player:SetAttribute(
        CombatConfig.VIEW_LOCK.STATE_ATTRIBUTE,
        enabled
    )

    return enabled
end


return table.freeze(CombatInputActions)
