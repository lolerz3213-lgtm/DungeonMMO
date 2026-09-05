--!strict
-- Pure UI state projection for functional Phase 2A Base/Dungeon interfaces.
local UiStateRules = {}

function UiStateRules.for_state(state_name: string, payload: any?): any
    local data = payload or {}
    local paid_offer = data.paid_offer
    local free_available = data.free_available == true
    local death_state = state_name == "ReviveChoice"
        or state_name == "Spectating"
    local paid_available = death_state
        and not free_available
        and type(paid_offer) == "table"
    local revive_action = nil
    if death_state and free_available then
        revive_action = "Free"
    elseif paid_available then
        revive_action = "Paid"
    end

    return {
        state = state_name,
        entry_enabled = state_name == "BaseReady",
        show_objective = state_name == "DungeonActive"
            or state_name == "Boss"
            or state_name == "Checkpoint",
        show_boss = state_name == "Boss",
        show_revive = death_state,
        force_view_lock_off = death_state or state_name == "Complete",
        revive_action = revive_action,
        show_return_to_lobby = death_state,
        paid_purchase_enabled = paid_available
            and paid_offer.live_enabled == true,
        paid_price = if type(paid_offer) == "table"
            then paid_offer.price
            else nil,
        show_completion = state_name == "Complete",
        completion = data.completion,
        return_seconds = data.return_seconds,
        show_failure = state_name == "Failure",
        reward_promise = nil,
    }
end

return table.freeze(UiStateRules)
