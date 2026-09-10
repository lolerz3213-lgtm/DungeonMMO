--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)
local CombatTargetRules = require(
    script.Parent:WaitForChild("CombatTargetRules")
)
local DamageService = require(
    script.Parent:WaitForChild("DamageService")
)

local SpiritOrbService = {}

export type OrbContext = {
    attacker: Player,
    character: Model,
    attack_id: string,
    attack_definition: any,
    magical_multiplier: number,
    critical_chance: number?,
    critical_damage_multiplier: number?,
    sequence_id: number?,
}

local function resolve_target_model(
    part: BasePart?
): Model?
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

local function create_orb(
    position: Vector3,
    finisher: boolean
): Part
    local diameter = if finisher
        then CombatConfig.SPIRIT_ORB.FINISHER_DIAMETER
        else CombatConfig.SPIRIT_ORB.NORMAL_DIAMETER

    local orb = Instance.new("Part")
    orb.Name = if finisher
        then "SpiritOrbFinisher"
        else "SpiritOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(diameter, diameter, diameter)
    orb.Position = position
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.Material = Enum.Material.Neon
    orb.Color = if finisher
        then Color3.fromRGB(155, 205, 255)
        else Color3.fromRGB(115, 170, 255)
    orb.CastShadow = false

    local light = Instance.new("PointLight")
    light.Name = "SpiritOrbGlow"
    light.Brightness = if finisher then 2.4 else 1.5
    light.Range = if finisher then 10 else 7
    light.Color = orb.Color
    light.Parent = orb

    orb.Parent = Workspace
    return orb
end

local function apply_damage(
    context: OrbContext,
    target: Model,
    target_index: number
): number
    local applied = DamageService.apply_damage({
        attacker = context.attacker,
        attacker_character = context.character,
        target = target,
        source_kind = "MagicBasic",
        source_id = "SpiritOrb",
        attack_id = context.attack_id,
        base_damage =
            CombatConfig.SPIRIT_ORB.BASE_DAMAGE
            * context.magical_multiplier,
        multiplier =
            context.attack_definition.POWER_MULTIPLIER,
        sequence_id = context.sequence_id,
        critical_chance = context.critical_chance,
        critical_damage_multiplier =
            context.critical_damage_multiplier,
    })

    target:SetAttribute(
        "LastSpiritOrbTargetIndex",
        target_index
    )

    return applied
end

local function explode_finisher(
    context: OrbContext,
    position: Vector3
)
    local marker = Instance.new("Part")
    marker.Name = "SpiritOrbBurst"
    marker.Shape = Enum.PartType.Ball
    marker.Size = Vector3.new(
        CombatConfig.SPIRIT_ORB.FINISHER_AOE_RADIUS * 2,
        CombatConfig.SPIRIT_ORB.FINISHER_AOE_RADIUS * 2,
        CombatConfig.SPIRIT_ORB.FINISHER_AOE_RADIUS * 2
    )
    marker.Position = position
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(140, 195, 255)
    marker.Transparency = 0.72
    marker.CastShadow = false
    marker.Parent = Workspace
    Debris:AddItem(marker, 0.16)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        context.character,
        marker,
    }
    params.RespectCanCollide = false

    local seen: {[Model]: boolean} = {}
    local target_index = 0

    for _, part in Workspace:GetPartBoundsInRadius(
        position,
        CombatConfig.SPIRIT_ORB.FINISHER_AOE_RADIUS,
        params
    ) do
        local target = resolve_target_model(part)

        if not target or seen[target] then
            continue
        end

        seen[target] = true

        local legal = CombatTargetRules.is_damageable(
            context.character,
            target
        )

        if not legal then
            continue
        end

        target_index += 1
        apply_damage(context, target, target_index)
    end
end

function SpiritOrbService.fire(
    context: OrbContext
): boolean
    local root = context.character:FindFirstChild(
        "HumanoidRootPart"
    )

    if not root or not root:IsA("BasePart") then
        return false
    end

    local horizontal = Vector3.new(
        root.CFrame.LookVector.X,
        0,
        root.CFrame.LookVector.Z
    )

    if horizontal.Magnitude <= 0.001 then
        return false
    end

    local direction = horizontal.Unit
    local origin =
        root.Position
        + Vector3.new(0, 1.65, 0)
        + direction * 1.4

    local finisher =
        context.attack_id
            == CombatConfig.BASIC_ATTACK.ATTACK_ORDER[3]

    local orb = create_orb(origin, finisher)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        context.character,
        orb,
    }
    params.IgnoreWater = true

    local travelled = 0
    local alive = true
    local connection: RBXScriptConnection? = nil

    local function finish(position: Vector3, burst: boolean)
        if not alive then
            return
        end

        alive = false

        if connection then
            connection:Disconnect()
            connection = nil
        end

        if orb.Parent then
            orb.Position = position
            orb:Destroy()
        end

        if burst then
            explode_finisher(context, position)
        end
    end

    connection = RunService.Heartbeat:Connect(
        function(delta_time: number)
            if not orb.Parent
                or not context.character.Parent
            then
                finish(orb.Position, false)
                return
            end

            local remaining =
                CombatConfig.SPIRIT_ORB.MAX_RANGE_STUDS
                - travelled

            if remaining <= 0 then
                finish(orb.Position, finisher)
                return
            end

            local step = math.min(
                remaining,
                CombatConfig.SPIRIT_ORB.SPEED_STUDS_PER_SECOND
                    * math.max(delta_time, 0)
            )

            if step <= 0 then
                return
            end

            local start_position = orb.Position
            local delta = direction * step
            local result = Workspace:Raycast(
                start_position,
                delta,
                params
            )

            if result then
                local impact = result.Position

                if finisher then
                    finish(impact, true)
                    return
                end

                local target = resolve_target_model(
                    result.Instance
                )

                if target then
                    local legal =
                        CombatTargetRules.is_damageable(
                            context.character,
                            target
                        )

                    if legal then
                        apply_damage(context, target, 1)
                    end
                end

                finish(impact, false)
                return
            end

            orb.Position = start_position + delta
            travelled += step

            if travelled
                >= CombatConfig.SPIRIT_ORB.MAX_RANGE_STUDS
                    - 0.001
            then
                finish(orb.Position, finisher)
            end
        end
    )

    return true
end

return table.freeze(SpiritOrbService)
