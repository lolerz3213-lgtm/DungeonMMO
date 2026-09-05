--!strict
-- Deterministic DataStore substitute used by Studio contract tests.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileSchema = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema")
)

local InMemoryProfileAdapter = {}

function InMemoryProfileAdapter.new(initial_data: {[number]: any}?): any
    local storage: {[number]: any} = {}

    if initial_data then
        for user_id, profile in pairs(initial_data) do
            storage[user_id] = ProfileSchema.deep_clone(profile)
        end
    end

    local adapter = {}

    function adapter:update(user_id: number, transform: (any) -> any): (any?, string?)
        local old_value = ProfileSchema.deep_clone(storage[user_id])
        local ok, transformed = pcall(transform, old_value)

        if not ok then
            return nil, "UpdateTransformFailed"
        end

        if transformed == nil then
            return nil, "UpdateCancelled"
        end

        storage[user_id] = ProfileSchema.deep_clone(transformed)
        return ProfileSchema.deep_clone(storage[user_id]), nil
    end

    return table.freeze(adapter)
end

return table.freeze(InMemoryProfileAdapter)
