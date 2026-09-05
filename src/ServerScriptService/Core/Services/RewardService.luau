--!strict
-- Server-authoritative persistent reward application. Completion grants are profile-persisted
-- and idempotent; ordinary per-runtime sources are deduped until encounter/session persistence
-- becomes the long-lived source of truth in the dungeon runtime slice.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileSchema = require(
    ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema")
)

local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local RewardService = {}
RewardService.__index = RewardService

local COMPLETION_HISTORY_MIN_AGE_SECONDS = 24 * 60 * 60
local COMPLETION_HISTORY_MAX = 128
local MONSTER_HISTORY_MIN_AGE_SECONDS = 24 * 60 * 60
local MONSTER_HISTORY_MAX = 256

local function clone(value: any): any
    return ProfileSchema.deep_clone(value)
end

local function valid_positive_integer(value: any): boolean
    return type(value) == "number"
        and value == value
        and value > 0
        and value < math.huge
        and value % 1 == 0
end

local function valid_non_negative_integer(value: any): boolean
    return type(value) == "number"
        and value == value
        and value >= 0
        and value < math.huge
        and value % 1 == 0
end

local function completion_transaction_id(session_id: string, slot: number): string
    return string.format("Completion:%s:Slot%d", session_id, slot)
end

local function result_from_completion_record(transaction_id: string, record: any, already_applied: boolean): any
    return {
        ok = true,
        reason = nil,
        already_applied = already_applied,
        transaction_id = transaction_id,
        gold_granted = record.GoldGranted or 0,
        item_id = record.ItemId,
        applied_at = record.AppliedAt,
    }
end

local function roll_loot(loot_table: {any}, rng: any): string?
    local total_weight = 0
    for _, entry in ipairs(loot_table) do
        if type(entry.Weight) == "number" and entry.Weight > 0 then
            total_weight += entry.Weight
        end
    end
    if total_weight <= 0 then
        return nil
    end

    local roll = rng:NextNumber(0, total_weight)
    local cumulative = 0
    local selected: any = loot_table[#loot_table]
    for _, entry in ipairs(loot_table) do
        cumulative += entry.Weight
        if roll < cumulative then
            selected = entry
            break
        end
    end

    if selected.Kind == "Nothing" then
        return nil
    elseif selected.Kind == "Item" then
        return selected.ItemId
    elseif selected.Kind == "ItemPool" then
        local items = selected.ItemIds
        if type(items) ~= "table" or #items == 0 then
            return nil
        end
        local index = rng:NextInteger(1, #items)
        return items[index]
    end

    return nil
end

function RewardService.new(
    profile_service: any,
    progression_service: any,
    inventory_service: any,
    session_service: any?,
    rng: any?,
    clock: (() -> number)?
): any
    assert(profile_service ~= nil, "RewardService requires ProfileService.")
    assert(progression_service ~= nil, "RewardService requires ProgressionService.")
    assert(inventory_service ~= nil, "RewardService requires InventoryService.")

    local self = setmetatable({}, RewardService)
    self._profiles = profile_service
    self._progression = progression_service
    self._inventory = inventory_service
    self._sessions = session_service
    self._rng = rng or Random.new()
    self._clock = clock or os.time
    self._runtime_sources = {}
    self._runtime_monsters = {}
    return self
end

function RewardService:_runtime_source_key(user_id: number, source_id: string): string
    return tostring(user_id) .. ":" .. source_id
end

function RewardService:grant_gold(user_id: number, amount: number, source_id: string): any
    if not valid_positive_integer(amount) then
        return {ok = false, reason = "InvalidGoldAmount"}
    end
    if type(source_id) ~= "string" or source_id == "" then
        return {ok = false, reason = "InvalidSourceId"}
    end

    local source_key = self:_runtime_source_key(user_id, source_id)
    local previous = self._runtime_sources[source_key]
    if previous then
        local repeated = clone(previous)
        repeated.already_applied = true
        return repeated
    end

    local mutated, mutate_error = self._profiles:mutate(user_id, function(profile: any)
        local slot = profile.Account.SelectedCharacterSlot
        local character = profile.Characters["Slot" .. tostring(slot)]
        if not character then
            error("Selected character slot is missing")
        end
        character.Gold += amount
    end)
    if not mutated then
        return {ok = false, reason = mutate_error or "ProfileMutationFailed"}
    end

    local applied = {
        ok = true,
        reason = nil,
        already_applied = false,
        source_id = source_id,
        gold_granted = amount,
    }
    self._runtime_sources[source_key] = clone(applied)
    return applied
end

function RewardService:grant_monster_reward(
    member_user_ids: {number},
    monster_reward: any,
    transaction_id: string
): any
    if type(transaction_id) ~= "string" or transaction_id == "" then
        return {ok = false, reason = "InvalidTransactionId"}
    end
    if type(monster_reward) ~= "table"
        or not valid_positive_integer(monster_reward.XP)
        or not valid_non_negative_integer(monster_reward.GoldMin)
        or not valid_non_negative_integer(monster_reward.GoldMax)
        or monster_reward.GoldMax < monster_reward.GoldMin
    then
        return {ok = false, reason = "InvalidMonsterReward"}
    end

    local runtime_previous = self._runtime_monsters[transaction_id]
    if runtime_previous then
        local repeated = clone(runtime_previous)
        repeated.already_applied = true
        return repeated
    end

    local session_id = string.match(transaction_id, "^([^:]+):") or ""
    local results: {[string]: any} = {}
    local any_new_application = false

    for _, user_id in ipairs(member_user_ids) do
        local existing_character = self._profiles:get_character(user_id, 1)
        if not existing_character then
            return {
                ok = false,
                reason = "ProfileNotLoaded",
                partial_results = clone(results),
            }
        end

        local existing_history = existing_character.RewardHistory
            and existing_character.RewardHistory.Monster
            and existing_character.RewardHistory.Monster[transaction_id]
        if existing_history then
            results[tostring(user_id)] = {
                ok = true,
                already_applied = true,
                xp_granted = existing_history.XPGranted or 0,
                gold_granted = existing_history.GoldGranted or 0,
                levels_gained = existing_history.LevelsGained or 0,
                new_level = existing_history.NewLevel or existing_character.Level,
                carried_xp = existing_history.CarriedXP or existing_character.XP,
            }
        else
            local gold_roll = self._rng:NextInteger(monster_reward.GoldMin, monster_reward.GoldMax)
            local member_result: any = nil
            local mutated, mutate_error = self._profiles:mutate(user_id, function(profile: any)
                local slot = profile.Account.SelectedCharacterSlot
                local character = profile.Characters["Slot" .. tostring(slot)]
                if not character then
                    error("Selected character slot is missing")
                end
                if type(character.RewardHistory) ~= "table" then
                    character.RewardHistory = {Completion = {}, Monster = {}}
                end
                if type(character.RewardHistory.Monster) ~= "table" then
                    character.RewardHistory.Monster = {}
                end

                local already = character.RewardHistory.Monster[transaction_id]
                if already then
                    member_result = {
                        ok = true,
                        already_applied = true,
                        xp_granted = already.XPGranted or 0,
                        gold_granted = already.GoldGranted or 0,
                        levels_gained = already.LevelsGained or 0,
                        new_level = already.NewLevel or character.Level,
                        carried_xp = already.CarriedXP or character.XP,
                    }
                    return
                end

                local xp_result = ProgressionService.apply_xp_to_character(character, monster_reward.XP)
                if xp_result.ok ~= true then
                    error(xp_result.reason or "XPApplyFailed")
                end
                character.Gold += gold_roll

                local record = {
                    SessionId = session_id,
                    AppliedAt = self._clock(),
                    XPGranted = monster_reward.XP,
                    GoldGranted = gold_roll,
                    LevelsGained = xp_result.levels_gained,
                    NewLevel = xp_result.new_level,
                    CarriedXP = xp_result.carried_xp,
                }
                character.RewardHistory.Monster[transaction_id] = record
                member_result = {
                    ok = true,
                    already_applied = false,
                    xp_granted = record.XPGranted,
                    gold_granted = record.GoldGranted,
                    levels_gained = record.LevelsGained,
                    new_level = record.NewLevel,
                    carried_xp = record.CarriedXP,
                }
            end)

            if not mutated then
                return {
                    ok = false,
                    reason = mutate_error or "ProfileMutationFailed",
                    partial_results = clone(results),
                }
            end
            if member_result and member_result.already_applied ~= true then
                any_new_application = true
            end
            results[tostring(user_id)] = member_result
        end
        self:_prune_monster_history(user_id)
    end

    local applied = {
        ok = true,
        reason = nil,
        already_applied = not any_new_application,
        transaction_id = transaction_id,
        member_results = results,
    }
    self._runtime_monsters[transaction_id] = clone(applied)
    return applied
end

function RewardService:_prune_monster_history(user_id: number)
    local character = self._profiles:get_character(user_id, 1)
    if not character or type(character.RewardHistory) ~= "table" or type(character.RewardHistory.Monster) ~= "table" then
        return
    end

    local entries = {}
    for key, record in pairs(character.RewardHistory.Monster) do
        if type(record) == "table" and type(record.AppliedAt) == "number" then
            table.insert(entries, {Key = key, Record = record})
        end
    end
    if #entries <= MONSTER_HISTORY_MAX then
        return
    end

    table.sort(entries, function(a, b)
        return a.Record.AppliedAt > b.Record.AppliedAt
    end)
    local now = self._clock()
    local removable: {[string]: boolean} = {}
    for index = MONSTER_HISTORY_MAX + 1, #entries do
        local item = entries[index]
        if now - item.Record.AppliedAt >= MONSTER_HISTORY_MIN_AGE_SECONDS then
            local can_remove = true
            if self._sessions and type(item.Record.SessionId) == "string" and item.Record.SessionId ~= "" then
                local session = self._sessions:get(item.Record.SessionId)
                if session and (session.State == "Active" or session.State == "Creating") then
                    can_remove = false
                end
            end
            if can_remove then removable[item.Key] = true end
        end
    end
    if next(removable) == nil then return end

    self._profiles:mutate(user_id, function(profile: any)
        local history = profile.Characters.Slot1.RewardHistory.Monster
        for key in pairs(removable) do history[key] = nil end
    end)
end

function RewardService:_prune_completion_history(user_id: number)
    local character = self._profiles:get_character(user_id, 1)
    if not character or type(character.RewardHistory) ~= "table" or type(character.RewardHistory.Completion) ~= "table" then
        return
    end

    local entries = {}
    for key, record in pairs(character.RewardHistory.Completion) do
        if type(record) == "table" and type(record.AppliedAt) == "number" then
            table.insert(entries, {Key = key, Record = record})
        end
    end
    if #entries <= COMPLETION_HISTORY_MAX then
        return
    end

    table.sort(entries, function(a, b)
        return a.Record.AppliedAt > b.Record.AppliedAt
    end)

    local now = self._clock()
    local removable: {[string]: boolean} = {}
    for index = COMPLETION_HISTORY_MAX + 1, #entries do
        local item = entries[index]
        local age = now - item.Record.AppliedAt
        if age >= COMPLETION_HISTORY_MIN_AGE_SECONDS then
            local can_remove = true
            if self._sessions and type(item.Record.SessionId) == "string" then
                local session = self._sessions:get(item.Record.SessionId)
                if session and (session.State == "Active" or session.State == "Creating") then
                    can_remove = false
                end
            end
            if can_remove then
                removable[item.Key] = true
            end
        end
    end

    if next(removable) == nil then
        return
    end

    self._profiles:mutate(user_id, function(profile: any)
        local history = profile.Characters.Slot1.RewardHistory.Completion
        for key in pairs(removable) do
            history[key] = nil
        end
    end)
end

function RewardService:grant_completion(
    session_id: string,
    slot: number,
    user_id: number,
    reward_definition: any,
    rng: any?
): any
    if type(session_id) ~= "string" or session_id == "" then
        return {ok = false, reason = "InvalidSessionId"}
    end
    if slot ~= 1 then
        return {ok = false, reason = "UnsupportedCharacterSlot"}
    end
    if type(reward_definition) ~= "table"
        or not valid_non_negative_integer(reward_definition.Gold)
        or type(reward_definition.LootTable) ~= "table"
    then
        return {ok = false, reason = "InvalidRewardDefinition"}
    end

    local transaction_id = completion_transaction_id(session_id, slot)
    local existing_character = self._profiles:get_character(user_id, slot)
    if not existing_character then
        return {ok = false, reason = "ProfileNotLoaded"}
    end
    local existing = existing_character.RewardHistory.Completion[transaction_id]
    if existing then
        return result_from_completion_record(transaction_id, existing, true)
    end

    local roll_rng = rng or self._rng
    local item_id = roll_loot(reward_definition.LootTable, roll_rng)
    local applied_result: any = nil
    local mutated, mutate_error = self._profiles:mutate(user_id, function(profile: any)
        local character = profile.Characters["Slot" .. tostring(slot)]
        if not character then
            error("Character slot is missing")
        end

        local history = character.RewardHistory.Completion
        local already = history[transaction_id]
        if already then
            applied_result = result_from_completion_record(transaction_id, already, true)
            return
        end

        character.Gold += reward_definition.Gold
        if item_id then
            local item_result = InventoryService.apply_item_to_character(character, item_id, 1)
            if item_result.ok ~= true then
                error(item_result.reason or "CompletionItemApplyFailed")
            end
        end

        local record = {
            SessionId = session_id,
            Slot = slot,
            AppliedAt = self._clock(),
            GoldGranted = reward_definition.Gold,
            ItemId = item_id,
        }
        history[transaction_id] = record
        applied_result = result_from_completion_record(transaction_id, record, false)
    end)

    if not mutated then
        return {ok = false, reason = mutate_error or "ProfileMutationFailed"}
    end

    self:_prune_completion_history(user_id)
    return applied_result
end

return table.freeze(RewardService)
