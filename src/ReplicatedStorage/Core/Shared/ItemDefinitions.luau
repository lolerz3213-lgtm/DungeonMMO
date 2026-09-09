--!strict
local ItemDefinitions = {}

local FIGHTER = table.freeze({"Fighter"})
local ELF = table.freeze({"Elf"})

local DEFINITIONS = table.freeze({
    marauder_sword = table.freeze({
        Id = "marauder_sword",
        Name = "Marauder Sword",
        Kind = "Equipment",
        Slot = "Weapon",
        Category = "Sword",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        WeaponTags = table.freeze({"OneHandedSword"}),
        CombatModifiers = table.freeze({
            PhysicalDamageBonus = 0.10,
        }),
    }),

    marauder_shield = table.freeze({
        Id = "marauder_shield",
        Name = "Marauder Shield",
        Kind = "Equipment",
        Slot = "OffHand",
        Category = "Shield",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        CombatModifiers = table.freeze({
            MaxHealthFlat = 8,
        }),
    }),

    marauder_armor = table.freeze({
        Id = "marauder_armor",
        Name = "Marauder Armour",
        Kind = "Equipment",
        Slot = "Body",
        Category = "HeavyArmor",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        CombatModifiers = table.freeze({
            MaxHealthFlat = 10,
        }),
    }),

    marauder_helmet = table.freeze({
        Id = "marauder_helmet",
        Name = "Marauder Helmet",
        Kind = "Equipment",
        Slot = "Helmet",
        Category = "HeavyArmor",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        CombatModifiers = table.freeze({
            MaxHealthFlat = 4,
        }),
    }),

    marauder_gloves = table.freeze({
        Id = "marauder_gloves",
        Name = "Marauder Gloves",
        Kind = "Equipment",
        Slot = "Gloves",
        Category = "HeavyArmor",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        CombatModifiers = table.freeze({
            PhysicalDamageBonus = 0.03,
            CriticalChanceBonus = 0.01,
        }),
    }),

    marauder_boots = table.freeze({
        Id = "marauder_boots",
        Name = "Marauder Boots",
        Kind = "Equipment",
        Slot = "Boots",
        Category = "HeavyArmor",
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        CombatModifiers = table.freeze({
            MaxHealthFlat = 3,
        }),
    }),

    test_elf_helmet = table.freeze({
        Id = "test_elf_helmet",
        Name = "TEST Elven Helmet",
        Kind = "Equipment",
        Slot = "Helmet",
        Category = "LightArmor",
        AllowedRaces = ELF,
        AllowedBaseClasses = FIGHTER,
        Rarity = "Basic",
        Stackable = false,
        TestOnly = true,
    }),

    captain_emblem = table.freeze({
        Id = "captain_emblem",
        Name = "Captain's Emblem",
        Kind = "Material",
        Rarity = "Uncommon",
        Stackable = true,
    }),

    skill_book_test = table.freeze({
        Id = "skill_book_test",
        Name = "Unidentified Skill Book",
        Kind = "SkillBook",
        Rarity = "Rare",
        Stackable = true,
        Learnable = false,
    }),

    arc_slash_book_bound = table.freeze({
        Id = "arc_slash_book_bound",
        Name = "Arc Slash Skill Book",
        Kind = "SkillBook",
        Rarity = "Rare",
        Stackable = false,
        Learnable = true,
        Bound = true,
        Tradeable = false,
        SkillId = "ArcSlash",
    }),
})

--[[
Returns one immutable item definition by stable item ID.

Args:
    item_id (string): Stable item identifier.

Returns:
    any?: Frozen item definition, or nil when the ID is unknown.
]]
function ItemDefinitions.get(item_id: string): any?
    return DEFINITIONS[item_id]
end

--[[
Returns the complete immutable item-definition catalogue.

Args:
    None.

Returns:
    any: Frozen item-definition table keyed by stable item ID.
]]
function ItemDefinitions.all(): any
    return DEFINITIONS
end

return table.freeze(ItemDefinitions)
