--!strict
-- Server-authoritative swept physical projectile delivery for Ranger arrows.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatTargetRules = require(
    script.Parent:WaitForChild("CombatTargetRules")
)
local DamageService = require(
    script.Parent:WaitForChild("DamageService")
)

local RangerProjectileService = {}

export type ProjectileContext = {
    attacker: Player,
    character: Model,
    source_id: string,
    base_damage: number,
    damage_multiplier: number,
    speed: number,
    max_range: number,
    max_targets: number,
    retention: number,
    critical_chance: number?,
    critical_damage_multiplier: number?,
    sequence_id: number?,
    on_hit: ((Model, number, number) -> ())?,
}

--[[
Resolves a Humanoid-owning target Model from one raycast part.

Args:
    part (BasePart?): Raycast impact part.

Returns:
    Model?: Nearest Humanoid-owning ancestor, otherwise nil.
]]
local function resolve_target_model(part: BasePart?): Model?
    local current: Instance? = part

    while current and current ~= Workspace do
        if current:IsA("Model")
            and current:FindFirstChildOfClass("Humanoid")
        then
            return current
        end

        current = current.Parent
    end

    return nil
end

--[[
Creates a simple visible server-owned Ranger arrow.

Args:
    position (Vector3): Initial world position.
    direction (Vector3): Unit travel direction.

Returns:
    Part: Anchored non-colliding arrow marker.
]]
local function create_arrow(
    position: Vector3,
    direction: Vector3
): Part
    local arrow = Instance.new("Part")
    arrow.Name = "RangerArrow"
    arrow.Size = Vector3.new(0.12, 0.12, 2.2)
    arrow.Anchored = true
    arrow.CanCollide = false
    arrow.CanTouch = false
    arrow.CanQuery = false
    arrow.CastShadow = false
    arrow.Material = Enum.Material.Wood
    arrow.Color = Color3.fromRGB(126, 86, 51)
    arrow.CFrame = CFrame.lookAt(
        position,
        position + direction
    )
    arrow.Parent = Workspace
    Debris:AddItem(arrow, 3)
    return arrow
end

--[[
Applies one physical Ranger arrow hit through the shared damage service.

Args:
    context (ProjectileContext): Authoritative projectile definition.
    target (Model): Accepted NPC target.
    target_index (number): One-based penetration index.

Returns:
    number: Effective health damage applied.
]]
local function apply_target_damage(
    context: ProjectileContext,
    target: Model,
    target_index: number
): number
    local retention = math.clamp(context.retention, 0, 1)
    local penetration_multiplier = retention ^ math.max(0, target_index - 1)
    local applied = DamageService.apply_damage({
        attacker = context.attacker,
        attacker_character = context.character,
        target = target,
        source_kind = "RangedPhysical",
        source_id = context.source_id,
        attack_id = context.source_id,
        base_damage = context.base_damage,
        multiplier = context.damage_multiplier * penetration_multiplier,
        sequence_id = context.sequence_id,
        critical_chance = context.critical_chance,
        critical_damage_multiplier = context.critical_damage_multiplier,
    })

    if context.on_hit then
        context.on_hit(target, target_index, applied)
    end

    return applied
end

--[[
Fires one swept, server-authoritative physical Ranger arrow.

The server derives direction from the character's facing. Client-provided hit
results, damage, travel time and penetration order are never trusted.

Args:
    context (ProjectileContext): Authoritative projectile configuration.

Returns:
    boolean: True when a live projectile was created.
]]
function RangerProjectileService.fire(
    context: ProjectileContext
): boolean
    local root = context.character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return false
    end

    local forward = Vector3.new(
        root.CFrame.LookVector.X,
        0,
        root.CFrame.LookVector.Z
    )

    if forward.Magnitude <= 0.001 then
        return false
    end

    local direction = forward.Unit
    local origin = root.Position
        + Vector3.new(0, 1.6, 0)
        + direction * 1.8
    local arrow = create_arrow(origin, direction)
    local exclusions: {Instance} = {
        context.character,
        arrow,
    }
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclusions
    params.IgnoreWater = true

    local max_range = math.max(1, tonumber(context.max_range) or 1)
    local speed = math.max(1, tonumber(context.speed) or 1)
    local max_targets = math.max(
        1,
        math.floor(tonumber(context.max_targets) or 1)
    )
    local travelled = 0
    local target_index = 0
    local alive = true
    local connection: RBXScriptConnection? = nil

    local function finish(position: Vector3)
        if not alive then
            return
        end

        alive = false

        if connection then
            connection:Disconnect()
            connection = nil
        end

        if arrow.Parent then
            arrow.CFrame = CFrame.lookAt(
                position,
                position + direction
            )
            arrow:Destroy()
        end
    end

    connection = RunService.Heartbeat:Connect(
        function(delta_time: number)
            if not arrow.Parent or not context.character.Parent then
                finish(arrow.Position)
                return
            end

            local remaining = max_range - travelled

            if remaining <= 0 then
                finish(arrow.Position)
                return
            end

            local step = math.min(
                remaining,
                speed * math.max(delta_time, 0)
            )

            if step <= 0 then
                return
            end

            local start_position = arrow.Position
            local delta = direction * step
            local result = Workspace:Raycast(
                start_position,
                delta,
                params
            )

            if result then
                local target = resolve_target_model(result.Instance)
                local legal = false

                if target then
                    legal = CombatTargetRules.is_damageable(
                        context.character,
                        target
                    )
                end

                if target and legal then
                    target_index += 1
                    apply_target_damage(
                        context,
                        target,
                        target_index
                    )

                    if target_index >= max_targets then
                        finish(result.Position)
                        return
                    end

                    table.insert(exclusions, target)
                    params.FilterDescendantsInstances = exclusions
                    arrow.CFrame = CFrame.lookAt(
                        result.Position + direction * 0.05,
                        result.Position + direction
                    )
                    travelled += result.Distance + 0.05
                    return
                end

                finish(result.Position)
                return
            end

            travelled += step
            local position = start_position + delta
            arrow.CFrame = CFrame.lookAt(
                position,
                position + direction
            )

            if travelled >= max_range - 0.001 then
                finish(position)
            end
        end
    )

    return true
end

return table.freeze(RangerProjectileService)
