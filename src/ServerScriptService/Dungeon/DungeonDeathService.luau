--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ReviveConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ReviveConfig")
)
local CombatConfig = require(
    ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Shared"):WaitForChild("CombatConfig")
)
local StaminaService = require(
    ServerScriptService:WaitForChild("Combat"):WaitForChild("StaminaService")
)

local DungeonDeathService = {}
DungeonDeathService.__index = DungeonDeathService

local function operation(ok: boolean, reason: string?, extra: any?): any
    local out = extra or {}
    out.ok = ok
    out.reason = reason
    return out
end

local function all_members_inactive(session: any): boolean
    local has_member = false
    for _, member in pairs(session.Members or {}) do
        has_member = true
        if member.Connected == true and member.Mode == "Active" then
            return false
        end
    end
    return has_member
end

local function default_safe_paid_cframe(death_cframe: CFrame, player: Player): CFrame?
    local character = player.Character
    local exclusions = {}
    if character then
        table.insert(exclusions, character)
    end
    local ray_params = RaycastParams.new()
    ray_params.FilterType = Enum.RaycastFilterType.Exclude
    ray_params.FilterDescendantsInstances = exclusions
    ray_params.RespectCanCollide = true

    local overlap_params = OverlapParams.new()
    overlap_params.FilterType = Enum.RaycastFilterType.Exclude
    overlap_params.FilterDescendantsInstances = exclusions
    overlap_params.RespectCanCollide = true

    local offsets = {
        Vector3.new(0, 0, 0), Vector3.new(4, 0, 0), Vector3.new(-4, 0, 0),
        Vector3.new(0, 0, 4), Vector3.new(0, 0, -4),
    }
    for _, offset in ipairs(offsets) do
        local origin = death_cframe.Position + offset + Vector3.new(0, 6, 0)
        local hit = Workspace:Raycast(origin, Vector3.new(0, -14, 0), ray_params)
        if hit then
            local candidate = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
            local blockers = Workspace:GetPartBoundsInBox(candidate, Vector3.new(2.5, 4, 2.5), overlap_params)
            local blocked = false
            for _, part in ipairs(blockers) do
                if part.CanCollide and part ~= hit.Instance then
                    blocked = true
                    break
                end
            end
            if not blocked then
                return candidate
            end
        end
    end
    return nil
end

local function default_spawn_player(player: Player, cframe: CFrame): boolean
    local old_character = player.Character
    player:LoadCharacter()
    local character = player.Character
    if not character or character == old_character then
        character = player.CharacterAdded:Wait()
    end
    character:PivotTo(cframe)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
    end
    StaminaService.reset_player(player)
    character:SetAttribute("CombatStamina", CombatConfig.STAMINA.MAX)
    return true
end

function DungeonDeathService.new(
    session_service: any,
    checkpoint_service: any,
    session_id: string,
    options: any?
): any
    assert(session_service ~= nil and checkpoint_service ~= nil, "DungeonDeathService dependencies are required")
    local config = options or {}
    local self = setmetatable({}, DungeonDeathService)
    self._sessions = session_service
    self._checkpoints = checkpoint_service
    self._session_id = session_id
    self._clock = config.clock or os.time
    self._spawn_player = config.spawn_player or default_spawn_player
    self._safe_paid_cframe = config.safe_paid_cframe or default_safe_paid_cframe
    self._emit_state = config.emit_state or function(_user_id: number, _payload: any) end
    self._paid_offer_provider = config.paid_offer_provider or function(_user_id: number) return nil end
    self._on_member_mode = config.on_member_mode or function(_user_id: number, _mode: string) end
    self._death_cframes = {}
    return self
end

function DungeonDeathService:_emit(user_id: number)
    local session = self._sessions:get(self._session_id)
    if not session then
        return
    end
    local member = session.Members[tostring(user_id)]
    if not member then
        return
    end
    self._emit_state(user_id, {
        session_state = session.State,
        member_mode = member.Mode,
        free_available = member.FreeReviveUsed ~= true and session.State == "Active",
        paid_offer = self._paid_offer_provider(user_id),
        wipe_ends_at = session.WipeDecisionEndsAt,
    })
end

function DungeonDeathService:_refresh_wipe_state(): any
    local session = self._sessions:get(self._session_id)
    if not session or session.State ~= "Active" then
        return operation(false, "SessionNotActive")
    end
    if all_members_inactive(session) then
        if type(session.WipeDecisionEndsAt) ~= "number" then
            local deadline = self._clock() + ReviveConfig.WIPE_DECISION_SECONDS
            local set_result = self._sessions:set_wipe_deadline(self._session_id, deadline)
            if not set_result.ok then
                return set_result
            end
        end
    elseif session.WipeDecisionEndsAt ~= nil then
        self._sessions:set_wipe_deadline(self._session_id, nil)
    end
    return operation(true, nil)
end

function DungeonDeathService:on_player_died(player: any, death_cframe: CFrame): any
    local session = self._sessions:get(self._session_id)
    if not session or session.State ~= "Active" then
        return operation(false, "SessionNotActive")
    end
    local member = session.Members[tostring(player.UserId)]
    if not member then
        return operation(false, "NotMember")
    end
    self._death_cframes[player.UserId] = death_cframe
    local mode = if member.FreeReviveUsed == true then "Spectating" else "Dead"
    local changed = self._sessions:set_member_mode(self._session_id, player.UserId, mode)
    if not changed.ok then
        return changed
    end
    self._on_member_mode(player.UserId, mode)
    self:_refresh_wipe_state()
    self:_emit(player.UserId)
    return operation(true, nil, {session = self._sessions:get(self._session_id)})
end

function DungeonDeathService:request_free_revive(player: any): any
    local result = self._sessions:consume_free_revive(self._session_id, player.UserId)
    if not result.ok then
        self:_emit(player.UserId)
        return result
    end
    local checkpoint = self._checkpoints:get_active_checkpoint()
    local spawned = self._spawn_player(player, checkpoint.CFrame)
    if not spawned then
        self._sessions:set_member_mode(self._session_id, player.UserId, "Spectating")
        self._on_member_mode(player.UserId, "Spectating")
        return operation(false, "RespawnFailed", {session = result.session})
    end
    self._on_member_mode(player.UserId, "Active")
    self:_refresh_wipe_state()
    self:_emit(player.UserId)
    return operation(true, nil, {session = self._sessions:get(self._session_id), checkpoint = checkpoint})
end

function DungeonDeathService:request_paid_revive(player: any): any
    local session = self._sessions:get(self._session_id)
    if not session or session.State ~= "Active" then
        return operation(false, "SessionNotActive")
    end
    local member = session.Members[tostring(player.UserId)]
    if not member then
        return operation(false, "NotMember")
    end
    if member.FreeReviveUsed ~= true then
        return operation(false, "FreeReviveStillAvailable")
    end
    if member.Mode ~= "Dead" and member.Mode ~= "Spectating" then
        return operation(false, "MemberNotDead")
    end
    local offer = self._paid_offer_provider(player.UserId)
    if not offer then
        return operation(false, "PaidOfferUnavailable")
    end
    return operation(false, "PaidPurchaseRequired", {paid_offer = offer})
end

function DungeonDeathService:complete_paid_revive(player: any): any
    -- Paid/Robux revives use the same latest-checkpoint destination as free revives.
    -- Payment changes availability/count, never positional advantage.
    local checkpoint = self._checkpoints:get_active_checkpoint()
    local target = checkpoint.CFrame
    local spawned = self._spawn_player(player, target)
    if not spawned then
        self._sessions:set_member_mode(self._session_id, player.UserId, "Spectating")
        self._on_member_mode(player.UserId, "Spectating")
        return operation(false, "RespawnFailed")
    end
    self._on_member_mode(player.UserId, "Active")
    self:_refresh_wipe_state()
    self:_emit(player.UserId)
    return operation(true, nil, {cframe = target, checkpoint = checkpoint})
end

function DungeonDeathService:tick(now: number?): any
    local tick_now = now or self._clock()
    local session = self._sessions:get(self._session_id)
    if not session or session.State ~= "Active" then
        return {failed = session and session.State == "Failed" or false}
    end
    local deadline = session.WipeDecisionEndsAt
    if type(deadline) == "number" and tick_now >= deadline and all_members_inactive(session) then
        local failed = self._sessions:mark_failed(self._session_id, "WipeReviveTimeout")
        for _, member in pairs(session.Members) do
            self:_emit(member.UserId)
        end
        return {failed = failed.ok == true, reason = failed.reason}
    end
    return {failed = false}
end

return table.freeze(DungeonDeathService)
