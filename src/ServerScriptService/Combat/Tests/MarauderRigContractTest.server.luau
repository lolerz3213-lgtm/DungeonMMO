local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER

local MOTOR_NAMES = {
    "MarauderBodyMotor",
    "MarauderHeadMotor",
    "MarauderRightArmMotor",
    "MarauderLeftArmMotor",
    "MarauderBladeMotor",
}

local function test_jointed_rig_and_stable_collision_hull()
    for _, model_name in MarauderConfig.MODEL_NAMES do
        local model = Workspace:WaitForChild(model_name)
        local root = model:WaitForChild("HumanoidRootPart") :: BasePart
        local collision_body = model:WaitForChild("CollisionBody") :: BasePart

        assert(root.Anchored, model_name .. " root must remain authoritative/anchored")
        assert(collision_body.CanCollide, model_name .. " collision hull must block players")
        assert(not collision_body.Anchored, model_name .. " collision hull should belong to the anchored root assembly")

        for _, motor_name in MOTOR_NAMES do
            local motor = model:FindFirstChild(motor_name, true)
            assert(motor and motor:IsA("Motor6D"), model_name .. " missing " .. motor_name)
            assert(motor:GetAttribute("BaseC0") ~= nil, motor_name .. " needs a stored neutral transform")
        end

        for _, visual_name in {"Body", "Head", "RightArm", "LeftArm", "TrainingBlade"} do
            local visual = model:WaitForChild(visual_name) :: BasePart
            assert(not visual.CanCollide, model_name .. " visual parts must not drive collision")
        end
    end
end


test_jointed_rig_and_stable_collision_hull()

print("[Marauder Rig Contract Tests] PASS")
