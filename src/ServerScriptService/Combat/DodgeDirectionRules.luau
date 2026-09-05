local DodgeDirectionRules = {}

DodgeDirectionRules.DodgeStyle = table.freeze({
    FORWARD_ROLL = "ForwardRoll",
    SIDE_DASH = "SideDash",
    BACKWARD_ROLL = "BackwardRoll",
})

local DodgeStyle = DodgeDirectionRules.DodgeStyle

local VALID_INPUT_CODES = {
    Forward = true,
    Backward = true,
    Left = true,
    Right = true,
    ForwardLeft = true,
    ForwardRight = true,
    BackwardLeft = true,
    BackwardRight = true,
}


--[[
Checks whether a client dodge-direction intent is one of the allowed inputs.

Args:
    input_code (any): Client-provided direction identifier.

Returns:
    boolean: True only for one of the eight supported dodge directions.
]]
function DodgeDirectionRules.is_valid_input_code(input_code: any): boolean
    return typeof(input_code) == "string"
        and VALID_INPUT_CODES[input_code] == true
end


--[[
Returns whether an input is a pure lateral A/D direction.

Args:
    input_code (string): Validated eight-way dodge input code.

Returns:
    boolean: True only for pure Left or Right dodge input.
]]
function DodgeDirectionRules.is_lateral_input_code(
    input_code: string
): boolean
    return input_code == "Left" or input_code == "Right"
end


--[[
Returns whether an input belongs to the backward roll family.

Args:
    input_code (string): Validated eight-way dodge input code.

Returns:
    boolean: True for backward and backward-diagonal input.
]]
function DodgeDirectionRules.is_backward_input_code(
    input_code: string
): boolean
    return input_code == "Backward"
        or input_code == "BackwardLeft"
        or input_code == "BackwardRight"
end


--[[
Returns the authoritative visual family for one dodge request.

Unlocked dodges always turn toward camera-relative travel and use the normal
forward roll. View-Locked dodges preserve combat facing, so A/D use the
lateral slide-dash and backward inputs use the backward roll.

Args:
    input_code (string): Validated eight-way dodge input code.
    view_locked (boolean): Whether combat View Lock is active.

Returns:
    string: One DodgeStyle value.
]]
function DodgeDirectionRules.get_dodge_style(
    input_code: string,
    view_locked: boolean
): string
    if not view_locked then
        return DodgeStyle.FORWARD_ROLL
    end

    if DodgeDirectionRules.is_lateral_input_code(input_code) then
        return DodgeStyle.SIDE_DASH
    end

    if DodgeDirectionRules.is_backward_input_code(input_code) then
        return DodgeStyle.BACKWARD_ROLL
    end

    return DodgeStyle.FORWARD_ROLL
end


--[[
Returns whether one dodge should use the short lateral slide-dash profile.

Lateral slide-dashes only exist while View Lock is enabled. With View Lock off,
all camera-relative dodge directions rotate the character into travel and use
the normal forward-roll profile.

Args:
    input_code (string): Validated eight-way dodge input code.
    view_locked (boolean): Whether combat View Lock is active.

Returns:
    boolean: True only for View-Locked pure Left or Right input.
]]
function DodgeDirectionRules.should_use_lateral_profile(
    input_code: string,
    view_locked: boolean
): boolean
    return DodgeDirectionRules.get_dodge_style(
        input_code,
        view_locked
    ) == DodgeStyle.SIDE_DASH
end


--[[
Returns whether an active dodge should continuously follow character facing.

Only View-Locked dodges steer from live facing. Unlocked camera-relative
rolls turn into their world direction once at dodge start, then travel
without repeatedly rewriting the character root CFrame.

Args:
    view_locked (boolean): Whether combat View Lock was active at dodge start.

Returns:
    boolean: True only for View-Locked steerable dodges.
]]
function DodgeDirectionRules.should_follow_facing_during_dodge(
    view_locked: boolean
): boolean
    return view_locked
end


--[[
Checks whether one numeric component is finite and reasonably bounded.

Args:
    value (number): Numeric component to validate.

Returns:
    boolean: True when the component is finite and safe to normalize.
]]
local function is_finite_component(value: number): boolean
    return value == value and math.abs(value) < 1000000
end


--[[
Validates and normalizes a client world-space dodge direction.

Only horizontal direction is accepted. The server discards magnitude and Y,
so clients cannot choose dodge speed, distance, lift, or collision behavior.

Args:
    direction (any): Client-provided camera-relative world direction.

Returns:
    Vector3?: Normalized horizontal direction, or nil when invalid.
]]
function DodgeDirectionRules.sanitize_world_direction(
    direction: any
): Vector3?
    if typeof(direction) ~= "Vector3" then
        return nil
    end

    if not is_finite_component(direction.X)
        or not is_finite_component(direction.Y)
        or not is_finite_component(direction.Z) then
        return nil
    end

    local planar = Vector3.new(direction.X, 0, direction.Z)

    if planar.Magnitude < 0.001 then
        return nil
    end

    return planar.Unit
end


--[[
Returns a normalized horizontal facing vector with a safe fallback.

Args:
    facing_direction (Vector3): Current character LookVector.

Returns:
    Vector3: Normalized planar forward direction.
]]
local function get_forward(facing_direction: Vector3): Vector3
    local planar = Vector3.new(
        facing_direction.X,
        0,
        facing_direction.Z
    )

    if planar.Magnitude < 0.001 then
        return Vector3.new(0, 0, -1)
    end

    return planar.Unit
end


--[[
Resolves one validated local dodge input against current character facing.

This is used while View Lock is enabled. The input remains relative to
current facing, so camera turns can steer a roll or lateral slide-dash.

Args:
    input_code (string): One of the eight supported dodge input codes.
    facing_direction (Vector3): Current character LookVector.

Returns:
    Vector3: Normalized planar world-space dodge direction.
]]
function DodgeDirectionRules.resolve(
    input_code: string,
    facing_direction: Vector3
): Vector3
    local forward = get_forward(facing_direction)
    local right = Vector3.new(
        -forward.Z,
        0,
        forward.X
    )

    if input_code == "Backward" then
        return -forward
    end

    if input_code == "Left" then
        return -right
    end

    if input_code == "Right" then
        return right
    end

    if input_code == "ForwardLeft" then
        return (forward - right).Unit
    end

    if input_code == "ForwardRight" then
        return (forward + right).Unit
    end

    if input_code == "BackwardLeft" then
        return (-forward - right).Unit
    end

    if input_code == "BackwardRight" then
        return (-forward + right).Unit
    end

    return forward
end


return table.freeze(DodgeDirectionRules)
