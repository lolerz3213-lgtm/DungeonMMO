--!strict

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Base =
    ServerScriptService:WaitForChild(
        "Base"
    )

local Core =
    ServerScriptService:WaitForChild(
        "Core"
    )

local Adapters =
    Core:WaitForChild("Adapters")

local Services =
    Core:WaitForChild("Services")

local BaseProgressionController = require(
    Base:WaitForChild(
        "BaseProgressionController"
    )
)

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

local InventoryService = require(
    Services:WaitForChild(
        "InventoryService"
    )
)

local AttributeService = require(
    Services:WaitForChild(
        "AttributeService"
    )
)

local LoadoutService = require(
    Services:WaitForChild(
        "LoadoutService"
    )
)

local SkillProgressionService = require(
    Services:WaitForChild(
        "SkillProgressionService"
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
            "[Base Progression Controller Tests] "
                .. message,
            2
        )
    end
end

local function make_controller(
    profiles: any,
    context: string
): (any, any)
    local inventory =
        InventoryService.new(
            profiles
        )

    local attributes =
        AttributeService.new(
            profiles
        )

    local loadout =
        LoadoutService.new(
            profiles
        )

    local skills =
        SkillProgressionService.new(
            profiles,
            inventory,
            loadout
        )

    local controller =
        BaseProgressionController.new({
            context = context,
            profiles = profiles,
            inventory = inventory,
            attributes = attributes,
            loadout = loadout,
            skills = skills,
        })

    return controller, inventory
end

-- ------------------------------------------------------------
-- Unresolved Base character
-- ------------------------------------------------------------

do
    local profiles =
        ProfileService.new(
            InMemoryProfileAdapter.new()
        )

    assert(profiles:load(6100))

    local controller =
        make_controller(
            profiles,
            "Base"
        )

    local snapshot =
        controller:build_snapshot(
            6100
        )

    check(
        snapshot
            .Identity
            .CreationStage
            == "RaceSelection",
        "fresh controller snapshot must remain unresolved."
    )

    local desired = {
        Strength = 5,
        Dexterity = 5,
        Vitality = 5,
        Intellect = 5,
        Spirit = 5,
    }

    local blocked_attribute =
        controller:commit_attributes(
            6100,
            desired
        )

    check(
        blocked_attribute.ok == false
            and blocked_attribute.reason
                == "IdentityIncomplete",
        "Base controller must block unresolved attribute commits."
    )

    check(
        controller:respec_attributes(
            6100
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved attribute respec."
    )

    check(
        controller:learn_skill(
            6100,
            "ArcSlash"
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved skill learning."
    )

    check(
        controller:purchase_rank(
            6100,
            "Mend"
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved rank purchase."
    )

    check(
        controller:respec_skills(
            6100
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved skill respec."
    )

    check(
        controller:set_loadout(
            6100,
            {}
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved loadout set."
    )

    check(
        controller:move_skill_to_slot(
            6100,
            "Mend",
            1
        ).reason == "IdentityIncomplete",
        "Base controller must block unresolved loadout move."
    )
end

-- ------------------------------------------------------------
-- Completed Human Fighter
-- ------------------------------------------------------------

local profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

assert(profiles:load(6101))

assert(
    profiles:mutate(
        6101,
        function(profile: any)
            local character =
                profile.Characters.Slot1

            character.Level = 10

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

            character
                .Progression
                .AttributePointEntitlement =
                9

            character
                .Progression
                .SkillPointEntitlement =
                9

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

local controller, inventory =
    make_controller(
        profiles,
        "Base"
    )

local snapshot =
    controller:build_snapshot(
        6101
    )

check(
    snapshot.Level == 10
        and snapshot.APAvailable == 9
        and snapshot.SPAvailable == 9,
    "completed Fighter snapshot must expose Level/AP/SP."
)

check(
    snapshot.Identity.RaceId
        == "Human"
        and snapshot.Identity.ClassId
            == "Fighter",
    "completed Fighter snapshot must expose identity."
)

local committed =
    controller:commit_attributes(
        6101,
        {
            Strength = 6,
            Dexterity = 4,
            Vitality = 6,
            Intellect = 5,
            Spirit = 5,
        }
    )

check(
    committed.ok == true
        and controller
            :build_snapshot(6101)
            .Attributes
            .Strength
            == 6,
    "Base controller must commit valid racial-baseline preview."
)

local invalid =
    controller:commit_attributes(
        6101,
        {
            Strength = 99,
            Dexterity = 4,
            Vitality = 6,
            Intellect = 5,
            Spirit = 5,
        }
    )

check(
    invalid.ok == false
        and controller
            :build_snapshot(6101)
            .Attributes
            .Strength
            == 6,
    "invalid attribute commit must preserve previous state."
)

local dungeon_controller =
    make_controller(
        profiles,
        "Dungeon"
    )

local rejected =
    dungeon_controller
        :respec_attributes(
            6101
        )

check(
    rejected.ok == false
        and rejected.reason
            == "BaseOnlyAction",
    "permanent progression mutation must reject outside Base."
)

check(
    inventory:add_item(
        6101,
        "arc_slash_book_bound",
        1
    ).ok,
    "test Arc Slash book must be granted."
)

local learned =
    controller:learn_skill(
        6101,
        "ArcSlash"
    )

check(
    learned.ok == true
        and controller
            :build_snapshot(6101)
            .Skills
            .ArcSlash
            .Rank
            == 1,
    "Fighter trainer must consume book and learn Arc Slash."
)

local changed =
    controller:set_loadout(
        6101,
        {
            "Mend",
            "ShieldBash",
            "ArcSlash",
        }
    )

check(
    changed.ok == true
        and controller
            :build_snapshot(6101)
            .Loadout[3]
            == "ArcSlash",
    "Base controller must accept valid loadout changes."
)

local moved =
    controller:move_skill_to_slot(
        6101,
        "Mend",
        3
    )

local moved_snapshot =
    controller:build_snapshot(
        6101
    )

check(
    moved.ok == true
        and moved_snapshot.Loadout[3]
            == "Mend"
        and moved_snapshot.Loadout[1]
            == false,
    "controller move must relocate selected skill."
)

local gap =
    controller:move_skill_to_slot(
        6101,
        "ShieldBash",
        6
    )

local gap_snapshot =
    controller:build_snapshot(
        6101
    )

check(
    gap.ok == true
        and gap_snapshot.Loadout[6]
            == "ShieldBash",
    "last slot must remain exact."
)

for slot = 1, 6 do
    check(
        gap_snapshot.Loadout[slot]
            ~= nil,
        "wire snapshot must contain every slot."
    )
end

check(
    gap_snapshot.Loadout[1] == false
        and gap_snapshot.Loadout[2]
            == false
        and gap_snapshot.Loadout[3]
            == "Mend",
    "wire gaps must remain explicit."
)

print(
    string.format(
        "[Base Progression Controller Tests] PASS: %d assertions.",
        assertions
    )
)