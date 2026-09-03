local CollectionService = game:GetService(
    "CollectionService"
)
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local assertion_count = 0


--[[
Raises an error when a training-dummy assertion fails.

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
            "[Training Dummy Tests] " .. message
        )
    end
end


--[[
Waits briefly for the runtime Training Dummy to be created.

Args:
    None.

Returns:
    Model?: Runtime Training Dummy.
]]
local function wait_for_dummy(): Model?
    local deadline = os.clock() + 2

    repeat
        local dummy = workspace:FindFirstChild(
            "TrainingDummy"
        )

        if dummy and dummy:IsA("Model") then
            return dummy
        end

        task.wait(0.05)
    until os.clock() >= deadline

    return nil
end


local dummy = wait_for_dummy()

if not dummy then
    error(
        "[Training Dummy Tests] RED: "
            .. "TrainingDummy runtime model is missing."
    )
end

assert_true(
    CollectionService:HasTag(
        dummy,
        CombatConfig.TARGETS.NPC_TAG
    ),
    "TrainingDummy must have the combat target tag."
)

local humanoid =
    dummy:FindFirstChildOfClass("Humanoid")

assert_true(
    humanoid ~= nil,
    "TrainingDummy must contain a Humanoid."
)

if humanoid then
    assert_true(
        humanoid.MaxHealth == 200,
        "TrainingDummy MaxHealth must be 200."
    )

    assert_true(
        humanoid.Health == 200,
        "TrainingDummy must start at full health."
    )
end

local root = dummy:FindFirstChild(
    "HumanoidRootPart"
)

assert_true(
    root ~= nil and root:IsA("BasePart"),
    "TrainingDummy must contain HumanoidRootPart."
)

if root and root:IsA("BasePart") then
    assert_true(
        root.Anchored,
        "TrainingDummy root must be anchored."
    )
end

assert_true(
    CombatConfig.DEBUG.SHOW_MELEE_HITBOX ~= nil,
    "SHOW_MELEE_HITBOX debug toggle must exist."
)

assert_true(
    CombatConfig.DEBUG.PRINT_MELEE_HITS ~= nil,
    "PRINT_MELEE_HITS debug toggle must exist."
)

assert_true(
    CombatConfig.DEBUG.PRINT_DAMAGE ~= nil,
    "PRINT_DAMAGE debug toggle must exist."
)

print(
    string.format(
        "[Training Dummy Tests] PASS: %d assertions.",
        assertion_count
    )
)
