--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileSchema = require(
    ReplicatedStorage
        :WaitForChild("Core")
        :WaitForChild("Shared")
        :WaitForChild("ProfileSchema")
)
local ProgressionRuntimeState = require(
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")
        :WaitForChild("ProgressionRuntimeState")
)

local assertions = 0
local user_id = 928402

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Weapon Requirement Tests] " .. message, 2)
    end
end

local character = ProfileSchema.create_default(user_id).Characters.Slot1
character.Identity.RaceId = "Human"
character.Identity.BaseClassId = "Fighter"
character.Identity.ClassId = "Fighter"
character.Identity.CreationStage = "Complete"
character.Progression.Skills.ArcSlash = {
    Known = true,
    StarterGranted = false,
    PurchasedRank = 1,
    Proficiency = 0,
}
character.Progression.Loadout[3] = "ArcSlash"

character.Equipment.Weapon = nil
ProgressionRuntimeState.set_character(user_id, character)
local fake_tool_usable, fake_tool_reason =
    ProgressionRuntimeState.is_skill_usable(
        user_id,
        "ArcSlash",
        {OneHandedSword = true}
    )
check(
    fake_tool_usable == false and fake_tool_reason == "WrongWeapon",
    "Tool/client-style tags must not grant Arc Slash without equipped sword"
)

character.Equipment.Weapon = "marauder_sword"
ProgressionRuntimeState.set_character(user_id, character)
local equipped_usable, equipped_reason =
    ProgressionRuntimeState.is_skill_usable(
        user_id,
        "ArcSlash",
        {}
    )
check(
    equipped_usable == true and equipped_reason == nil,
    "authoritative equipped sword must satisfy Arc Slash without Tool tags"
)

ProgressionRuntimeState.clear_character(user_id)

print(string.format(
    "[Equipment Weapon Requirement Tests] PASS: %d assertions.",
    assertions
))
