local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)

local BasicAttack = CombatConfig.BASIC_ATTACK


--[[
Handles keyboard, mouse and controller input for the prototype basic attack.

Args:
    action_name (string): ContextActionService action identifier.
    input_state (Enum.UserInputState): Current action input state.
    input_object (InputObject): Input event that triggered the action.

Returns:
    Enum.ContextActionResult: Whether the prototype consumed the input.
]]
local function on_basic_attack(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Sink
    end

    ClientCombatController.request_attack()

    return Enum.ContextActionResult.Sink
end


ContextActionService:BindAction(
    BasicAttack.ACTION_NAME,
    on_basic_attack,
    false,
    Enum.UserInputType.MouseButton1,
    Enum.KeyCode.ButtonR2
)
