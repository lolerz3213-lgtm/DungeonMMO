--!strict
-- Central single-server authority for loaded persistent player profiles.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileSchema = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema")
)
local ProfileMigration = require(
    ServerScriptService:WaitForChild("Core"):WaitForChild("Services"):WaitForChild("ProfileMigration")
)

local ProfileService = {}
ProfileService.__index = ProfileService

local function snapshot(value: any): any
    return ProfileSchema.deep_clone(value)
end

function ProfileService.new(store_adapter: any, lease_service: any?): any
    assert(store_adapter ~= nil, "ProfileService requires a storage adapter.")

    local self = setmetatable({}, ProfileService)
    self._store_adapter = store_adapter
    self._lease_service = lease_service
    self._loaded = {}
    return self
end

function ProfileService:load(user_id: number): (any?, string?)
    local existing = self._loaded[user_id]
    if existing then
        return snapshot(existing.profile), nil
    end

    if self._lease_service then
        local lease_result = self._lease_service:claim(user_id)
        if not lease_result or lease_result.ok ~= true then
            return nil, if lease_result and lease_result.reason then lease_result.reason else "LeaseClaimFailed"
        end
    end

    local migration_error: string? = nil
    local stored, store_error = self._store_adapter:update(user_id, function(raw_value)
        local ok, migrated_or_error = pcall(ProfileMigration.migrate, raw_value)
        if not ok then
            migration_error = tostring(migrated_or_error)
            error(migrated_or_error)
        end
        return migrated_or_error
    end)

    if not stored then
        if self._lease_service then
            self._lease_service:release(user_id)
        end
        if migration_error then
            return nil, "ProfileMigrationFailed"
        end
        return nil, store_error or "ProfileLoadFailed"
    end

    local migrated_ok, migrated = pcall(ProfileMigration.migrate, stored)
    if not migrated_ok then
        if self._lease_service then
            self._lease_service:release(user_id)
        end
        return nil, "ProfileMigrationFailed"
    end

    self._loaded[user_id] = {
        profile = migrated,
        dirty = false,
    }

    return snapshot(migrated), nil
end

function ProfileService:get_profile(user_id: number): any?
    local record = self._loaded[user_id]
    if not record then
        return nil
    end
    return snapshot(record.profile)
end

function ProfileService:get_character(user_id: number, slot: number?): any?
    local record = self._loaded[user_id]
    if not record then
        return nil
    end

    local selected_slot = slot or record.profile.Account.SelectedCharacterSlot
    local slot_key = "Slot" .. tostring(selected_slot)
    local character = record.profile.Characters[slot_key]
    if not character then
        return nil
    end

    return snapshot(character)
end

function ProfileService:mutate(user_id: number, mutator: (any) -> ()): (boolean, string?)
    local record = self._loaded[user_id]
    if not record then
        return false, "ProfileNotLoaded"
    end

    local working_copy = snapshot(record.profile)
    local ok = pcall(mutator, working_copy)
    if not ok then
        return false, "MutationFailed"
    end

    local migration_ok, sanitized = pcall(ProfileMigration.migrate, working_copy)
    if not migration_ok then
        return false, "MutationInvalid"
    end

    record.profile = sanitized
    record.dirty = true
    return true, nil
end

function ProfileService:save(user_id: number, _reason: string): (boolean, string?)
    local record = self._loaded[user_id]
    if not record then
        return false, "ProfileNotLoaded"
    end

    if not record.dirty then
        return true, nil
    end

    local value_to_save = snapshot(record.profile)
    local stored, store_error = self._store_adapter:update(user_id, function(_old_value)
        return value_to_save
    end)

    if not stored then
        return false, store_error or "ProfileSaveFailed"
    end

    local migration_ok, sanitized = pcall(ProfileMigration.migrate, stored)
    if not migration_ok then
        return false, "ProfileMigrationFailed"
    end

    record.profile = sanitized
    record.dirty = false
    return true, nil
end

function ProfileService:forget_for_handoff(user_id: number): (boolean, string?)
    local record = self._loaded[user_id]
    if not record then
        return true, nil
    end

    if record.dirty then
        return false, "ProfileDirtyBeforeHandoffForget"
    end

    -- The source lease is intentionally left in Handoff state for the destination
    -- server to claim. This method only removes the local writable cache.
    self._loaded[user_id] = nil
    return true, nil
end

function ProfileService:release(user_id: number, reason: string): (boolean, string?)
    local record = self._loaded[user_id]
    if not record then
        return true, nil
    end

    local saved, save_error = self:save(user_id, reason)
    if not saved then
        return false, save_error
    end

    self._loaded[user_id] = nil

    if self._lease_service then
        local lease_result = self._lease_service:release(user_id)
        if lease_result and lease_result.ok == false then
            return false, lease_result.reason or "LeaseReleaseFailed"
        end
    end

    return true, nil
end

return table.freeze(ProfileService)
