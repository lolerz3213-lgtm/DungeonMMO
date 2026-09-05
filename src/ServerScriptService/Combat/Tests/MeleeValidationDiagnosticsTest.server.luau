local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local combat_folder = ServerScriptService:WaitForChild("Combat")

local CombatConfig = require(shared_folder:WaitForChild("CombatConfig"))
local MeleeHitService = require(combat_folder:WaitForChild("MeleeHitService"))

local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    assertion_count += 1
    if not condition then
        error("[Melee Validation Diagnostics Tests] " .. message, 2)
    end
end

local function create_model(name: string, position: Vector3, tagged: boolean): Model
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

local origin = Vector3.new(1100, 20, 1100)
local attacker = create_model("ValidationAttacker", origin, false)
local accepted = create_model("ValidationAccepted", origin + Vector3.new(0, 0, -4), true)
local outside_arc = create_model("ValidationArcReject", origin + Vector3.new(5, 0, -1), true)
local outside_range = create_model("ValidationRangeReject", origin + Vector3.new(5.8, 0, -3), true)
local obstructed = create_model("ValidationObstructed", origin + Vector3.new(-2, 0, -4), true)

local wall = Instance.new("Part")
wall.Name = "ValidationWall"
wall.Size = Vector3.new(1.2, 6, 1)
wall.CFrame = CFrame.new(origin + Vector3.new(-1, 1, -2))
wall.Anchored = true
wall.CanCollide = true
wall.Parent = workspace

local rejected: {[string]: boolean} = {}
local accepted_names: {[string]: boolean} = {}
local context = {
    attacker = nil,
    character = attacker,
    attack_id = "Slash1",
    attack_definition = CombatConfig.BASIC_ATTACK.ATTACKS.Slash1,
    base_damage = 0,
    on_candidate_rejected = function(target: Model, reason: string)
        rejected[target.Name .. ":" .. reason] = true
    end,
    on_target_accepted = function(target: Model)
        accepted_names[target.Name] = true
    end,
}

local targets = MeleeHitService.collect_targets(context, {})
assert_true(#targets >= 1, "At least the front target must be accepted.")
assert_true(accepted_names[accepted.Name] == true, "Accepted callback must fire for valid target.")
assert_true(rejected[outside_arc.Name .. ":Arc"] == true, "Arc rejection must report Arc.")
assert_true(rejected[outside_range.Name .. ":Range"] == true, "Range rejection must report Range.")
assert_true(rejected[obstructed.Name .. ":Obstructed"] == true, "Obstruction rejection must report Obstructed.")

local cancel_count = 0
MeleeHitService.begin_active_window({
    attacker = nil,
    character = attacker,
    attack_id = "CancelDiagnostic",
    attack_definition = CombatConfig.BASIC_ATTACK.ATTACKS.Slash1,
    base_damage = 0,
    is_cancelled = function()
        return true
    end,
    on_window_cancelled = function()
        cancel_count += 1
    end,
})

task.wait(CombatConfig.BASIC_ATTACK.ATTACKS.Slash1.ACTIVE_SECONDS + 0.05)
assert_true(cancel_count == 1, "Cancelled active window must report exactly once.")

local dedupe_origin = origin + Vector3.new(30, 0, 0)
local dedupe_attacker = create_model("ValidationDedupeAttacker", dedupe_origin, false)
local dedupe_target = create_model(
    "ValidationDedupeTarget",
    dedupe_origin + Vector3.new(0, 0, -4),
    true
)
local accepted_count = 0

MeleeHitService.begin_active_window({
    attacker = nil,
    character = dedupe_attacker,
    attack_id = "DedupeDiagnostic",
    attack_definition = CombatConfig.BASIC_ATTACK.ATTACKS.Slash1,
    base_damage = 0,
    on_target_accepted = function(target: Model)
        if target == dedupe_target then
            accepted_count += 1
        end
    end,
})

task.wait(CombatConfig.BASIC_ATTACK.ATTACKS.Slash1.ACTIVE_SECONDS + 0.05)
assert_true(
    accepted_count == 1,
    "Repeated Active-window samples must confirm one target only once."
)

dedupe_attacker:Destroy()
dedupe_target:Destroy()

wall:Destroy()
attacker:Destroy()
accepted:Destroy()
outside_arc:Destroy()
outside_range:Destroy()
obstructed:Destroy()

print(string.format("[Melee Validation Diagnostics Tests] PASS: %d assertions.", assertion_count))
