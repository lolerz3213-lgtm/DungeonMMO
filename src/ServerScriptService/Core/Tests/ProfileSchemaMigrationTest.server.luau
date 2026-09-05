--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local core_shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local core_services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")

local schema_module = core_shared:FindFirstChild("ProfileSchema")
if not schema_module then
    error("[Profile Schema/Migration Tests] RED: ProfileSchema is missing.")
end

local migration_module = core_services:FindFirstChild("ProfileMigration")
if not migration_module then
    error("[Profile Schema/Migration Tests] RED: ProfileMigration is missing.")
end

local ProfileSchema = require(schema_module)
local ProfileMigration = require(migration_module)
local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    assertion_count += 1
    if not condition then
        error("[Profile Schema/Migration Tests] " .. message, 2)
    end
end

local fresh_a = ProfileSchema.create_default(123)
local fresh_b = ProfileSchema.create_default(456)

assert_true(fresh_a.SchemaVersion == 3, "Fresh profile must use schema version 3.")
assert_true(fresh_a.Account.SelectedCharacterSlot == 1, "Slot 1 must be selected by default.")
assert_true(fresh_a.Characters.Slot1.Level == 1, "Fresh Slot1 Level must be 1.")
assert_true(fresh_a.Characters.Slot1.XP == 0, "Fresh Slot1 XP must be 0.")
assert_true(fresh_a.Characters.Slot1.Gold == 0, "Fresh Slot1 Gold must be 0.")
assert_true(type(fresh_a.Characters.Slot1.Inventory) == "table", "Inventory must be a table.")
assert_true(fresh_a.Characters.Slot1.Inventory ~= fresh_b.Characters.Slot1.Inventory, "Fresh profiles must not share Inventory tables.")
assert_true(fresh_a.Characters.Slot1.RewardHistory.Completion ~= fresh_b.Characters.Slot1.RewardHistory.Completion, "Fresh profiles must not share reward history tables.")
assert_true(type(fresh_a.Characters.Slot1.RewardHistory.Monster) == "table", "Fresh profile must include persistent monster reward history.")
assert_true(fresh_a.Characters.Slot1.RewardHistory.Monster ~= fresh_b.Characters.Slot1.RewardHistory.Monster, "Fresh profiles must not share monster reward history tables.")

local migrated_empty = ProfileMigration.migrate({})
assert_true(migrated_empty.SchemaVersion == 3, "Missing schema must migrate to version 3.")
assert_true(migrated_empty.Characters.Slot1.Level == 1, "Missing Slot1 must be deep-filled.")

local migrated_partial = ProfileMigration.migrate({
    CustomFutureField = {KeepMe = true},
    Account = {CustomAccountField = "keep"},
    Characters = {
        Slot1 = {
            Level = 4,
            XP = -10,
            Gold = 0 / 0,
            Inventory = {"ExistingItem"},
            CustomCharacterField = 99,
        },
    },
})

assert_true(migrated_partial.CustomFutureField.KeepMe == true, "Unknown top-level fields must be preserved.")
assert_true(migrated_partial.Account.CustomAccountField == "keep", "Unknown Account fields must be preserved.")
assert_true(migrated_partial.Characters.Slot1.CustomCharacterField == 99, "Unknown character fields must be preserved.")
assert_true(migrated_partial.Characters.Slot1.Level == 4, "Valid existing Level must be preserved.")
assert_true(migrated_partial.Characters.Slot1.XP == 0, "Negative XP must sanitize to 0.")
assert_true(migrated_partial.Characters.Slot1.Gold == 0, "NaN Gold must sanitize to 0.")
assert_true(migrated_partial.Characters.Slot1.Inventory[1] == "ExistingItem", "Existing inventory entries must survive migration.")
assert_true(type(migrated_partial.Characters.Slot1.DungeonProgress) == "table", "DungeonProgress must be deep-filled.")
assert_true(type(migrated_partial.Characters.Slot1.RewardHistory.Completion) == "table", "Completion reward history must be deep-filled.")
assert_true(type(migrated_partial.Characters.Slot1.RewardHistory.Monster) == "table", "Monster reward history must be deep-filled during migration.")

local sanitized_inf = ProfileMigration.migrate({
    Characters = {Slot1 = {XP = math.huge, Gold = math.huge}},
})
assert_true(sanitized_inf.Characters.Slot1.XP == 0, "Infinite XP must sanitize to 0.")
assert_true(sanitized_inf.Characters.Slot1.Gold == 0, "Infinite Gold must sanitize to 0.")

print(string.format("[Profile Schema/Migration Tests] PASS: %d assertions.", assertion_count))
