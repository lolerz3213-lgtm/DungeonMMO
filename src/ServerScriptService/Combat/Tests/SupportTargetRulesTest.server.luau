--!strict
local ServerScriptService =
    game:GetService("ServerScriptService")

local combat_folder =
    ServerScriptService:WaitForChild("Combat")
local SupportTargetRules = require(
    combat_folder:WaitForChild(
        "SupportTargetRules"
    )
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Support Target Rules Tests] "
                .. message,
            2
        )
    end
end

local function candidate(
    key: string,
    is_self: boolean,
    distance: number,
    health: number,
    max_health: number,
    aim_dot: number?,
    line_of_sight: boolean?
): any
    return {
        key = key,
        is_self = is_self,
        distance = distance,
        health = health,
        max_health = max_health,
        aim_dot = aim_dot,
        line_of_sight = line_of_sight,
    }
end

local mend_self =
    SupportTargetRules.choose_mend_target({
        candidate(
            "self",
            true,
            0,
            40,
            100,
            1,
            true
        ),
        candidate(
            "ally",
            false,
            5,
            10,
            100,
            1,
            true
        ),
    }, 12)

check(
    mend_self == "self",
    "Mend must be self-only even when an injured ally is nearby."
)

local mend_full =
    SupportTargetRules.choose_mend_target({
        candidate(
            "self",
            true,
            0,
            100,
            100,
            1,
            true
        ),
        candidate(
            "ally",
            false,
            5,
            10,
            100,
            1,
            true
        ),
    }, 12)

check(
    mend_full == nil,
    "Mend must reject a full-health caster instead of healing an ally."
)

local aimed =
    SupportTargetRules.choose_aimed_or_self({
        candidate(
            "self",
            true,
            0,
            50,
            100,
            1,
            true
        ),
        candidate(
            "ally_a",
            false,
            8,
            40,
            100,
            0.91,
            true
        ),
        candidate(
            "ally_b",
            false,
            10,
            30,
            100,
            0.98,
            true
        ),
    }, 22, true, 0.85)

check(
    aimed == "ally_b",
    "Mage support must choose the valid ally closest to the caster aim."
)

local blocked =
    SupportTargetRules.choose_aimed_or_self({
        candidate(
            "self",
            true,
            0,
            50,
            100,
            1,
            true
        ),
        candidate(
            "ally",
            false,
            6,
            20,
            100,
            0.99,
            false
        ),
    }, 22, true, 0.85)

check(
    blocked == "self",
    "Blocked aimed ally must fall back to the caster."
)

local off_aim =
    SupportTargetRules.choose_aimed_or_self({
        candidate(
            "self",
            true,
            0,
            50,
            100,
            1,
            true
        ),
        candidate(
            "ally",
            false,
            6,
            20,
            100,
            0.2,
            true
        ),
    }, 22, true, 0.85)

check(
    off_aim == "self",
    "Off-aim ally must not steal a self cast."
)

local full_self_with_aimed_ally =
    SupportTargetRules.choose_aimed_or_self({
        candidate(
            "self",
            true,
            0,
            100,
            100,
            1,
            true
        ),
        candidate(
            "ally",
            false,
            6,
            20,
            100,
            0.99,
            true
        ),
    }, 22, true, 0.85)

check(
    full_self_with_aimed_ally == "ally",
    "Aimed injured ally must remain valid when caster is full."
)

print(
    string.format(
        "[Support Target Rules Tests] PASS: %d assertions.",
        assertions
    )
)
