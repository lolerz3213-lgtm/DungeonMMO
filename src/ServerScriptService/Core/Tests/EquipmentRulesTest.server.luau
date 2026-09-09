--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")

local module = Shared:FindFirstChild("EquipmentRules")
if not module then
    error("[Equipment Rules Tests] RED: EquipmentRules is missing.")
end

local EquipmentRules = require(module)
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))

local assertions = 0
local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Equipment Rules Tests] " .. message, 2)
    end
end

local function character(race_id: string, class_id: string, stage: string?): any
    return {
        Identity = {
            Version = 1,
            RaceId = race_id,
            BaseClassId = class_id,
            ClassId = class_id,
            CreationStage = stage or "Complete",
        },
    }
end

local human = character("Human", "Fighter")
local elf = character("Elf", "Fighter")
local sword = ItemDefinitions.get("marauder_sword")
local book = ItemDefinitions.get("arc_slash_book_bound")
local elf_helmet = ItemDefinitions.get("test_elf_helmet")

check(EquipmentRules.validate(human, sword, "Weapon").ok == true, "Human Fighter sword must be eligible.")
check(EquipmentRules.validate(elf, sword, "Weapon").ok == true, "Elf Fighter sword must be eligible.")
check(EquipmentRules.validate(human, sword, "Body").reason == "WrongSlot", "wrong slot must fail closed.")
check(EquipmentRules.validate(human, sword, "Ring").reason == "UnknownEquipmentSlot", "unknown slot must fail closed.")
check(EquipmentRules.validate(human, book, "Weapon").reason == "NotEquipment", "Skill Book must not equip.")
check(EquipmentRules.validate(character("Human", "Fighter", "RaceSelection"), sword, "Weapon").reason == "IdentityIncomplete", "incomplete identity must reject.")
check(elf_helmet ~= nil, "test_elf_helmet must exist for restriction proof.")
check(EquipmentRules.validate(human, elf_helmet, "Helmet").reason == "RaceRestricted", "Human must reject Elf-only helmet.")
check(EquipmentRules.validate(elf, elf_helmet, "Helmet").ok == true, "Elf must accept Elf-only helmet.")

print(string.format("[Equipment Rules Tests] PASS: %d assertions.", assertions))
