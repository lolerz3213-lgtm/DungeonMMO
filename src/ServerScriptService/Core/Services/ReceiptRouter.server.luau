--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local RevivePurchaseRegistry = require(script.Parent:WaitForChild("RevivePurchaseRegistry"))

MarketplaceService.ProcessReceipt = function(receipt_info)
    local service = RevivePurchaseRegistry.get()
    if not service then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    return service:process_receipt(receipt_info)
end
