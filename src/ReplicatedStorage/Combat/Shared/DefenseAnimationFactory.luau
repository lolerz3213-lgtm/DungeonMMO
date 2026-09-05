local DefenseAnimationFactory = {}

DefenseAnimationFactory.DodgeStyle = table.freeze({
    FORWARD_ROLL = "ForwardRoll",
    SIDE_DASH = "SideDash",
    BACKWARD_ROLL = "BackwardRoll",
})


--[[
Returns the left-shoulder transform used only as a block IK fallback.

Args:
    None.

Returns:
    CFrame: Fallback shoulder transform for the shield arm.
]]
function DefenseAnimationFactory.get_block_shoulder_transform(): CFrame
    return CFrame.new(-0.04, -0.10, -0.18)
        * CFrame.Angles(
            math.rad(22),
            math.rad(-34),
            math.rad(-10)
        )
end


--[[
Returns the left-elbow transform used only as a block IK fallback.

Args:
    None.

Returns:
    CFrame: Fallback elbow bend behind the shield.
]]
function DefenseAnimationFactory.get_block_elbow_transform(): CFrame
    return CFrame.Angles(
        math.rad(58),
        math.rad(6),
        math.rad(-32)
    )
end


--[[
Returns the left-wrist transform used only as a block IK fallback.

Args:
    None.

Returns:
    CFrame: Fallback wrist alignment.
]]
function DefenseAnimationFactory.get_block_wrist_transform(): CFrame
    return CFrame.Angles(
        math.rad(-8),
        math.rad(-4),
        math.rad(4)
    )
end


--[[
Returns the torso transform for a forward-braced shield wall.

Args:
    None.

Returns:
    CFrame: Waist transform for the prototype guard posture.
]]
function DefenseAnimationFactory.get_block_waist_transform(): CFrame
    return CFrame.new(0, 0, -0.06)
        * CFrame.Angles(
            math.rad(-7),
            math.rad(3),
            0
        )
end


--[[
Returns eased progress for dodge presentation.

Args:
    progress (number): Normalized progress from zero to one.

Returns:
    number: Smooth normalized progress.
]]
local function get_eased_progress(progress: number): number
    local clamped = math.clamp(progress, 0, 1)

    return clamped * clamped * (3 - (2 * clamped))
end


--[[
Returns a signed lateral travel direction from local dodge yaw.

The live rig needs the stylised slide lean opposite to the previous hop
prototype. Positive now represents screen-left and negative screen-right.

Args:
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    number: Positive one for left, negative one for right.
]]
local function get_side_travel_sign(
    direction_yaw_radians: number
): number
    if direction_yaw_radians < 0 then
        return -1
    end

    return 1
end


--[[
Returns smooth normalized interpolation between two progress points.

Args:
    progress (number): Normalized animation progress.
    start_progress (number): Segment start.
    end_progress (number): Segment end.

Returns:
    number: Smooth value from zero to one.
]]
local function smooth_segment(
    progress: number,
    start_progress: number,
    end_progress: number
): number
    local width = math.max(
        end_progress - start_progress,
        0.0001
    )
    local normalized = math.clamp(
        (progress - start_progress) / width,
        0,
        1
    )

    return normalized
        * normalized
        * (3 - (2 * normalized))
end


--[[
Returns one smooth pulse across load, push, flight, or landing phases.

Args:
    progress (number): Normalized animation progress.
    start_progress (number): Pulse start.
    peak_progress (number): Pulse peak.
    end_progress (number): Pulse end.

Returns:
    number: Smooth pulse from zero to one and back to zero.
]]
local function smooth_pulse(
    progress: number,
    start_progress: number,
    peak_progress: number,
    end_progress: number
): number
    local rise = smooth_segment(
        progress,
        start_progress,
        peak_progress
    )
    local fall = 1 - smooth_segment(
        progress,
        peak_progress,
        end_progress
    )

    return math.min(rise, fall)
end


--[[
Returns the phase weights for one low lateral slide-dash.

The pose compresses briefly, bursts sideways, stays low through the glide,
then gathers the feet underneath the body. There is no airborne phase.

Args:
    progress (number): Normalized slide-dash progress.

Returns:
    number: Compression weight.
    number: Burst weight.
    number: Low-glide weight.
    number: Recovery weight.
]]
local function get_side_dash_phases(
    progress: number
): (number, number, number, number)
    local clamped = math.clamp(progress, 0, 1)
    local compress = smooth_pulse(clamped, 0, 0.08, 0.20)
    local burst = smooth_pulse(clamped, 0.03, 0.18, 0.42)
    local glide = smooth_pulse(clamped, 0.12, 0.47, 0.82)
    local recover = smooth_pulse(clamped, 0.66, 0.86, 1.0)

    return compress, burst, glide, recover
end


--[[
Classifies local dodge direction into one of three animation families.

Forward diagonals remain rolls. Pure lateral directions use a slide-dash.
Backward and backward-diagonal directions use a backward roll.

Args:
    direction_yaw_radians (number): Local yaw toward dodge travel.

Returns:
    string: One of DefenseAnimationFactory.DodgeStyle values.
]]
function DefenseAnimationFactory.get_dodge_style(
    direction_yaw_radians: number
): string
    local absolute_degrees = math.abs(
        math.deg(direction_yaw_radians)
    )

    if absolute_degrees <= 67.5 then
        return DefenseAnimationFactory.DodgeStyle.FORWARD_ROLL
    end

    if absolute_degrees >= 112.5 then
        return DefenseAnimationFactory.DodgeStyle.BACKWARD_ROLL
    end

    return DefenseAnimationFactory.DodgeStyle.SIDE_DASH
end


--[[
Returns a full forward-roll body transform for dodge progress.

Args:
    progress (number): Normalized dodge progress from zero to one.
    direction_yaw_radians (number?): Local yaw toward travel.

Returns:
    CFrame: Root-joint transform for the forward-roll visual.
]]
function DefenseAnimationFactory.get_roll_root_transform(
    progress: number,
    direction_yaw_radians: number?
): CFrame
    local clamped = math.clamp(progress, 0, 1)
    local eased = get_eased_progress(clamped)
    local lift = math.sin(clamped * math.pi) * 0.35
    local rotation = -math.pi * 2 * eased
    local yaw = math.clamp(
        direction_yaw_radians or 0,
        math.rad(-30),
        math.rad(30)
    )

    return CFrame.new(0, lift, 0)
        * CFrame.Angles(0, yaw, 0)
        * CFrame.Angles(rotation, 0, 0)
end


--[[
Returns the root pose for a low anime-style lateral slide-dash.

The character stays close to the ground, shifts the hips sideways first,
counter-leans away from travel, and recovers upright without a jump arc.

Args:
    progress (number): Normalized side-dash progress from zero to one.
    direction_yaw_radians (number): Local yaw toward lateral travel.

Returns:
    CFrame: Root transform for the left/right slide-dash.
]]
function DefenseAnimationFactory.get_side_dash_root_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    local compress, burst, glide, recover =
        get_side_dash_phases(progress)
    local travel_sign = get_side_travel_sign(
        direction_yaw_radians
    )
    local low_pose = (-0.07 * compress)
        - (0.045 * glide)
        - (0.02 * recover)
    local lateral_pose = 0.045
        * travel_sign
        * math.max(burst, glide)
    local pitch = math.rad(-4) * burst
        + math.rad(3) * recover
    local lean = math.rad(11)
        * travel_sign
        * math.max(burst, glide * 0.9)
        - math.rad(3)
            * travel_sign
            * recover

    return CFrame.new(
        lateral_pose,
        low_pose,
        0
    ) * CFrame.Angles(
        pitch,
        0,
        lean
    )
end


--[[
Returns a small upper-body counterbalance for the lateral slide-dash.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    CFrame: Waist counterbalance that keeps the chest combat-facing.
]]
function DefenseAnimationFactory.get_side_dash_waist_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    local _compress, burst, glide, recover =
        get_side_dash_phases(progress)
    local travel_sign = get_side_travel_sign(
        direction_yaw_radians
    )
    local counter_lean = -math.rad(3)
        * travel_sign
        * math.max(burst, glide)
        + math.rad(1.5)
            * travel_sign
            * recover

    return CFrame.Angles(
        math.rad(1.5) * burst,
        0,
        counter_lean
    )
end


--[[
Returns one hip pose for a lateral slide-dash.

Both legs remain loaded underneath the hips like a compact chassé. The
leading leg gets only a small directional emphasis so the pose reads as a
two-foot glide instead of a one-foot hop.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.
    is_left_leg (boolean): True for the left hip.

Returns:
    CFrame: Hip pose for this leg.
]]
local function get_side_dash_hip_transform(
    progress: number,
    direction_yaw_radians: number,
    is_left_leg: boolean
): CFrame
    local compress, burst, glide, recover =
        get_side_dash_phases(progress)
    local leading_left = direction_yaw_radians > 0
    local is_leading = is_left_leg == leading_left

    -- Keep both legs loaded underneath the hips. The previous prototype
    -- drove the trailing hip backward while the lead hip reached outward,
    -- which read as a one-foot hop. This chassé-style pose keeps the hip
    -- flexion nearly symmetrical and uses only a small lead-leg emphasis.
    local flex_degrees = (-10 * compress)
        + (-10 * burst)
        + (-12 * glide)
        + (-5 * recover)

    if is_leading then
        flex_degrees += (-3 * burst)
            + (-3 * glide)
    else
        flex_degrees += (-1 * burst)
            + (-1 * glide)
    end

    local outward_sign = if is_left_leg then -1 else 1
    local stance_degrees = (4 * compress)
        + (7 * burst)
        + (8 * glide)
        + (3 * recover)
    local outward_degrees = outward_sign * stance_degrees

    return CFrame.Angles(
        math.rad(flex_degrees),
        0,
        math.rad(outward_degrees)
    )
end


--[[
Returns the left-hip pose for a lateral slide-dash.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    CFrame: Left hip pose.
]]
function DefenseAnimationFactory.get_side_dash_left_hip_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    return get_side_dash_hip_transform(
        progress,
        direction_yaw_radians,
        true
    )
end


--[[
Returns the right-hip pose for a lateral slide-dash.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    CFrame: Right hip pose.
]]
function DefenseAnimationFactory.get_side_dash_right_hip_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    return get_side_dash_hip_transform(
        progress,
        direction_yaw_radians,
        false
    )
end


--[[
Returns one knee pose for a lateral slide-dash.

Both knees compress together, stay bent through the low glide, and recover
together. Only a tiny lead-leg emphasis remains for directional readability.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.
    is_left_leg (boolean): True for the left knee.

Returns:
    CFrame: Knee pose for this leg.
]]
local function get_side_dash_leg_knee_transform(
    progress: number,
    direction_yaw_radians: number,
    is_left_leg: boolean
): CFrame
    local compress, burst, glide, recover =
        get_side_dash_phases(progress)
    local leading_left = direction_yaw_radians > 0
    local is_leading = is_left_leg == leading_left

    -- Both knees stay visibly flexed through the burst and glide. The tiny
    -- lead/trail difference sells direction without lifting one leg enough
    -- to make the dash look like a hop.
    local bend_degrees = (20 * compress)
        + (21 * burst)
        + (23 * glide)
        + (12 * recover)

    if is_leading then
        bend_degrees += (2 * burst) + (2 * glide)
    else
        bend_degrees += (1 * burst) + (1 * glide)
    end

    return CFrame.Angles(
        math.rad(bend_degrees),
        0,
        0
    )
end


--[[
Returns the left-knee pose for a lateral slide-dash.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    CFrame: Left knee pose.
]]
function DefenseAnimationFactory.get_side_dash_left_knee_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    return get_side_dash_leg_knee_transform(
        progress,
        direction_yaw_radians,
        true
    )
end


--[[
Returns the right-knee pose for a lateral slide-dash.

Args:
    progress (number): Normalized side-dash progress.
    direction_yaw_radians (number): Local yaw toward travel.

Returns:
    CFrame: Right knee pose.
]]
function DefenseAnimationFactory.get_side_dash_right_knee_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    return get_side_dash_leg_knee_transform(
        progress,
        direction_yaw_radians,
        false
    )
end


--[[
Returns a compatibility knee pose for older prototype tests.

Args:
    progress (number): Normalized side-dash progress.

Returns:
    CFrame: Symmetric low-glide knee bend.
]]
function DefenseAnimationFactory.get_side_dash_knee_transform(
    progress: number
): CFrame
    local compress, burst, glide, recover =
        get_side_dash_phases(progress)
    local bend_degrees = (18 * compress)
        + (20 * burst)
        + (22 * glide)
        + (14 * recover)

    return CFrame.Angles(
        math.rad(bend_degrees),
        0,
        0
    )
end


--[[
Returns a backward-roll transform without turning the character around.

Args:
    progress (number): Normalized dodge progress from zero to one.
    direction_yaw_radians (number): Local yaw toward retreat travel.

Returns:
    CFrame: Root transform for backward and backward-diagonal rolls.
]]
function DefenseAnimationFactory.get_backward_roll_root_transform(
    progress: number,
    direction_yaw_radians: number
): CFrame
    local clamped = math.clamp(progress, 0, 1)
    local eased = get_eased_progress(clamped)
    local lift = math.sin(clamped * math.pi) * 0.30
    local rotation = math.pi * 2 * eased
    local side_sign = 0

    if direction_yaw_radians > math.rad(112.5)
        and direction_yaw_radians < math.rad(170) then
        side_sign = 1
    elseif direction_yaw_radians < math.rad(-112.5)
        and direction_yaw_radians > math.rad(-170) then
        side_sign = -1
    end

    return CFrame.new(
        0.08 * side_sign * math.sin(clamped * math.pi),
        lift,
        0
    ) * CFrame.Angles(
        rotation,
        0,
        math.rad(-7) * side_sign * math.sin(clamped * math.pi)
    )
end


--[[
Returns a recoil pose for normalized Guard Break progress.

Args:
    progress (number): Normalized Guard Break progress from zero to one.

Returns:
    CFrame: Waist transform for stagger presentation.
]]
function DefenseAnimationFactory.get_guard_break_waist_transform(
    progress: number
): CFrame
    local clamped = math.clamp(progress, 0, 1)
    local recoil = math.sin(clamped * math.pi)

    return CFrame.Angles(
        math.rad(18) * recoil,
        0,
        math.rad(12) * recoil
    )
end


return table.freeze(DefenseAnimationFactory)
