--!strict
-- ProcessReceipt is global per server. DungeonRuntime registers the active revive service here.
local RevivePurchaseRegistry = {}
local active_service: any = nil

function RevivePurchaseRegistry.set(service: any?)
    active_service = service
end

function RevivePurchaseRegistry.get(): any?
    return active_service
end

return table.freeze(RevivePurchaseRegistry)
