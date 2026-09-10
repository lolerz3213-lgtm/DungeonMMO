--!strict
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatTargetRules = require(
    script.Parent:WaitForChild("CombatTargetRules")
)
local DamageService = require(
    script.Parent:WaitForChild("DamageService")
)

local WindStrikeService = {}

export type WindStrikeContext = {
    attacker: Player,
    character: Model,
    skill_definition: any,
    magical_multiplier: number,
    critical_chance: number?,
    critical_damage_multiplier: number?,
    sequence_id: number?,
}

local function resolve_target_model(part: BasePart?): Model?
    local current: Instance? = part
    while current and current ~= Workspace do
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function create_projectile(position: Vector3): Part
    local projectile = Instance.new("Part")
    projectile.Name = "WindStrikeProjectile"
    projectile.Shape = Enum.PartType.Ball
    projectile.Size = Vector3.new(1.45, 1.45, 1.45)
    projectile.Position = position
    projectile.Anchored = true
    projectile.CanCollide = false
    projectile.CanTouch = false
    projectile.CanQuery = false
    projectile.Material = Enum.Material.Neon
    projectile.Color = Color3.fromRGB(185, 235, 255)
    projectile.CastShadow = false

    local light = Instance.new("PointLight")
    light.Name = "WindStrikeGlow"
    light.Brightness = 2.2
    light.Range = 9
    light.Color = projectile.Color
    light.Parent = projectile

    projectile.Parent = Workspace
    Debris:AddItem(projectile, 3)
    return projectile
end

function WindStrikeService.fire(context: WindStrikeContext): boolean
    local root = context.character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return false
    end

    local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if forward.Magnitude <= 0.001 then
        return false
    end

    local direction = forward.Unit
    local origin = root.Position + Vector3.new(0, 1.7, 0) + direction * 1.5
    local projectile = create_projectile(origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {context.character, projectile}
    params.IgnoreWater = true

    local travelled = 0
    local alive = true
    local connection: RBXScriptConnection? = nil

    local function finish(position: Vector3)
        if not alive then return end
        alive = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if projectile.Parent then
            projectile.Position = position
            projectile:Destroy()
        end
    end

    connection = RunService.Heartbeat:Connect(function(dt: number)
        if not projectile.Parent or not context.character.Parent then
            finish(projectile.Position)
            return
        end

        local remaining = context.skill_definition.RANGE_STUDS - travelled
        if remaining <= 0 then
            finish(projectile.Position)
            return
        end

        local step = math.min(
            remaining,
            context.skill_definition.PROJECTILE_SPEED * math.max(dt, 0)
        )
        if step <= 0 then return end

        local start_position = projectile.Position
        local delta = direction * step
        local result = Workspace:Raycast(start_position, delta, params)
        if result then
            local target = resolve_target_model(result.Instance)
            if target and CombatTargetRules.is_damageable(context.character, target) then
                DamageService.apply_damage({
                    attacker = context.attacker,
                    attacker_character = context.character,
                    target = target,
                    source_kind = "MagicSkill",
                    source_id = "WindStrike",
                    attack_id = "WindStrike",
                    base_damage = context.skill_definition.BASE_DAMAGE
                        * context.magical_multiplier,
                    multiplier = 1,
                    sequence_id = context.sequence_id,
                    critical_chance = context.critical_chance,
                    critical_damage_multiplier = context.critical_damage_multiplier,
                })
                target:SetAttribute("LastWindStrikeSequence", context.sequence_id or 0)
                finish(result.Position)
                return
            end

            finish(result.Position)
            return
        end

        travelled += step
        projectile.Position = start_position + delta
    end)

    return true
end

return table.freeze(WindStrikeService)
