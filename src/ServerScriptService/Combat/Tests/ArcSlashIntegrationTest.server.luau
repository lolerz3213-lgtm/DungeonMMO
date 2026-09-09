--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SkillDefinitions = require(
    ReplicatedStorage
        :WaitForChild("Combat")
        :WaitForChild("Shared")
        :WaitForChild("SkillDefinitions")
)
local ProgressionRuntimeState = require(
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")
        :WaitForChild("ProgressionRuntimeState")
)
local ProfileSchema = require(
    ReplicatedStorage
        :WaitForChild("Core")
        :WaitForChild("Shared")
        :WaitForChild("ProfileSchema")
)

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Arc Slash Integration Tests] " .. message, 2)
    end
end

local arc = SkillDefinitions.get("ArcSlash")
check(arc ~= nil, "Arc Slash combat definition must exist.")
check(
    arc.KIND == "Melee" and arc.ID == "ArcSlash",
    "Arc Slash must be a melee active skill."
)
check(
    arc.ARC_DEGREES >= 90 and arc.REACH_STUDS >= 6,
    "Arc Slash must be a frontal cleave with meaningful reach."
)

local character = ProfileSchema.create_default(501).Characters.Slot1
character.Equipment.Weapon = "marauder_sword"
character.Progression.Skills.ArcSlash = {
    Known = true,
    StarterGranted = false,
    PurchasedRank = 1,
    Proficiency = 0,
}
character.Progression.Loadout[3] = "ArcSlash"
ProgressionRuntimeState.set_character(501, character)
check(
    ProgressionRuntimeState.get_skill_rank(501, "ArcSlash") == 1,
    "Runtime state must expose purchased Arc Slash rank."
)

local usable, reason = ProgressionRuntimeState.is_skill_usable(
    501,
    "ArcSlash",
    {}
)
check(
    usable == true and reason == nil,
    "Purchased/equipped Arc Slash with equipped sword must be usable."
)

character.Equipment.Weapon = nil
ProgressionRuntimeState.set_character(501, character)
local wrong, wrong_reason = ProgressionRuntimeState.is_skill_usable(
    501,
    "ArcSlash",
    {OneHandedSword = true}
)
check(
    wrong == false and wrong_reason == "WrongWeapon",
    "Arc Slash must reject when authoritative Weapon is not a sword."
)

character.Equipment.Weapon = "marauder_sword"
character.Progression.Loadout[3] = nil
ProgressionRuntimeState.set_character(501, character)
local unequipped, unequipped_reason =
    ProgressionRuntimeState.is_skill_usable(
        501,
        "ArcSlash",
        {}
    )
check(
    unequipped == false and unequipped_reason == "SkillNotEquipped",
    "Known Arc Slash must still require an active loadout slot."
)

local rank1 = SkillDefinitions.get_for_rank("ArcSlash", 1)
local rank3 = SkillDefinitions.get_for_rank("ArcSlash", 3)
check(
    rank1 ~= nil
        and rank3 ~= nil
        and rank3.BASE_DAMAGE > rank1.BASE_DAMAGE,
    "Arc Slash rank values must come from server data and improve damage."
)

local mend1 = SkillDefinitions.get_for_rank("Mend", 1)
local mend3 = SkillDefinitions.get_for_rank("Mend", 3)
check(
    mend1 ~= nil
        and mend3 ~= nil
        and mend3.PULSE_HEAL > mend1.PULSE_HEAL,
    "Mend ranks must improve server-owned healing."
)

local bash1 = SkillDefinitions.get_for_rank("ShieldBash", 1)
local bash3 = SkillDefinitions.get_for_rank("ShieldBash", 3)
check(
    bash1 ~= nil
        and bash3 ~= nil
        and bash3.BASE_DAMAGE > bash1.BASE_DAMAGE,
    "Shield Bash ranks must improve server-owned effectiveness."
)

ProgressionRuntimeState.clear_character(501)

print(string.format(
    "[Arc Slash Integration Tests] PASS: %d assertions.",
    assertions
))
