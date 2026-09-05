--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local shared=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared")
local services=ServerScriptService:WaitForChild("Core"):WaitForChild("Services")
local ProfileSchema=require(shared:WaitForChild("ProfileSchema"))
local ProfileMigration=require(services:WaitForChild("ProfileMigration"))
local n=0
local function check(v:boolean,m:string) n+=1 if not v then error("[Phase 2B Profile Migration Tests] "..m,2) end end
local phase2a={SchemaVersion=2,Account={SelectedCharacterSlot=1},Characters={Slot1={Level=5,XP=25,Gold=9,Inventory={},DungeonProgress={},RewardHistory={Completion={},Monster={}}}}}
local first=ProfileMigration.migrate(phase2a)
local second=ProfileMigration.migrate(first)
local p=first.Characters.Slot1.Progression
local p2=second.Characters.Slot1.Progression
check(ProfileSchema.VERSION == 3, "schema version must advance to 3")
check(p.AttributePointEntitlement == 4, "Level 5 must receive 4 AP entitlement")
check(p.SkillPointEntitlement == 4, "Level 5 must receive 4 SP entitlement")
check(p.Attributes.Strength == 5 and p.Attributes.Dexterity == 5 and p.Attributes.Vitality == 5 and p.Attributes.Intellect == 5 and p.Attributes.Spirit == 5, "all attributes must start at 5")
check(p.Skills.Mend.Known == true and p.Skills.Mend.PurchasedRank == 1 and p.Skills.Mend.StarterGranted == true, "Mend must migrate as free prototype starter")
check(p.Skills.ShieldBash.Known == true and p.Skills.ShieldBash.PurchasedRank == 1, "Shield Bash must migrate as free prototype starter")
check(p.Loadout[1] == "ShieldBash" and p.Loadout[2] == "Mend", "prototype loadout must migrate")
check(p.RespecCounters.Attributes == 0 and p.RespecCounters.Skills == 0, "respec counters must start at zero")
check(p.OneTimeRewards.ArcSlashFirstClear == false, "first-clear reward flag must default false")
check(p2.AttributePointEntitlement == 4 and p2.SkillPointEntitlement == 4, "migration must be idempotent")
print(string.format("[Phase 2B Profile Migration Tests] PASS: %d assertions.",n))
