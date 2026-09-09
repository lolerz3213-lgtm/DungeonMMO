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
local EquipmentStatResolver = require(
    Shared:WaitForChild("EquipmentStatResolver")
)
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

local EFFECT_KEYS = table.freeze({
    "PhysicalDamageBonus",
    "MaxHealthFlat",
    "CriticalChanceBonus",
})

--[[
Builds a stable rejected-action result.

Args:
    reason (string): Stable rejection reason.

Returns:
    any: Rejected result payload.
]]
local function rejected(reason: string): any
    return {
        ok = false,
        reason = reason,
    }
end

--[[
Returns the account-selected character from a profile table.

Args:
    profile (any): Loaded persistent profile.

Returns:
    any?: Selected character table, or nil when profile shape is invalid.
]]
local function selected_character(profile: any): any?
    if type(profile) ~= "table"
        or type(profile.Account) ~= "table"
        or type(profile.Characters) ~= "table"
    then
        return nil
    end

    local selected = math.floor(
        tonumber(profile.Account.SelectedCharacterSlot) or 1
    )

    return profile.Characters["Slot" .. tostring(selected)]
end

--[[
Ensures a character has a mutable Equipment table.

Args:
    character (any): Persistent character table.

Returns:
    any: Mutable Equipment table owned by the character.
]]
local function ensure_equipment(character: any): any
    if type(character.Equipment) ~= "table" then
        character.Equipment = {}
    end

    return character.Equipment
end

--[[
Sanitizes the supported effect fields for client snapshot display.

Args:
    resolved (any): Resolver result or nil.

Returns:
    any: Dense display-safe effect summary with numeric values.
]]
local function effect_summary(resolved: any): any
    local result = {}

    for _, key in ipairs(EFFECT_KEYS) do
        local value = resolved and resolved[key]
        result[key] = if type(value) == "number" then value else 0
    end

    return result
end

--[[
Calculates a display-only difference between two resolved effect summaries.

Args:
    after (any): Candidate resolved effects.
    before (any): Current resolved effects.

Returns:
    any: Dense candidate-minus-current effect summary.
]]
local function effect_delta(after: any, before: any): any
    local result = {}

    for _, key in ipairs(EFFECT_KEYS) do
        result[key] = (tonumber(after[key]) or 0)
            - (tonumber(before[key]) or 0)
    end

    return result
end

--[[
Copies only valid persistent item IDs from the six canonical slots.

Args:
    equipment (any): Character Equipment table.

Returns:
    any: Sanitized slot-to-item snapshot.
]]
local function copy_slots(equipment: any): any
    local source = if type(equipment) == "table" then equipment else {}
    local slots = {}

    for _, slot in ipairs(EquipmentSlots.ORDER) do
        local item_id = source[slot]

        if type(item_id) == "string" then
            slots[slot] = item_id
        end
    end

    return slots
end

--[[
Counts owned equipment items without consuming or mutating Inventory.

Args:
    inventory (any): Persistent Inventory array.

Returns:
    any: Item-ID-to-quantity map containing equipment items only.
]]
local function collect_equipment_totals(inventory: any): any
    local totals = {}

    if type(inventory) ~= "table" then
        return totals
    end

    for _, entry in ipairs(inventory) do
        if type(entry) == "table" and type(entry.ItemId) == "string" then
            local definition = ItemDefinitions.get(entry.ItemId)

            if definition and definition.Kind == "Equipment" then
                local quantity = math.max(
                    0,
                    math.floor(tonumber(entry.Quantity) or 1)
                )

                totals[entry.ItemId] = (totals[entry.ItemId] or 0)
                    + quantity
            end
        end
    end

    return totals
end

--[[
Builds one owned-item row with server-computed current/candidate effects.

Args:
    character (any): Persistent character used for eligibility checks.
    source_equipment (any): Current persistent Equipment table.
    equipped_effects (any): Sanitized current effect summary.
    item_id (string): Owned equipment item ID.
    quantity (number): Owned quantity.

Returns:
    any?: Sanitized owned-item row, or nil for an unknown definition.
]]
local function build_owned_entry(
    character: any,
    source_equipment: any,
    equipped_effects: any,
    item_id: string,
    quantity: number
): any?
    local definition = ItemDefinitions.get(item_id)

    if not definition then
        return nil
    end

    local eligibility = EquipmentRules.validate(
        character,
        definition,
        definition.Slot
    )
    local item_equipment = {
        [definition.Slot] = item_id,
    }
    local item_effects = effect_summary(
        EquipmentStatResolver.resolve(item_equipment)
    )
    local candidate_equipment = EquipmentStatResolver.with_slot(
        source_equipment,
        definition.Slot,
        item_id
    )
    local preview_effects = effect_summary(
        EquipmentStatResolver.resolve(candidate_equipment)
    )

    return {
        ItemId = item_id,
        Name = definition.Name,
        Quantity = quantity,
        Slot = definition.Slot,
        Category = definition.Category,
        Eligible = eligibility.ok == true,
        Reason = eligibility.reason,
        TestOnly = definition.TestOnly == true,
        Effects = item_effects,
        PreviewEffects = preview_effects,
        DeltaEffects = effect_delta(preview_effects, equipped_effects),
    }
end

--[[
Sorts owned Equipment rows by canonical slot order and display name.

Args:
    owned (any): Mutable owned-item array.

Returns:
    None.
]]
local function sort_owned(owned: any)
    table.sort(owned, function(left: any, right: any): boolean
        local left_index = SLOT_ORDER[left.Slot] or 999
        local right_index = SLOT_ORDER[right.Slot] or 999

        if left_index ~= right_index then
            return left_index < right_index
        end

        return tostring(left.Name) < tostring(right.Name)
    end)
end

--[[
Validates the latest profile state inside an equip mutation.

Args:
    profile (any): Profile passed by ProfileService.mutate.
    definition (any): Requested equipment definition.
    item_id (string): Requested item ID.
    slot (string): Requested canonical slot.

Returns:
    string?: Stable failure reason, or nil when mutation may proceed.
]]
local function equip_mutation_reason(
    profile: any,
    definition: any,
    item_id: string,
    slot: string
): string?
    local character = selected_character(profile)

    if not character then
        return "ProfileNotLoaded"
    end

    local validation = EquipmentRules.validate(
        character,
        definition,
        slot
    )

    if not validation.ok then
        return validation.reason or "EquipmentRejected"
    end

    if InventoryService.count_item(character, item_id) < 1 then
        return "ItemNotOwned"
    end

    return nil
end

--[[
Creates a server-authoritative EquipmentService for one runtime context.

Args:
    profile_service (any): Loaded ProfileService dependency.
    context (string?): Runtime context; defaults to Base.

Returns:
    any: EquipmentService instance.
]]
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

--[[
Rejects mutation attempts outside Base.

Args:
    None.

Returns:
    any?: Rejection payload in non-Base contexts, otherwise nil.
]]
function EquipmentService:_base_only(): any?
    if self._context ~= "Base" then
        return rejected("BaseOnlyAction")
    end

    return nil
end

--[[
Builds the authoritative sanitized Equipment snapshot for UI/runtime display.

Args:
    user_id (number): Player user ID whose loaded character is inspected.

Returns:
    any: Slot, owned-item and server-resolved effect snapshot.
]]
function EquipmentService:build_snapshot(user_id: number): any
    local character = self._profiles:get_character(user_id, 1)

    if not character then
        return {
            ok = false,
            reason = "ProfileNotLoaded",
            Slots = {},
            Owned = {},
            EquippedEffects = effect_summary(nil),
        }
    end

    local source_equipment = if type(character.Equipment) == "table"
        then character.Equipment
        else {}
    local equipped_effects = effect_summary(
        EquipmentStatResolver.resolve(source_equipment)
    )
    local totals = collect_equipment_totals(character.Inventory)
    local owned = {}

    for item_id, quantity in pairs(totals) do
        if quantity > 0 then
            local row = build_owned_entry(
                character,
                source_equipment,
                equipped_effects,
                item_id,
                quantity
            )

            if row then
                table.insert(owned, row)
            end
        end
    end

    sort_owned(owned)

    return {
        ok = true,
        Slots = copy_slots(source_equipment),
        Owned = owned,
        EquippedEffects = equipped_effects,
    }
end

--[[
Equips one owned eligible item into its canonical Base-only slot.

Args:
    user_id (number): Player user ID whose profile is mutated.
    item_id (string): Stable equipment item ID.
    slot (string): Requested canonical slot.

Returns:
    any: Accepted result or stable rejection payload.
]]
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

    local validation = EquipmentRules.validate(current, definition, slot)

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
            failure_reason = equip_mutation_reason(
                profile,
                definition,
                item_id,
                slot
            )

            if failure_reason then
                error(failure_reason)
            end

            local character = assert(selected_character(profile))
            ensure_equipment(character)[slot] = item_id
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

--[[
Unequips one canonical slot in Base without consuming Inventory.

Args:
    user_id (number): Player user ID whose profile is mutated.
    slot (string): Canonical slot to clear.

Returns:
    any: Accepted result or stable rejection payload.
]]
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

            ensure_equipment(character)[slot] = nil
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
