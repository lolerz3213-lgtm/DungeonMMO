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

local module_script = combat_folder:FindFirstChild(
    "MeleeHitService"
)

if not module_script then
    error(
        "[Melee Hit Service Tests] RED: "
            .. "MeleeHitService module is missing."
    )
end

local MeleeHitService = require(module_script)

local assertion_count = 0
local TEST_ORIGIN = Vector3.new(
    500,
    20,
    500
)


--[[
Raises an error when a melee-hit assertion fails.

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
            "[Melee Hit Service Tests] "
                .. message
        )
    end
end


--[[
Creates a basic R15-like combat Model at a world position.

Args:
    name (string): Model name.
    position (Vector3): Root position.
    tagged (boolean): Whether to add the NPC combat tag.

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
Returns true when a Model is present in a target array.

Args:
    targets ({Model}): Models returned by melee acquisition.
    expected (Model): Model being searched.

Returns:
    boolean: True when the expected Model is present.
]]
local function contains_target(
    targets: {Model},
    expected: Model
): boolean
    for _, target in targets do
        if target == expected then
            return true
        end
    end

    return false
end


local attacker = create_combat_model(
    "MeleeTestAttacker",
    TEST_ORIGIN,
    false
)

local front = create_combat_model(
    "MeleeTestFront",
    TEST_ORIGIN + Vector3.new(0, 0, -4),
    true
)

local cleave = create_combat_model(
    "MeleeTestCleave",
    TEST_ORIGIN + Vector3.new(2.5, 0, -4),
    true
)

local edge = create_combat_model(
    "MeleeTestEdge",
    TEST_ORIGIN + Vector3.new(3.4, 0, -3.6),
    true
)

local out_of_range = create_combat_model(
    "MeleeTestOutOfRange",
    TEST_ORIGIN + Vector3.new(0, 0, -7),
    true
)

local behind = create_combat_model(
    "MeleeTestBehind",
    TEST_ORIGIN + Vector3.new(0, 0, 3),
    true
)

local blocked = create_combat_model(
    "MeleeTestBlocked",
    TEST_ORIGIN + Vector3.new(-2.8, 0, -4),
    true
)

local wall = Instance.new("Part")
wall.Name = "MeleeTestWall"
wall.Size = Vector3.new(2.2, 6, 0.8)
wall.CFrame = CFrame.new(
    TEST_ORIGIN + Vector3.new(-1.4, 1, -2)
)
wall.Anchored = true
wall.CanCollide = true
wall.Parent = workspace

local attack_definition =
    CombatConfig.BASIC_ATTACK.ATTACKS.Slash1

assert_true(
    attack_definition.HITBOX ~= nil,
    "Slash1 must define HITBOX configuration."
)

local context = {
    attacker = nil,
    character = attacker,
    attack_id = "Slash1",
    attack_definition = attack_definition,
    base_damage = 10,
}

local already_hit: {[Model]: boolean} = {}

local targets =
    MeleeHitService.collect_targets(
        context,
        already_hit
    )

assert_true(
    contains_target(targets, front),
    "Target directly in front must be acquired."
)

assert_true(
    contains_target(targets, cleave),
    "Second valid NPC must be acquired for cleave."
)

assert_true(
    contains_target(targets, edge),
    "Target inside the arc edge must be acquired."
)

assert_true(
    not contains_target(
        targets,
        out_of_range
    ),
    "Target beyond reach must be rejected."
)

assert_true(
    not contains_target(targets, behind),
    "Target behind attacker must be rejected."
)

assert_true(
    not contains_target(targets, blocked),
    "Solid geometry must block melee damage."
)

assert_true(
    already_hit[front] == true,
    "Accepted target must enter per-swing deduplication."
)

local second_targets =
    MeleeHitService.collect_targets(
        context,
        already_hit
    )

assert_true(
    not contains_target(
        second_targets,
        front
    ),
    "Already-hit target must not be returned twice."
)

assert_true(
    not contains_target(
        second_targets,
        cleave
    ),
    "All accepted cleave targets must deduplicate."
)

local SkillDefinitions = require(
    shared_folder:WaitForChild("SkillDefinitions")
)

local shield_bash_definition = SkillDefinitions.get("ShieldBash")
assert_true(
    shield_bash_definition ~= nil,
    "Shield Bash definition must exist for cone tests."
)

local bash_origin = TEST_ORIGIN + Vector3.new(30, 0, 0)
local bash_attacker = create_combat_model(
    "ShieldBashConeAttacker",
    bash_origin,
    false
)

local inside_angle = math.rad(55)
local outside_angle = math.rad(65)
local cone_test_distance = 4

local inside_target = create_combat_model(
    "ShieldBashConeInside",
    bash_origin + Vector3.new(
        math.sin(inside_angle) * cone_test_distance,
        0,
        -math.cos(inside_angle) * cone_test_distance
    ),
    true
)

local outside_target = create_combat_model(
    "ShieldBashConeOutside",
    bash_origin + Vector3.new(
        math.sin(outside_angle) * cone_test_distance,
        0,
        -math.cos(outside_angle) * cone_test_distance
    ),
    true
)

local bash_context = {
    attacker = nil,
    character = bash_attacker,
    attack_id = "ShieldBash",
    attack_definition = shield_bash_definition,
    base_damage = 0,
}

local bash_targets = MeleeHitService.collect_targets(
    bash_context,
    {}
)

assert_true(
    contains_target(bash_targets, inside_target),
    "Shield Bash must accept a target 55 degrees off centre."
)

assert_true(
    not contains_target(bash_targets, outside_target),
    "Shield Bash must reject a target 65 degrees off centre."
)

local reach_inside = create_combat_model(
    "ShieldBashReachInside",
    bash_origin + Vector3.new(0, 0, -5.8),
    true
)
local reach_outside = create_combat_model(
    "ShieldBashReachOutside",
    bash_origin + Vector3.new(0, 0, -6.2),
    true
)

local reach_targets = MeleeHitService.collect_targets(
    bash_context,
    {}
)

assert_true(
    contains_target(reach_targets, reach_inside),
    "Shield Bash must accept a frontal target at 5.8 studs."
)
assert_true(
    not contains_target(reach_targets, reach_outside),
    "Shield Bash must reject a frontal target beyond 6 studs."
)

local callback_count = 0
local callback_context = {
    attacker = nil,
    character = attacker,
    attack_id = "ShieldBashTest",
    attack_definition = attack_definition,
    base_damage = 0,
    on_target = function(_target: Model)
        callback_count += 1
    end,
}

MeleeHitService.begin_active_window(callback_context)
task.wait(attack_definition.ACTIVE_SECONDS + 0.05)

assert_true(
    callback_count == 3,
    "Optional target callback must run once per accepted target."
)

for _, instance in {
    attacker,
    front,
    cleave,
    edge,
    out_of_range,
    behind,
    blocked,
    wall,
    bash_attacker,
    inside_target,
    outside_target,
    reach_inside,
    reach_outside,
} do
    instance:Destroy()
end

print(
    string.format(
        "[Melee Hit Service Tests] PASS: "
            .. "%d assertions.",
        assertion_count
    )
)
