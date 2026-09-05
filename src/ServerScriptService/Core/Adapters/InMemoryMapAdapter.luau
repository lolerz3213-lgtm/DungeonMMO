--!strict
-- Deterministic MemoryStore substitute for Studio contract tests.
local InMemoryMapAdapter = {}

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

function InMemoryMapAdapter.new(clock: (() -> number)?): any
    local now = clock or os.time
    local storage: {[string]: {Value: any, ExpiresAt: number}} = {}
    local adapter = {}

    local function prune(key: string)
        local entry = storage[key]
        if entry and entry.ExpiresAt <= now() then
            storage[key] = nil
        end
    end

    function adapter:get(key: string): (any?, string?)
        prune(key)
        local entry = storage[key]
        if not entry then
            return nil, nil
        end
        return deep_clone(entry.Value), nil
    end

    function adapter:update(key: string, transform: (any) -> any, expiration_seconds: number): (any?, string?)
        assert(type(expiration_seconds) == "number" and expiration_seconds > 0, "expiration_seconds must be positive")
        prune(key)

        local old_value = if storage[key] then deep_clone(storage[key].Value) else nil
        local ok, transformed = pcall(transform, old_value)
        if not ok then
            return nil, "UpdateTransformFailed"
        end
        if transformed == nil then
            return nil, "UpdateCancelled"
        end

        storage[key] = {
            Value = deep_clone(transformed),
            ExpiresAt = now() + expiration_seconds,
        }
        return deep_clone(transformed), nil
    end

    function adapter:remove(key: string): (boolean, string?)
        storage[key] = nil
        return true, nil
    end

    return table.freeze(adapter)
end

return table.freeze(InMemoryMapAdapter)
