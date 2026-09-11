--!strict
local SkillProgressionDefinitions = {}

local DEFINITIONS = table.freeze({
    Mend = table.freeze({
        Id = "Mend",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Support",
        WeaponTags = table.freeze({}),
    }),

    ShieldBash = table.freeze({
        Id = "ShieldBash",
        Tier = "Uncommon",
        MaxRank = 3,
        Kind = "Physical",
        WeaponTags = table.freeze({}),
    }),

    ArcSlash = table.freeze({
        Id = "ArcSlash",
        Tier = "Rare",
        MaxRank = 3,
        Kind = "Physical",
        WeaponTags = table.freeze({
            "OneHandedSword",
        }),
    }),

    WindStrike = table.freeze({
        Id = "WindStrike",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Magic",
        WeaponTags = table.freeze({
            "ArcaneWand",
        }),
    }),

    ArcaneWard = table.freeze({
        Id = "ArcaneWard",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Support",
        WeaponTags = table.freeze({
            "ArcaneWand",
        }),
    }),

    MageHeal = table.freeze({
        Id = "MageHeal",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Support",
        WeaponTags = table.freeze({
            "ArcaneWand",
        }),
    }),

    PiercingShot = table.freeze({
        Id = "PiercingShot",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Physical",
        WeaponTags = table.freeze({
            "Longbow",
        }),
    }),

    CripplingShot = table.freeze({
        Id = "CripplingShot",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Control",
        WeaponTags = table.freeze({
            "Longbow",
        }),
    }),

    Volley = table.freeze({
        Id = "Volley",
        Tier = "Common",
        MaxRank = 3,
        Kind = "Physical",
        WeaponTags = table.freeze({
            "Longbow",
        }),
    }),
})

function SkillProgressionDefinitions.get(
    skill_id: string
): any?
    return DEFINITIONS[skill_id]
end

function SkillProgressionDefinitions.all(): any
    return DEFINITIONS
end

return table.freeze(
    SkillProgressionDefinitions
)
