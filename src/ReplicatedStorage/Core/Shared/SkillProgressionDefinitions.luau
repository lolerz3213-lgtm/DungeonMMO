--!strict
local SkillProgressionDefinitions = {}

local DEFINITIONS = table.freeze({
    Mend = table.freeze({Id = "Mend", Tier = "Common", MaxRank = 3, Kind = "Support", WeaponTags = {}}),
    ShieldBash = table.freeze({Id = "ShieldBash", Tier = "Uncommon", MaxRank = 3, Kind = "Physical", WeaponTags = {}}),
    ArcSlash = table.freeze({Id = "ArcSlash", Tier = "Rare", MaxRank = 3, Kind = "Physical", WeaponTags = {"OneHandedSword"}}),
})

function SkillProgressionDefinitions.get(skill_id: string): any?
    return DEFINITIONS[skill_id]
end

function SkillProgressionDefinitions.all(): any
    return DEFINITIONS
end

return table.freeze(SkillProgressionDefinitions)
