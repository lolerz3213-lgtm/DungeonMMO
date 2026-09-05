--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Core"):WaitForChild("Services")
local coordinator_module = Services:FindFirstChild("TeleportCoordinator")
if not coordinator_module then
    error("[Teleport Coordinator Tests] RED: TeleportCoordinator is missing.")
end
local TeleportCoordinator = require(coordinator_module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Teleport Coordinator Tests] " .. message, 2)
    end
end

local calls = {}
local fake_adapter: any = {}
function fake_adapter:reserve_server(place_id: number)
    table.insert(calls, "ReserveServerAsync")
    return true, "reserved-code-1"
end
function fake_adapter:teleport(_place_id: number, _players: {any}, _reserved_code: string?, teleport_data: any)
    table.insert(calls, "TeleportAsync")
    self.last_teleport_data = teleport_data
    return true, nil
end
function fake_adapter:connect_init_failed(_handler: (...any) -> ())
    return nil
end

local fake_profile: any = {}
function fake_profile:save(_user_id: number, _reason: string)
    table.insert(calls, "SaveProfile")
    return true, nil
end

local fake_lease: any = {}
function fake_lease:begin_handoff(_user_id: number, _nonce: string, _destination: string)
    table.insert(calls, "BeginHandoff")
    return {ok = true}
end
function fake_lease:cancel_handoff(_user_id: number, _nonce: string)
    table.insert(calls, "CancelHandoff")
    return {ok = true}
end

local fake_sessions: any = {}
function fake_sessions:get_for_user(_user_id: number) return nil end
function fake_sessions:create(dungeon_id: string, member_ids: {number}, return_place_id: number, reserved_code: string)
    table.insert(calls, "CreateSession")
    return {
        SessionId = "session-a",
        DungeonId = dungeon_id,
        MemberUserIds = member_ids,
        ReturnPlaceId = return_place_id,
        ReservedAccessCode = reserved_code,
        State = "Creating",
        Members = { ["42"] = {UserId = 42, Connected = false, Mode = "Active"} },
    }, nil
end
function fake_sessions:set_handoff_nonce(_session_id: string, _user_id: number, _nonce: string)
    table.insert(calls, "SetHandoffNonce")
    return {ok = true}
end
function fake_sessions:mark_failed(_session_id: string, _reason: string)
    table.insert(calls, "MarkFailed")
    return {ok = true}
end

local coordinator = TeleportCoordinator.new(fake_adapter, fake_profile, fake_lease, fake_sessions)
local player: any = {UserId = 42}
local result = coordinator:start_dungeon({player}, "TestDungeon", 987654)
check(result.ok == true, "Valid solo dungeon start must initiate teleport.")
local expected = {"ReserveServerAsync", "CreateSession", "SaveProfile", "BeginHandoff", "SetHandoffNonce", "TeleportAsync"}
for index, name in ipairs(expected) do
    check(calls[index] == name, string.format("Call %d must be %s, got %s", index, name, tostring(calls[index])))
end
local teleport_data = fake_adapter.last_teleport_data
check(teleport_data.SessionId == "session-a" and teleport_data.DungeonId == "TestDungeon", "TeleportData must contain routing IDs.")
check(teleport_data.Gold == nil and teleport_data.XP == nil and teleport_data.Inventory == nil, "TeleportData must never contain persistent value data.")
check(teleport_data.ReviveCount == nil and teleport_data.Loot == nil and teleport_data.Eligible == nil, "TeleportData must never contain reward/revive authority.")
check(coordinator:is_pending(42) == true, "Successful outbound teleport remains pending until the player leaves or destination claims.")

local failed_calls = {}
local failing_adapter: any = {}
function failing_adapter:reserve_server(_place_id: number)
    table.insert(failed_calls, "ReserveServerAsync")
    return true, "reserved-fail"
end
function failing_adapter:teleport(_place_id: number, _players: {any}, _reserved_code: string?, _teleport_data: any)
    table.insert(failed_calls, "TeleportAsync")
    return false, "ForcedTeleportFailure"
end
function failing_adapter:connect_init_failed(_handler: (...any) -> ()) return nil end
local failing_profile: any = {}
function failing_profile:save(_user_id: number, _reason: string) return true, nil end
local failing_lease: any = {cancelled = false}
function failing_lease:begin_handoff(_user_id: number, _nonce: string, _destination: string) return {ok = true} end
function failing_lease:cancel_handoff(_user_id: number, _nonce: string)
    self.cancelled = true
    return {ok = true}
end
local failing_sessions: any = {}
function failing_sessions:get_for_user(_user_id: number) return nil end
function failing_sessions:create(dungeon_id: string, members: {number}, return_place_id: number, code: string)
    return {SessionId="session-fail", DungeonId=dungeon_id, MemberUserIds=members, ReturnPlaceId=return_place_id, ReservedAccessCode=code, State="Creating", Members={["42"]={UserId=42}}}, nil
end
function failing_sessions:set_handoff_nonce(_session_id: string, _user_id: number, _nonce: string) return {ok = true} end
function failing_sessions:mark_failed(_session_id: string, _reason: string) self.failed = true return {ok = true} end

local failing = TeleportCoordinator.new(failing_adapter, failing_profile, failing_lease, failing_sessions)
local failed = failing:start_dungeon({player}, "TestDungeon", 987654)
check(failed.ok == false, "Synchronous TeleportAsync failure must be reported.")
check(failing_lease.cancelled == true, "Failed outbound teleport must cancel the source handoff.")
check(failing_sessions.failed == true, "Failed fresh outbound teleport must fail its newly-created session.")
check(failing:is_pending(42) == false, "Failed outbound teleport must restore source runtime availability.")

print(string.format("[Teleport Coordinator Tests] PASS: %d assertions.", assertions))
