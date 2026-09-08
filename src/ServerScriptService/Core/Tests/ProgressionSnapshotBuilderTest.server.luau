--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local ProfileSchema = require(
    Shared:WaitForChild(
        "ProfileSchema"
    )
)

local ProgressionSnapshotBuilder = require(
    Services:WaitForChild(
        "ProgressionSnapshotBuilder"
    )
)

local assertions = 0

local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Progression Snapshot Builder Tests] "
                .. message,
            2
        )
    end
end

-- ------------------------------------------------------------
-- Completed Elf Fighter fixture
-- ------------------------------------------------------------

local character =
    ProfileSchema
        .create_default(9201)
        .Characters
        .Slot1

character.Level = 10
character.XP = 42
character.Gold = 77

character.Identity = {
    Version = 1,
    RaceId = "Elf",
    BaseClassId = "Fighter",
    ClassId = "Fighter",
    CreationStage = "Complete",
}

character
    .Progression
    .AttributePointEntitlement = 9

character
    .Progression
    .SkillPointEntitlement = 9

character.Progression.Attributes = {
    Strength = 6,
    Dexterity = 7,
    Vitality = 6,
    Intellect = 5,
    Spirit = 5,
}

character.Progression.Skills = {
    ShieldBash = {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 2,
        Proficiency = 150,
    },

    Mend = {
        Known = true,
        StarterGranted = true,
        PurchasedRank = 1,
        Proficiency = 50,
    },

    ArcSlash = {
        Known = true,
        StarterGranted = false,
        PurchasedRank = 1,
        Proficiency = 200,
    },
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

character
    .Progression
    .OneTimeRewards
    .ArcSlashFirstClear = true

character.Inventory = {
    {
        ItemId =
            "arc_slash_book_bound",

        Quantity = 1,
    },
}

local snapshot =
    ProgressionSnapshotBuilder.build(
        character
    )

check(
    snapshot.Level == 10
        and snapshot.XP == 42
        and snapshot.Gold == 77,
    "profile summary must be copied."
)

check(
    snapshot.Identity.RaceId == "Elf",
    "race must be exposed."
)

check(
    snapshot.Identity.BaseClassId
        == "Fighter",
    "base class must be exposed."
)

check(
    snapshot.Identity.ClassId
        == "Fighter",
    "current class must be exposed."
)

check(
    snapshot.Identity.CreationStage
        == "Complete",
    "creation stage must be exposed."
)

check(
    snapshot.Identity
        ~= character.Identity,
    "identity snapshot must not expose persistent table."
)

check(
    snapshot
        .AttributeBaseline
        .Dexterity
        == 6,
    "Elf Dexterity baseline must be 6."
)

check(
    snapshot
        .AttributeBaseline
        .Vitality
        == 4,
    "Elf Vitality baseline must be 4."
)

check(
    snapshot.Attributes.Strength == 6
        and snapshot.Attributes.Dexterity == 7
        and snapshot.Attributes.Vitality == 6,
    "allocated attributes must be copied."
)

check(
    snapshot.Attributes
        ~= character.Progression.Attributes,
    "attributes must be sanitized into a new table."
)

check(
    snapshot.RespecCounters.Attributes
        == 2
        and snapshot.RespecCounters.Skills
            == 3,
    "respec counters must be copied."
)

check(
    snapshot.RespecCounters
        ~= character
            .Progression
            .RespecCounters,
    "respec counters must not expose persistent table."
)

check(
    snapshot
        .OneTimeRewards
        .ArcSlashFirstClear
        == true,
    "one-time reward state must be copied."
)

check(
    snapshot.OneTimeRewards
        ~= character
            .Progression
            .OneTimeRewards,
    "one-time rewards must not expose persistent table."
)

check(
    snapshot
        .Skills
        .ShieldBash
        .StarterGranted
        == true,
    "Shield Bash starter state must be present."
)

check(
    snapshot
        .Skills
        .ShieldBash
        .Rank
        == 2,
    "Shield Bash purchased rank must be present."
)

check(
    snapshot
        .Skills
        .Mend
        .StarterGranted
        == true,
    "Mend starter state must be present."
)

check(
    snapshot
        .Skills
        .ArcSlash
        .StarterGranted
        == false,
    "non-starter Arc Slash state must be present."
)

check(
    snapshot
        .Skills
        .ArcSlash
        .BookOwned
        == true,
    "Arc Slash book ownership must derive from inventory."
)

check(
    #snapshot.Loadout == 6,
    "wire loadout must contain all six slots."
)

check(
    snapshot.Loadout[1]
        == "ShieldBash",
    "slot 1 must be preserved."
)

check(
    snapshot.Loadout[2]
        == false,
    "intentional slot 2 gap must be explicit."
)

check(
    snapshot.Loadout[3]
        == "Mend",
    "slot 3 must survive the gap."
)

check(
    snapshot.Loadout[4] == false
        and snapshot.Loadout[5] == false,
    "empty middle slots must be explicit."
)

check(
    snapshot.Loadout[6]
        == "ArcSlash",
    "slot 6 must be preserved."
)

snapshot.Identity.RaceId = "Human"
snapshot.AttributeBaseline.Dexterity = 999
snapshot.Attributes.Strength = 999
snapshot.RespecCounters.Attributes = 999
snapshot.OneTimeRewards.ArcSlashFirstClear = false

check(
    character.Identity.RaceId
        == "Elf",
    "snapshot identity mutation must not mutate persistent identity."
)

check(
    character
        .Progression
        .Attributes
        .Strength
        == 6,
    "snapshot attribute mutation must not mutate persistent attributes."
)

check(
    character
        .Progression
        .RespecCounters
        .Attributes
        == 2,
    "snapshot respec mutation must not mutate persistent counters."
)

check(
    character
        .Progression
        .OneTimeRewards
        .ArcSlashFirstClear
        == true,
    "snapshot reward mutation must not mutate persistent flags."
)

-- ------------------------------------------------------------
-- Fresh unresolved character
-- ------------------------------------------------------------

local unresolved =
    ProfileSchema
        .create_default(9202)
        .Characters
        .Slot1

local unresolved_snapshot =
    ProgressionSnapshotBuilder.build(
        unresolved
    )

check(
    unresolved_snapshot
        .Identity
        .CreationStage
        == "RaceSelection",
    "fresh unresolved snapshot must expose RaceSelection."
)

check(
    unresolved_snapshot
        .Identity
        .RaceId
        == nil,
    "fresh unresolved snapshot must not invent a race."
)

check(
    unresolved_snapshot.APAvailable
        == 0,
    "unresolved identity must expose zero available AP."
)

check(
    unresolved_snapshot
        .AttributeBaseline
        .Strength
        == 5
        and unresolved_snapshot
            .AttributeBaseline
            .Dexterity
            == 5
        and unresolved_snapshot
            .AttributeBaseline
            .Vitality
            == 5,
    "unresolved baseline must safely use neutral values."
)

check(
    unresolved_snapshot
        .Skills
        .ShieldBash
        .Known
        == false,
    "fresh unresolved snapshot must not invent Fighter starters."
)

-- ------------------------------------------------------------
-- Missing character fallback
-- ------------------------------------------------------------

local empty_snapshot =
    ProgressionSnapshotBuilder.build(nil)

check(
    empty_snapshot.Level == 1
        and empty_snapshot.APAvailable == 0
        and empty_snapshot.SPAvailable == 0,
    "missing-character fallback must be safe."
)

check(
    empty_snapshot
        .Identity
        .CreationStage
        == "RaceSelection",
    "missing-character fallback must expose a safe unresolved stage."
)

check(
    #empty_snapshot.Loadout == 6,
    "missing-character fallback must use dense six-slot loadout."
)

print(
    string.format(
        "[Progression Snapshot Builder Tests] PASS: %d assertions.",
        assertions
    )
)