--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("CompletionRewardPresentation")
if not module then
    error("[Completion Reward Presentation Tests] RED: CompletionRewardPresentation is missing.")
end

local Presentation = require(module)
local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Completion Reward Presentation Tests] " .. message, 2)
    end
end

local fresh = Presentation.text({
    gold_granted = 50,
    item_id = "marauder_sword",
    arc_slash_book = {
        ok = true,
        already_applied = false,
        item_id = "arc_slash_book_bound",
    },
})
check(string.find(fresh, "50", 1, true) ~= nil, "gold must be shown.")
check(string.find(fresh, "marauder_sword", 1, true) ~= nil, "personal loot must be shown.")
check(string.find(fresh, "Arc Slash Skill Book", 1, true) ~= nil, "new Skill Book must be shown.")

local existing = Presentation.text({
    gold_granted = 50,
    item_id = nil,
    arc_slash_book = {ok = true, already_applied = true},
})
check(string.find(existing, "Arc Slash Skill Book", 1, true) == nil, "already-applied book must not be shown as newly awarded.")

print(string.format("[Completion Reward Presentation Tests] PASS: %d assertions.", assertions))
