--!strict
local CompletionService = {}
CompletionService.__index = CompletionService

local function result(ok: boolean, reason: string?, extra: any?): any
    local out = extra or {}
    out.ok = ok
    out.reason = reason
    return out
end

function CompletionService.new(session_service: any, reward_service: any, profile_service: any, reward_definition: any): any
    assert(session_service and reward_service and profile_service, "CompletionService dependencies are required")
    local self = setmetatable({}, CompletionService)
    self._sessions = session_service
    self._rewards = reward_service
    self._profiles = profile_service
    self._reward_definition = reward_definition
    return self
end

function CompletionService:commit(session_id: string): any
    local session = self._sessions:get(session_id)
    if not session then return result(false, "SessionNotFound") end
    if session.State ~= "Complete" then return result(false, "SessionNotComplete") end
    if session.CompletionRewardsCommitted == true then
        return result(true, nil, {
            already_applied = true,
            member_results = session.CompletionRewardSummary or {},
        })
    end

    local member_results: {[string]: any} = {}
    for _, user_id in ipairs(session.CompletionRecipients or {}) do
        local granted = self._rewards:grant_completion(session_id, 1, user_id, self._reward_definition)
        if not granted or granted.ok ~= true then
            return result(false, if granted then granted.reason else "RewardGrantFailed", {member_results = member_results})
        end
        member_results[tostring(user_id)] = granted
    end

    -- Save barrier: no return portal opens until every affected profile has persisted.
    for _, user_id in ipairs(session.CompletionRecipients or {}) do
        local saved, save_error = self._profiles:save(user_id, "DungeonCompletion")
        if not saved then
            return result(false, "ProfileSaveFailed", {
                save_user_id = user_id,
                save_error = save_error,
                member_results = member_results,
            })
        end
    end

    local committed = self._sessions:mark_completion_rewards_committed(session_id, member_results)
    if not committed or committed.ok ~= true then
        return result(false, if committed then committed.reason else "SessionCommitFailed", {member_results = member_results})
    end
    return result(true, nil, {already_applied = false, member_results = member_results})
end

return table.freeze(CompletionService)
