--!strict
-- Server-authoritative prototype Marauder Captain controller.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = ServerScriptService:WaitForChild("Combat")
local Dungeon = ServerScriptService:WaitForChild("Dungeon")
local DamageService = require(Combat:WaitForChild("DamageService"))
local DefenseService = require(Combat:WaitForChild("DefenseService"))
local StaggerService = require(Combat:WaitForChild("StaggerService"))
local PresentationService = require(Combat:WaitForChild("MarauderPresentationService"))
local Factory = require(Dungeon:WaitForChild("MarauderCaptainFactory"))

local TAG = "DungeonMarauderCaptain"
local CHASE_SPEED = 11.5
local STOP_RANGE = 6.2
local THINK_INTERVAL = 0.05
local ATTACK_ORDER = {"CaptainSlash", "CaptainHeavy", "CaptainShockwave"}

type Runtime = {
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    body: BasePart,
    nextAttackAt: number,
    patternIndex: number,
    attacking: boolean,
    attackSequence: number,
}

local runtimes: {[Model]: Runtime} = {}

local function living_target(player: Player, encounter_id: string): (Model?, BasePart?)
    local character = player.Character
    if not character then return nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil, nil end
    if character:GetAttribute("DungeonRunParticipant") ~= true then return nil, nil end
    if character:GetAttribute("DungeonEncounterId") ~= encounter_id then return nil, nil end
    return character, root
end

local function nearest_target(runtime: Runtime): (Player?, Model?, BasePart?, number)
    local encounter_id = tostring(runtime.model:GetAttribute("DungeonEncounterId") or "MarauderCaptain")
    local best_player: Player? = nil
    local best_character: Model? = nil
    local best_root: BasePart? = nil
    local best_distance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local character, root = living_target(player, encounter_id)
        if character and root then
            local delta = Vector3.new(root.Position.X - runtime.root.Position.X, 0, root.Position.Z - runtime.root.Position.Z)
            if delta.Magnitude < best_distance then
                best_player, best_character, best_root, best_distance = player, character, root, delta.Magnitude
            end
        end
    end
    return best_player, best_character, best_root, best_distance
end

local function face(runtime: Runtime, target_root: BasePart)
    local target = Vector3.new(target_root.Position.X, runtime.root.Position.Y, target_root.Position.Z)
    if (target - runtime.root.Position).Magnitude > 0.01 then
        runtime.model:PivotTo(CFrame.lookAt(runtime.root.Position, target))
    end
end

local function resolve_hit(runtime: Runtime, player: Player, character: Model, attack_name: string, definition: any)
    if runtime.humanoid.Health <= 0 then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local planar = Vector3.new(root.Position.X - runtime.root.Position.X, 0, root.Position.Z - runtime.root.Position.Z)
    if planar.Magnitude > definition.ATTACK_REACH_STUDS then return end

    if definition.RADIAL ~= true then
        local forward = Vector3.new(runtime.root.CFrame.LookVector.X, 0, runtime.root.CFrame.LookVector.Z)
        if forward.Magnitude <= 0.01 or planar.Magnitude <= 0.01 then return end
        local angle = math.deg(math.acos(math.clamp(forward.Unit:Dot(planar.Unit), -1, 1)))
        if angle > definition.ATTACK_ARC_DEGREES / 2 then return end
    end

    local defense = DefenseService.resolve({
        attacker = runtime.model,
        target_player = player,
        target_character = character,
        source_kind = if definition.RADIAL then "EnemyArea" else "EnemyMelee",
        source_id = attack_name,
        attack_position = runtime.root.Position,
        stamina_damage = definition.STAMINA_DAMAGE,
        blockable = definition.RADIAL ~= true,
        parryable = definition.RADIAL ~= true,
    })
    if defense.outcome == "Parried" then
        StaggerService.apply(runtime.model, defense.attacker_stagger_seconds)
        return
    end
    if defense.outcome == "Hit" then
        DamageService.apply_damage({
            attacker = nil,
            attacker_character = runtime.model,
            target = character,
            source_kind = if definition.RADIAL then "EnemyArea" else "EnemyMelee",
            source_id = attack_name,
            attack_id = attack_name,
            base_damage = definition.HEALTH_DAMAGE,
            multiplier = 1,
            sequence_id = runtime.attackSequence,
        })
    end
end

local function clear_attack(runtime: Runtime)
    runtime.attacking = false
    runtime.model:SetAttribute("AttackTelegraph", false)
    runtime.model:SetAttribute("AttackName", "")
    if runtime.humanoid.Health > 0 then
        runtime.model:SetAttribute("MarauderAIState", "Ready")
        PresentationService.reset_pose(runtime.model, 0.12)
    end
end

local function perform_attack(runtime: Runtime, target_player: Player, target_character: Model, target_root: BasePart)
    if runtime.attacking or runtime.humanoid.Health <= 0 or StaggerService.is_staggered(runtime.model) then return end
    local attack_name = ATTACK_ORDER[runtime.patternIndex]
    runtime.patternIndex = if runtime.patternIndex >= #ATTACK_ORDER then 1 else runtime.patternIndex + 1
    local definition = Factory.ATTACKS[attack_name]
    runtime.attacking = true
    runtime.attackSequence += 1
    local sequence = runtime.attackSequence
    runtime.nextAttackAt = os.clock() + definition.ATTACK_INTERVAL_SECONDS
    runtime.model:SetAttribute("MarauderAIState", "Attacking")
    runtime.model:SetAttribute("AttackName", attack_name)
    runtime.model:SetAttribute("AttackTelegraph", true)
    face(runtime, target_root)
    runtime.body.Material = Enum.Material.Neon
    runtime.body.Color = definition.TELEGRAPH_COLOR
    PresentationService.play_attack_windup(runtime.model, definition.PRESENTATION, definition.WIND_UP_SECONDS)
    task.wait(definition.WIND_UP_SECONDS)
    if runtime.attackSequence ~= sequence or runtime.humanoid.Health <= 0 or StaggerService.is_staggered(runtime.model) then
        clear_attack(runtime)
        return
    end

    PresentationService.play_attack_strike(runtime.model, definition.PRESENTATION, definition.ATTACK_LOCK_SECONDS)
    task.wait(definition.ATTACK_LOCK_SECONDS)
    if runtime.attackSequence ~= sequence or runtime.humanoid.Health <= 0 or StaggerService.is_staggered(runtime.model) then
        clear_attack(runtime)
        return
    end

    runtime.model:SetAttribute("AttackTelegraph", false)
    if definition.RADIAL == true then
        local encounter_id = tostring(runtime.model:GetAttribute("DungeonEncounterId") or "MarauderCaptain")
        for _, player in ipairs(Players:GetPlayers()) do
            local character = living_target(player, encounter_id)
            if character then resolve_hit(runtime, player, character, attack_name, definition) end
        end
    else
        local current_character = target_player.Character
        if current_character == target_character then
            resolve_hit(runtime, target_player, target_character, attack_name, definition)
        end
    end
    clear_attack(runtime)
end

local function attach(model: Instance)
    if not model:IsA("Model") or runtimes[model] then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    local body = model:FindFirstChild("Body")
    if not humanoid or not root or not root:IsA("BasePart") or not body or not body:IsA("BasePart") then return end
    local runtime: Runtime = {
        model = model,
        humanoid = humanoid,
        root = root,
        body = body,
        nextAttackAt = os.clock() + 0.7,
        patternIndex = 1,
        attacking = false,
        attackSequence = 0,
    }
    runtimes[model] = runtime
    humanoid.Died:Connect(function()
        runtime.attackSequence += 1
        runtime.attacking = false
        model:SetAttribute("AttackTelegraph", false)
        model:SetAttribute("AttackName", "")
        model:SetAttribute("MarauderAIState", "Dead")
    end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(attach)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
    if instance:IsA("Model") then runtimes[instance] = nil end
end)
for _, instance in ipairs(CollectionService:GetTagged(TAG)) do attach(instance) end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < THINK_INTERVAL then return end
    local step = accumulator
    accumulator = 0
    for model, runtime in pairs(runtimes) do
        if not model.Parent then
            runtimes[model] = nil
        elseif runtime.humanoid.Health <= 0 then
            model:SetAttribute("MarauderAIState", "Dead")
        elseif StaggerService.is_staggered(model) then
            if runtime.attacking then runtime.attackSequence += 1 end
            runtime.attacking = false
            model:SetAttribute("AttackTelegraph", false)
            model:SetAttribute("AttackName", "")
            model:SetAttribute("MarauderAIState", "Staggered")
        elseif not runtime.attacking then
            local player, character, target_root, distance = nearest_target(runtime)
            if not player or not character or not target_root then
                model:SetAttribute("MarauderAIState", "Idle")
                PresentationService.reset_pose(model, 0)
            elseif distance > STOP_RANGE then
                model:SetAttribute("MarauderAIState", "Chasing")
                local offset = Vector3.new(target_root.Position.X - runtime.root.Position.X, 0, target_root.Position.Z - runtime.root.Position.Z)
                local move = math.min(math.max(0, distance - STOP_RANGE), CHASE_SPEED * step)
                if offset.Magnitude > 0.01 and move > 0 then
                    local next_position = runtime.root.Position + offset.Unit * move
                    model:PivotTo(CFrame.lookAt(next_position, Vector3.new(target_root.Position.X, next_position.Y, target_root.Position.Z)))
                    PresentationService.set_chase_pose(model, os.clock())
                end
            else
                model:SetAttribute("MarauderAIState", "Ready")
                face(runtime, target_root)
                if os.clock() >= runtime.nextAttackAt then
                    task.spawn(perform_attack, runtime, player, character, target_root)
                end
            end
        end
    end
end)

print("[Marauder Captain] Controller ready.")
