local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local HotbarConfig = require(shared_folder:WaitForChild("HotbarConfig"))
local InputMappingConfig = require(
    shared_folder:WaitForChild("InputMappingConfig")
)
local CombatInputActions = require(
    script.Parent:WaitForChild("CombatInputActions")
)

local BasicAttack = CombatConfig.BASIC_ATTACK
local DefenseConfig = CombatConfig.DEFENSE
local Gamepad = InputMappingConfig.GAMEPAD


local function on_basic_attack(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state == Enum.UserInputState.Begin then
        CombatInputActions.request_attack()
    end

    return Enum.ContextActionResult.Sink
end


local function on_block(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state == Enum.UserInputState.Begin then
        CombatInputActions.set_block(true)
    elseif input_state == Enum.UserInputState.End
        or input_state == Enum.UserInputState.Cancel then
        CombatInputActions.set_block(false)
    end

    return Enum.ContextActionResult.Sink
end


local function on_dodge(
    _action_name: string,
    input_state: Enum.UserInputState,
    _input_object: InputObject
): Enum.ContextActionResult
    if input_state == Enum.UserInputState.Begin then
        CombatInputActions.request_dodge()
    end

    return Enum.ContextActionResult.Sink
end


local function make_skill_handler(slot: number)
    return function(
        _action_name: string,
        input_state: Enum.UserInputState,
        _input_object: InputObject
    ): Enum.ContextActionResult
        if input_state == Enum.UserInputState.Begin then
            CombatInputActions.request_skill_slot(slot)
        end

        return Enum.ContextActionResult.Sink
    end
end


ContextActionService:BindAction(
    BasicAttack.ACTION_NAME,
    on_basic_attack,
    false,
    Enum.UserInputType.MouseButton1,
    Gamepad.ATTACK
)

ContextActionService:BindAction(
    DefenseConfig.BLOCK_ACTION_NAME,
    on_block,
    false,
    Enum.UserInputType.MouseButton2,
    Gamepad.BLOCK
)

ContextActionService:BindAction(
    DefenseConfig.DODGE_ACTION_NAME,
    on_dodge,
    false,
    DefenseConfig.DODGE_KEY,
    Gamepad.DODGE
)

for slot = 1, HotbarConfig.ACTIVE_SLOT_COUNT do
    local action_name = HotbarConfig.get_action_name(slot)
    local keyboard_key = HotbarConfig.get_default_key(slot)
    local gamepad_key = HotbarConfig.get_default_gamepad_key(slot)

    if action_name and keyboard_key and gamepad_key then
        ContextActionService:BindAction(
            action_name,
            make_skill_handler(slot),
            false,
            keyboard_key,
            gamepad_key
        )
    elseif action_name and keyboard_key then
        ContextActionService:BindAction(
            action_name,
            make_skill_handler(slot),
            false,
            keyboard_key
        )
    end
end
