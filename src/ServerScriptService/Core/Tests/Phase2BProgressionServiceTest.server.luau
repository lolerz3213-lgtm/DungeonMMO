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

local Core = ServerScriptService
    :WaitForChild("Core")

local Adapters =
    Core:WaitForChild("Adapters")

local Services =
    Core:WaitForChild("Services")

local ProgressionConfig = require(
    Shared:WaitForChild(
        "ProgressionConfig"
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

local ProgressionService = require(
    Services:WaitForChild(
        "ProgressionService"
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
            "[Phase 2B Progression Service Tests] "
                .. message,
            2
        )
    end
end

-- ------------------------------------------------------------
-- Exact Level 20 config contract
-- ------------------------------------------------------------

check(
    ProgressionConfig.MAX_LEVEL == 20,
    "maximum level must be 20."
)

local expected_xp = {
    [10] = 1100,
    [11] = 1325,
    [12] = 1575,
    [13] = 1850,
    [14] = 2150,
    [15] = 2475,
    [16] = 2825,
    [17] = 3200,
    [18] = 3600,
    [19] = 4025,
}

for level = 10, 19 do
    check(
        ProgressionConfig.get_required_xp(level)
            == expected_xp[level],
        string.format(
            "Level %d threshold must be exactly %d.",
            level,
            expected_xp[level]
        )
    )
end

check(
    ProgressionConfig.get_required_xp(20)
        == nil,
    "Level 20 must not have a next-level threshold."
)

check(
    ProgressionConfig.level_entitlement(20)
        == 19,
    "Level 20 entitlement must be exactly 19."
)

-- Existing early thresholds remain unchanged.

check(
    ProgressionConfig.get_required_xp(1)
        == 100,
    "Level 1 threshold must remain 100."
)

check(
    ProgressionConfig.get_required_xp(9)
        == 900,
    "Level 9 threshold must remain 900."
)

-- ------------------------------------------------------------
-- Normal persistent progression
-- ------------------------------------------------------------

local profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

local loaded, load_error =
    profiles:load(9101)

check(
    loaded ~= nil
        and load_error == nil,
    "primary progression profile must load."
)

local progression =
    ProgressionService.new(profiles)

local first_level =
    progression:grant_xp(
        9101,
        100
    )

local character = assert(
    profiles:get_character(
        9101,
        1
    )
)

check(
    first_level.ok == true
        and character.Level == 2,
    "100 XP from Level 1 must reach Level 2."
)

check(
    character
        .Progression
        .AttributePointEntitlement
        == 1
        and character
            .Progression
            .SkillPointEntitlement
            == 1,
    "Level 2 must grant exactly one AP/SP entitlement."
)

-- ------------------------------------------------------------
-- Exact 10 -> 11 threshold
-- ------------------------------------------------------------

local ten_to_eleven = {
    Level = 10,
    XP = 0,

    Progression = {
        AttributePointEntitlement = 9,
        SkillPointEntitlement = 9,
    },
}

local exact_10_to_11 =
    ProgressionService.apply_xp_to_character(
        ten_to_eleven,
        1100
    )

check(
    exact_10_to_11.ok == true
        and ten_to_eleven.Level == 11
        and ten_to_eleven.XP == 0,
    "1100 XP must move Level 10 exactly to Level 11."
)

check(
    ten_to_eleven
        .Progression
        .AttributePointEntitlement
        == 10
        and ten_to_eleven
            .Progression
            .SkillPointEntitlement
            == 10,
    "Level 11 entitlement must become 10/10."
)

-- ------------------------------------------------------------
-- Multi-level carry
--
-- 10 -> 11 = 1100
-- 11 -> 12 = 1325
-- plus 50 carried XP
-- total = 2475
-- ------------------------------------------------------------

local multi_level = {
    Level = 10,
    XP = 0,

    Progression = {
        AttributePointEntitlement = 9,
        SkillPointEntitlement = 9,
    },
}

local multi_result =
    ProgressionService.apply_xp_to_character(
        multi_level,
        2475
    )

check(
    multi_result.ok == true
        and multi_result.levels_gained == 2
        and multi_level.Level == 12,
    "2475 XP from Level 10 must cross exactly two levels."
)

check(
    multi_level.XP == 50
        and multi_result.carried_xp == 50,
    "multi-level grant must carry the remaining 50 XP."
)

check(
    multi_level
        .Progression
        .AttributePointEntitlement
        == 11
        and multi_level
            .Progression
            .SkillPointEntitlement
            == 11,
    "Level 12 entitlement must become 11/11."
)

-- ------------------------------------------------------------
-- Huge grant must stop at Level 20
-- ------------------------------------------------------------

local huge =
    progression:grant_xp(
        9101,
        1000000
    )

character = assert(
    profiles:get_character(
        9101,
        1
    )
)

check(
    huge.ok == true
        and character.Level == 20,
    "huge XP grant must stop at Level 20."
)

check(
    character.XP == 0,
    "excess XP at Level 20 must be discarded."
)

check(
    character
        .Progression
        .AttributePointEntitlement
        == 19
        and character
            .Progression
            .SkillPointEntitlement
            == 19,
    "Level 20 entitlement must be exactly 19/19."
)

local entitlement_before_cap_grant =
    character
        .Progression
        .AttributePointEntitlement

local skill_entitlement_before_cap_grant =
    character
        .Progression
        .SkillPointEntitlement

local at_cap =
    ProgressionService.apply_xp_to_character(
        character,
        100
    )

check(
    at_cap.ok == true
        and at_cap.at_cap == true
        and at_cap.xp_granted == 0
        and character.Level == 20
        and character.XP == 0,
    "further XP at Level 20 must be discarded."
)

check(
    character
        .Progression
        .AttributePointEntitlement
        == entitlement_before_cap_grant
        and character
            .Progression
            .SkillPointEntitlement
            == skill_entitlement_before_cap_grant,
    "further grants at cap must not mint AP/SP."
)

-- ------------------------------------------------------------
-- DEV/TEST level tooling
-- ------------------------------------------------------------

local debug_profiles =
    ProfileService.new(
        InMemoryProfileAdapter.new()
    )

local debug_loaded, debug_load_error =
    debug_profiles:load(9102)

check(
    debug_loaded ~= nil
        and debug_load_error == nil,
    "debug progression profile must load."
)

local debug_progression =
    ProgressionService.new(
        debug_profiles
    )

local notifications = 0
local notified_level = 0

debug_progression:set_change_callback(
    function(user_id: number)
        notifications += 1

        notified_level = assert(
            debug_profiles:get_character(
                user_id,
                1
            )
        ).Level
    end
)

local dev_level =
    debug_progression:set_level_for_test(
        9102,
        4,
        "DEV"
    )

local debug_character = assert(
    debug_profiles:get_character(
        9102,
        1
    )
)

check(
    dev_level.ok == true
        and debug_character.Level == 4
        and debug_character.XP == 0,
    "DEV level command must set an exact level."
)

check(
    debug_character
        .Progression
        .AttributePointEntitlement
        == 3
        and debug_character
            .Progression
            .SkillPointEntitlement
            == 3,
    "DEV level command must synchronize AP/SP entitlement."
)

check(
    notifications == 1
        and notified_level == 4,
    "successful level mutation must notify after state change."
)

local dev_cap =
    debug_progression:set_level_for_test(
        9102,
        20,
        "DEV"
    )

debug_character = assert(
    debug_profiles:get_character(
        9102,
        1
    )
)

check(
    dev_cap.ok == true
        and debug_character.Level == 20
        and debug_character.XP == 0,
    "DEV level command must support the new Level 20 cap."
)

check(
    debug_character
        .Progression
        .AttributePointEntitlement
        == 19
        and debug_character
            .Progression
            .SkillPointEntitlement
            == 19,
    "DEV Level 20 must synchronize entitlement to 19/19."
)

check(
    notifications == 2
        and notified_level == 20,
    "DEV Level 20 mutation must notify exactly once."
)

local prod_level =
    debug_progression:set_level_for_test(
        9102,
        10,
        "PROD"
    )

check(
    prod_level.ok == false
        and prod_level.reason
            == "DebugCommandDisabled",
    "level debug command must fail closed in PROD."
)

check(
    notifications == 2,
    "rejected PROD mutation must not notify."
)

local invalid_level =
    debug_progression:set_level_for_test(
        9102,
        21,
        "DEV"
    )

check(
    invalid_level.ok == false,
    "Level 21 debug mutation must reject."
)

check(
    notifications == 2,
    "invalid Level 21 mutation must not notify."
)

local xp_result =
    debug_progression:grant_xp(
        9102,
        1
    )

check(
    xp_result.ok == true,
    "XP grant at cap must return a valid result."
)

check(
    notifications == 3,
    "successful XP request must still notify."
)

debug_character = assert(
    debug_profiles:get_character(
        9102,
        1
    )
)

check(
    debug_character.Level == 20
        and debug_character.XP == 0
        and debug_character
            .Progression
            .AttributePointEntitlement
            == 19
        and debug_character
            .Progression
            .SkillPointEntitlement
            == 19,
    "cap XP request must leave Level 20 state unchanged."
)

print(
    string.format(
        "[Phase 2B Progression Service Tests] PASS: %d assertions.",
        assertions
    )
)