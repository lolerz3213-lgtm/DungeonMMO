--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local module = Shared:FindFirstChild("UiStateRules")
if not module then
    error(
        "[Phase2A UI State Tests] RED: UiStateRules is missing."
    )
end
local Rules = require(module)

local assertions = 0


local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Phase2A UI State Tests] " .. message, 2)
    end
end


local base_ready = Rules.for_state("BaseReady", {})
check(
    base_ready.entry_enabled == true,
    "BaseReady must allow dungeon entry."
)

local teleporting = Rules.for_state("Teleporting", {})
check(
    teleporting.entry_enabled == false,
    "Teleporting must disable dungeon entry."
)

local revive = Rules.for_state("ReviveChoice", {
    free_available = true,
    paid_offer = {
        price = 9,
        live_enabled = false,
    },
})
check(
    revive.revive_action == "Free",
    "First death must expose Free as the single revive action."
)
check(
    revive.show_return_to_lobby == true,
    "Death UI must always expose Return to Lobby."
)
check(
    revive.force_view_lock_off == true,
    "First death must force View Lock off on the client."
)

local spectator = Rules.for_state("Spectating", {
    free_available = false,
    paid_offer = {
        price = 49,
        live_enabled = false,
    },
})
check(
    spectator.revive_action == "Paid",
    "After free revive use, the same revive action must become Paid."
)
check(
    spectator.paid_purchase_enabled == false,
    "Live paid purchase remains disabled in Phase 2A."
)
check(
    spectator.show_return_to_lobby == true,
    "Return to Lobby must remain available after free revive use."
)
check(
    spectator.force_view_lock_off == true,
    "Robux-revive death must force View Lock off on the client."
)
check(
    spectator.reward_promise == nil,
    "Spectating UI must not promise completion rewards."
)

local complete = Rules.for_state("Complete", {
    completion = {
        gold_granted = 50,
        item_id = "marauder_sword",
    },
    return_seconds = 60,
})
check(
    complete.show_completion == true
        and complete.return_seconds == 60,
    "Complete state must show summary and return countdown."
)
check(
    complete.force_view_lock_off == true,
    "Dungeon completion must force View Lock off on the client."
)

print(
    string.format(
        "[Phase2A UI State Tests] PASS: %d assertions.",
        assertions
    )
)
