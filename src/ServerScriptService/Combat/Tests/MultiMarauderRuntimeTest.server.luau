local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local assertions = 0

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Multi Marauder Runtime Tests] " .. message, 2)
    end
    assertions += 1
end

local deadline = os.clock() + 3
for index, name in MarauderConfig.MODEL_NAMES do
    local model = Workspace:FindFirstChild(name)
    while not model and os.clock() < deadline do
        task.wait(0.05)
        model = Workspace:FindFirstChild(name)
    end
    assert_true(model ~= nil, string.format("%s was not created.", name))
    if model then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        assert_true(humanoid ~= nil, string.format("%s has no Humanoid.", name))
        assert_true(model:GetAttribute("MarauderSpawnIndex") == index, string.format("%s has wrong spawn index.", name))

        local state_deadline = os.clock() + 3
        while type(model:GetAttribute(MarauderConfig.AI_STATE_ATTRIBUTE)) ~= "string"
            and os.clock() < state_deadline do
            task.wait(0.05)
        end

        local aggro_deadline = os.clock() + 3
        while type(model:GetAttribute(MarauderConfig.AGGRO_TARGET_ATTRIBUTE)) ~= "number"
            and os.clock() < aggro_deadline do
            task.wait(0.05)
        end

        assert_true(type(model:GetAttribute(MarauderConfig.AI_STATE_ATTRIBUTE)) == "string", string.format("%s has no AI state.", name))
        assert_true(type(model:GetAttribute(MarauderConfig.AGGRO_TARGET_ATTRIBUTE)) == "number", string.format("%s has no aggro target attribute.", name))
    end
end

print(string.format("[Multi Marauder Runtime Tests] PASS: %d assertions.", assertions))
