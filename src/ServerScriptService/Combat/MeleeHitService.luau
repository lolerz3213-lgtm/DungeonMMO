local CollectionService = game:GetService(
    "CollectionService"
)
local Players = game:GetService("Players")
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
local CombatTargetRules = require(
    script.Parent:WaitForChild(
        "CombatTargetRules"
    )
)
local DamageService = require(
    script.Parent:WaitForChild(
        "DamageService"
    )
)

local MeleeHitService = {}

export type MeleeSwingContext = {
    attacker: Player?,
    character: Model,
    attack_id: string,
    attack_definition: any,
    base_damage: number,
}


--[[
Finds the Humanoid-owning Model for one overlapped Part.

Args:
    part (BasePart): Part returned by the overlap query.

Returns:
    Model?: Nearest ancestor Model containing a Humanoid.
]]
local function resolve_target_model(
    part: BasePart
): Model?
    local current: Instance? = part

    while current
        and current ~= Workspace do
        if current:IsA("Model")
            and current:FindFirstChildOfClass(
                "Humanoid"
            ) then
            return current
        end

        current = current.Parent
    end

    return nil
end


--[[
Returns the target position used for melee range and obstruction tests.

Args:
    target_model (Model): Candidate combat target.

Returns:
    Vector3?: Target root or PrimaryPart position.
]]
local function get_target_position(
    target_model: Model
): Vector3?
    local root = target_model:FindFirstChild(
        "HumanoidRootPart"
    )

    if root and root:IsA("BasePart") then
        return root.Position
    end

    if target_model.PrimaryPart then
        return target_model.PrimaryPart.Position
    end

    return nil
end


--[[
Checks whether a target lies inside configured planar reach and arc.

Args:
    root (BasePart): Attacker HumanoidRootPart.
    target_position (Vector3): Candidate target position.
    attack_definition (table): Configured melee attack definition.

Returns:
    boolean: True when the target is inside reach and arc.
]]
local function is_inside_attack_arc(
    root: BasePart,
    target_position: Vector3,
    attack_definition: any
): boolean
    local attacker_position = root.Position

    local offset = Vector3.new(
        target_position.X - attacker_position.X,
        0,
        target_position.Z - attacker_position.Z
    )

    local distance = offset.Magnitude

    if distance <= 1e-6 then
        return true
    end

    if distance > attack_definition.REACH_STUDS then
        return false
    end

    local look = root.CFrame.LookVector
    local forward = Vector3.new(
        look.X,
        0,
        look.Z
    )

    if forward.Magnitude <= 1e-6 then
        return false
    end

    forward = forward.Unit

    local direction = offset.Unit
    local dot = math.clamp(
        forward:Dot(direction),
        -1,
        1
    )

    local angle = math.deg(
        math.acos(dot)
    )
    local half_arc =
        attack_definition.ARC_DEGREES / 2

    return angle <= half_arc
end


--[[
Builds the overlap query that excludes the attacker character.

Args:
    character (Model): Character performing the melee swing.

Returns:
    OverlapParams: Query parameters for the broad-phase box.
]]
local function create_overlap_params(
    character: Model
): OverlapParams
    local params = OverlapParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        character,
    }
    params.RespectCanCollide = false

    return params
end


--[[
Builds an obstruction ray that ignores all combat characters.

Characters are not treated as dungeon walls. The ray therefore ignores
the attacker, tagged NPC targets, and current player characters.

Args:
    attacker_character (Model): Attacker Model.

Returns:
    RaycastParams: Parameters for geometry obstruction checks.
]]
local function create_obstruction_params(
    attacker_character: Model
): RaycastParams
    local excluded: {Instance} = {
        attacker_character,
    }

    for _, tagged in CollectionService:GetTagged(
        CombatConfig.TARGETS.NPC_TAG
    ) do
        table.insert(
            excluded,
            tagged
        )
    end

    for _, player in Players:GetPlayers() do
        if player.Character then
            table.insert(
                excluded,
                player.Character
            )
        end
    end

    local params = RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances =
        excluded
    params.RespectCanCollide = true

    return params
end


--[[
Returns whether solid level geometry blocks attacker-to-target line.

Args:
    attacker_root (BasePart): Attacker HumanoidRootPart.
    target_position (Vector3): Candidate target position.
    attacker_character (Model): Character performing the attack.

Returns:
    boolean: True when solid queryable geometry blocks the melee hit.
]]
local function is_obstructed(
    attacker_root: BasePart,
    target_position: Vector3,
    attacker_character: Model
): boolean
    local origin = attacker_root.Position
    local direction =
        target_position - origin

    if direction.Magnitude <= 1e-6 then
        return false
    end

    local result = Workspace:Raycast(
        origin,
        direction,
        create_obstruction_params(
            attacker_character
        )
    )

    return result ~= nil
end


--[[
Collects newly accepted targets for one server melee sample.

This function performs target acquisition only. The supplied
`already_hit` table is shared across all samples in one swing so each
target can be accepted only once.

Args:
    context (MeleeSwingContext): Authoritative melee swing information.
    already_hit ({[Model]: boolean}): Per-swing target deduplication.

Returns:
    {Model}: Newly accepted NPC targets for this sample.
]]
function MeleeHitService.collect_targets(
    context: MeleeSwingContext,
    already_hit: {[Model]: boolean}
): {Model}
    local character = context.character
    local root = character:FindFirstChild(
        "HumanoidRootPart"
    )

    if not root or not root:IsA("BasePart") then
        return {}
    end

    local attack_definition =
        context.attack_definition
    local hitbox = attack_definition.HITBOX

    if not hitbox then
        return {}
    end

    local hitbox_cframe =
        root.CFrame
        * CFrame.new(
            0,
            0,
            -hitbox.FORWARD_OFFSET
        )

    local parts = Workspace:GetPartBoundsInBox(
        hitbox_cframe,
        hitbox.SIZE,
        create_overlap_params(character)
    )

    local targets: {Model} = {}
    local candidates_seen: {[Model]: boolean} = {}

    for _, part in parts do
        local target_model =
            resolve_target_model(part)

        if not target_model
            or candidates_seen[target_model]
            or already_hit[target_model] then
            continue
        end

        candidates_seen[target_model] = true

        local valid =
            CombatTargetRules.is_damageable(
                character,
                target_model
            )

        if not valid then
            continue
        end

        local target_position =
            get_target_position(target_model)

        if not target_position then
            continue
        end

        if not is_inside_attack_arc(
            root,
            target_position,
            attack_definition
        ) then
            continue
        end

        if is_obstructed(
            root,
            target_position,
            character
        ) then
            continue
        end

        already_hit[target_model] = true

        table.insert(
            targets,
            target_model
        )
    end

    return targets
end


--[[
Applies damage to every newly accepted target from one sample.

Args:
    context (MeleeSwingContext): Authoritative melee swing information.
    already_hit ({[Model]: boolean}): Shared per-swing deduplication.

Returns:
    None.
]]
local function process_sample(
    context: MeleeSwingContext,
    already_hit: {[Model]: boolean}
)
    local targets =
        MeleeHitService.collect_targets(
            context,
            already_hit
        )

    for _, target in targets do
        DamageService.apply_damage({
            attacker = context.attacker,
            attacker_character =
                context.character,
            target = target,
            source_kind = "Melee",
            source_id =
                CombatConfig.PROTOTYPE_WEAPON
                    .TOOL_NAME,
            attack_id = context.attack_id,
            base_damage = context.base_damage,
            multiplier =
                context.attack_definition
                    .POWER_MULTIPLIER,
        })
    end
end


--[[
Runs repeated server melee samples across one Active attack window.

The first sample is processed immediately. Remaining samples are
scheduled strictly inside the Active duration. All samples share one
deduplication table, so an NPC can be damaged only once per swing while
multiple different NPCs can still be cleaved.

Args:
    context (MeleeSwingContext): Authoritative melee swing information.

Returns:
    None.
]]
function MeleeHitService.begin_active_window(
    context: MeleeSwingContext
)
    local attack_definition =
        context.attack_definition
    local hitbox = attack_definition.HITBOX

    if not hitbox then
        return
    end

    local sample_count = math.max(
        1,
        math.floor(hitbox.SAMPLE_COUNT or 1)
    )
    local active_seconds = math.max(
        0,
        attack_definition.ACTIVE_SECONDS or 0
    )
    local already_hit: {[Model]: boolean} = {}

    process_sample(
        context,
        already_hit
    )

    if sample_count <= 1 then
        return
    end

    local sample_interval =
        active_seconds / sample_count

    for sample_index = 2, sample_count do
        local delay_seconds =
            (sample_index - 1)
            * sample_interval

        task.delay(
            delay_seconds,
            function()
                process_sample(
                    context,
                    already_hit
                )
            end
        )
    end
end


return table.freeze(MeleeHitService)
