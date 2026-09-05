--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local core = ServerScriptService:WaitForChild("Core")
local adapters = core:WaitForChild("Adapters")
local services = core:WaitForChild("Services")

local adapter_module = adapters:FindFirstChild("InMemoryProfileAdapter")
if not adapter_module then
    error("[Profile Service Tests] RED: InMemoryProfileAdapter is missing.")
end

local service_module = services:FindFirstChild("ProfileService")
if not service_module then
    error("[Profile Service Tests] RED: ProfileService is missing.")
end

local InMemoryProfileAdapter = require(adapter_module)
local ProfileService = require(service_module)
local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    assertion_count += 1
    if not condition then
        error("[Profile Service Tests] " .. message, 2)
    end
end

local adapter = InMemoryProfileAdapter.new()
local profiles = ProfileService.new(adapter)

local loaded, load_error = profiles:load(42)
assert_true(loaded ~= nil and load_error == nil, "Fresh profile must load successfully.")
assert_true(loaded.Characters.Slot1.Level == 1, "Fresh loaded profile must start at Level 1.")

loaded.Characters.Slot1.Gold = 999
local untouched = profiles:get_character(42, 1)
assert_true(untouched ~= nil and untouched.Gold == 0, "Load result must be a snapshot, not the authoritative live table.")

local mutated, mutate_error = profiles:mutate(42, function(profile)
    profile.Characters.Slot1.Gold += 25
    profile.Characters.Slot1.XP += 40
end)
assert_true(mutated and mutate_error == nil, "Mutation must succeed for a loaded profile.")

local snapshot = profiles:get_character(42, 1)
assert_true(snapshot ~= nil and snapshot.Gold == 25, "Snapshot must include successful mutation.")
assert_true(snapshot ~= nil and snapshot.XP == 40, "Snapshot must include XP mutation.")

snapshot.Gold = 777
local second_snapshot = profiles:get_character(42, 1)
assert_true(second_snapshot ~= nil and second_snapshot.Gold == 25, "Returned character snapshots must not mutate authoritative data.")

local saved, save_error = profiles:save(42, "UnitTest")
assert_true(saved and save_error == nil, "Dirty profile must save successfully.")

local released, release_error = profiles:release(42, "UnitTest")
assert_true(released and release_error == nil, "Loaded profile must release successfully.")
assert_true(profiles:get_profile(42) == nil, "Released profile must leave the loaded cache.")

local reloaded, reload_error = profiles:load(42)
assert_true(reloaded ~= nil and reload_error == nil, "Released profile must reload successfully.")
assert_true(reloaded.Characters.Slot1.Gold == 25, "Gold must survive save/release/reload.")
assert_true(reloaded.Characters.Slot1.XP == 40, "XP must survive save/release/reload.")

local missing_mutation, missing_error = profiles:mutate(999, function(_profile) end)
assert_true(not missing_mutation and missing_error == "ProfileNotLoaded", "Mutating an unloaded profile must fail closed.")

local callback_ok, callback_error = profiles:mutate(42, function(_profile)
    error("intentional mutation failure")
end)
assert_true(not callback_ok and callback_error == "MutationFailed", "Mutator exceptions must not escape or dirty the profile.")

local after_failed_mutation = profiles:get_character(42, 1)
assert_true(after_failed_mutation ~= nil and after_failed_mutation.Gold == 25, "Failed mutation must roll back partial changes.")

local handoff_loaded, handoff_load_error = profiles:load(43)
assert_true(handoff_loaded ~= nil and handoff_load_error == nil, "Handoff test profile must load.")
local forgot, forget_error = profiles:forget_for_handoff(43)
assert_true(forgot and forget_error == nil, "Successful teleport handoff must be able to drop the source cache without releasing the destination lease.")
assert_true(profiles:get_profile(43) == nil, "Forgotten handoff profile must not remain writable from the source cache.")

print(string.format("[Profile Service Tests] PASS: %d assertions.", assertion_count))
