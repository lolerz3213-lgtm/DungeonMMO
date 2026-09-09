--!strict
-- Server-authoritative persistent equipment service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local EquipmentSlots = require(Shared:WaitForChild("EquipmentSlots"))
local EquipmentRules = require(Shared:WaitForChild("EquipmentRules"))
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))
local CharacterIdentityRules = require(
    Shared:WaitForChild("CharacterIdentityRules")
)
local InventoryService = require(Services:WaitForChild("InventoryService"))

local EquipmentService = {}
EquipmentService.__index = EquipmentService

local SLOT_ORDER = {}
for index, slot in ipairs(EquipmentSlots.ORDER) do
    SLOT_ORDER[slot] = index
end

local function rejected(reason: string): any
    return {
        ok = false,
        reason = reason,
    }
end

local function selected_character(profile: any): any?
    if (
        type(profile) ~= "table"
        or type(profile.Account) ~= "table"
        or type(profile.Characters) ~= "table"
    ) then
        return nil
    end

    local selected = math.floor(
        tonumber(profile.Account.SelectedCharacterSlot) or 1
    )

    return profile.Characters["Slot" .. tostring(selected)]
end

local function ensure_equipment(character: any): any
    if type(character.Equipment) ~= "table" then
        character.Equipment = {}
    end

    return character.Equipment
end

function EquipmentService.new(
    profile_service: any,
    context: string?
): any
    assert(
        profile_service ~= nil,
        "EquipmentService requires ProfileService"
    )

    return setmetatable({
        _profiles = profile_service,
        _context = context or "Base",
    }, EquipmentService)
end

function EquipmentService:_base_only(): any?
    if self._context ~= "Base" then
        return rejected("BaseOnlyAction")
    end

    return nil
end

function EquipmentService:build_snapshot(user_id: number): any
    local character = self._profiles:get_character(user_id, 1)

    if not character then
        return {
            ok = false,
            reason = "ProfileNotLoaded",
            Slots = {},
            Owned = {},
        }
    end

    local slots = {}
    local source_equipment = if type(character.Equipment) == "table"
        then character.Equipment
        else {}

    for _, slot in ipairs(EquipmentSlots.ORDER) do
        local item_id = source_equipment[slot]
        if type(item_id) == "string" then
            slots[slot] = item_id
        end
    end

    local totals = {}

    if type(character.Inventory) == "table" then
        for _, entry in ipairs(character.Inventory) do
            if (
                type(entry) == "table"
                and type(entry.ItemId) == "string"
            ) then
                local definition = ItemDefinitions.get(entry.ItemId)

                if definition and definition.Kind == "Equipment" then
                    local quantity = math.max(
                        0,
                        math.floor(tonumber(entry.Quantity) or 1)
                    )

                    totals[entry.ItemId] = (
                        totals[entry.ItemId] or 0
                    ) + quantity
                end
            end
        end
    end

    local owned = {}

    for item_id, quantity in pairs(totals) do
        if quantity > 0 then
            local definition = ItemDefinitions.get(item_id)

            if definition then
                local eligibility = EquipmentRules.validate(
                    character,
                    definition,
                    definition.Slot
                )

                table.insert(owned, {
                    ItemId = item_id,
                    Name = definition.Name,
                    Quantity = quantity,
                    Slot = definition.Slot,
                    Category = definition.Category,
                    Eligible = eligibility.ok == true,
                    Reason = eligibility.reason,
                    TestOnly = definition.TestOnly == true,
                })
            end
        end
    end

    table.sort(owned, function(left: any, right: any): boolean
        local left_index = SLOT_ORDER[left.Slot] or 999
        local right_index = SLOT_ORDER[right.Slot] or 999

        if left_index ~= right_index then
            return left_index < right_index
        end

        return tostring(left.Name) < tostring(right.Name)
    end)

    return {
        ok = true,
        Slots = slots,
        Owned = owned,
    }
end

function EquipmentService:equip(
    user_id: number,
    item_id: string,
    slot: string
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    if not EquipmentSlots.is_valid(slot) then
        return rejected("UnknownEquipmentSlot")
    end

    local definition = ItemDefinitions.get(item_id)

    if not definition then
        return rejected("UnknownItem")
    end

    if definition.Kind ~= "Equipment" then
        return rejected("NotEquipment")
    end

    local current = self._profiles:get_character(user_id, 1)

    if not current then
        return rejected("ProfileNotLoaded")
    end

    local validation = EquipmentRules.validate(
        current,
        definition,
        slot
    )

    if not validation.ok then
        return validation
    end

    if InventoryService.count_item(current, item_id) < 1 then
        return rejected("ItemNotOwned")
    end

    local failure_reason: string? = nil

    local ok, mutation_error = self._profiles:mutate(
        user_id,
        function(profile: any)
            local character = selected_character(profile)

            if not character then
                failure_reason = "ProfileNotLoaded"
                error(failure_reason)
            end

            local latest_validation = EquipmentRules.validate(
                character,
                definition,
                slot
            )

            if not latest_validation.ok then
                failure_reason = latest_validation.reason
                error(failure_reason or "EquipmentRejected")
            end

            if InventoryService.count_item(character, item_id) < 1 then
                failure_reason = "ItemNotOwned"
                error(failure_reason)
            end

            local equipment = ensure_equipment(character)
            equipment[slot] = item_id
        end
    )

    if not ok then
        return rejected(
            failure_reason
                or mutation_error
                or "ProfileMutationFailed"
        )
    end

    return {
        ok = true,
        slot = slot,
        item_id = item_id,
    }
end

function EquipmentService:unequip(
    user_id: number,
    slot: string
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    if not EquipmentSlots.is_valid(slot) then
        return rejected("UnknownEquipmentSlot")
    end

    local current = self._profiles:get_character(user_id, 1)

    if not current then
        return rejected("ProfileNotLoaded")
    end

    if not CharacterIdentityRules.is_complete(current) then
        return rejected("IdentityIncomplete")
    end

    local ok, mutation_error = self._profiles:mutate(
        user_id,
        function(profile: any)
            local character = selected_character(profile)

            if not character then
                error("ProfileNotLoaded")
            end

            local equipment = ensure_equipment(character)
            equipment[slot] = nil
        end
    )

    if not ok then
        return rejected(mutation_error or "ProfileMutationFailed")
    end

    return {
        ok = true,
        slot = slot,
        item_id = nil,
    }
end

return table.freeze(EquipmentService)
