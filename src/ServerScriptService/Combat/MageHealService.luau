--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SupportTargetRules = require(
    script.Parent:WaitForChild("SupportTargetRules")
)

local MageHealService = {}

type HotRecord = {
    serial: number,
    caster: Player,
}
local hot_records: {[Model]: HotRecord} = {}
local serial_counter = 0
local heal_callback: ((Player, Player, number) -> ())? = nil

local function get_character_parts(
    player: Player
): (Humanoid?, BasePart?)
    local character = player.Character
    if not character then
        return nil, nil
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild(
        "HumanoidRootPart"
    )

    if not humanoid
        or not root
        or not root:IsA("BasePart")
    then
        return humanoid, nil
    end

    return humanoid, root
end

local function line_of_sight(
    caster: Player,
    target: Player,
    origin: Vector3,
    target_position: Vector3
): boolean
    local caster_character = caster.Character
    local target_character = target.Character

    if not caster_character or not target_character then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        caster_character,
    }
    params.IgnoreWater = true

    local result = Workspace:Raycast(
        origin,
        target_position - origin,
        params
    )

    return result == nil
        or result.Instance:IsDescendantOf(
            target_character
        )
end

function MageHealService.set_heal_callback(
    callback: ((Player, Player, number) -> ())?
)
    heal_callback = callback
end

function MageHealService.find_target(
    caster: Player,
    range_studs: number
): Player?
    local caster_humanoid, caster_root =
        get_character_parts(caster)

    if not caster_humanoid
        or not caster_root
        or caster_humanoid.Health <= 0
    then
        return nil
    end

    local forward = Vector3.new(
        caster_root.CFrame.LookVector.X,
        0,
        caster_root.CFrame.LookVector.Z
    )

    if forward.Magnitude > 0.001 then
        forward = forward.Unit
    else
        forward = Vector3.new(0, 0, -1)
    end

    local origin =
        caster_root.Position
        + Vector3.new(0, 1.5, 0)
    local candidates = {}

    for _, candidate in Players:GetPlayers() do
        local humanoid, root =
            get_character_parts(candidate)

        if not humanoid
            or not root
            or humanoid.Health <= 0
        then
            continue
        end

        local is_self = candidate == caster
        local offset = root.Position - caster_root.Position
        local horizontal = Vector3.new(
            offset.X,
            0,
            offset.Z
        )
        local distance = if is_self
            then 0
            else horizontal.Magnitude
        local aim_dot = if is_self
            then 1
            elseif horizontal.Magnitude > 0.001
            then forward:Dot(horizontal.Unit)
            else 1

        table.insert(candidates, {
            key = candidate,
            is_self = is_self,
            distance = distance,
            health = humanoid.Health,
            max_health = humanoid.MaxHealth,
            aim_dot = aim_dot,
            line_of_sight = is_self
                or line_of_sight(
                    caster,
                    candidate,
                    origin,
                    root.Position
                        + Vector3.new(0, 1.2, 0)
                ),
        })
    end

    return SupportTargetRules.choose_aimed_or_self(
        candidates,
        range_studs,
        true,
        0.85
    )
end

function MageHealService.get_delivery(
    race_id: string?,
    total_heal: number,
    definition: any
): (number, number, number)
    local instant_fraction =
        definition.HUMAN_INSTANT_FRACTION
    local hot_seconds =
        definition.HUMAN_HOT_SECONDS

    if race_id == "Elf" then
        instant_fraction =
            definition.ELF_INSTANT_FRACTION
        hot_seconds =
            definition.ELF_HOT_SECONDS
    end

    instant_fraction = math.clamp(
        tonumber(instant_fraction) or 0,
        0,
        1
    )
    hot_seconds = math.max(
        0,
        tonumber(hot_seconds) or 0
    )

    local safe_total = math.max(
        0,
        total_heal
    )
    local instant =
        safe_total * instant_fraction

    return
        instant,
        math.max(0, safe_total - instant),
        hot_seconds
end

function MageHealService.apply_heal(
    caster: Player,
    target: Player,
    amount: number
): number
    local humanoid = get_character_parts(target)

    if not humanoid
        or humanoid.Health <= 0
        or amount <= 0
    then
        return 0
    end

    local before = humanoid.Health
    humanoid.Health = math.min(
        humanoid.MaxHealth,
        humanoid.Health + amount
    )
    local healed = math.max(
        0,
        humanoid.Health - before
    )

    if healed > 0 then
        local character = target.Character
        if character then
            character:SetAttribute(
                "MageHealLastAmount",
                healed
            )
            local pulse =
                character:GetAttribute(
                    "MageHealPulse"
                )
            character:SetAttribute(
                "MageHealPulse",
                if type(pulse) == "number"
                    then pulse + 1
                    else 1
            )
        end

        if heal_callback then
            heal_callback(caster, target, healed)
        end
    end

    return healed
end

local function cancel_hot(target: Player)
    local character = target.Character
    if character then
        hot_records[character] = nil
    end
end

function MageHealService.cast(
    caster: Player,
    target: Player,
    total_heal: number,
    race_id: string?,
    definition: any
): (boolean, number)
    local humanoid = get_character_parts(target)

    if not humanoid
        or humanoid.Health <= 0
        or humanoid.Health >= humanoid.MaxHealth
        or total_heal <= 0
    then
        return false, 0
    end

    local instant_amount,
        hot_amount,
        hot_seconds =
            MageHealService.get_delivery(
                race_id,
                total_heal,
                definition
            )

    cancel_hot(target)

    local effective_total =
        MageHealService.apply_heal(
            caster,
            target,
            instant_amount
        )

    if hot_amount <= 0 or hot_seconds <= 0 then
        return true, effective_total
    end

    serial_counter += 1
    local serial = serial_counter
    local character = target.Character

    if not character then
        return true, effective_total
    end

    hot_records[character] = {
        serial = serial,
        caster = caster,
    }

    local tick_seconds = math.max(
        0.1,
        tonumber(definition.HOT_TICK_SECONDS)
            or 1
    )
    local tick_count = math.max(
        1,
        math.ceil(hot_seconds / tick_seconds)
    )
    local per_tick = hot_amount / tick_count

    for tick_index = 1, tick_count do
        task.delay(
            math.min(
                hot_seconds,
                tick_index * tick_seconds
            ),
            function()
                local current =
                    hot_records[character]

                if not current
                    or current.serial ~= serial
                    or not character.Parent
                then
                    return
                end

                local healed =
                    MageHealService.apply_heal(
                        caster,
                        target,
                        per_tick
                    )

                if healed > 0 then
                    effective_total += healed
                end

                if tick_index >= tick_count then
                    local latest =
                        hot_records[character]

                    if latest
                        and latest.serial == serial
                    then
                        hot_records[character] = nil
                    end
                end
            end
        )
    end

    return true, effective_total
end

function MageHealService.cancel_player(
    player: Player
)
    cancel_hot(player)

    local owned_targets = {}

    for character, record in hot_records do
        local target =
            Players:GetPlayerFromCharacter(
                character
            )

        if target == player
            or record.caster == player
        then
            table.insert(
                owned_targets,
                character
            )
        end
    end

    for _, character in owned_targets do
        hot_records[character] = nil
    end
end

return table.freeze(MageHealService)
