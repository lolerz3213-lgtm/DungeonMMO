--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("TrainerCatalogues")
if not module then
    error("[Trainer Catalogues Tests] RED: TrainerCatalogues is missing.")
end

local TrainerCatalogues = require(module)
local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Trainer Catalogues Tests] " .. message, 2)
    end
end

local function fighter(race_id: string): any
    return {
        Identity = {
            Version = 1,
            RaceId = race_id,
            BaseClassId = "Fighter",
            ClassId = "Fighter",
            CreationStage = "Complete",
        },
    }
end

local human = TrainerCatalogues.resolve_for_character("FighterTrainer", fighter("Human"))
local elf = TrainerCatalogues.resolve_for_character("FighterTrainer", fighter("Elf"))
check(human.ok == true, "Human Fighter must resolve FighterTrainer.")
check(elf.ok == true, "Elf Fighter must resolve FighterTrainer.")
check(type(human.Trainer) == "table", "trainer snapshot must exist.")
check(human.Trainer.DisplayName == "Fighter Trainer", "trainer display name mismatch.")
check(#human.Trainer.Skills == 3, "Fighter trainer must expose exactly three Phase 2C.B skills.")
check(human.Trainer.Skills[1].SkillId == "ShieldBash", "Shield Bash order mismatch.")
check(human.Trainer.Skills[2].SkillId == "Mend", "Mend order mismatch.")
check(human.Trainer.Skills[3].SkillId == "ArcSlash", "Arc Slash order mismatch.")
check(human.Trainer.Skills[3].SourceItemId == "arc_slash_book_bound", "Arc Slash book source mismatch.")
check(TrainerCatalogues.can_offer("FighterTrainer", fighter("Human"), "FakeSkill").ok == false, "arbitrary skill must reject.")

print(string.format("[Trainer Catalogues Tests] PASS: %d assertions.", assertions))
