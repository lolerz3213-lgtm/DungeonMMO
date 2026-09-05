local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local server_combat_folder = ServerScriptService
    :WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local MeleeHitService = require(
    server_combat_folder:WaitForChild("MeleeHitService")
)

local assertion_count = 0


--[[
Asserts one boolean condition for melee cancellation behaviour.

Args:
    condition (boolean): Condition that must be true.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Melee Cancellation Tests] " .. message, 2)
    end

    assertion_count += 1
end


--[[
Creates a minimal humanoid model for melee sampling.

Args:
    name (string): Model name.
    position (Vector3): World root position.
    tagged (boolean): Whether the model is a valid NPC combat target.

Returns:
    Model: Created model.
]]
local function create_model(
    name: string,
    position: Vector3,
    tagged: boolean
): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.CFrame = CFrame.new(position)
    root.Anchored = true
    root.CanCollide = false
    root.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = model
    model.PrimaryPart = root

    if tagged then
        CollectionService:AddTag(model, CombatConfig.TARGETS.NPC_TAG)
    end

    return model
end


local origin = Vector3.new(650, 20, 650)
local attacker = create_model("CancelTestAttacker", origin, false)
local target = create_model(
    "CancelTestTarget",
    origin + Vector3.new(0, 0, -4),
    true
)
local callback_count = 0

MeleeHitService.begin_active_window({
    attacker = nil,
    character = attacker,
    attack_id = "CancelTest",
    attack_definition = CombatConfig.BASIC_ATTACK.ATTACKS.Slash1,
    base_damage = 0,
    is_cancelled = function()
        return true
    end,
    on_target = function(_target: Model)
        callback_count += 1
    end,
})

task.wait(
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash1.ACTIVE_SECONDS + 0.05
)

assert_true(
    callback_count == 0,
    "A cancelled active window must not deliver melee callbacks."
)

attacker:Destroy()
target:Destroy()

print(
    string.format(
        "[Melee Cancellation Tests] PASS: %d assertions.",
        assertion_count
    )
)
