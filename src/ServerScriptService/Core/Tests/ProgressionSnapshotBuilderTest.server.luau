--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileSchema = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema")
)

local services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Progression Snapshot Builder Tests] " .. message, 2)
    end
end

local builder_module = services:FindFirstChild("ProgressionSnapshotBuilder")
check(
    builder_module ~= nil,
    "shared ProgressionSnapshotBuilder must exist before Base/Dungeon can share one sanitized payload."
)

local ProgressionSnapshotBuilder = require(builder_module :: ModuleScript)

local character = ProfileSchema.create_default(9201).Characters.Slot1
character.Level = 10
character.XP = 42
character.Gold = 77
character.Progression.AttributePointEntitlement = 9
character.Progression.SkillPointEntitlement = 9
character.Progression.Attributes.Strength = 6
character.Progression.Attributes.Vitality = 7
character.Progression.Skills.ShieldBash.PurchasedRank = 2
character.Progression.Skills.ShieldBash.Proficiency = 150
character.Progression.Skills.ArcSlash = {
    Known = true,
    StarterGranted = false,
    PurchasedRank = 1,
    Proficiency = 200,
}
character.Progression.Loadout = {
    [1] = "ShieldBash",
    [3] = "Mend",
    [6] = "ArcSlash",
}
character.Progression.RespecCounters = {
    Attributes = 2,
    Skills = 3,
}
character.Progression.OneTimeRewards.ArcSlashFirstClear = true
character.Inventory = {
    {ItemId = "arc_slash_book_bound", Quantity = 1},
}

local snapshot = ProgressionSnapshotBuilder.build(character)

check(snapshot.Level == 10 and snapshot.XP == 42 and snapshot.Gold == 77, "profile summary must be copied.")
check(snapshot.Attributes.Strength == 6 and snapshot.Attributes.Vitality == 7, "attributes must be copied.")
check(snapshot.Attributes ~= character.Progression.Attributes, "attributes must be sanitized into a new table.")
check(snapshot.RespecCounters.Attributes == 2 and snapshot.RespecCounters.Skills == 3, "respec counters must be copied.")
check(snapshot.RespecCounters ~= character.Progression.RespecCounters, "respec counters must not expose the persistent table.")
check(snapshot.OneTimeRewards.ArcSlashFirstClear == true, "one-time reward state must be copied.")
check(snapshot.OneTimeRewards ~= character.Progression.OneTimeRewards, "one-time rewards must not expose the persistent table.")
check(snapshot.Skills.ShieldBash.StarterGranted == true, "starter-granted state must be present.")
check(snapshot.Skills.ArcSlash.StarterGranted == false, "non-starter skill state must be present.")
check(snapshot.Skills.ArcSlash.BookOwned == true, "Arc Slash book ownership must be derived from inventory.")
check(#snapshot.Loadout == 6, "wire loadout must contain all six slots.")
check(snapshot.Loadout[1] == "ShieldBash", "slot 1 must be preserved.")
check(snapshot.Loadout[2] == false, "intentional slot 2 gap must be explicit on the wire.")
check(snapshot.Loadout[3] == "Mend", "slot 3 must survive the gap.")
check(snapshot.Loadout[4] == false and snapshot.Loadout[5] == false, "empty middle slots must be explicit.")
check(snapshot.Loadout[6] == "ArcSlash", "slot 6 must be preserved.")

snapshot.Attributes.Strength = 999
snapshot.RespecCounters.Attributes = 999
snapshot.OneTimeRewards.ArcSlashFirstClear = false

check(character.Progression.Attributes.Strength == 6, "snapshot mutation must not mutate persistent attributes.")
check(character.Progression.RespecCounters.Attributes == 2, "snapshot mutation must not mutate persistent respec counters.")
check(character.Progression.OneTimeRewards.ArcSlashFirstClear == true, "snapshot mutation must not mutate persistent reward flags.")

local empty_snapshot = ProgressionSnapshotBuilder.build(nil)
check(empty_snapshot.Level == 1 and empty_snapshot.APAvailable == 0 and empty_snapshot.SPAvailable == 0, "missing character fallback must be safe.")
check(#empty_snapshot.Loadout == 6, "missing character fallback must still use a dense six-slot wire loadout.")

print(string.format("[Progression Snapshot Builder Tests] PASS: %d assertions.", assertions))
