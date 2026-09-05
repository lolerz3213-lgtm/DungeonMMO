--!strict
-- Atomic single-writer profile authority with explicit Base <-> Dungeon handoff.
local ProfileLeaseService = {}
ProfileLeaseService.__index = ProfileLeaseService

ProfileLeaseService.LEASE_TTL_SECONDS = 45
ProfileLeaseService.HANDOFF_TTL_SECONDS = 60
ProfileLeaseService.STORAGE_TTL_SECONDS = 120

local VALID_DESTINATIONS: {[string]: boolean} = table.freeze({
    Base = true,
    Dungeon = true,
})

local function lease_key(user_id: number): string
    return "User_" .. tostring(user_id)
end

local function is_expired(record: any, now: number): boolean
    return type(record) ~= "table"
        or type(record.ExpiresAt) ~= "number"
        or record.ExpiresAt <= now
        or record.State == "Released"
end

local function result(ok: boolean, reason: string?, lease: any?): any
    return {
        ok = ok,
        reason = reason,
        lease = lease,
    }
end

function ProfileLeaseService.new(map_adapter: any, server_id: string, clock: (() -> number)?): any
    assert(map_adapter ~= nil, "ProfileLeaseService requires a map adapter.")
    assert(type(server_id) == "string" and server_id ~= "", "server_id is required")

    local self = setmetatable({}, ProfileLeaseService)
    self._map = map_adapter
    self._server_id = server_id
    self._clock = clock or os.time
    return self
end

function ProfileLeaseService:_update(user_id: number, transform: (any, number) -> (any, any)): any
    assert(type(user_id) == "number" and user_id > 0, "user_id must be positive")

    local now = self._clock()
    local operation_result = result(false, "LeaseUpdateFailed")
    local stored, store_error = self._map:update(lease_key(user_id), function(old_record: any)
        local new_record, new_result = transform(old_record, now)
        operation_result = new_result
        return new_record
    end, ProfileLeaseService.STORAGE_TTL_SECONDS)

    if stored == nil then
        return result(false, store_error or "LeaseStoreFailed")
    end
    if operation_result.ok then
        operation_result.lease = stored
    end
    return operation_result
end

function ProfileLeaseService:claim(user_id: number): any
    return self:_update(user_id, function(old_record: any, now: number)
        if not is_expired(old_record, now) then
            if old_record.OwnerServerId == self._server_id and old_record.State == "Owned" then
                local renewed = {
                    State = "Owned",
                    OwnerServerId = self._server_id,
                    ExpiresAt = now + ProfileLeaseService.LEASE_TTL_SECONDS,
                    UpdatedAt = now,
                }
                return renewed, result(true, nil)
            end

            local reason = if old_record.State == "Handoff" then "HandoffInProgress" else "LeaseHeld"
            return old_record, result(false, reason)
        end

        local claimed = {
            State = "Owned",
            OwnerServerId = self._server_id,
            ExpiresAt = now + ProfileLeaseService.LEASE_TTL_SECONDS,
            UpdatedAt = now,
        }
        return claimed, result(true, nil)
    end)
end

function ProfileLeaseService:renew(user_id: number): any
    return self:_update(user_id, function(old_record: any, now: number)
        if is_expired(old_record, now) then
            return old_record or {
                State = "Released",
                ExpiresAt = now,
                UpdatedAt = now,
            }, result(false, "LeaseExpired")
        end
        if old_record.OwnerServerId ~= self._server_id then
            return old_record, result(false, "NotOwner")
        end
        if old_record.State ~= "Owned" then
            return old_record, result(false, "HandoffInProgress")
        end

        local renewed = {
            State = "Owned",
            OwnerServerId = self._server_id,
            ExpiresAt = now + ProfileLeaseService.LEASE_TTL_SECONDS,
            UpdatedAt = now,
        }
        return renewed, result(true, nil)
    end)
end

function ProfileLeaseService:begin_handoff(user_id: number, nonce: string, destination_kind: string): any
    if type(nonce) ~= "string" or nonce == "" then
        return result(false, "InvalidNonce")
    end
    if VALID_DESTINATIONS[destination_kind] ~= true then
        return result(false, "InvalidDestination")
    end

    return self:_update(user_id, function(old_record: any, now: number)
        if is_expired(old_record, now) then
            return old_record or {
                State = "Released",
                ExpiresAt = now,
                UpdatedAt = now,
            }, result(false, "LeaseExpired")
        end
        if old_record.OwnerServerId ~= self._server_id then
            return old_record, result(false, "NotOwner")
        end
        if old_record.State ~= "Owned" then
            return old_record, result(false, "HandoffInProgress")
        end

        local handoff = {
            State = "Handoff",
            OwnerServerId = self._server_id,
            ExpiresAt = now + ProfileLeaseService.HANDOFF_TTL_SECONDS,
            UpdatedAt = now,
            Handoff = {
                Nonce = nonce,
                DestinationKind = destination_kind,
                SourceServerId = self._server_id,
            },
        }
        return handoff, result(true, nil)
    end)
end

function ProfileLeaseService:claim_handoff(user_id: number, nonce: string): any
    if type(nonce) ~= "string" or nonce == "" then
        return result(false, "InvalidNonce")
    end

    return self:_update(user_id, function(old_record: any, now: number)
        if is_expired(old_record, now) then
            return old_record or {
                State = "Released",
                ExpiresAt = now,
                UpdatedAt = now,
            }, result(false, "LeaseExpired")
        end
        if old_record.State ~= "Handoff" or type(old_record.Handoff) ~= "table" then
            return old_record, result(false, "NoHandoff")
        end
        if old_record.Handoff.Nonce ~= nonce then
            return old_record, result(false, "NonceMismatch")
        end

        local claimed = {
            State = "Owned",
            OwnerServerId = self._server_id,
            ExpiresAt = now + ProfileLeaseService.LEASE_TTL_SECONDS,
            UpdatedAt = now,
        }
        return claimed, result(true, nil)
    end)
end

function ProfileLeaseService:cancel_handoff(user_id: number, nonce: string): any
    if type(nonce) ~= "string" or nonce == "" then
        return result(false, "InvalidNonce")
    end

    return self:_update(user_id, function(old_record: any, now: number)
        if is_expired(old_record, now) then
            return old_record or {
                State = "Released",
                ExpiresAt = now,
                UpdatedAt = now,
            }, result(false, "LeaseExpired")
        end
        if old_record.OwnerServerId ~= self._server_id then
            return old_record, result(false, "NotOwner")
        end
        if old_record.State ~= "Handoff" or type(old_record.Handoff) ~= "table" then
            return old_record, result(false, "NoHandoff")
        end
        if old_record.Handoff.Nonce ~= nonce then
            return old_record, result(false, "NonceMismatch")
        end

        local restored = {
            State = "Owned",
            OwnerServerId = self._server_id,
            ExpiresAt = now + ProfileLeaseService.LEASE_TTL_SECONDS,
            UpdatedAt = now,
        }
        return restored, result(true, nil)
    end)
end

function ProfileLeaseService:release(user_id: number): any
    return self:_update(user_id, function(old_record: any, now: number)
        if is_expired(old_record, now) then
            local released = {
                State = "Released",
                OwnerServerId = self._server_id,
                ExpiresAt = now,
                UpdatedAt = now,
            }
            return released, result(true, nil)
        end
        if old_record.OwnerServerId ~= self._server_id then
            return old_record, result(false, "NotOwner")
        end
        if old_record.State == "Handoff" then
            return old_record, result(false, "HandoffInProgress")
        end

        local released = {
            State = "Released",
            OwnerServerId = self._server_id,
            ExpiresAt = now,
            UpdatedAt = now,
        }
        return released, result(true, nil)
    end)
end

return table.freeze(ProfileLeaseService)
