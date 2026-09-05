local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local module = shared_folder:FindFirstChild("MendPresentationRules")

if not module then
    error("[Mend Presentation Rules Tests] RED: MendPresentationRules is missing.")
end

local MendPresentationRules = require(module)
local assertion_count = 0


local function assert_true(condition: boolean, message: string)
    assertion_count += 1

    if not condition then
        error("[Mend Presentation Rules Tests] " .. message, 2)
    end
end


assert_true(
    MendPresentationRules.ATTRIBUTE_RECEIVING == "MendReceiving",
    "Receiving attribute contract changed unexpectedly."
)
assert_true(
    MendPresentationRules.ATTRIBUTE_PULSE_SERIAL == "MendPulseSerial",
    "Pulse serial attribute contract changed unexpectedly."
)
assert_true(
    MendPresentationRules.ATTRIBUTE_SOURCE_USER_ID == "MendSourceUserId",
    "Source-user attribute contract changed unexpectedly."
)
assert_true(
    MendPresentationRules.get_root_transform() ~= CFrame.identity,
    "Mend kneel must move the root from the normal pose."
)
assert_true(
    MendPresentationRules.get_right_hip_transform() ~= CFrame.identity,
    "Mend kneel must bend the right leg."
)
assert_true(
    MendPresentationRules.get_right_knee_transform() ~= CFrame.identity,
    "Mend kneel must bend the right knee."
)

print(
    string.format(
        "[Mend Presentation Rules Tests] PASS: %d assertions.",
        assertion_count
    )
)
