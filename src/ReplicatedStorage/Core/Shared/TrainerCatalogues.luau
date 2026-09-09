--!strict
-- Data-driven trainer catalogue and pure trainer authorization.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local CharacterIdentityRules = require(
    Shared:WaitForChild("CharacterIdentityRules")
)

local DEFINITIONS = table.freeze({
    FighterTrainer = table.freeze({
        Id = "FighterTrainer",
        DisplayName = "Fighter Trainer",
        AllowedBaseClasses = table.freeze({"Fighter"}),
        Skills = table.freeze({
            table.freeze({
                SkillId = "ShieldBash",
                Mode = "Rank",
            }),
            table.freeze({
                SkillId = "Mend",
                Mode = "Rank",
            }),
            table.freeze({
                SkillId = "ArcSlash",
                Mode = "LearnOrRank",
                SourceItemId = "arc_slash_book_bound",
            }),
        }),
    }),
})

local TrainerCatalogues = {}

local function failure(reason: string): any
    return {
        ok = false,
        reason = reason,
    }
end

local function allowed(whitelist: any, value: any): boolean
    if whitelist == nil then
        return true
    end

    if type(whitelist) ~= "table" then
        return false
    end

    for _, candidate in ipairs(whitelist) do
        if candidate == value then
            return true
        end
    end

    return false
end

local function copy_trainer(definition: any): any
    local skills = {}

    for _, entry in ipairs(definition.Skills) do
        table.insert(skills, {
            SkillId = entry.SkillId,
            Mode = entry.Mode,
            SourceItemId = entry.SourceItemId,
        })
    end

    return {
        Id = definition.Id,
        DisplayName = definition.DisplayName,
        Skills = skills,
    }
end

function TrainerCatalogues.get(trainer_id: string): any?
    return DEFINITIONS[trainer_id]
end

function TrainerCatalogues.resolve_for_character(
    trainer_id: string,
    character: any
): any
    local definition = DEFINITIONS[trainer_id]

    if not definition then
        return failure("UnknownTrainer")
    end

    if (
        type(character) ~= "table"
        or not CharacterIdentityRules.is_complete(character)
    ) then
        return failure("IdentityIncomplete")
    end

    local identity = character.Identity

    if not allowed(definition.AllowedRaces, identity.RaceId) then
        return failure("TrainerRestricted")
    end

    if not allowed(definition.AllowedBaseClasses, identity.BaseClassId) then
        return failure("TrainerRestricted")
    end

    if not allowed(definition.AllowedClasses, identity.ClassId) then
        return failure("TrainerRestricted")
    end

    local trainer = copy_trainer(definition)

    return {
        ok = true,
        Trainer = trainer,
        TrainerId = trainer.Id,
        DisplayName = trainer.DisplayName,
        Skills = trainer.Skills,
    }
end

function TrainerCatalogues.can_offer(
    trainer_id: string,
    character: any,
    skill_id: string
): any
    local resolved = TrainerCatalogues.resolve_for_character(
        trainer_id,
        character
    )

    if not resolved.ok then
        return resolved
    end

    for _, entry in ipairs(resolved.Trainer.Skills) do
        if entry.SkillId == skill_id then
            return {
                ok = true,
                Entry = entry,
                Trainer = resolved.Trainer,
            }
        end
    end

    return failure("SkillNotTeachableHere")
end

return table.freeze(TrainerCatalogues)
