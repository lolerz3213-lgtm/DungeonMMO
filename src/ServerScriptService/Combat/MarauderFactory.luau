--!strict
-- Reusable primitive Marauder construction shared by the Phase 1 training arena and Phase 2 dungeon rooms.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(
    ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig")
)

local MarauderConfig = CombatConfig.TRAINING_MARAUDER
local MarauderFactory = {}

export type CreateOptions = {
    Parent: Instance,
    Name: string,
    SpawnCFrame: CFrame,
    SpawnIndex: number?,
    RespawnEnabled: boolean?,
    ControllerEnabled: boolean?,
    TargetEnabled: boolean?,
    EncounterId: string?,
    EnemyId: string?,
    LifeIndex: number?,
    RewardXP: number?,
    RewardGoldMin: number?,
    RewardGoldMax: number?,
}

local function create_part(
    parent: Instance,
    name: string,
    size: Vector3,
    local_cframe: CFrame,
    anchored: boolean,
    can_collide: boolean
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = local_cframe
    part.Anchored = anchored
    part.CanCollide = can_collide
    part.CanQuery = true
    part.CanTouch = false
    part.Massless = not anchored
    part.Parent = parent
    return part
end

local function create_motor(
    parent: Instance,
    name: string,
    part_zero: BasePart,
    part_one: BasePart,
    base_c0: CFrame
): Motor6D
    local motor = Instance.new("Motor6D")
    motor.Name = name
    motor.Part0 = part_zero
    motor.Part1 = part_one
    motor.C0 = base_c0
    motor.C1 = CFrame.new()
    motor:SetAttribute("BaseC0", base_c0)
    motor.Parent = parent
    return motor
end

local function create_collision_weld(root: BasePart, collision_body: BasePart)
    local weld = Instance.new("WeldConstraint")
    weld.Name = "MarauderCollisionWeld"
    weld.Part0 = root
    weld.Part1 = collision_body
    weld.Parent = root
end

local function create_humanoid(parent: Model): Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = MarauderConfig.MAX_HEALTH
    humanoid.Health = MarauderConfig.MAX_HEALTH
    humanoid.DisplayName = "Training Marauder"
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = parent
    return humanoid
end

local function create_visual_rig(model: Model, root: BasePart)
    local collision_body = create_part(
        model,
        "CollisionBody",
        MarauderConfig.COLLISION_BODY_SIZE,
        CFrame.new(0, 2.35, 0),
        false,
        true
    )
    collision_body.Transparency = 1
    create_collision_weld(root, collision_body)

    local body = create_part(model, "Body", Vector3.new(2.8, 4, 1.5), CFrame.new(0, 2.4, 0), false, false)
    body.Color = Color3.fromRGB(118, 64, 56)
    body.Material = Enum.Material.SmoothPlastic

    local head = create_part(model, "Head", Vector3.new(2, 1.5, 1.5), CFrame.new(0, 5.2, 0), false, false)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.fromRGB(156, 122, 92)

    local right_arm = create_part(model, "RightArm", Vector3.new(0.8, 3.3, 0.8), CFrame.new(1.8, 2.75, 0), false, false)
    right_arm.Color = body.Color
    local left_arm = create_part(model, "LeftArm", Vector3.new(0.8, 3.3, 0.8), CFrame.new(-1.8, 2.75, 0), false, false)
    left_arm.Color = body.Color

    local weapon = create_part(model, "TrainingBlade", Vector3.new(0.35, 0.35, 4.5), CFrame.new(1.8, 1.15, -1.35), false, false)
    weapon.Color = Color3.fromRGB(92, 96, 104)
    weapon.Material = Enum.Material.Metal

    create_motor(model, "MarauderBodyMotor", root, body, CFrame.new(0, 2.4, 0))
    create_motor(model, "MarauderHeadMotor", body, head, CFrame.new(0, 2.8, 0))
    create_motor(model, "MarauderRightArmMotor", body, right_arm, CFrame.new(1.8, 0.35, 0))
    create_motor(model, "MarauderLeftArmMotor", body, left_arm, CFrame.new(-1.8, 0.35, 0))
    create_motor(
        model,
        "MarauderBladeMotor",
        right_arm,
        weapon,
        CFrame.new(0, -1.6, -1.35) * CFrame.Angles(math.rad(-18), 0, math.rad(12))
    )
end

function MarauderFactory.create(options: CreateOptions): Model
    assert(options.Parent ~= nil, "MarauderFactory Parent is required")
    assert(type(options.Name) == "string" and options.Name ~= "", "MarauderFactory Name is required")
    assert(typeof(options.SpawnCFrame) == "CFrame", "MarauderFactory SpawnCFrame is required")

    local model = Instance.new("Model")
    model.Name = options.Name
    model.Parent = options.Parent

    local root = create_part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(), true, false)
    root.Transparency = 1
    create_visual_rig(model, root)
    create_humanoid(model)

    model.PrimaryPart = root
    local spawn_position = options.SpawnCFrame.Position
    model:SetAttribute(MarauderConfig.SPAWN_INDEX_ATTRIBUTE, options.SpawnIndex or 0)
    model:SetAttribute("MarauderSpawnX", spawn_position.X)
    model:SetAttribute("MarauderSpawnY", spawn_position.Y)
    model:SetAttribute("MarauderSpawnZ", spawn_position.Z)
    model:SetAttribute("MarauderRespawnEnabled", if options.RespawnEnabled == nil then true else options.RespawnEnabled)
    model:SetAttribute("DungeonEncounterId", options.EncounterId or "")
    model:SetAttribute("DungeonEnemyId", options.EnemyId or "")
    model:SetAttribute("DungeonLifeIndex", options.LifeIndex or 1)
    model:SetAttribute("DungeonRewardXP", options.RewardXP or 0)
    model:SetAttribute("DungeonRewardGoldMin", options.RewardGoldMin or 0)
    model:SetAttribute("DungeonRewardGoldMax", options.RewardGoldMax or 0)

    if options.TargetEnabled ~= false then
        CollectionService:AddTag(model, CombatConfig.TARGETS.NPC_TAG)
    end
    if options.ControllerEnabled ~= false then
        CollectionService:AddTag(model, MarauderConfig.CONTROLLER_TAG)
    end

    model:PivotTo(options.SpawnCFrame)
    return model
end

return table.freeze(MarauderFactory)
