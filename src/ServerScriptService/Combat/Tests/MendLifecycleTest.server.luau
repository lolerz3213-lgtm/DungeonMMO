local MendService = require(
    script.Parent.Parent:WaitForChild("MendService")
)

local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Mend Lifecycle Tests] " .. message, 2)
    end
end


assert_true(
    type(MendService.cancel_channels_for_target) == "function",
    "Mend must be able to cancel channels immediately when a recipient dies."
)

print(
    string.format(
        "[Mend Lifecycle Tests] PASS: %d assertions.",
        assertion_count
    )
)
