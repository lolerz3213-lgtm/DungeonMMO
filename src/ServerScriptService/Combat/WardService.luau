--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SupportTargetRules = require(
    script.Parent:WaitForChild("SupportTargetRules")
)

local WardService = {}

type WardRecord = {
    caster: Player,
    remaining: number,
    maximum: number,
    expires_at: number,
    serial: number,
}

local records: {[Model]: WardRecord} = {}
local serial_counter = 0
local absorb_callback:
    ((Player, Player, number) -> ())? = nil

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

    if not root or not root:IsA("BasePart") then
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

local function replicate(
    character: Model,
    record: WardRecord?
)
    if record then
        character:SetAttribute(
            "ArcaneWardActive",
            true
        )
        character:SetAttribute(
            "ArcaneWardCurrent",
            record.remaining
        )
        character:SetAttribute(
            "ArcaneWardMax",
            record.maximum
        )
        character:SetAttribute(
            "ArcaneWardSourceUserId",
            record.caster.UserId
        )
        return
    end

    character:SetAttribute(
        "ArcaneWardActive",
        false
    )
    character:SetAttribute(
        "ArcaneWardCurrent",
        0
    )
    character:SetAttribute(
        "ArcaneWardMax",
        0
    )
    character:SetAttribute(
        "ArcaneWardSourceUserId",
        0
    )
end

local function clear_character(
    character: Model
)
    records[character] = nil

    if character.Parent then
        replicate(character, nil)
    end
end

function WardService.set_absorb_callback(
    callback:
        ((Player, Player, number) -> ())?
)
    absorb_callback = callback
end

function WardService.find_target(
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
        false,
        0.85
    )
end

function WardService.apply_ward(
    caster: Player,
    target: Player,
    amount: number,
    duration: number
): boolean
    local humanoid = get_character_parts(target)
    local character = target.Character

    if not character
        or not humanoid
        or humanoid.Health <= 0
        or amount <= 0
        or duration <= 0
    then
        return false
    end

    serial_counter += 1

    local record: WardRecord = {
        caster = caster,
        remaining = amount,
        maximum = amount,
        expires_at = os.clock() + duration,
        serial = serial_counter,
    }

    -- Same Ward family does not stack. Recast replaces the old
    -- shield with a newly calculated full Ward and refreshes duration.
    records[character] = record
    replicate(character, record)

    local expected_serial = record.serial

    task.delay(duration, function()
        local current = records[character]

        if current
            and current.serial == expected_serial
        then
            clear_character(character)
        end
    end)

    return true
end

function WardService.calculate_absorption(
    remaining: number,
    damage: number
): (number, number, number)
    local safe_remaining = math.max(
        0,
        remaining
    )
    local requested = math.max(
        0,
        damage
    )
    local absorbed = math.min(
        requested,
        safe_remaining
    )

    return
        safe_remaining - absorbed,
        requested - absorbed,
        absorbed
end

function WardService.absorb_damage(
    target: Model,
    damage: number
): (number, number)
    local requested = math.max(0, damage)
    local record = records[target]

    if not record then
        return requested, 0
    end

    if os.clock() >= record.expires_at
        or record.remaining <= 0
    then
        clear_character(target)
        return requested, 0
    end

    local next_remaining,
        health_damage,
        absorbed =
            WardService.calculate_absorption(
                record.remaining,
                requested
            )

    record.remaining = next_remaining

    local target_player =
        Players:GetPlayerFromCharacter(target)

    if record.remaining <= 0 then
        clear_character(target)
    else
        replicate(target, record)
    end

    if absorbed > 0
        and target_player
        and absorb_callback
    then
        absorb_callback(
            record.caster,
            target_player,
            absorbed
        )
    end

    return health_damage, absorbed
end

function WardService.get_remaining(
    target: Model
): number
    local record = records[target]

    if not record
        or os.clock() >= record.expires_at
    then
        return 0
    end

    return record.remaining
end

function WardService.cancel_player(
    player: Player
)
    local character = player.Character
    if character then
        clear_character(character)
    end

    local owned = {}

    for target, record in records do
        if record.caster == player then
            table.insert(owned, target)
        end
    end

    for _, target in owned do
        clear_character(target)
    end
end

return table.freeze(WardService)
