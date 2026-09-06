--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local module = Shared:FindFirstChild("ProgressionTrainerRules")
if not module then
    error("[Progression Trainer Rules Tests] RED: ProgressionTrainerRules is missing.")
end
local Rules = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then error("[Progression Trainer Rules Tests] " .. message, 2) end
end

local snapshot = {
    Attributes = {Strength = 9, Dexterity = 6, Vitality = 7, Intellect = 5, Spirit = 8},
    APAvailable = 4,
}
local preview = Rules.create_attribute_preview(snapshot)
check(
    preview.Strength == 9
        and preview.Dexterity == 6
        and preview.Vitality == 7
        and preview.Intellect == 5
        and preview.Spirit == 8,
    "preview reset must use the supplied snapshot rather than stale prior state."
)
preview.Strength += 1
preview.Spirit += 2
check(Rules.pending_attribute_spend(snapshot, preview) == 3, "pending spend must compare the preview against the same authoritative snapshot.")
check(Rules.can_add_attribute_point(snapshot, preview) == true, "preview may spend while pending points remain below AP available.")
preview.Vitality += 1
check(Rules.can_add_attribute_point(snapshot, preview) == false, "preview must stop once all available AP are pending.")

print(string.format("[Progression Trainer Rules Tests] PASS: %d assertions.", assertions))
