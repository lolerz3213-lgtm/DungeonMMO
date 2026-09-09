--!strict

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Core = ServerScriptService
    :WaitForChild("Core")

local Adapters =
    Core:WaitForChild("Adapters")

local Services =
    Core:WaitForChild("Services")

local InMemoryProfileAdapter = require(
    Adapters:WaitForChild(
        "InMemoryProfileAdapter"
    )
)

local ProfileService = require(
    Services:WaitForChild(
        "ProfileService"
    )
)

local LoadoutService = require(
    Services:WaitForChild(
        "LoadoutService"
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
            "[Loadout Service Tests] "
                .. message,
            2
        )
    end
end

local unresolved_profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

assert(
    unresolved_profiles:load(9400)
)

local unresolved_service =
    LoadoutService.new(
        unresolved_profiles
    )

local unresolved_set =
    unresolved_service:set(
        9400,
        {},
        "Base"
    )

check(
    unresolved_set.ok == false
        and unresolved_set.reason
            == "IdentityIncomplete",
    "unresolved loadout set must be blocked."
)

local unresolved_move =
    unresolved_service:move_to_slot(
        9400,
        "Mend",
        1,
        "Base"
    )

check(
    unresolved_move.ok == false
        and unresolved_move.reason
            == "IdentityIncomplete",
    "unresolved loadout move must be blocked."
)

local profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

assert(profiles:load(9401))

assert(
    profiles:mutate(
        9401,
        function(profile: any)
            local character =
                profile.Characters.Slot1

            character.Identity = {
                Version = 1,
                RaceId = "Human",
                BaseClassId = "Fighter",
                ClassId = "Fighter",
                CreationStage = "Complete",
            }

            character.Progression.Attributes = {
                Strength = 5,
                Dexterity = 4,
                Vitality = 6,
                Intellect = 5,
                Spirit = 5,
            }

            character.Progression.Skills = {
                ShieldBash = {
                    Known = true,
                    StarterGranted = true,
                    PurchasedRank = 1,
                    Proficiency = 0,
                },

                Mend = {
                    Known = true,
                    StarterGranted = true,
                    PurchasedRank = 1,
                    Proficiency = 0,
                },
            }

            character.Progression.Loadout = {
                [1] = "ShieldBash",
                [2] = "Mend",
            }
        end
    )
)

local service =
    LoadoutService.new(profiles)

local character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    character.Progression.Loadout[1]
        == "ShieldBash"
        and character
            .Progression
            .Loadout[2]
            == "Mend",
    "completed Fighter starter loadout must be present."
)

assert(
    profiles:mutate(
        9401,
        function(profile: any)
            profile
                .Characters
                .Slot1
                .Progression
                .Skills
                .ArcSlash = {
                    Known = true,
                    StarterGranted = false,
                    PurchasedRank = 1,
                    Proficiency = 0,
                }
        end
    )
)

local equipped =
    service:auto_equip_first_free(
        9401,
        "ArcSlash"
    )

character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    equipped == true
        and character
            .Progression
            .Loadout[3]
            == "ArcSlash",
    "new learned skill must fill first free slot."
)

local invalid =
    service:set(
        9401,
        {
            "Mend",
            "Mend",
        },
        "Base"
    )

character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    invalid.ok == false
        and character
            .Progression
            .Loadout[1]
            == "ShieldBash",
    "invalid duplicate request must preserve loadout."
)

local moved =
    service:move_to_slot(
        9401,
        "ShieldBash",
        3,
        "Base"
    )

character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    moved.ok == true
        and character
            .Progression
            .Loadout[3]
            == "ShieldBash"
        and character
            .Progression
            .Loadout[1]
            == nil,
    "move must relocate skill without duplication."
)

check(
    character
        .Progression
        .Loadout[2]
        == "Mend",
    "unmoved Mend slot must remain intact."
)

local moved_again =
    service:move_to_slot(
        9401,
        "Mend",
        3,
        "Base"
    )

character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    moved_again.ok == true
        and character
            .Progression
            .Loadout[3]
            == "Mend"
        and character
            .Progression
            .Loadout[2]
            == nil,
    "move must replace occupied destination from authoritative state."
)

local bad_slot =
    service:move_to_slot(
        9401,
        "ShieldBash",
        7,
        "Base"
    )

check(
    bad_slot.ok == false
        and bad_slot.reason
            == "InvalidSlot",
    "slots outside active range must reject."
)

local active =
    service:move_to_slot(
        9401,
        "ShieldBash",
        1,
        "DungeonActive"
    )

check(
    active.ok == false
        and active.reason
            == "LoadoutLockedDuringEncounter",
    "active encounter must reject swapping."
)

for slot = 1, 6 do
    local placed =
        service:move_to_slot(
            9401,
            "ShieldBash",
            slot,
            "Base"
        )

    character = assert(
        profiles:get_character(
            9401,
            1
        )
    )

    local count = 0

    for _, skill_id in pairs(
        character
            .Progression
            .Loadout
    ) do
        if skill_id == "ShieldBash" then
            count += 1
        end
    end

    check(
        placed.ok == true
            and character
                .Progression
                .Loadout[slot]
                == "ShieldBash"
            and count == 1,
        "every target slot must remain exact and unique."
    )
end

check(
    service:set(
        9401,
        {
            [1] = "ShieldBash",
        },
        "Base"
    ).ok,
    "prepare deliberate gap."
)

check(
    service:move_to_slot(
        9401,
        "Mend",
        3,
        "Base"
    ).ok,
    "place learned skill after gap."
)

character = assert(
    profiles:get_character(
        9401,
        1
    )
)

check(
    character.Progression.Loadout[1]
        == "ShieldBash"
        and character
            .Progression
            .Loadout[2]
            == nil
        and character
            .Progression
            .Loadout[3]
            == "Mend",
    "Slot 3 placement must preserve Slot 2 gap."
)

for _, slot in ipairs({
    0,
    -1,
    7,
    1.5,
    "3",
    false,
    math.huge,
    -math.huge,
    0 / 0,
}) do
    local rejected =
        service:move_to_slot(
            9401,
            "Mend",
            slot,
            "Base"
        )

    character = assert(
        profiles:get_character(
            9401,
            1
        )
    )

    check(
        rejected.ok == false
            and rejected.reason
                == "InvalidSlot"
            and character
                .Progression
                .Loadout[3]
                == "Mend"
            and character
                .Progression
                .Loadout[1]
                == "ShieldBash",
        "invalid slots must fail closed without mutation."
    )
end

check(
    service:move_to_slot(
        9401,
        "Mend",
        nil,
        "Base"
    ).reason == "InvalidSlot",
    "missing target must fail closed."
)

check(
    service:move_to_slot(
        9401,
        "Mend",
        6,
        "DungeonClear"
    ).ok,
    "cleared Dungeon supports atomic moves."
)

print(
    string.format(
        "[Loadout Service Tests] PASS: %d assertions.",
        assertions
    )
)