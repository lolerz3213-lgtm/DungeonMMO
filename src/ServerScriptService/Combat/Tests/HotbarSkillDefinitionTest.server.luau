local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local hotbar_module = shared_folder:FindFirstChild("HotbarConfig")
local skill_module = shared_folder:FindFirstChild("SkillDefinitions")

if not hotbar_module then
    error("[Hotbar Skill Tests] RED: HotbarConfig is missing.")
end

if not skill_module then
    error("[Hotbar Skill Tests] RED: SkillDefinitions is missing.")
end

local HotbarConfig = require(hotbar_module)
local SkillDefinitions = require(skill_module)

local assertion_count = 0


--[[
Raises an error when one hotbar/skill assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Hotbar Skill Tests] " .. message, 2)
    end
end


assert_true(
    HotbarConfig.SLOT_COUNT == 8,
    "Hotbar must expose exactly eight active-skill slots."
)

local expected_keys = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
}

for slot = 1, HotbarConfig.SLOT_COUNT do
    assert_true(
        HotbarConfig.get_default_key(slot) == expected_keys[slot],
        string.format("Slot %d has the wrong default keyboard key.", slot)
    )
    assert_true(
        HotbarConfig.get_action_name(slot)
            == string.format("SkillSlot%d", slot),
        string.format("Slot %d has the wrong logical action name.", slot)
    )
end

assert_true(
    HotbarConfig.get_skill_for_slot(1) == "ShieldBash",
    "Prototype Slot 1 must equip Shield Bash."
)
assert_true(
    HotbarConfig.get_skill_for_slot(2) == "Mend",
    "Prototype Slot 2 must equip Mend."
)
assert_true(
    HotbarConfig.get_default_gamepad_key(1) == Enum.KeyCode.ButtonR1,
    "Prototype Slot 1 must expose the accepted RB controller binding."
)

local shield_bash = SkillDefinitions.get("ShieldBash")

assert_true(shield_bash ~= nil, "Shield Bash definition is missing.")
assert_true(
    shield_bash.ID == "ShieldBash",
    "Shield Bash skill id is wrong."
)
assert_true(
    shield_bash.STAMINA_COST == 20,
    "Shield Bash must cost 20 Stamina."
)
assert_true(
    shield_bash.COOLDOWN_SECONDS == 4.0,
    "Shield Bash cooldown must be 4.0 seconds."
)
assert_true(
    shield_bash.WIND_UP_SECONDS == 0.16,
    "Shield Bash wind-up must be 0.16 seconds."
)
assert_true(
    shield_bash.REACH_STUDS == 6.0,
    "Shield Bash reach must be 6 studs."
)
assert_true(
    shield_bash.HITBOX.ARC_DEGREES == nil,
    "Shield Bash arc belongs on the skill definition, not HITBOX."
)
assert_true(
    shield_bash.ARC_DEGREES
        == require(shared_folder:WaitForChild("CombatConfig"))
            .DEFENSE.BLOCK_ARC_DEGREES,
    "Shield Bash must use the same frontal cone as blocking."
)
assert_true(
    shield_bash.BASE_DAMAGE
        < require(shared_folder:WaitForChild("CombatConfig"))
            .PROTOTYPE_WEAPON.BASE_DAMAGE,
    "Shield Bash health damage must remain below a normal sword hit."
)
assert_true(
    shield_bash.STAGGER_SECONDS > 0,
    "Shield Bash must apply positive stagger duration."
)
assert_true(
    SkillDefinitions.is_valid("ShieldBash"),
    "Shield Bash must be recognised as a valid skill."
)
local mend = SkillDefinitions.get("Mend")

assert_true(mend ~= nil, "Mend definition is missing.")
assert_true(mend.ID == "Mend", "Mend skill id is wrong.")
assert_true(mend.KIND == "Support", "Mend must be a support skill.")
assert_true(mend.STAMINA_COST == 0, "Mend must cost no Stamina in Phase 1.")
assert_true(mend.COOLDOWN_SECONDS == 8.0, "Mend cooldown must be 8 seconds.")
assert_true(mend.HEAL_AMOUNT == 25, "Mend must restore 25 HP total.")
assert_true(mend.CHANNEL_SECONDS == 2.0, "Mend must channel for 2 seconds.")
assert_true(mend.PULSE_COUNT == 5, "Mend must use five heal pulses.")
assert_true(mend.PULSE_HEAL == 5, "Mend pulse heal must be 5 HP.")
assert_true(mend.PULSE_INTERVAL_SECONDS == 0.4, "Mend pulse interval must be 0.4 seconds.")
assert_true(mend.RANGE_STUDS == 12, "Mend ally range must be 12 studs.")
assert_true(SkillDefinitions.is_valid("Mend"), "Mend must be a valid skill.")

assert_true(
    not SkillDefinitions.is_valid("UnknownSkill"),
    "Unknown skills must be rejected."
)

print(
    string.format(
        "[Hotbar Skill Tests] PASS: %d assertions.",
        assertion_count
    )
)
