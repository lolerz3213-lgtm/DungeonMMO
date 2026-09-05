local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local StaminaConfig = CombatConfig.STAMINA

local StaminaService = {}

type StaminaRecord = {
    current: number,
    last_spend_at: number,
    regen_delay_seconds: number,
    regen_paused: boolean,
}

local records: {[Instance]: StaminaRecord} = {}


--[[
Replicates one authoritative Stamina record as read-only attributes.

Args:
    subject (Instance): Player-like instance receiving replicated attributes.
    record (StaminaRecord): Authoritative Stamina record.

Returns:
    None.
]]
local function replicate(
    subject: Instance,
    record: StaminaRecord
)
    subject:SetAttribute(
        "CombatStamina",
        record.current
    )
    subject:SetAttribute(
        "CombatMaxStamina",
        StaminaConfig.MAX
    )
end


--[[
Creates a fresh Stamina record.

Args:
    subject (Instance): Player-like instance owning Stamina.

Returns:
    None.
]]
function StaminaService.initialize_player(
    subject: Instance
)
    local record: StaminaRecord = {
        current = StaminaConfig.MAX,
        last_spend_at = -math.huge,
        regen_delay_seconds =
            StaminaConfig.REGEN_DELAY_SECONDS,
        regen_paused = false,
    }

    records[subject] = record
    replicate(subject, record)
end


--[[
Resets an existing subject to full Stamina.

Args:
    subject (Instance): Player-like instance whose Stamina resets.

Returns:
    None.
]]
function StaminaService.reset_player(
    subject: Instance
)
    StaminaService.initialize_player(subject)
end


--[[
Removes all authoritative Stamina state for a subject.

Args:
    subject (Instance): Player-like instance leaving combat ownership.

Returns:
    None.
]]
function StaminaService.remove_player(
    subject: Instance
)
    records[subject] = nil
end


--[[
Returns current authoritative Stamina.

Args:
    subject (Instance): Player-like Stamina owner.

Returns:
    number: Current Stamina, or zero when no record exists.
]]
function StaminaService.get(
    subject: Instance
): number
    local record = records[subject]

    if not record then
        return 0
    end

    return record.current
end


--[[
Attempts to spend Stamina atomically.

Args:
    subject (Instance): Player-like Stamina owner.
    amount (number): Requested non-negative Stamina spend.
    regen_delay_seconds (number?): Optional recovery delay override.

Returns:
    boolean: True only when the full spend was applied.
]]
function StaminaService.try_spend(
    subject: Instance,
    amount: number,
    regen_delay_seconds: number?
): boolean
    local record = records[subject]

    if not record then
        return false
    end

    local requested = math.max(0, amount)

    if record.current < requested then
        return false
    end

    record.current -= requested
    record.last_spend_at = os.clock()
    record.regen_delay_seconds =
        regen_delay_seconds
        or StaminaConfig.REGEN_DELAY_SECONDS

    replicate(subject, record)

    return true
end


--[[
Applies incoming Stamina loss and reports exhaustion.

Args:
    subject (Instance): Player-like Stamina owner.
    amount (number): Requested non-negative Stamina loss.
    regen_delay_seconds (number?): Optional recovery delay override.

Returns:
    number: Actual Stamina removed.
    boolean: True when the loss leaves Stamina at zero.
]]
function StaminaService.apply_loss(
    subject: Instance,
    amount: number,
    regen_delay_seconds: number?
): (number, boolean)
    local record = records[subject]

    if not record then
        return 0, false
    end

    local requested = math.max(0, amount)
    local spent = math.min(
        record.current,
        requested
    )

    record.current -= spent
    record.last_spend_at = os.clock()
    record.regen_delay_seconds =
        regen_delay_seconds
        or StaminaConfig.REGEN_DELAY_SECONDS

    replicate(subject, record)

    return spent, requested > 0 and record.current <= 0
end


--[[
Pauses or resumes passive Stamina regeneration.

Args:
    subject (Instance): Player-like Stamina owner.
    paused (boolean): True while regeneration must be disabled.

Returns:
    None.
]]
function StaminaService.set_regen_paused(
    subject: Instance,
    paused: boolean
)
    local record = records[subject]

    if not record then
        return
    end

    record.regen_paused = paused
end


--[[
Returns whether Stamina regeneration is currently paused.

Args:
    subject (Instance): Player-like Stamina owner.

Returns:
    boolean: True when passive regeneration is paused.
]]
function StaminaService.is_regen_paused(
    subject: Instance
): boolean
    local record = records[subject]

    return record ~= nil
        and record.regen_paused
        or false
end


RunService.Heartbeat:Connect(function(delta_time: number)
    local now = os.clock()

    for subject, record in records do
        if record.regen_paused
            or record.current >= StaminaConfig.MAX then
            continue
        end

        local elapsed = now - record.last_spend_at

        if elapsed < record.regen_delay_seconds then
            continue
        end

        local old_value = record.current

        record.current = math.min(
            StaminaConfig.MAX,
            record.current
                + StaminaConfig.REGEN_PER_SECOND
                * delta_time
        )

        if record.current ~= old_value then
            replicate(subject, record)
        end
    end
end)


return table.freeze(StaminaService)
