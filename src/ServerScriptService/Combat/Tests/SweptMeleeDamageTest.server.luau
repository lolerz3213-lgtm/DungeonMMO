local CollectionService = game:GetService(
    "CollectionService"
)
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)
local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local combat_folder = ServerScriptService
    :WaitForChild("Combat")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local MeleeHitService = require(
    combat_folder:WaitForChild(
        "MeleeHitService"
    )
)

if MeleeHitService.begin_active_window == nil then
    error(
        "[Swept Melee Damage Tests] RED: "
            .. "begin_active_window is missing."
    )
end

local assertion_count = 0
local EPSILON = 1e-6
local TEST_ORIGIN = Vector3.new(
    700,
    25,
    700
)


--[[
Raises an error when a swept-melee assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Swept Melee Damage Tests] "
                .. message
        )
    end
end


--[[
Checks two numeric values using floating-point tolerance.

Args:
    actual (number): Value produced by the system.
    expected (number): Required value.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_number(
    actual: number,
    expected: number,
    message: string
)
    assert_true(
        math.abs(actual - expected) <= EPSILON,
        string.format(
            "%s Expected %.3f, got %.3f.",
            message,
            expected,
            actual
        )
    )
end


--[[
Creates one stationary combat Model.

Args:
    name (string): Model name.
    position (Vector3): Root world position.
    tagged (boolean): Whether the model is an NPC combat target.

Returns:
    Model: Test combat Model.
]]
local function create_combat_model(
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

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2, 3, 1)
    body.CFrame = CFrame.new(
        position + Vector3.new(0, 2, 0)
    )
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = model

    model.PrimaryPart = root

    if tagged then
        CollectionService:AddTag(
            model,
            CombatConfig.TARGETS.NPC_TAG
        )
    end

    return model
end


--[[
Gets the Humanoid from a deterministic test Model.

Args:
    model (Model): Model expected to own a Humanoid.

Returns:
    Humanoid: The target Humanoid.
]]
local function get_humanoid(
    model: Model
): Humanoid
    local humanoid =
        model:FindFirstChildOfClass("Humanoid")

    assert_true(
        humanoid ~= nil,
        model.Name .. " must contain a Humanoid."
    )

    return humanoid :: Humanoid
end


local attacker = create_combat_model(
    "SweptDamageAttacker",
    TEST_ORIGIN,
    false
)

local target_one = create_combat_model(
    "SweptDamageTargetOne",
    TEST_ORIGIN + Vector3.new(0, 0, -4),
    true
)

local target_two = create_combat_model(
    "SweptDamageTargetTwo",
    TEST_ORIGIN + Vector3.new(2.5, 0, -4),
    true
)

local target_one_humanoid =
    get_humanoid(target_one)
local target_two_humanoid =
    get_humanoid(target_two)

local attack_definition =
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash1

assert_true(
    attack_definition.HITBOX.SAMPLE_COUNT > 1,
    "Slash1 must use multiple Active-window samples."
)

MeleeHitService.begin_active_window({
    attacker = nil,
    character = attacker,
    attack_id = "Slash1",
    attack_definition = attack_definition,
    base_damage =
        CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE,
})

task.wait(
    attack_definition.ACTIVE_SECONDS + 0.08
)

assert_number(
    target_one_humanoid.Health,
    90,
    "Target one must take Slash1 damage exactly once."
)

assert_number(
    target_two_humanoid.Health,
    90,
    "Cleave target must take Slash1 damage exactly once."
)

task.wait(
    attack_definition.ACTIVE_SECONDS + 0.08
)

assert_number(
    target_one_humanoid.Health,
    90,
    "Scheduled samples must not damage target one twice."
)

assert_number(
    target_two_humanoid.Health,
    90,
    "Scheduled samples must not damage cleave target twice."
)

for _, model in {
    attacker,
    target_one,
    target_two,
} do
    model:Destroy()
end

print(
    string.format(
        "[Swept Melee Damage Tests] PASS: "
            .. "%d assertions.",
        assertion_count
    )
)
