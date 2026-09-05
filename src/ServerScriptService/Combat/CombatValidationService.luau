local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local remotes_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Remotes")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local DedupeRules = require(
    script.Parent:WaitForChild("CombatValidationDedupeRules")
)

local validation_event = remotes_folder:WaitForChild(
    CombatConfig.REMOTES.VALIDATION_EVENT
) :: RemoteEvent

local CombatValidationService = {}
local dedupe_trackers: {[Player]: DedupeRules.Tracker} = {}

export type ValidationPayload = {
    server_time: number,
    event: string,
    outcome: string,
    detail: string,
    sequence_id: number?,
}


--[[Returns whether runtime combat validation output is enabled.]]
function CombatValidationService.is_enabled(): boolean
    return RunService:IsStudio()
        or CombatConfig.DEBUG.COMBAT_VALIDATION == true
end


--[[Builds one serialisable server validation payload.]]
function CombatValidationService.make_payload(
    event_name: string,
    outcome: string,
    detail: string?,
    sequence_id: number?,
    server_time: number?
): ValidationPayload
    return {
        server_time = server_time or os.clock(),
        event = event_name,
        outcome = outcome,
        detail = detail or "",
        sequence_id = sequence_id,
    }
end


--[[Formats one payload for Studio Output and the client feed.]]
function CombatValidationService.format_payload(
    payload: ValidationPayload
): string
    local sequence_text = ""

    if payload.sequence_id ~= nil then
        sequence_text = string.format(" #%d", payload.sequence_id)
    end

    local detail_text = ""

    if payload.detail ~= "" then
        detail_text = " " .. payload.detail
    end

    return string.format(
        "[%.3f]%s %s %s%s",
        payload.server_time,
        sequence_text,
        payload.event,
        payload.outcome,
        detail_text
    )
end


--[[Publishes one authoritative validation decision for a player.]]
function CombatValidationService.emit(
    player: Player?,
    event_name: string,
    outcome: string,
    detail: string?,
    sequence_id: number?
)
    if not CombatValidationService.is_enabled() then
        return
    end

    if player then
        local tracker = dedupe_trackers[player]
        if not tracker then
            tracker = DedupeRules.new_tracker()
            dedupe_trackers[player] = tracker
        end

        if not DedupeRules.should_publish(
            tracker,
            event_name,
            outcome,
            detail or "",
            sequence_id
        ) then
            return
        end
    end

    local payload = CombatValidationService.make_payload(
        event_name,
        outcome,
        detail,
        sequence_id
    )

    print(
        "[CombatValidation] "
            .. CombatValidationService.format_payload(payload)
    )

    if player and player.Parent == Players then
        validation_event:FireClient(player, payload)
    end
end


Players.PlayerRemoving:Connect(function(player)
    dedupe_trackers[player] = nil
end)


return table.freeze(CombatValidationService)
