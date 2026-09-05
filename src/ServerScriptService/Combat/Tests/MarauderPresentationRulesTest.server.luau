local MarauderPresentationRules = require(
    script.Parent.Parent:WaitForChild("MarauderPresentationRules")
)

local function pose_signature(pose: any): string
    return table.concat({
        tostring(pose.Body),
        tostring(pose.Head),
        tostring(pose.RightArm),
        tostring(pose.LeftArm),
    }, "|")
end

local function test_normal_attack_has_visible_motion()
    local windup = MarauderPresentationRules.get_attack_pose("Normal", "WindUp")
    local strike = MarauderPresentationRules.get_attack_pose("Normal", "Strike")

    assert(
        pose_signature(windup) ~= pose_signature(strike),
        "Normal Strike wind-up and strike poses must be visibly different"
    )
end

local function test_heavy_attack_reads_differently_from_normal()
    local normal = MarauderPresentationRules.get_attack_pose("Normal", "WindUp")
    local heavy = MarauderPresentationRules.get_attack_pose("Heavy", "WindUp")

    assert(
        pose_signature(normal) ~= pose_signature(heavy),
        "Heavy Overhead must have a distinct wind-up silhouette"
    )
    local heavy_x = heavy.RightArm:ToEulerAnglesXYZ()
    assert(
        math.abs(heavy_x) > 0,
        "Heavy Overhead right arm must leave its idle pose"
    )
end

local function test_stagger_pose_is_not_idle()
    local stagger = MarauderPresentationRules.get_stagger_pose()
    local idle = MarauderPresentationRules.get_idle_pose()

    assert(
        pose_signature(stagger) ~= pose_signature(idle),
        "stagger needs a visible recoil pose"
    )
end


test_normal_attack_has_visible_motion()
test_heavy_attack_reads_differently_from_normal()
test_stagger_pose_is_not_idle()

print("[Marauder Presentation Rules Tests] PASS")
