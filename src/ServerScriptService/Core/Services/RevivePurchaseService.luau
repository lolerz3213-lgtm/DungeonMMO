--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReviveConfig = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ReviveConfig")
)

local RevivePurchaseService = {}
RevivePurchaseService.__index = RevivePurchaseService

local function operation(ok: boolean, reason: string?, extra: any?): any
    local out = extra or {}
    out.ok = ok
    out.reason = reason
    return out
end

function RevivePurchaseService.new(session_service: any, options: any?): any
    assert(session_service ~= nil, "RevivePurchaseService requires DungeonSessionService")
    local config = options or {}
    local self = setmetatable({}, RevivePurchaseService)
    self._sessions = session_service
    self._is_studio = config.is_studio == true
    self._purchase_id_factory = config.purchase_id_factory or function()
        return "StudioRevive:" .. HttpService:GenerateGUID(false)
    end
    self._on_granted = config.on_granted
    return self
end

function RevivePurchaseService:get_current_offer(session: any, user_id: number): any?
    if type(session) ~= "table" or session.State ~= "Active" or type(session.Members) ~= "table" then
        return nil
    end
    local member = session.Members[tostring(user_id)]
    if not member or member.FreeReviveUsed ~= true then
        return nil
    end
    local paid_number = (member.PaidReviveCount or 0) + 1
    local price = ReviveConfig.PAID_PRICES[paid_number] or ReviveConfig.PAID_PRICE_5_PLUS
    return {
        paid_number = paid_number,
        price = price,
        live_enabled = ReviveConfig.LIVE_PAID_REVIVES_ENABLED == true,
    }
end

function RevivePurchaseService:grant_revive_once(purchase_id: string, user_id: number, session_id: string): any
    if type(purchase_id) ~= "string" or purchase_id == "" then
        return operation(false, "InvalidPurchaseId")
    end
    local granted = self._sessions:grant_paid_revive_once(session_id, user_id, purchase_id)
    if not granted or granted.ok ~= true then
        return operation(false, if granted then granted.reason else "ReviveGrantFailed", {session = if granted then granted.session else nil})
    end

    if granted.already_applied ~= true and self._on_granted then
        self._on_granted(user_id, session_id)
    end
    return operation(true, nil, {
        already_applied = granted.already_applied == true,
        session = granted.session,
    })
end

function RevivePurchaseService:simulate_approved_purchase(user_id: number, session_id: string): any
    if not self._is_studio then
        return operation(false, "StudioOnly")
    end
    return self:grant_revive_once(self._purchase_id_factory(), user_id, session_id)
end

function RevivePurchaseService:process_receipt(receipt_info: any): Enum.ProductPurchaseDecision
    -- Live Phase 2A paid-revive products intentionally remain disabled until TEST receipt validation.
    if ReviveConfig.LIVE_PAID_REVIVES_ENABLED ~= true then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- No live Developer Product IDs are configured in this phase.
    if type(receipt_info) ~= "table" then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

return table.freeze(RevivePurchaseService)
