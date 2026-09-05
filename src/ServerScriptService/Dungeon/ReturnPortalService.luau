--!strict
local ReturnPortalService = {}
ReturnPortalService.__index = ReturnPortalService

local function result(ok: boolean, reason: string?, extra: any?): any
    local out = extra or {}
    out.ok = ok
    out.reason = reason
    return out
end

local function player_user_id(player: any): number?
    local user_id = player and player.UserId
    if type(user_id) ~= "number" or user_id <= 0 then
        return nil
    end
    return user_id
end

function ReturnPortalService.new(
    session_service: any,
    teleport_coordinator: any,
    options: any?
): any
    assert(
        session_service and teleport_coordinator,
        "ReturnPortalService dependencies are required"
    )
    local config = options or {}
    local self = setmetatable({}, ReturnPortalService)
    self._sessions = session_service
    self._coordinator = teleport_coordinator
    self._clock = config.clock or os.time
    self._is_studio = config.is_studio == true
    self._auto_return_seconds = config.auto_return_seconds or 60
    self._opened = {}
    return self
end

function ReturnPortalService:open(
    session_id: string,
    completion_result: any
): any
    local session = self._sessions:get(session_id)
    if not session then
        return result(false, "SessionNotFound")
    end
    if session.State ~= "Complete"
        or session.CompletionRewardsCommitted ~= true
    then
        return result(false, "CompletionNotCommitted")
    end
    local existing = self._opened[session_id]
    if existing then
        return result(true, nil, existing)
    end
    local opened = {
        opened_at = self._clock(),
        return_at = self._clock() + self._auto_return_seconds,
        completion_result = completion_result,
        auto_attempted = false,
    }
    self._opened[session_id] = opened
    return result(true, nil, opened)
end

function ReturnPortalService:get_state(session_id: string): any?
    return self._opened[session_id]
end

function ReturnPortalService:request_return(
    session_id: string,
    players: {any}
): any
    local opened = self._opened[session_id]
    if not opened then
        return result(false, "ReturnNotOpen")
    end
    local session = self._sessions:get(session_id)
    if not session
        or session.State ~= "Complete"
        or session.CompletionRewardsCommitted ~= true
    then
        return result(false, "CompletionNotCommitted")
    end
    if self._is_studio then
        return result(true, nil, {simulated = true})
    end
    local returned = self._coordinator:return_to_base(players, session)
    if not returned or returned.ok ~= true then
        return result(
            false,
            if returned then returned.reason else "ReturnTeleportFailed"
        )
    end
    return result(true, nil, {simulated = false, session = session})
end

function ReturnPortalService:request_abandon(
    session_id: string,
    players: {any}
): any
    if #players < 1 then
        return result(false, "NoPlayers")
    end

    for _, player in ipairs(players) do
        local user_id = player_user_id(player)
        if not user_id then
            return result(false, "InvalidPlayer")
        end
        local abandoned = self._sessions:abandon_member(
            session_id,
            user_id
        )
        if not abandoned.ok then
            return result(false, abandoned.reason)
        end
    end

    local session = self._sessions:get(session_id)
    if not session then
        return result(false, "SessionNotFound")
    end
    if self._is_studio then
        return result(true, nil, {
            simulated = true,
            session = session,
        })
    end

    local returned = self._coordinator:return_to_base(players, session)
    if not returned or returned.ok ~= true then
        return result(
            false,
            if returned then returned.reason else "ReturnTeleportFailed",
            {session = session}
        )
    end
    return result(true, nil, {
        simulated = false,
        session = session,
    })
end

function ReturnPortalService:tick(
    session_id: string,
    players: {any}
): any
    local opened = self._opened[session_id]
    if not opened
        or opened.auto_attempted == true
        or self._clock() < opened.return_at
    then
        return {triggered = false}
    end
    opened.auto_attempted = true
    local returned = self:request_return(session_id, players)
    return {triggered = true, result = returned}
end

return table.freeze(ReturnPortalService)
