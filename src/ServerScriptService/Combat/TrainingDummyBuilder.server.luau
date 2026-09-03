local CollectionService = game:GetService(
    "CollectionService"
)
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)
local Workspace = game:GetService("Workspace")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local MAIN_DUMMY_NAME = "TrainingDummy"
local CLEAVE_DUMMY_NAME = "TrainingDummyCleave"

local FALLBACK_CFRAME = CFrame.new(
    0,
    4,
    -12
)


--[[
Creates one anchored Part for a training target.

Args:
    parent (Instance): Model receiving the Part.
    name (string): Part name.
    size (Vector3): Part dimensions.
    local_cframe (CFrame): Transform relative to the model pivot.

Returns:
    Part: Configured anchored target Part.
]]
local function create_part(
    parent: Instance,
    name: string,
    size: Vector3,
    local_cframe: CFrame
): Part
    local part = Instance.new("Part")

    part.Name = name
    part.Size = size
    part.Anchored = true
    part.CanCollide = true
    part.CanQuery = true
    part.CanTouch = false
    part.CFrame = local_cframe
    part.Parent = parent

    return part
end


--[[
Creates one deterministic stationary combat Training Dummy.

Args:
    name (string): Runtime Model name.

Returns:
    Model: Tagged NPC combat target.
]]
local function create_dummy(
    name: string
): Model
    local existing = Workspace:FindFirstChild(name)

    if existing then
        existing:Destroy()
    end

    local model = Instance.new("Model")

    model.Name = name
    model.Parent = Workspace

    local root = create_part(
        model,
        "HumanoidRootPart",
        Vector3.new(2, 2, 1),
        CFrame.new(0, 0, 0)
    )

    root.Transparency = 1

    local body = create_part(
        model,
        "Body",
        Vector3.new(2.6, 4, 1.4),
        CFrame.new(0, 2.4, 0)
    )

    local head = create_part(
        model,
        "Head",
        Vector3.new(2, 1.5, 1.5),
        CFrame.new(0, 5.1, 0)
    )

    head.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.Wood
    head.Material = Enum.Material.Wood

    local humanoid = Instance.new("Humanoid")

    humanoid.MaxHealth = 200
    humanoid.Health = 200
    humanoid.DisplayName = "Training Dummy"
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = model

    model.PrimaryPart = root

    CollectionService:AddTag(
        model,
        CombatConfig.TARGETS.NPC_TAG
    )

    return model
end


--[[
Returns the most useful arena spawn transform currently available.

Args:
    None.

Returns:
    CFrame: Spawn transform or a deterministic fallback.
]]
local function get_spawn_cframe(): CFrame
    local spawn = Workspace:FindFirstChildWhichIsA(
        "SpawnLocation",
        true
    )

    if spawn then
        return spawn.CFrame
    end

    local reset_spawn = Workspace:FindFirstChild(
        "ResetSpawn",
        true
    )

    if reset_spawn
        and reset_spawn:IsA("BasePart") then
        return reset_spawn.CFrame
    end

    return FALLBACK_CFRAME
end


--[[
Positions the two targets relative to the arena spawn.

Args:
    main_dummy (Model): Primary single-target dummy.
    cleave_dummy (Model): Secondary cleave-test dummy.

Returns:
    None.
]]
local function position_dummies(
    main_dummy: Model,
    cleave_dummy: Model
)
    local spawn_cframe = get_spawn_cframe()

    main_dummy:PivotTo(
        spawn_cframe
            * CFrame.new(0, 2, -12)
    )

    cleave_dummy:PivotTo(
        spawn_cframe
            * CFrame.new(3.6, 2, -12)
    )
end


local main_dummy = create_dummy(
    MAIN_DUMMY_NAME
)
local cleave_dummy = create_dummy(
    CLEAVE_DUMMY_NAME
)

position_dummies(
    main_dummy,
    cleave_dummy
)

-- ArenaBuilder may create the SpawnLocation after this Script starts.
-- Reposition once more after a short delay so both systems remain
-- independent of Script execution order.
task.delay(
    0.25,
    function()
        if main_dummy.Parent
            and cleave_dummy.Parent then
            position_dummies(
                main_dummy,
                cleave_dummy
            )
        end
    end
)

print(
    "[Combat Prototype] Training targets created."
)
