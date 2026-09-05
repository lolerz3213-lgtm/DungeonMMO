--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local Services = Core:WaitForChild("Services")
local module = Services:FindFirstChild("RevivePurchaseService")
if not module then
    error("[Revive Purchase Tests] RED: RevivePurchaseService is missing.")
end
local RevivePurchaseService = require(module)

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Revive Purchase Tests] " .. message, 2)
    end
end

local session = {
    SessionId = "session-paid",
    State = "Active",
    Members = {
        ["101"] = {UserId = 101, Connected = true, Mode = "Spectating", FreeReviveUsed = true, PaidReviveCount = 0},
    },
}
local processed = {}
local fake_sessions: any = {}
function fake_sessions:get(session_id: string): any
    return if session_id == session.SessionId then session else nil
end
function fake_sessions:grant_paid_revive_once(session_id: string, user_id: number, purchase_id: string): any
    if session_id ~= session.SessionId then return {ok = false, reason = "SessionNotFound"} end
    if session.State ~= "Active" then return {ok = false, reason = "InvalidTransition", session = session} end
    local member = session.Members[tostring(user_id)]
    if not member then return {ok = false, reason = "NotMember", session = session} end
    if member.Mode ~= "Spectating" and member.Mode ~= "Dead" then return {ok = false, reason = "MemberNotDead", session = session} end
    if processed[purchase_id] then return {ok = true, already_applied = true, session = session} end
    processed[purchase_id] = true
    member.PaidReviveCount += 1
    member.Mode = "Active"
    return {ok = true, already_applied = false, session = session}
end

local grants = 0
local service = RevivePurchaseService.new(fake_sessions, {
    is_studio = true,
    purchase_id_factory = function() return "studio-purchase-1" end,
    on_granted = function(_user_id: number, _session_id: string)
        grants += 1
    end,
})

local expected_prices = {9, 49, 99, 199, 399, 399}
for index, price in ipairs(expected_prices) do
    session.Members["101"].PaidReviveCount = index - 1
    local offer = service:get_current_offer(session, 101)
    check(offer ~= nil and offer.price == price and offer.paid_number == index, "Paid tier " .. tostring(index) .. " must use expected price.")
end
session.Members["101"].PaidReviveCount = 0

local first = service:grant_revive_once("studio-purchase-1", 101, "session-paid")
check(first.ok == true and first.already_applied == false, "First approved purchase must grant exactly once.")
check(grants == 1 and session.Members["101"].PaidReviveCount == 1, "Approved purchase must increment paid revive count and invoke grant callback once.")

session.Members["101"].Mode = "Spectating"
local duplicate = service:grant_revive_once("studio-purchase-1", 101, "session-paid")
check(duplicate.ok == true and duplicate.already_applied == true, "Duplicate PurchaseId must be idempotent.")
check(grants == 1, "Duplicate PurchaseId must not invoke revive callback twice.")

local wrong_session = service:grant_revive_once("purchase-wrong-session", 101, "wrong")
check(wrong_session.ok == false, "Wrong SessionId must not grant a revive.")
session.Members["101"].Mode = "Active"
local not_spectating = service:grant_revive_once("purchase-active", 101, "session-paid")
check(not_spectating.ok == false, "Active player must not receive paid revive.")
session.Members["101"].Mode = "Spectating"
session.State = "Complete"
local complete = service:grant_revive_once("purchase-complete", 101, "session-paid")
check(complete.ok == false, "Complete session must not grant a revive.")

print(string.format("[Revive Purchase Tests] PASS: %d assertions.", assertions))
