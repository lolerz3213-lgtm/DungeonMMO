--!strict
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
local ServerScriptService =
    game:GetService("ServerScriptService")

local SkillDefinitions = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("SkillDefinitions")
)
local MageHealService = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("MageHealService")
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Mage Heal Service Tests] "
                .. message,
            2
        )
    end
end

local definition =
    assert(
        SkillDefinitions.get_for_rank(
            "MageHeal",
            1
        )
    )

local human_instant,
    human_hot,
    human_seconds =
        MageHealService.get_delivery(
            "Human",
            40,
            definition
        )

check(
    math.abs(human_instant - 32) < 0.001
        and math.abs(human_hot - 8) < 0.001,
    "Human Mage Heal must be mostly upfront."
)
check(
    human_seconds == 4,
    "Human residual heal must use the shorter four-second delivery."
)

local elf_instant,
    elf_hot,
    elf_seconds =
        MageHealService.get_delivery(
            "Elf",
            40,
            definition
        )

check(
    math.abs(elf_instant - 12) < 0.001
        and math.abs(elf_hot - 28) < 0.001,
    "Elf Mage Heal must deliver most healing over time."
)
check(
    elf_seconds == 6,
    "Elf heal-over-time must use the longer six-second delivery."
)
check(
    math.abs(
        human_instant
            + human_hot
            - elf_instant
            - elf_hot
    ) < 0.001,
    "Human and Elf variants must have equal baseline total healing."
)

print(
    string.format(
        "[Mage Heal Service Tests] PASS: %d assertions.",
        assertions
    )
)
