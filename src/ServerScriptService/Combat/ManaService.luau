--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatConfig = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("CombatConfig")
)
local AttributeConfig = require(
    ReplicatedStorage
        :WaitForChild("Core")
        :WaitForChild("Shared")
        :WaitForChild("AttributeConfig")
)
local ProgressionRuntimeState = require(
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")
        :WaitForChild("ProgressionRuntimeState")
)

local ManaService = {}

type ManaRecord = {
    current: number,
    maximum: number,
    regen_per_second: number,
    last_spend_at: number,
}

local records: {[Instance]: ManaRecord} = {}

local function resolve_limits(subject: Instance): (number, number)
    if subject:IsA("Player") then
        local player = subject :: Player
        return
            ProgressionRuntimeState.get_max_mana(player.UserId),
            ProgressionRuntimeState.get_mana_regen_per_second(player.UserId)
    end

    return
        AttributeConfig.BASE_MAX_MANA,
        AttributeConfig.BASE_MANA_REGEN_PER_SECOND
end

local function refresh_limits(
    subject: Instance,
    record: ManaRecord
)
    local maximum, regen = resolve_limits(subject)
    local was_full = record.current >= record.maximum - 0.001

    record.maximum = maximum
    record.regen_per_second = regen

    if was_full then
        record.current = maximum
    else
        record.current = math.min(record.current, maximum)
    end
end

local function replicate(
    subject: Instance,
    record: ManaRecord
)
    subject:SetAttribute("CombatMana", record.current)
    subject:SetAttribute("CombatMaxMana", record.maximum)
    subject:SetAttribute(
        "CombatManaRegenPerSecond",
        record.regen_per_second
    )
end

function ManaService.initialize_player(subject: Instance)
    local maximum, regen = resolve_limits(subject)
    local record: ManaRecord = {
        current = maximum,
        maximum = maximum,
        regen_per_second = regen,
        last_spend_at = -math.huge,
    }

    records[subject] = record
    replicate(subject, record)
end

function ManaService.reset_player(subject: Instance)
    ManaService.initialize_player(subject)
end

function ManaService.remove_player(subject: Instance)
    records[subject] = nil
end

function ManaService.get(subject: Instance): number
    local record = records[subject]
    return if record then record.current else 0
end

function ManaService.get_max(subject: Instance): number
    local record = records[subject]
    return if record then record.maximum else 0
end

function ManaService.try_spend(
    subject: Instance,
    amount: number
): boolean
    local record = records[subject]
    if not record then
        return false
    end

    refresh_limits(subject, record)

    local requested = math.max(0, amount)
    if record.current < requested then
        replicate(subject, record)
        return false
    end

    record.current -= requested
    record.last_spend_at = os.clock()
    replicate(subject, record)
    return true
end

RunService.Heartbeat:Connect(function(delta_time: number)
    local now = os.clock()

    for subject, record in records do
        local before_max = record.maximum
        local before_regen = record.regen_per_second
        refresh_limits(subject, record)

        local changed =
            before_max ~= record.maximum
            or before_regen ~= record.regen_per_second

        if record.current < record.maximum
            and now - record.last_spend_at
                >= CombatConfig.MANA.REGEN_DELAY_SECONDS
        then
            local before = record.current
            record.current = math.min(
                record.maximum,
                record.current
                    + record.regen_per_second * delta_time
            )
            changed = changed or record.current ~= before
        end

        if changed then
            replicate(subject, record)
        end
    end
end)

return table.freeze(ManaService)
