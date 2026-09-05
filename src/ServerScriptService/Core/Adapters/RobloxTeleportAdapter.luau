--!strict
-- Small TeleportService boundary so coordination rules can be tested without real teleports.
local TeleportService = game:GetService("TeleportService")

local RobloxTeleportAdapter = {}

function RobloxTeleportAdapter.new(options: any?): any
    local config = options or {}
    local force_teleport_failure = config.force_teleport_failure == true
    local failure_reason = "ForcedTeleportFailure"
    if type(config.failure_reason) == "string" and config.failure_reason ~= "" then
        failure_reason = config.failure_reason
    end
    local adapter = {}

    function adapter:reserve_server(place_id: number): (boolean, string?)
        local ok, access_code = pcall(function()
            return TeleportService:ReserveServerAsync(place_id)
        end)
        if not ok then
            return false, tostring(access_code)
        end
        if type(access_code) ~= "string" or access_code == "" then
            return false, "ReserveServerReturnedInvalidCode"
        end
        return true, access_code
    end

    function adapter:teleport(
        place_id: number,
        players: {Player},
        reserved_code: string?,
        teleport_data: any
    ): (boolean, string?)
        if force_teleport_failure then
            return false, failure_reason
        end

        local options = Instance.new("TeleportOptions")
        if type(reserved_code) == "string" and reserved_code ~= "" then
            options.ReservedServerAccessCode = reserved_code
        end
        options:SetTeleportData(teleport_data)

        local ok, result = pcall(function()
            return TeleportService:TeleportAsync(place_id, players, options)
        end)
        if not ok then
            return false, tostring(result)
        end
        return true, nil
    end

    function adapter:connect_init_failed(handler: (...any) -> ())
        return TeleportService.TeleportInitFailed:Connect(handler)
    end

    return table.freeze(adapter)
end

return table.freeze(RobloxTeleportAdapter)
