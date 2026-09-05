--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local InMemoryMapAdapter = require(Adapters:WaitForChild("InMemoryMapAdapter"))
local ProfileLeaseService = require(Services:WaitForChild("ProfileLeaseService"))

local now = 1000
local function clock(): number
    return now
end

local fake_map = InMemoryMapAdapter.new(clock)
local lease_a = ProfileLeaseService.new(fake_map, "ServerA", clock)
local lease_b = ProfileLeaseService.new(fake_map, "ServerB", clock)

assert(lease_a:claim(42).ok, "Server A must claim an unowned profile.")
assert(not lease_b:claim(42).ok, "Server B must not steal a live lease.")

local renewed = lease_a:renew(42)
assert(renewed.ok, "The owner must be able to renew its lease.")

local nonce = "handoff-42-a"
assert(lease_a:begin_handoff(42, nonce, "Dungeon").ok, "Owner must start handoff.")
assert(not lease_a:renew(42).ok, "Source must stop ordinary renewal while handoff is pending.")
assert(not lease_b:claim_handoff(42, "wrong").ok, "Wrong handoff nonce must be rejected.")
assert(lease_b:claim_handoff(42, nonce).ok, "Destination must claim with the exact nonce.")
assert(not lease_a:renew(42).ok, "Old owner must lose authority after destination claim.")
assert(lease_b:renew(42).ok, "New owner must be able to renew after handoff.")

assert(lease_b:begin_handoff(42, "return-42", "Base").ok, "New owner must be able to begin return handoff.")
assert(lease_b:cancel_handoff(42, "return-42").ok, "Source must be able to cancel its still-pending handoff.")
assert(lease_b:renew(42).ok, "Cancelling handoff must restore source authority.")

assert(lease_b:release(42).ok, "Owner must release its lease.")
assert(lease_a:claim(42).ok, "Another server must claim after release.")

assert(lease_a:release(42).ok)
assert(lease_a:claim(77).ok)
now += ProfileLeaseService.LEASE_TTL_SECONDS + 1
assert(lease_b:claim(77).ok, "Expired lease must be reclaimable by another server.")

print("[Profile Lease Tests] PASS")
