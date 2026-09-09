--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local CharacterIdentityRules = require(
    Shared:WaitForChild("CharacterIdentityRules")
)
local TrainerCatalogues = require(
    Shared:WaitForChild("TrainerCatalogues")
)
local ProgressionRuntimeState = require(
    Services:WaitForChild("ProgressionRuntimeState")
)
local ProgressionSnapshotBuilder = require(
    Services:WaitForChild("ProgressionSnapshotBuilder")
)

local BaseProgressionController = {}
BaseProgressionController.__index = BaseProgressionController

local function failure(reason: string): any
    return {
        ok = false,
        reason = reason,
    }
end

local function trainer_arguments(
    trainer_or_skill: string,
    maybe_skill: string?
): (string, string)
    if maybe_skill == nil then
        return "FighterTrainer", trainer_or_skill
    end

    return trainer_or_skill, maybe_skill
end

function BaseProgressionController.new(options: any): any
    assert(
        type(options) == "table",
        "BaseProgressionController options are required"
    )
    assert(
        options.profiles
            and options.inventory
            and options.attributes
            and options.loadout
            and options.skills,
        "BaseProgressionController services are required"
    )

    return setmetatable({
        _context = options.context or "Base",
        _profiles = options.profiles,
        _inventory = options.inventory,
        _attributes = options.attributes,
        _loadout = options.loadout,
        _skills = options.skills,
    }, BaseProgressionController)
end

function BaseProgressionController:_base_only(): any?
    if self._context ~= "Base" then
        return failure("BaseOnlyAction")
    end

    return nil
end

function BaseProgressionController:_identity_complete(user_id: number): any?
    local character = self._profiles:get_character(user_id, 1)

    if not character then
        return failure("ProfileNotLoaded")
    end

    if not CharacterIdentityRules.is_complete(character) then
        return failure("IdentityIncomplete")
    end

    return nil
end

function BaseProgressionController:build_snapshot(user_id: number): any
    local character = self._profiles:get_character(user_id, 1)
    return ProgressionSnapshotBuilder.build(character)
end

function BaseProgressionController:build_trainer_snapshot(
    user_id: number,
    trainer_id: string
): any
    local character = self._profiles:get_character(user_id, 1)

    if not character then
        return failure("ProfileNotLoaded")
    end

    return TrainerCatalogues.resolve_for_character(
        trainer_id,
        character
    )
end

function BaseProgressionController:commit_attributes(
    user_id: number,
    desired: any
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    return self._attributes:commit(user_id, desired)
end

function BaseProgressionController:respec_attributes(user_id: number): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    return self._attributes:respec(user_id)
end

function BaseProgressionController:learn_skill(
    user_id: number,
    trainer_or_skill: string,
    maybe_skill: string?
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    local trainer_id, skill_id = trainer_arguments(
        trainer_or_skill,
        maybe_skill
    )

    local character = self._profiles:get_character(user_id, 1)
    if not character then
        return failure("ProfileNotLoaded")
    end

    local offered = TrainerCatalogues.can_offer(
        trainer_id,
        character,
        skill_id
    )

    if not offered.ok then
        return offered
    end

    local entry = offered.Entry

    if entry.Mode ~= "Learn" and entry.Mode ~= "LearnOrRank" then
        return failure("SkillNotLearnableHere")
    end

    if type(entry.SourceItemId) ~= "string" or entry.SourceItemId == "" then
        return failure("SkillSourceItemMissing")
    end

    return self._skills:learn_skill(
        user_id,
        skill_id,
        entry.SourceItemId
    )
end

function BaseProgressionController:purchase_rank(
    user_id: number,
    trainer_or_skill: string,
    maybe_skill: string?
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    local trainer_id, skill_id = trainer_arguments(
        trainer_or_skill,
        maybe_skill
    )

    local character = self._profiles:get_character(user_id, 1)
    if not character then
        return failure("ProfileNotLoaded")
    end

    local offered = TrainerCatalogues.can_offer(
        trainer_id,
        character,
        skill_id
    )

    if not offered.ok then
        return offered
    end

    local mode = offered.Entry.Mode

    if mode ~= "Rank" and mode ~= "LearnOrRank" then
        return failure("SkillNotRankableHere")
    end

    return self._skills:purchase_rank(user_id, skill_id)
end

function BaseProgressionController:respec_skills(user_id: number): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    return self._skills:respec_skills(user_id)
end

function BaseProgressionController:set_loadout(
    user_id: number,
    slots: any
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    local result = self._loadout:set(user_id, slots, "Base")

    if result.ok then
        local character = self._profiles:get_character(user_id, 1)
        if character then
            ProgressionRuntimeState.set_character(user_id, character)
        end
    end

    return result
end

function BaseProgressionController:move_skill_to_slot(
    user_id: number,
    skill_id: any,
    slot: any
): any
    local blocked = self:_base_only()
    if blocked then
        return blocked
    end

    blocked = self:_identity_complete(user_id)
    if blocked then
        return blocked
    end

    local result = self._loadout:move_to_slot(
        user_id,
        skill_id,
        slot,
        "Base"
    )

    if result.ok then
        local character = self._profiles:get_character(user_id, 1)
        if character then
            ProgressionRuntimeState.set_character(user_id, character)
        end
    end

    return result
end

return table.freeze(BaseProgressionController)
