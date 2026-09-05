--!strict
-- Maps persistent checkpoint IDs to local CFrames and enforces monotonic activation.
local CheckpointService = {}
CheckpointService.__index = CheckpointService

function CheckpointService.new(session_service: any, session_id: string): any
    assert(session_service ~= nil, "CheckpointService requires DungeonSessionService")
    assert(type(session_id) == "string" and session_id ~= "", "CheckpointService requires SessionId")
    local self = setmetatable({}, CheckpointService)
    self._sessions = session_service
    self._session_id = session_id
    self._registry = {}
    return self
end

function CheckpointService:register(checkpoint_id: string, sequence: number, cframe: CFrame)
    assert(type(checkpoint_id) == "string" and checkpoint_id ~= "", "checkpoint_id is required")
    assert(type(sequence) == "number" and sequence >= 0 and sequence % 1 == 0, "checkpoint sequence must be a non-negative integer")
    assert(typeof(cframe) == "CFrame", "checkpoint cframe is required")
    self._registry[checkpoint_id] = {Id = checkpoint_id, Sequence = sequence, CFrame = cframe}
end

function CheckpointService:activate(checkpoint_id: string): any
    local target = self._registry[checkpoint_id]
    if not target then
        return {ok = false, reason = "UnknownCheckpoint"}
    end
    local session = self._sessions:get(self._session_id)
    if not session or not session.Checkpoint then
        return {ok = false, reason = "SessionNotFound"}
    end
    if target.Sequence < session.Checkpoint.Sequence then
        return {ok = false, reason = "CheckpointRegression"}
    end
    return self._sessions:activate_checkpoint(self._session_id, target.Id, target.Sequence)
end

function CheckpointService:get_active_checkpoint(): any
    local session = self._sessions:get(self._session_id)
    local checkpoint_id = if session and session.Checkpoint then session.Checkpoint.Id else "Entrance"
    local record = self._registry[checkpoint_id] or self._registry.Entrance
    if not record then
        error("CheckpointService requires an Entrance checkpoint registration")
    end
    return {Id = record.Id, Sequence = record.Sequence, CFrame = record.CFrame}
end

return table.freeze(CheckpointService)
