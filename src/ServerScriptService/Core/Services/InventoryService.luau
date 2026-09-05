--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ItemDefinitions=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ItemDefinitions"))
local InventoryService={}; InventoryService.__index=InventoryService
local function valid_quantity(q:any):boolean return type(q)=="number" and q==q and q>0 and q<math.huge and q%1==0 end
local function count_item(inv:{any},item_id:string):number local total=0 for _,e in ipairs(inv) do if type(e)=="table" and e.ItemId==item_id then total+=(if type(e.Quantity)=="number" then e.Quantity else 0) end end return total end
function InventoryService.count_item(character:any,item_id:string):number return if type(character)=="table" and type(character.Inventory)=="table" then count_item(character.Inventory,item_id) else 0 end
function InventoryService.apply_item_to_character(character:any,item_id:string,quantity:number?):any
    local amount=quantity or 1; if type(item_id)~="string" or item_id=="" then return {ok=false,reason="InvalidItemId"} end
    if not valid_quantity(amount) then return {ok=false,reason="InvalidQuantity"} end
    local def=ItemDefinitions.get(item_id); if not def then return {ok=false,reason="UnknownItem"} end
    if type(character)~="table" then return {ok=false,reason="InvalidCharacter"} end; if type(character.Inventory)~="table" then character.Inventory={} end
    if def.Stackable==true then
        local target=nil; for _,e in ipairs(character.Inventory) do if type(e)=="table" and e.ItemId==item_id then target=e break end end
        if target then target.Quantity=(if type(target.Quantity)=="number" then target.Quantity else 0)+amount else table.insert(character.Inventory,{ItemId=item_id,Quantity=amount}) end
    else for _=1,amount do table.insert(character.Inventory,{ItemId=item_id,Quantity=1}) end end
    return {ok=true,item_id=item_id,quantity_added=amount,total_quantity=count_item(character.Inventory,item_id)}
end
function InventoryService.apply_remove_from_character(character:any,item_id:string,quantity:number?):any
    local amount=quantity or 1; if not valid_quantity(amount) then return {ok=false,reason="InvalidQuantity"} end
    if type(character)~="table" or type(character.Inventory)~="table" then return {ok=false,reason="ItemNotOwned"} end
    if count_item(character.Inventory,item_id)<amount then return {ok=false,reason="ItemNotOwned"} end
    local remaining=amount
    for i=#character.Inventory,1,-1 do
        local e=character.Inventory[i]
        if remaining>0 and type(e)=="table" and e.ItemId==item_id then
            local q=if type(e.Quantity)=="number" then e.Quantity else 1
            local take=math.min(q,remaining); q-=take; remaining-=take
            if q<=0 then table.remove(character.Inventory,i) else e.Quantity=q end
        end
    end
    return {ok=true,item_id=item_id,quantity_removed=amount,total_quantity=count_item(character.Inventory,item_id)}
end
function InventoryService.new(profile_service:any):any assert(profile_service); return setmetatable({_profiles=profile_service},InventoryService) end
function InventoryService:add_item(user_id:number,item_id:string,quantity:number?):any
    local amount=quantity or 1; if not ItemDefinitions.get(item_id) then return {ok=false,reason="UnknownItem"} end
    local result:any=nil; local ok,err=self._profiles:mutate(user_id,function(profile:any) local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; result=InventoryService.apply_item_to_character(c,item_id,amount); if not result.ok then error(result.reason) end end)
    return if ok then result else {ok=false,reason=err or "ProfileMutationFailed"}
end
function InventoryService:consume_item(user_id:number,item_id:string,quantity:number?):any
    local result:any=nil; local ok,err=self._profiles:mutate(user_id,function(profile:any) local c=profile.Characters["Slot"..tostring(profile.Account.SelectedCharacterSlot)]; result=InventoryService.apply_remove_from_character(c,item_id,quantity); if not result.ok then error(result.reason) end end)
    return if ok then result else {ok=false,reason=err or "ProfileMutationFailed"}
end
return table.freeze(InventoryService)
