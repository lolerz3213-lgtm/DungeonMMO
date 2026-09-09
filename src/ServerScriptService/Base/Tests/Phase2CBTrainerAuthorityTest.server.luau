--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Base = ServerScriptService:WaitForChild("Base")
local Core = ServerScriptService:WaitForChild("Core")
local Adapters = Core:WaitForChild("Adapters")
local Services = Core:WaitForChild("Services")

local BaseProgressionController = require(Base:WaitForChild("BaseProgressionController"))
local InMemoryProfileAdapter = require(Adapters:WaitForChild("InMemoryProfileAdapter"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local AttributeService = require(Services:WaitForChild("AttributeService"))
local LoadoutService = require(Services:WaitForChild("LoadoutService"))
local SkillProgressionService = require(Services:WaitForChild("SkillProgressionService"))

local profiles = ProfileService.new(InMemoryProfileAdapter.new())
assert(profiles:load(6291))
assert(profiles:mutate(6291, function(profile: any)
    local c = profile.Characters.Slot1
    c.Level = 10
    c.Identity = {
        Version = 1,
        RaceId = "Human",
        BaseClassId = "Fighter",
        ClassId = "Fighter",
        CreationStage = "Complete",
    }
    c.Progression.Attributes = {
        Strength=5, Dexterity=4, Vitality=6, Intellect=5, Spirit=5,
    }
    c.Progression.SkillPointEntitlement = 9
    c.Progression.Skills = {
        ShieldBash = {Known=true, StarterGranted=true, PurchasedRank=1, Proficiency=0},
        Mend = {Known=true, StarterGranted=true, PurchasedRank=1, Proficiency=0},
    }
    c.Progression.Loadout = {[1]="ShieldBash", [2]="Mend"}
end))

local inventory = InventoryService.new(profiles)
local attributes = AttributeService.new(profiles)
local loadout = LoadoutService.new(profiles)
local skills = SkillProgressionService.new(profiles, inventory, loadout)

local controller = BaseProgressionController.new({
    context = "Base",
    profiles = profiles,
    inventory = inventory,
    attributes = attributes,
    loadout = loadout,
    skills = skills,
})

assert(inventory:add_item(6291, "arc_slash_book_bound", 1).ok)

local learned = controller:learn_skill(6291, "FighterTrainer", "ArcSlash")
if learned.ok ~= true then
    error(
        "[Phase 2C.B Trainer Authority Tests] RED: FighterTrainer + ArcSlash should be authorized; got "
            .. tostring(learned.reason)
            .. "."
    )
end

local fake = controller:purchase_rank(6291, "FighterTrainer", "FakeSkill")
if fake.ok ~= false or fake.reason ~= "SkillNotTeachableHere" then
    error("[Phase 2C.B Trainer Authority Tests] RED: arbitrary trainer skill must fail as SkillNotTeachableHere.")
end

print("[Phase 2C.B Trainer Authority Tests] PASS.")
