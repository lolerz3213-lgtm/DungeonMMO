local MendPresentationRules = {
    ATTRIBUTE_RECEIVING = "MendReceiving",
    ATTRIBUTE_PULSE_SERIAL = "MendPulseSerial",
    ATTRIBUTE_SOURCE_USER_ID = "MendSourceUserId",
}


--[[
Returns the lowered root pose for the prototype kneeling Mend channel.

Args:
    None.

Returns:
    CFrame: Root transform applied while Mending.
]]
function MendPresentationRules.get_root_transform(): CFrame
    return CFrame.new(0, -0.48, 0.10)
        * CFrame.Angles(math.rad(-5), 0, 0)
end


--[[
Returns the forward treatment lean for the upper body.

Args:
    None.

Returns:
    CFrame: Waist transform applied while Mending.
]]
function MendPresentationRules.get_waist_transform(): CFrame
    return CFrame.Angles(math.rad(-14), 0, 0)
end


--[[
Returns the right-hip bend that drops the caster onto one knee.

Args:
    None.

Returns:
    CFrame: RightHip transform applied while Mending.
]]
function MendPresentationRules.get_right_hip_transform(): CFrame
    return CFrame.Angles(math.rad(-72), 0, math.rad(5))
end


--[[
Returns the right-knee bend for the grounded kneeling leg.

Args:
    None.

Returns:
    CFrame: RightKnee transform applied while Mending.
]]
function MendPresentationRules.get_right_knee_transform(): CFrame
    return CFrame.Angles(math.rad(92), 0, 0)
end


--[[
Returns the supporting left-leg hip pose.

Args:
    None.

Returns:
    CFrame: LeftHip transform applied while Mending.
]]
function MendPresentationRules.get_left_hip_transform(): CFrame
    return CFrame.Angles(math.rad(-24), 0, math.rad(-4))
end


--[[
Returns the supporting left-knee bend.

Args:
    None.

Returns:
    CFrame: LeftKnee transform applied while Mending.
]]
function MendPresentationRules.get_left_knee_transform(): CFrame
    return CFrame.Angles(math.rad(30), 0, 0)
end


--[[
Returns the right-arm treatment pose.

Args:
    None.

Returns:
    CFrame: RightShoulder transform applied while Mending.
]]
function MendPresentationRules.get_right_shoulder_transform(): CFrame
    return CFrame.Angles(
        math.rad(42),
        math.rad(-10),
        math.rad(18)
    )
end


--[[
Returns the left-arm treatment pose.

Args:
    None.

Returns:
    CFrame: LeftShoulder transform applied while Mending.
]]
function MendPresentationRules.get_left_shoulder_transform(): CFrame
    return CFrame.Angles(
        math.rad(42),
        math.rad(10),
        math.rad(-18)
    )
end


return table.freeze(MendPresentationRules)
