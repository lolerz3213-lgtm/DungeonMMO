--!strict
local ItemDefinitions = {}
local DEFINITIONS = table.freeze({
    marauder_sword = table.freeze({Id="marauder_sword",Name="Marauder Sword",Kind="Equipment",Slot="Weapon",Rarity="Basic",Stackable=false}),
    marauder_shield = table.freeze({Id="marauder_shield",Name="Marauder Shield",Kind="Equipment",Slot="OffHand",Rarity="Basic",Stackable=false}),
    marauder_armor = table.freeze({Id="marauder_armor",Name="Marauder Armour",Kind="Equipment",Slot="Body",Rarity="Basic",Stackable=false}),
    captain_emblem = table.freeze({Id="captain_emblem",Name="Captain's Emblem",Kind="Material",Rarity="Uncommon",Stackable=true}),
    skill_book_test = table.freeze({Id="skill_book_test",Name="Unidentified Skill Book",Kind="SkillBook",Rarity="Rare",Stackable=true,Learnable=false}),
    arc_slash_book_bound = table.freeze({Id="arc_slash_book_bound",Name="Arc Slash Skill Book",Kind="SkillBook",Rarity="Rare",Stackable=false,Learnable=true,Bound=true,Tradeable=false,SkillId="ArcSlash"}),
})
function ItemDefinitions.get(item_id:string) return DEFINITIONS[item_id] end
function ItemDefinitions.all() return DEFINITIONS end
return table.freeze(ItemDefinitions)
