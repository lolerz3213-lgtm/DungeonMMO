local CombatTypes = require(script.Parent:WaitForChild("CombatTypes"))

local State = CombatTypes.State

local ALLOWED_TRANSITIONS = table.freeze({
    [State.LOCOMOTION] = table.freeze({
        [State.WIND_UP] = true,
    }),
    [State.WIND_UP] = table.freeze({
        [State.ACTIVE] = true,
    }),
    [State.ACTIVE] = table.freeze({
        [State.RECOVERY] = true,
    }),
    [State.RECOVERY] = table.freeze({
        [State.LOCOMOTION] = true,
        [State.WIND_UP] = true,
    }),
})

local BUFFER_BOUNDARY_EPSILON = 1e-9

local StateRules = {}


--[[
Checks whether one combat state may transition directly to another.

Args:
    current_state (string): Current combat-state name.
    next_state (string): Requested combat-state name.

Returns:
    boolean: True when the transition is part of the combat state graph.
]]
function StateRules.can_transition(
    current_state: string,
    next_state: string
): boolean
    local allowed_next_states = ALLOWED_TRANSITIONS[current_state]

    if not allowed_next_states then
        return false
    end

    return allowed_next_states[next_state] == true
end


--[[
Returns the movement multiplier for an attack state.

Args:
    state_name (string): Combat state being evaluated.
    attack_definition (table): Config for the active attack.

Returns:
    number: Multiplier applied to the character's base walk speed.
]]
function StateRules.get_movement_scale(
    state_name: string,
    attack_definition: any
): number
    if state_name == State.WIND_UP then
        return attack_definition.MOVEMENT_SCALE.WIND_UP
    end

    if state_name == State.ACTIVE then
        return attack_definition.MOVEMENT_SCALE.ACTIVE
    end

    if state_name == State.RECOVERY then
        return attack_definition.MOVEMENT_SCALE.RECOVERY
    end

    return 1
end


--[[
Finds the attack that follows the current attack in a looping chain.

Args:
    current_attack_id (string): Current attack identifier.
    attack_order ({string}): Ordered attack identifiers.

Returns:
    string: Identifier for the next attack in the chain.
]]
function StateRules.get_next_attack_id(
    current_attack_id: string,
    attack_order: {string}
): string
    for index, attack_id in attack_order do
        if attack_id == current_attack_id then
            local next_index = (index % #attack_order) + 1
            return attack_order[next_index]
        end
    end

    return attack_order[1]
end


--[[
Checks whether the late-recovery combo buffer is currently open.

Args:
    recovery_elapsed (number): Seconds spent in recovery.
    recovery_duration (number): Total recovery duration in seconds.
    buffer_duration (number): Size of the late-recovery buffer window.

Returns:
    boolean: True while input may be buffered into the next attack.
]]
function StateRules.is_buffer_window_open(
    recovery_elapsed: number,
    recovery_duration: number,
    buffer_duration: number
): boolean
    if recovery_elapsed < 0 then
        return false
    end

    local buffer_start = math.max(
        0,
        recovery_duration - buffer_duration
    )

    return recovery_elapsed + BUFFER_BOUNDARY_EPSILON >= buffer_start
        and recovery_elapsed <= recovery_duration
            + BUFFER_BOUNDARY_EPSILON
end


--[[
Checks whether a stored combo continuation has expired.

Args:
    idle_duration (number): Seconds since the previous attack ended.
    reset_duration (number): Allowed time before the chain resets.

Returns:
    boolean: True when the next attack must return to Slash 1.
]]
function StateRules.should_reset_combo(
    idle_duration: number,
    reset_duration: number
): boolean
    return idle_duration >= reset_duration
end


return table.freeze(StateRules)
