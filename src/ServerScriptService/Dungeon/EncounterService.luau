--!strict
-- Local Dungeon-server encounter ownership and exactly-once monster reward dispatch.
local EncounterService = {}
EncounterService.__index = EncounterService

type MemberRecord = {
    UserId: number,
    Connected: boolean,
    Mode: string,
}

type EnemyRecord = {
    Model: Model,
    Dead: boolean,
}

type EncounterRecord = {
    Id: string,
    Members: {[number]: MemberRecord},
    Enemies: {[Model]: EnemyRecord},
    TotalEnemies: number,
    DeadEnemies: number,
    Clear: boolean,
}

local function operation(ok: boolean, reason: string?, extra: any?): any
    local out = extra or {}
    out.ok = ok
    out.reason = reason
    return out
end

local function reward_from_model(model: Model): any
    return {
        XP = model:GetAttribute("DungeonRewardXP"),
        GoldMin = model:GetAttribute("DungeonRewardGoldMin"),
        GoldMax = model:GetAttribute("DungeonRewardGoldMax"),
    }
end

local function transaction_id(session_id: string, model: Model): string
    return string.format(
        "%s:%s:Life%d",
        session_id,
        tostring(model:GetAttribute("DungeonEnemyId")),
        tonumber(model:GetAttribute("DungeonLifeIndex")) or 1
    )
end

function EncounterService.new(reward_service: any, session_id: string): any
    assert(reward_service ~= nil, "EncounterService requires RewardService")
    assert(type(session_id) == "string" and session_id ~= "", "EncounterService requires SessionId")
    local self = setmetatable({}, EncounterService)
    self._rewards = reward_service
    self._session_id = session_id
    self._encounters = {}
    self._current_id = nil
    return self
end

function EncounterService:start(encounter_id: string, member_user_ids: {number}, enemy_models: {Model}): any
    if type(encounter_id) ~= "string" or encounter_id == "" then
        return operation(false, "InvalidEncounterId")
    end
    if self._encounters[encounter_id] ~= nil then
        return operation(false, "EncounterAlreadyStarted")
    end

    local members: {[number]: MemberRecord} = {}
    for _, user_id in ipairs(member_user_ids) do
        members[user_id] = {UserId = user_id, Connected = true, Mode = "Active"}
    end

    local enemies: {[Model]: EnemyRecord} = {}
    local count = 0
    for _, model in ipairs(enemy_models) do
        if model:IsA("Model") and enemies[model] == nil then
            enemies[model] = {Model = model, Dead = false}
            count += 1
        end
    end
    if count == 0 then
        return operation(false, "NoEnemies")
    end

    local record: EncounterRecord = {
        Id = encounter_id,
        Members = members,
        Enemies = enemies,
        TotalEnemies = count,
        DeadEnemies = 0,
        Clear = false,
    }
    self._encounters[encounter_id] = record
    self._current_id = encounter_id
    return operation(true, nil, {encounter = record})
end

function EncounterService:mark_member_mode(user_id: number, mode: string)
    for _, encounter in pairs(self._encounters) do
        local member = encounter.Members[user_id]
        if member then
            member.Mode = mode
        end
    end
end

function EncounterService:mark_member_connected(user_id: number, connected: boolean)
    for _, encounter in pairs(self._encounters) do
        local member = encounter.Members[user_id]
        if member then
            member.Connected = connected
        end
    end
end

function EncounterService:get_eligible_members(encounter_id: string): {number}
    local encounter: EncounterRecord? = self._encounters[encounter_id]
    if not encounter then
        return {}
    end
    local eligible = {}
    for user_id, member in pairs(encounter.Members) do
        if member.Connected and member.Mode == "Active" then
            table.insert(eligible, user_id)
        end
    end
    table.sort(eligible)
    return eligible
end

function EncounterService:on_enemy_died(enemy_model: Model): any
    local encounter_id = self._current_id
    if not encounter_id then
        return operation(false, "NoActiveEncounter")
    end
    local encounter: EncounterRecord? = self._encounters[encounter_id]
    if not encounter then
        return operation(false, "EncounterNotFound")
    end
    local enemy = encounter.Enemies[enemy_model]
    if not enemy then
        return operation(false, "EnemyNotRegistered")
    end
    if enemy.Dead then
        return operation(true, nil, {already_processed = true, cleared = encounter.Clear})
    end

    enemy.Dead = true
    encounter.DeadEnemies += 1
    local eligible = self:get_eligible_members(encounter_id)
    local reward_result = self._rewards:grant_monster_reward(
        eligible,
        reward_from_model(enemy_model),
        transaction_id(self._session_id, enemy_model)
    )
    if reward_result.ok ~= true then
        enemy.Dead = false
        encounter.DeadEnemies -= 1
        return operation(false, reward_result.reason or "RewardFailed", {reward_result = reward_result})
    end

    encounter.Clear = encounter.DeadEnemies >= encounter.TotalEnemies
    return operation(true, nil, {
        already_processed = false,
        cleared = encounter.Clear,
        reward_result = reward_result,
        eligible_members = eligible,
    })
end

function EncounterService:get_current_id(): string?
    return self._current_id
end

function EncounterService:is_member_active(user_id: number): boolean
    local encounter_id = self._current_id
    if not encounter_id then return false end
    local encounter = self._encounters[encounter_id]
    if not encounter or encounter.Clear then return false end
    local member = encounter.Members[user_id]
    return member ~= nil and member.Connected == true and member.Mode == "Active"
end

function EncounterService:is_contribution_eligible(user_id: number, target_model: Model?): boolean
    if not self:is_member_active(user_id) then return false end
    if target_model == nil then return true end
    local encounter = self._encounters[self._current_id]
    return encounter ~= nil and encounter.Enemies[target_model] ~= nil
end

function EncounterService:is_clear(encounter_id: string): boolean
    local encounter: EncounterRecord? = self._encounters[encounter_id]
    return encounter ~= nil and encounter.Clear == true
end

return table.freeze(EncounterService)
