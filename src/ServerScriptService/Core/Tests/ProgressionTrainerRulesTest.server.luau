--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Rules = require(
    Shared:WaitForChild(
        "ProgressionTrainerRules"
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
            "[Progression Trainer Rules Tests] "
                .. message,
            2
        )
    end
end

local human_snapshot = {
    Attributes = {
        Strength = 5,
        Dexterity = 4,
        Vitality = 6,
        Intellect = 5,
        Spirit = 5,
    },

    AttributeBaseline = {
        Strength = 5,
        Dexterity = 4,
        Vitality = 6,
        Intellect = 5,
        Spirit = 5,
    },

    APAvailable = 4,
}

local human_preview =
    Rules.create_attribute_preview(
        human_snapshot
    )

check(
    human_preview.Strength == 5
        and human_preview.Dexterity == 4
        and human_preview.Vitality == 6
        and human_preview.Intellect == 5
        and human_preview.Spirit == 5,
    "Human preview must preserve racial values below/above neutral 5."
)

check(
    Rules.pending_attribute_spend(
        human_snapshot,
        human_preview
    ) == 0,
    "racial baseline preview must start with zero pending spend."
)

human_preview.Dexterity = 5

check(
    Rules.pending_attribute_spend(
        human_snapshot,
        human_preview
    ) == 1,
    "Human Dexterity 4 to 5 preview must cost one pending AP."
)

human_preview.Vitality = 5

check(
    Rules.pending_attribute_spend(
        human_snapshot,
        human_preview
    ) == 1,
    "trainer preview must clamp Human Vitality to racial baseline 6."
)

check(
    Rules.can_add_attribute_point(
        human_snapshot,
        human_preview
    ) == true,
    "trainer may continue while pending spend is below AP available."
)

local elf_snapshot = {
    Attributes = {
        Strength = 5,
        Dexterity = 6,
        Vitality = 4,
        Intellect = 5,
        Spirit = 5,
    },

    AttributeBaseline = {
        Strength = 5,
        Dexterity = 6,
        Vitality = 4,
        Intellect = 5,
        Spirit = 5,
    },

    APAvailable = 4,
}

local elf_preview =
    Rules.create_attribute_preview(
        elf_snapshot
    )

check(
    elf_preview.Dexterity == 6
        and elf_preview.Vitality == 4,
    "Elf preview must preserve 6 DEX and 4 VIT baseline."
)

elf_preview.Dexterity = 8

check(
    Rules.pending_attribute_spend(
        elf_snapshot,
        elf_preview
    ) == 2,
    "Elf Dexterity 6 to 8 preview must cost two AP."
)

local allocated_snapshot = {
    Attributes = {
        Strength = 9,
        Dexterity = 6,
        Vitality = 7,
        Intellect = 5,
        Spirit = 8,
    },

    AttributeBaseline = {
        Strength = 5,
        Dexterity = 4,
        Vitality = 6,
        Intellect = 5,
        Spirit = 5,
    },

    APAvailable = 4,
}

local allocated_preview =
    Rules.create_attribute_preview(
        allocated_snapshot
    )

check(
    allocated_preview.Strength == 9
        and allocated_preview.Dexterity == 6
        and allocated_preview.Vitality == 7
        and allocated_preview.Intellect == 5
        and allocated_preview.Spirit == 8,
    "preview reset must use authoritative current attributes."
)

allocated_preview.Strength += 1
allocated_preview.Spirit += 2

check(
    Rules.pending_attribute_spend(
        allocated_snapshot,
        allocated_preview
    ) == 3,
    "pending spend must compare against current allocated values."
)

check(
    Rules.can_add_attribute_point(
        allocated_snapshot,
        allocated_preview
    ) == true,
    "three pending AP must fit inside four available AP."
)

allocated_preview.Vitality += 1

check(
    Rules.can_add_attribute_point(
        allocated_snapshot,
        allocated_preview
    ) == false,
    "trainer must stop when all four available AP are pending."
)

print(
    string.format(
        "[Progression Trainer Rules Tests] PASS: %d assertions.",
        assertions
    )
)