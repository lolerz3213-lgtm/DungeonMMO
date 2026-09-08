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

local ProficiencyService = require(
    Services:WaitForChild(
        "ProficiencyService"
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
            "[Proficiency Service Tests] "
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
    unresolved_profiles:load(9500)
)

local unresolved_service =
    ProficiencyService.new(
        unresolved_profiles
    )

local blocked =
    unresolved_service:grant(
        9500,
        "Mend",
        10,
        {
            eligible = true,
        }
    )

check(
    blocked.ok == false
        and blocked.reason
            == "IdentityIncomplete"
        and blocked.granted == 0,
    "unresolved proficiency grant must return IdentityIncomplete and zero grant."
)

local blocked_test =
    unresolved_service:set_for_test(
        9500,
        "Mend",
        10,
        "TEST"
    )

check(
    blocked_test.ok == false
        and blocked_test.reason
            == "IdentityIncomplete",
    "unresolved TEST proficiency mutation must be blocked."
)

local profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

assert(profiles:load(9501))

assert(
    profiles:mutate(
        9501,
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
    ProficiencyService.new(
        profiles
    )

local first =
    service:grant(
        9501,
        "Mend",
        90,
        {
            eligible = true,
        }
    )

check(
    first.ok == true
        and first.new_value == 90,
    "eligible contribution must grant proficiency."
)

local second =
    service:grant(
        9501,
        "Mend",
        20,
        {
            eligible = true,
        }
    )

check(
    second.new_value == 100
        and second.granted == 10,
    "grant must clamp to next-rank threshold."
)

local third =
    service:grant(
        9501,
        "Mend",
        20,
        {
            eligible = true,
        }
    )

check(
    third.granted == 0
        and third.new_value == 100,
    "proficiency must remain capped until rank purchase."
)

local ineligible =
    service:grant(
        9501,
        "Mend",
        20,
        {
            eligible = false,
        }
    )

check(
    ineligible.granted == 0,
    "ineligible contribution must grant zero."
)

local prod =
    service:set_for_test(
        9501,
        "Mend",
        "max",
        "PROD"
    )

check(
    prod.ok == false
        and prod.reason
            == "CommandDisabledInProd",
    "PROD test command must fail closed."
)

local test_result =
    service:set_for_test(
        9501,
        "Mend",
        0,
        "TEST"
    )

check(
    test_result.ok == true
        and test_result.new_value == 0,
    "TEST command must set proficiency for completed identity."
)

print(
    string.format(
        "[Proficiency Service Tests] PASS: %d assertions.",
        assertions
    )
)