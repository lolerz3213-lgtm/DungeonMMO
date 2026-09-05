local MarauderPresentationRules = {}

export type Pose = {
    Body: CFrame,
    Head: CFrame,
    RightArm: CFrame,
    LeftArm: CFrame,
    Blade: CFrame,
}

local IDENTITY = CFrame.new()

local IDLE_POSE: Pose = {
    Body = IDENTITY,
    Head = IDENTITY,
    RightArm = CFrame.Angles(math.rad(-8), 0, math.rad(8)),
    LeftArm = CFrame.Angles(math.rad(4), 0, math.rad(-6)),
    Blade = IDENTITY,
}

local ATTACK_POSES = {
    Normal = {
        WindUp = {
            Body = CFrame.Angles(math.rad(-5), math.rad(-28), 0),
            Head = CFrame.Angles(0, math.rad(16), 0),
            RightArm = CFrame.Angles(math.rad(-42), 0, math.rad(62)),
            LeftArm = CFrame.Angles(math.rad(10), 0, math.rad(-18)),
            Blade = CFrame.Angles(0, 0, math.rad(8)),
        },
        Strike = {
            Body = CFrame.Angles(math.rad(5), math.rad(34), 0),
            Head = CFrame.Angles(0, math.rad(-12), 0),
            RightArm = CFrame.Angles(math.rad(-18), 0, math.rad(-82)),
            LeftArm = CFrame.Angles(math.rad(-6), 0, math.rad(14)),
            Blade = CFrame.Angles(0, 0, math.rad(-10)),
        },
    },
    Heavy = {
        WindUp = {
            Body = CFrame.Angles(math.rad(-12), 0, 0),
            Head = CFrame.Angles(math.rad(8), 0, 0),
            RightArm = CFrame.Angles(math.rad(-138), 0, math.rad(12)),
            LeftArm = CFrame.Angles(math.rad(-62), 0, math.rad(-18)),
            Blade = CFrame.Angles(math.rad(-18), 0, 0),
        },
        Strike = {
            Body = CFrame.Angles(math.rad(19), 0, 0),
            Head = CFrame.Angles(math.rad(-8), 0, 0),
            RightArm = CFrame.Angles(math.rad(58), 0, math.rad(-8)),
            LeftArm = CFrame.Angles(math.rad(20), 0, math.rad(-12)),
            Blade = CFrame.Angles(math.rad(20), 0, 0),
        },
    },
}

local STAGGER_POSE: Pose = {
    Body = CFrame.Angles(math.rad(-17), math.rad(-8), math.rad(5)),
    Head = CFrame.Angles(math.rad(12), math.rad(6), 0),
    RightArm = CFrame.Angles(math.rad(28), 0, math.rad(32)),
    LeftArm = CFrame.Angles(math.rad(18), 0, math.rad(-30)),
    Blade = CFrame.Angles(math.rad(12), 0, math.rad(18)),
}

local DEATH_POSE: Pose = {
    Body = CFrame.new(0, -0.65, 0) * CFrame.Angles(0, 0, math.rad(78)),
    Head = CFrame.Angles(0, 0, math.rad(15)),
    RightArm = CFrame.Angles(math.rad(35), 0, math.rad(30)),
    LeftArm = CFrame.Angles(math.rad(-20), 0, math.rad(-40)),
    Blade = CFrame.Angles(math.rad(10), 0, math.rad(25)),
}


--[[Returns the neutral Marauder pose.]]
function MarauderPresentationRules.get_idle_pose(): Pose
    return IDLE_POSE
end


--[[Returns one configured attack pose.]]
function MarauderPresentationRules.get_attack_pose(
    attack_name: string,
    phase_name: string
): Pose
    local attack_poses = ATTACK_POSES[attack_name]

    assert(attack_poses ~= nil, "Unknown Marauder presentation attack: " .. attack_name)

    local pose = attack_poses[phase_name]

    assert(pose ~= nil, "Unknown Marauder presentation phase: " .. phase_name)

    return pose
end


--[[Returns the visible stagger recoil pose.]]
function MarauderPresentationRules.get_stagger_pose(): Pose
    return STAGGER_POSE
end


--[[Returns the visible death pose.]]
function MarauderPresentationRules.get_death_pose(): Pose
    return DEATH_POSE
end


--[[Returns a lightweight procedural chase pose for one elapsed time.]]
function MarauderPresentationRules.get_chase_pose(elapsed_seconds: number): Pose
    local phase = elapsed_seconds * math.pi * 3.6
    local bob = math.sin(phase)
    local arm_swing = math.sin(phase) * math.rad(12)

    return {
        Body = CFrame.new(0, math.abs(bob) * 0.07, 0)
            * CFrame.Angles(math.rad(4 + bob * 2), 0, 0),
        Head = CFrame.Angles(math.rad(-2), 0, 0),
        RightArm = CFrame.Angles(arm_swing - math.rad(6), 0, math.rad(7)),
        LeftArm = CFrame.Angles(-arm_swing + math.rad(4), 0, math.rad(-6)),
        Blade = IDENTITY,
    }
end


return table.freeze(MarauderPresentationRules)
