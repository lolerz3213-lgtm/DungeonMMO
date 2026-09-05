local MarauderSpacingRules = require(
    script.Parent.Parent:WaitForChild("MarauderSpacingRules")
)

local function assert_equal(actual: any, expected: any, message: string)
    assert(
        actual == expected,
        string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual))
    )
end

local ordinary = MarauderSpacingRules.get_candidate_order(7, nil)
assert_equal(ordinary[1], 1, "direct movement must remain first without a commitment")
assert_equal(#ordinary, 7, "ordinary candidate order must preserve every candidate")

local committed = MarauderSpacingRules.get_candidate_order(7, 3)
assert_equal(committed[1], 3, "committed sidestep must be tried first")
assert_equal(committed[2], 1, "direct movement may be the first fallback after committed steering")
assert_equal(#committed, 7, "committed order must preserve every candidate")

local seen = {}
for _, candidate_index in committed do
    assert(not seen[candidate_index], "candidate order must not contain duplicates")
    seen[candidate_index] = true
end

print("[Marauder Steering Commit Tests] PASS")
