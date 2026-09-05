local MarauderSpacingRules = require(
    script.Parent.Parent:WaitForChild("MarauderSpacingRules")
)

local MIN_SEPARATION = 4.0

local function assert_equal(actual: any, expected: any, message: string)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function test_rejects_move_that_enters_personal_space()
    local current = Vector3.new(0, 0, 0)
    local candidate = Vector3.new(1, 0, 0)
    local others = {Vector3.new(4.5, 0, 0)}

    assert_equal(
        MarauderSpacingRules.is_position_allowed(
            current,
            candidate,
            others,
            MIN_SEPARATION
        ),
        false,
        "movement must not enter another Marauder's personal space"
    )
end

local function test_allows_overlap_recovery_when_clearance_increases()
    local current = Vector3.new(0, 0, 0)
    local candidate = Vector3.new(-0.6, 0, 0)
    local others = {Vector3.new(2.5, 0, 0)}

    assert_equal(
        MarauderSpacingRules.is_position_allowed(
            current,
            candidate,
            others,
            MIN_SEPARATION
        ),
        true,
        "an overlapped Marauder must be able to move away"
    )
end

local function test_candidate_movements_include_side_steps()
    local candidates = MarauderSpacingRules.get_movement_candidates(
        Vector3.new(0, 0, -1)
    )

    assert(#candidates >= 5, "spacing rules need direct plus multiple side-step candidates")
    assert(candidates[1] == Vector3.new(0, 0, -1), "direct chase movement must be considered first")

    local has_left = false
    local has_right = false
    for _, candidate in candidates do
        has_left = has_left or candidate.X < -0.1
        has_right = has_right or candidate.X > 0.1
    end

    assert(has_left and has_right, "candidate set must let Marauders route around either side")
end


test_rejects_move_that_enters_personal_space()
test_allows_overlap_recovery_when_clearance_increases()
test_candidate_movements_include_side_steps()

print("[Marauder Spacing Rules Tests] PASS")
