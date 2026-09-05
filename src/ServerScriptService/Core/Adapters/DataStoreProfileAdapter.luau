--!strict
-- The only Core adapter allowed to talk directly to Roblox DataStoreService.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("EnvironmentConfig")
)

local DataStoreProfileAdapter = {}

function DataStoreProfileAdapter.new(): any
    local store = DataStoreService:GetDataStore(EnvironmentConfig.get_profile_store_name())
    local adapter = {}

    function adapter:update(user_id: number, transform: (any) -> any): (any?, string?)
        local key = "User_" .. tostring(user_id)
        local ok, result = pcall(function()
            return store:UpdateAsync(key, function(old_value)
                return transform(old_value)
            end)
        end)

        if not ok then
            warn(
                string.format(
                    "[Profile Persistence] UpdateAsync failed for user %d: %s",
                    user_id,
                    tostring(result)
                )
            )
            return nil, "DataStoreUpdateFailed"
        end

        if result == nil then
            return nil, "DataStoreUpdateCancelled"
        end

        return result, nil
    end

    return table.freeze(adapter)
end

return table.freeze(DataStoreProfileAdapter)
