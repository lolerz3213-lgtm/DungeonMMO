local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local StaminaService = require(
    script.Parent:WaitForChild("StaminaService")
)

local DefenseConfig = CombatConfig.DEFENSE
local StaminaConfig = CombatConfig.STAMINA

local DefenseService = {}

export type DefenseContext = {
    attacker: Model?,
    target_player: Player,
    target_character: Model,
    source_kind: string,
    source_id: string,
    attack_position: Vector3?,
    stamina_damage: number,
    blockable: boolean,
    parryable: boolean,
}

export type DefenseResult = {
    outcome: string,
    stamina_spent: number,
    attacker_stagger_seconds: number,
}

type TimedDefenseRecord = {
    character: Model,
    started_at: number,
}

type BlockDefenseRecord = {
    character: Model,
    started_at: number,
    parry_available: boolean,
}

local block_records: {[Instance]: BlockDefenseRecord} = {}
local dodge_records: {[Instance]: TimedDefenseRecord} = {}
local guard_break_event = Instance.new("BindableEvent")


--[[
Checks whether an incoming source is inside the defender's block cone.

Args:
    character (Model): Defending character.
    attack_position (Vector3): World position of the incoming attack source.

Returns:
    boolean: True when the source lies inside the frontal block arc.
]]
local function is_inside_block_cone(
    character: Model,
    attack_position: Vector3
): boolean
    local root = character:FindFirstChild(
        "HumanoidRootPart"
    )

    if not root or not root:IsA("BasePart") then
        return false
    end

    local forward = Vector3.new(
        root.CFrame.LookVector.X,
        0,
        root.CFrame.LookVector.Z
    )
    local offset = Vector3.new(
        attack_position.X - root.Position.X,
        0,
        attack_position.Z - root.Position.Z
    )

    if forward.Magnitude <= 1e-6
        or offset.Magnitude <= 1e-6 then
        return false
    end

    local dot = math.clamp(
        forward.Unit:Dot(offset.Unit),
        -1,
        1
    )
    local angle = math.deg(math.acos(dot))

    return angle <= DefenseConfig.BLOCK_ARC_DEGREES / 2
end


--[[
Marks the start of an authoritative block.

Args:
    player (Player): Defending player.
    character (Model): Current defending character.
    started_at (number): Server block-start timestamp.

Returns:
    None.
]]
function DefenseService.begin_block(
    player: Player,
    character: Model,
    started_at: number
)
    block_records[player] = {
        character = character,
        started_at = started_at,
        parry_available = true,
    }
end


--[[
Ends an authoritative block record.

Args:
    player (Player): Defending player.

Returns:
    None.
]]
function DefenseService.end_block(player: Player)
    block_records[player] = nil
end


--[[
Marks the start of an authoritative dodge.

Args:
    player (Player): Dodging player.
    character (Model): Current dodging character.
    started_at (number): Server dodge-start timestamp.

Returns:
    None.
]]
function DefenseService.begin_dodge(
    player: Player,
    character: Model,
    started_at: number
)
    dodge_records[player] = {
        character = character,
        started_at = started_at,
    }
end


--[[
Ends an authoritative dodge record.

Args:
    player (Player): Dodging player.

Returns:
    None.
]]
function DefenseService.end_dodge(player: Player)
    dodge_records[player] = nil
end


--[[
Clears all defensive timing records for a player.

Args:
    player (Player): Player whose defense records are removed.

Returns:
    None.
]]
function DefenseService.clear(player: Player)
    block_records[player] = nil
    dodge_records[player] = nil
end


--[[
Connects a listener for authoritative Guard Break events.

Args:
    callback ((Player) -> ()): Listener invoked for the broken defender.

Returns:
    RBXScriptConnection: Connection owned by the caller.
]]
function DefenseService.on_guard_break(
    callback: (Player) -> ()
): RBXScriptConnection
    return guard_break_event.Event:Connect(callback)
end


--[[
Resolves one incoming attack against authoritative defensive timing.

Args:
    context (DefenseContext): Incoming attack and defender information.
    now (number?): Optional deterministic server-time override for tests.

Returns:
    DefenseResult: Exactly one defensive outcome and its consequences.
]]
function DefenseService.resolve(
    context: DefenseContext,
    now: number?
): DefenseResult
    local resolved_now = now or os.clock()
    local player = context.target_player

    local dodge = dodge_records[player]

    if dodge
        and dodge.character == context.target_character
        and resolved_now >= dodge.started_at
        and resolved_now - dodge.started_at
            <= DefenseConfig.DODGE_IFRAME_SECONDS then
        return {
            outcome = "Dodged",
            stamina_spent = 0,
            attacker_stagger_seconds = 0,
        }
    end

    local block = block_records[player]

    if not block
        or block.character ~= context.target_character
        or not context.blockable
        or not context.attack_position
        or not is_inside_block_cone(
            context.target_character,
            context.attack_position
        ) then
        return {
            outcome = "Hit",
            stamina_spent = 0,
            attacker_stagger_seconds = 0,
        }
    end

    local block_elapsed = resolved_now - block.started_at

    if context.parryable
        and block.parry_available
        and block_elapsed >= 0
        and block_elapsed
            <= DefenseConfig.PARRY_WINDOW_SECONDS then
        block.parry_available = false

        player:SetAttribute(
            "CombatParryPulse",
            os.clock()
        )

        return {
            outcome = "Parried",
            stamina_spent = 0,
            attacker_stagger_seconds =
                DefenseConfig.PARRY_ATTACKER_STAGGER_SECONDS,
        }
    end

    local current_stamina = StaminaService.get(player)
    local regen_delay = StaminaConfig.REGEN_DELAY_SECONDS

    if context.stamina_damage >= current_stamina then
        regen_delay =
            StaminaConfig.GUARD_BREAK_REGEN_DELAY_SECONDS
    end

    local spent, exhausted = StaminaService.apply_loss(
        player,
        context.stamina_damage,
        regen_delay
    )

    if exhausted then
        DefenseService.end_block(player)
        guard_break_event:Fire(player)

        return {
            outcome = "GuardBroken",
            stamina_spent = spent,
            attacker_stagger_seconds = 0,
        }
    end

    return {
        outcome = "Blocked",
        stamina_spent = spent,
        attacker_stagger_seconds = 0,
    }
end


return table.freeze(DefenseService)
