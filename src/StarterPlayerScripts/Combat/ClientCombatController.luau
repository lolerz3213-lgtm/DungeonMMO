local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local combat_folder = ReplicatedStorage:WaitForChild("Combat")
local shared_folder = combat_folder:WaitForChild("Shared")
local remotes_folder = combat_folder:WaitForChild("Remotes")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local StateRules = require(
    shared_folder:WaitForChild("StateRules")
)
local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)

local attack_request = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.ATTACK_REQUEST
) :: RemoteEvent
local state_changed_remote = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.STATE_CHANGED
) :: RemoteEvent

local State = CombatTypes.State
local BasicAttack = CombatConfig.BASIC_ATTACK

local local_state_changed = Instance.new("BindableEvent")
local server_state_changed = Instance.new("BindableEvent")

local state_name = State.LOCOMOTION
local state_started_at = os.clock()
local current_attack_id: string? = nil
local current_skill_id: string? = nil
local next_attack_id = BasicAttack.ATTACK_ORDER[1]
local queued_attack = false
local combo_expires_at = 0
local sequence_id = 0

local ClientCombatController = {}


--[[
Publishes a predicted local combat-state transition for presentation.

Args:
    next_state (string): Predicted combat state to enter.

Returns:
    None.
]]
local function set_local_state(next_state: string)
    state_name = next_state
    state_started_at = os.clock()

    local_state_changed:Fire(
        state_name,
        current_attack_id or current_skill_id or ""
    )
end


--[[
Checks whether a delayed local prediction callback is still current.

Args:
    expected_sequence_id (number): Predicted attack sequence identifier.
    expected_state (string): State required for the callback to continue.

Returns:
    boolean: True when the callback still belongs to the active attack.
]]
local function sequence_is_current(
    expected_sequence_id: number,
    expected_state: string
): boolean
    return sequence_id == expected_sequence_id
        and state_name == expected_state
end


local start_predicted_attack


--[[
Finishes local predicted recovery and handles a buffered continuation.

Args:
    expected_sequence_id (number): Current predicted attack sequence.

Returns:
    None.
]]
local function finish_predicted_attack(
    expected_sequence_id: number
)
    if not sequence_is_current(
        expected_sequence_id,
        State.RECOVERY
    ) then
        return
    end

    if not current_attack_id then
        return
    end

    local next_id = StateRules.get_next_attack_id(
        current_attack_id,
        BasicAttack.ATTACK_ORDER
    )

    if queued_attack then
        queued_attack = false
        start_predicted_attack(next_id)
        return
    end

    next_attack_id = next_id
    combo_expires_at = os.clock()
        + BasicAttack.COMBO_RESET_SECONDS

    set_local_state(State.LOCOMOTION)
    current_attack_id = nil
end


--[[
Enters predicted recovery and schedules the attack finish.

Args:
    expected_sequence_id (number): Current predicted attack sequence.
    attack_definition (table): Configuration for the current attack.

Returns:
    None.
]]
local function enter_predicted_recovery(
    expected_sequence_id: number,
    attack_definition: any
)
    if not sequence_is_current(
        expected_sequence_id,
        State.ACTIVE
    ) then
        return
    end

    set_local_state(State.RECOVERY)

    task.delay(attack_definition.RECOVERY_SECONDS, function()
        finish_predicted_attack(expected_sequence_id)
    end)
end


--[[
Enters predicted active frames and schedules recovery.

Args:
    expected_sequence_id (number): Current predicted attack sequence.
    attack_definition (table): Configuration for the current attack.

Returns:
    None.
]]
local function enter_predicted_active(
    expected_sequence_id: number,
    attack_definition: any
)
    if not sequence_is_current(
        expected_sequence_id,
        State.WIND_UP
    ) then
        return
    end

    set_local_state(State.ACTIVE)

    task.delay(attack_definition.ACTIVE_SECONDS, function()
        enter_predicted_recovery(
            expected_sequence_id,
            attack_definition
        )
    end)
end


--[[
Starts the presentation-only predicted timing for one basic attack.

Args:
    attack_id (string): Locally predicted attack identifier.

Returns:
    None.
]]
start_predicted_attack = function(attack_id: string)
    local attack_definition = BasicAttack.ATTACKS[attack_id]

    if not attack_definition then
        return
    end

    sequence_id += 1
    current_attack_id = attack_id
    current_skill_id = nil
    queued_attack = false

    local expected_sequence_id = sequence_id

    set_local_state(State.WIND_UP)

    task.delay(attack_definition.WIND_UP_SECONDS, function()
        enter_predicted_active(
            expected_sequence_id,
            attack_definition
        )
    end)
end


--[[
Resets prediction when a new local character spawns.

Args:
    None.

Returns:
    None.
]]
local function reset_prediction()
    sequence_id += 1
    state_name = State.LOCOMOTION
    state_started_at = os.clock()
    current_attack_id = nil
    current_skill_id = nil
    next_attack_id = BasicAttack.ATTACK_ORDER[1]
    queued_attack = false
    combo_expires_at = 0

    local_state_changed:Fire(
        state_name,
        ""
    )
end


--[[
Requests one basic attack and starts immediate local prediction when valid.

Args:
    None.

Returns:
    boolean: True when the local request was accepted or buffered.
]]
function ClientCombatController.request_attack(): boolean
    if state_name == State.LOCOMOTION then
        local attack_id = next_attack_id

        if os.clock() >= combo_expires_at then
            attack_id = BasicAttack.ATTACK_ORDER[1]
        end

        start_predicted_attack(attack_id)
        attack_request:FireServer()
        return true
    end

    if state_name ~= State.RECOVERY then
        return false
    end

    if not current_attack_id or queued_attack then
        return false
    end

    local attack_definition = BasicAttack.ATTACKS[
        current_attack_id
    ]
    local recovery_elapsed = os.clock() - state_started_at

    local buffer_open = StateRules.is_buffer_window_open(
        recovery_elapsed,
        attack_definition.RECOVERY_SECONDS,
        BasicAttack.COMBO_BUFFER_SECONDS
    )

    if not buffer_open then
        return false
    end

    queued_attack = true
    attack_request:FireServer()

    return true
end


--[[
Connects a callback to predicted local combat-state changes.

Args:
    callback ((string, string) -> ()): Function receiving state and attack id.

Returns:
    RBXScriptConnection: Connection that may be disconnected by the caller.
]]
function ClientCombatController.on_state_changed(
    callback: (string, string) -> ()
): RBXScriptConnection
    return local_state_changed.Event:Connect(callback)
end


--[[
Connects a callback to authoritative server combat-state updates.

Args:
    callback ((string, string, number) -> ()): Function receiving the
        server state, attack id and server timestamp.

Returns:
    RBXScriptConnection: Connection that may be disconnected by the caller.
]]
function ClientCombatController.on_server_state_changed(
    callback: (string, string, number) -> ()
): RBXScriptConnection
    return server_state_changed.Event:Connect(callback)
end


--[[
Returns the current predicted local combat state.

Args:
    None.

Returns:
    string: Current local combat-state name.
]]
function ClientCombatController.get_state(): string
    return state_name
end


state_changed_remote.OnClientEvent:Connect(function(
    server_state_name: string,
    server_attack_id: string,
    server_timestamp: number
)
    local server_is_defending =
        server_state_name == State.BLOCKING
        or server_state_name == State.DODGING
        or server_state_name == State.GUARD_BREAK
    local local_is_defending =
        state_name == State.BLOCKING
        or state_name == State.DODGING
        or state_name == State.GUARD_BREAK
    local server_skill = SkillDefinitions.get(server_attack_id)
    local server_is_skill_state = server_skill ~= nil
        and (
            server_state_name == State.WIND_UP
            or server_state_name == State.ACTIVE
            or server_state_name == State.RECOVERY
            or server_state_name == State.MENDING
        )

    if server_state_name == State.DEAD then
        sequence_id += 1
        state_name = State.DEAD
        state_started_at = os.clock()
        current_attack_id = nil
        current_skill_id = nil
        queued_attack = false
        next_attack_id = BasicAttack.ATTACK_ORDER[1]
        combo_expires_at = 0

        local_state_changed:Fire(
            state_name,
            ""
        )
    elseif server_is_skill_state then
        sequence_id += 1
        state_name = server_state_name
        state_started_at = os.clock()
        current_attack_id = nil
        current_skill_id = server_attack_id
        queued_attack = false

        local_state_changed:Fire(
            state_name,
            current_skill_id
        )
    elseif server_is_defending then
        sequence_id += 1
        state_name = server_state_name
        state_started_at = os.clock()
        current_attack_id = nil
        current_skill_id = nil
        queued_attack = false

        local_state_changed:Fire(
            state_name,
            ""
        )
    elseif server_state_name == State.LOCOMOTION
        and (
            local_is_defending
            or current_skill_id ~= nil
            or state_name == State.DEAD
        ) then
        sequence_id += 1
        state_name = State.LOCOMOTION
        state_started_at = os.clock()
        current_attack_id = nil
        current_skill_id = nil
        queued_attack = false

        local_state_changed:Fire(
            state_name,
            ""
        )
    end

    server_state_changed:Fire(
        server_state_name,
        server_attack_id,
        server_timestamp
    )
end)

player.CharacterAdded:Connect(reset_prediction)
reset_prediction()

return table.freeze(ClientCombatController)
