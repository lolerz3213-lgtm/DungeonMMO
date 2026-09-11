--!strict
-- Server-authoritative Ranger Volley ground validation and pulse damage.

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local CombatTargetRules = require(
    script.Parent:WaitForChild("CombatTargetRules")
)
local DamageService = require(
    script.Parent:WaitForChild("DamageService")
)

local RangerVolleyService = {}

export type VolleyContext = {
    attacker: Player,
    character: Model,
    skill_definition: any,
    ranged_multiplier: number,
    sequence_id: number?,
    on_hit: ((Model, number, number) -> ())?,
}

--[[
Returns whether a Vector3 contains only finite components.

Args:
    value (any): Candidate aim intent.

Returns:
    boolean: True only for a finite Vector3.
]]
local function finite_vector3(value: any): boolean
    if typeof(value) ~= "Vector3" then
        return false
    end

    for _, component in ipairs({value.X, value.Y, value.Z}) do
        if component ~= component
            or component <= -math.huge
            or component >= math.huge
        then
            return false
        end
    end

    return true
end

--[[
Resolves the Humanoid-owning Model for one overlap part.

Args:
    part (BasePart): Part returned by an overlap query.

Returns:
    Model?: Nearest Humanoid-owning ancestor, otherwise nil.
]]
local function resolve_target_model(part: BasePart): Model?
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
Creates the functional Volley ground marker for the pulse lifetime.

Args:
    center (Vector3): Validated ground centre.
    radius (number): Volley radius in studs.
    lifetime (number): Marker lifetime in seconds.

Returns:
    Part: Non-querying marker disc.
]]
local function create_marker(
    center: Vector3,
    radius: number,
    lifetime: number
): Part
    local marker = Instance.new("Part")
    marker.Name = "RangerVolleyMarker"
    marker.Shape = Enum.PartType.Cylinder
    marker.Size = Vector3.new(0.12, radius * 2, radius * 2)
    marker.CFrame = CFrame.new(center + Vector3.new(0, 0.06, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(151, 205, 117)
    marker.Transparency = 0.68
    marker.Parent = Workspace
    Debris:AddItem(marker, lifetime)
    return marker
end

--[[
Creates a few short-lived downward arrow streaks for one Volley pulse.

Args:
    center (Vector3): Volley centre.
    radius (number): Volley radius.

Returns:
    None.
]]
local function create_pulse_visual(center: Vector3, radius: number)
    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(radius * 0.45, 0, radius * 0.25),
        Vector3.new(-radius * 0.35, 0, radius * 0.42),
        Vector3.new(radius * 0.20, 0, -radius * 0.50),
        Vector3.new(-radius * 0.48, 0, -radius * 0.18),
    }

    for _, offset in ipairs(offsets) do
        local streak = Instance.new("Part")
        streak.Name = "RangerVolleyArrow"
        streak.Size = Vector3.new(0.10, 4.5, 0.10)
        streak.Position = center + offset + Vector3.new(0, 3.0, 0)
        streak.Anchored = true
        streak.CanCollide = false
        streak.CanTouch = false
        streak.CanQuery = false
        streak.Material = Enum.Material.Wood
        streak.Color = Color3.fromRGB(126, 86, 51)
        streak.Parent = Workspace
        Debris:AddItem(streak, 0.16)
    end
end

--[[
Validates and clamps client Volley aim intent onto server-observed ground.

Args:
    character (Model): Authoritative casting character.
    aim_intent (any): Client-provided world aim intent only.
    max_range (number): Maximum planar targeting range.

Returns:
    Vector3?: Validated ground position, otherwise nil.
]]
function RangerVolleyService.resolve_ground(
    character: Model,
    aim_intent: any,
    max_range: number
): Vector3?
    if not finite_vector3(aim_intent) then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return nil
    end

    local horizontal = Vector3.new(
        aim_intent.X - root.Position.X,
        0,
        aim_intent.Z - root.Position.Z
    )
    local allowed_range = math.max(1, tonumber(max_range) or 1)

    if horizontal.Magnitude > allowed_range then
        horizontal = horizontal.Unit * allowed_range
    end

    local planar_target = Vector3.new(
        root.Position.X + horizontal.X,
        root.Position.Y,
        root.Position.Z + horizontal.Z
    )
    local ray_origin = planar_target + Vector3.new(0, 60, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = false

    local result = Workspace:Raycast(
        ray_origin,
        Vector3.new(0, -140, 0),
        params
    )

    return if result then result.Position else nil
end

--[[
Applies one server-owned Volley damage pulse to current area occupants.

Args:
    context (VolleyContext): Authoritative cast context.
    center (Vector3): Validated ground centre.
    pulse_index (number): One-based pulse number.
    base_damage (number): Base damage for this pulse.

Returns:
    number: Number of legal NPC targets damaged by this pulse.
]]
local function apply_pulse(
    context: VolleyContext,
    center: Vector3,
    pulse_index: number,
    base_damage: number
): number
    local radius = context.skill_definition.RADIUS_STUDS
    create_pulse_visual(center, radius)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {context.character}
    params.RespectCanCollide = false

    local seen: {[Model]: boolean} = {}
    local hit_count = 0

    for _, part in Workspace:GetPartBoundsInRadius(
        center,
        radius,
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

        hit_count += 1
        local applied = DamageService.apply_damage({
            attacker = context.attacker,
            attacker_character = context.character,
            target = target,
            source_kind = "RangerArea",
            source_id = "Volley",
            attack_id = "Volley",
            base_damage = base_damage,
            multiplier = context.ranged_multiplier,
            sequence_id = context.sequence_id,
        })

        if context.on_hit then
            context.on_hit(target, pulse_index, applied)
        end
    end

    return hit_count
end

--[[
Starts one server-authoritative Volley at an already validated ground centre.

Args:
    context (VolleyContext): Authoritative cast context.
    center (Vector3): Validated ground centre.

Returns:
    boolean: True when Volley scheduling started.
]]
function RangerVolleyService.cast(
    context: VolleyContext,
    center: Vector3
): boolean
    local definition = context.skill_definition
    local pulse_count = math.max(
        1,
        math.floor(tonumber(definition.PULSE_COUNT) or 1)
    )
    local interval = math.max(
        0.05,
        tonumber(definition.PULSE_INTERVAL_SECONDS) or 0.5
    )
    local lifetime = (pulse_count - 1) * interval + 0.3

    create_marker(center, definition.RADIUS_STUDS, lifetime)

    for pulse_index = 1, pulse_count do
        local delay_seconds = (pulse_index - 1) * interval

        task.delay(delay_seconds, function()
            if not context.character.Parent then
                return
            end

            local damage = if pulse_index == 1
                then definition.INITIAL_DAMAGE
                else definition.PULSE_DAMAGE

            apply_pulse(
                context,
                center,
                pulse_index,
                damage
            )
        end)
    end

    return true
end

return table.freeze(RangerVolleyService)
