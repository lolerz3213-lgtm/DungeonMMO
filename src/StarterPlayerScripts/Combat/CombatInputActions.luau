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
local UserInputService = game:GetService("UserInputService")
local core_shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")
local EquipmentPresentationRules = require(
    core_shared:WaitForChild("EquipmentPresentationRules")
)
local EquipmentDefenseRules = require(
    core_shared:WaitForChild("EquipmentDefenseRules")
)
local ProgressionClientState = require(
    script.Parent.Parent
        :WaitForChild("Core")
        :WaitForChild("ProgressionClientState")
)
local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)

local attack_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.ATTACK_REQUEST
) :: RemoteEvent
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
Returns whether authoritative runtime presentation identifies a Longbow.

Args:
    None.

Returns:
    boolean: True when the run snapshot exposes the Apprentice Longbow.
]]
local function is_longbow_equipped(): boolean
    local item_id = player:GetAttribute(
        EquipmentPresentationRules.WEAPON_ITEM_ATTRIBUTE
    )

    return EquipmentPresentationRules.show_longbow(item_id)
end

--[[
Begins the primary basic-attack input.

Longbow uses held Begin/End intent. Existing Fighter and Mage weapons retain
accepted immediate prediction and request behaviour.

Args:
    None.

Returns:
    boolean: True when a basic-attack intent was sent or predicted.
]]
function CombatInputActions.begin_attack(): boolean
    if not CombatInputActions.can_send_combat_input() then
        return false
    end

    if is_longbow_equipped() then
        attack_request:FireServer("DrawStart")
        return true
    end

    return ClientCombatController.request_attack()
end

--[[
Ends or cancels one held Longbow basic-attack input.

Args:
    cancelled (boolean): True to cancel without firing.

Returns:
    boolean: True when Longbow end intent was sent.
]]
function CombatInputActions.end_attack(cancelled: boolean): boolean
    if not is_longbow_equipped() then
        return false
    end

    attack_request:FireServer(
        if cancelled then "DrawCancel" else "DrawRelease"
    )
    return true
end

--[[
Compatibility tap request for legacy callers.

Longbow falls back to a Normal shot; held-capable input controllers should use
`begin_attack` and `end_attack` instead.

Args:
    None.

Returns:
    boolean: True when a basic-attack intent was sent or predicted.
]]
function CombatInputActions.request_attack(): boolean
    if not CombatInputActions.can_send_combat_input() then
        return false
    end

    if is_longbow_equipped() then
        attack_request:FireServer("DrawStart")
        attack_request:FireServer("DrawRelease")
        return true
    end

    return ClientCombatController.request_attack()
end

--[[
Returns current client world aim intent for server validation.

Args:
    None.

Returns:
    Vector3?: Client world aim position when available.
]]
local function get_world_aim_intent(): Vector3?
    local last_input = UserInputService:GetLastInputType()
    local mouse_input = last_input == Enum.UserInputType.MouseMovement
        or last_input == Enum.UserInputType.MouseButton1
        or last_input == Enum.UserInputType.MouseButton2
        or last_input == Enum.UserInputType.MouseButton3

    if mouse_input then
        local hit = player:GetMouse().Hit

        if typeof(hit) == "CFrame" then
            return hit.Position
        end
    end

    local camera = Workspace.CurrentCamera

    if camera then
        return camera.CFrame.Position
            + camera.CFrame.LookVector * 60
    end

    return nil
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

    if skill_id == "Volley" then
        skill_request:FireServer(
            skill_id,
            get_world_aim_intent()
        )
    else
        skill_request:FireServer(skill_id)
    end

    return true
end


--[[
Returns whether the equipped weapon permits the Block action.

Args:
    None.

Returns:
    boolean: False when current weapon metadata disables Block.
]]
function CombatInputActions.can_block(): boolean
    local item_id = player:GetAttribute(
        EquipmentPresentationRules.WEAPON_ITEM_ATTRIBUTE
    )

    return EquipmentDefenseRules.can_block_with_weapon(item_id)
end

--[[
Starts or ends held Block intent when the equipped weapon permits it.

Args:
    active (boolean): True for BlockStart, false for BlockEnd.

Returns:
    boolean: True when an intent was sent.
]]
function CombatInputActions.set_block(active: boolean): boolean
    if active and not CombatInputActions.can_send_combat_input() then
        return false
    end

    if not CombatInputActions.can_block() then
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
