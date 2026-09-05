local TweenService = game:GetService("TweenService")

local MarauderPresentationRules = require(
    script.Parent:WaitForChild("MarauderPresentationRules")
)

local MarauderPresentationService = {}

local MOTOR_NAMES = {
    Body = "MarauderBodyMotor",
    Head = "MarauderHeadMotor",
    RightArm = "MarauderRightArmMotor",
    LeftArm = "MarauderLeftArmMotor",
    Blade = "MarauderBladeMotor",
}

local active_tweens: {[Model]: {Tween}} = setmetatable({}, {__mode = "k"})


--[[Cancels pose tweens currently writing to one Marauder rig.]]
local function cancel_active_tweens(model: Model)
    local tweens = active_tweens[model]

    if not tweens then
        return
    end

    for _, tween in tweens do
        tween:Cancel()
    end

    active_tweens[model] = nil
end


--[[Returns one required named Motor6D from a Marauder rig.]]
local function get_motor(model: Model, motor_name: string): Motor6D
    local motor = model:FindFirstChild(motor_name, true)

    assert(
        motor and motor:IsA("Motor6D"),
        string.format("%s is missing %s", model.Name, motor_name)
    )

    return motor
end


--[[Returns the stored neutral C0 for one Marauder motor.]]
local function get_base_c0(motor: Motor6D): CFrame
    local base_c0 = motor:GetAttribute("BaseC0")

    if typeof(base_c0) == "CFrame" then
        return base_c0
    end

    motor:SetAttribute("BaseC0", motor.C0)
    return motor.C0
end


--[[Applies one local pose immediately or through replicated C0 tweens.]]
local function apply_pose(model: Model, pose: any, duration_seconds: number)
    cancel_active_tweens(model)

    local tweens = {}
    local duration = math.max(0, duration_seconds)

    for pose_key, motor_name in MOTOR_NAMES do
        local motor = get_motor(model, motor_name)
        local offset = pose[pose_key] or CFrame.new()
        local target_c0 = get_base_c0(motor) * offset

        if duration <= 0 then
            motor.C0 = target_c0
        else
            local tween = TweenService:Create(
                motor,
                TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {C0 = target_c0}
            )

            table.insert(tweens, tween)
            tween:Play()
        end
    end

    if #tweens > 0 then
        active_tweens[model] = tweens
    end
end


--[[Tweens into the readable wind-up silhouette for one attack.]]
function MarauderPresentationService.play_attack_windup(
    model: Model,
    attack_name: string,
    duration_seconds: number
)
    apply_pose(
        model,
        MarauderPresentationRules.get_attack_pose(attack_name, "WindUp"),
        duration_seconds
    )
end


--[[Tweens from wind-up through the visible committed strike.]]
function MarauderPresentationService.play_attack_strike(
    model: Model,
    attack_name: string,
    duration_seconds: number
)
    apply_pose(
        model,
        MarauderPresentationRules.get_attack_pose(attack_name, "Strike"),
        duration_seconds
    )
end


--[[Applies the shared parry/Shield Bash recoil pose.]]
function MarauderPresentationService.play_stagger(
    model: Model,
    duration_seconds: number
)
    apply_pose(
        model,
        MarauderPresentationRules.get_stagger_pose(),
        math.min(0.12, math.max(0, duration_seconds))
    )
end


--[[Applies a subtle moving pose while the Marauder advances.]]
function MarauderPresentationService.set_chase_pose(
    model: Model,
    elapsed_seconds: number
)
    apply_pose(
        model,
        MarauderPresentationRules.get_chase_pose(elapsed_seconds),
        0
    )
end


--[[Applies a simple readable death/fall silhouette.]]
function MarauderPresentationService.play_death(model: Model)
    apply_pose(
        model,
        MarauderPresentationRules.get_death_pose(),
        0.18
    )
end


--[[Returns all presentation motors to their neutral pose.]]
function MarauderPresentationService.reset_pose(
    model: Model,
    duration_seconds: number
)
    apply_pose(
        model,
        MarauderPresentationRules.get_idle_pose(),
        duration_seconds
    )
end


return MarauderPresentationService
