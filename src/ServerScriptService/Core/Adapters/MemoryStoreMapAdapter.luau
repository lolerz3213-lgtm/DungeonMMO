--!strict
-- Thin, environment-prefixed MemoryStoreSortedMap boundary.
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("EnvironmentConfig")
)

local MemoryStoreMapAdapter = {}

local function deep_clone(value: any): any
    if type(value) ~= "table" then
        return value
    end

    local cloned = {}
    for key, child in pairs(value) do
        cloned[deep_clone(key)] = deep_clone(child)
    end
    return cloned
end

function MemoryStoreMapAdapter.new(map_suffix: string): any
    assert(type(map_suffix) == "string" and map_suffix ~= "", "map_suffix is required")

    local map_name = EnvironmentConfig.get_memory_prefix() .. "_" .. map_suffix
    local sorted_map = MemoryStoreService:GetSortedMap(map_name)
    local adapter = {}

    function adapter:get(key: string): (any?, string?)
        local ok, value = pcall(function()
            local stored_value = sorted_map:GetAsync(key)
            return stored_value
        end)
        if not ok then
            return nil, "MemoryStoreGetFailed"
        end
        return deep_clone(value), nil
    end

    function adapter:update(key: string, transform: (any) -> any, expiration_seconds: number): (any?, string?)
        assert(type(expiration_seconds) == "number" and expiration_seconds > 0, "expiration_seconds must be positive")

        local transform_error: string? = nil
        local ok, value = pcall(function()
            local updated_value = sorted_map:UpdateAsync(key, function(old_value: any, old_sort_key: any)
                local transform_ok, transformed = pcall(transform, deep_clone(old_value))
                if not transform_ok then
                    transform_error = "UpdateTransformFailed"
                    error(transformed)
                end
                if transformed == nil then
                    transform_error = "UpdateCancelled"
                    error("MemoryStore adapter transform returned nil")
                end
                return transformed, old_sort_key
            end, expiration_seconds)
            return updated_value
        end)

        if not ok then
            return nil, transform_error or "MemoryStoreUpdateFailed"
        end
        return deep_clone(value), nil
    end

    function adapter:remove(key: string): (boolean, string?)
        local ok = pcall(function()
            sorted_map:RemoveAsync(key)
        end)
        if not ok then
            return false, "MemoryStoreRemoveFailed"
        end
        return true, nil
    end

    return table.freeze(adapter)
end

return table.freeze(MemoryStoreMapAdapter)
