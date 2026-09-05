local AggroGraceRules = {}


--[[Returns whether a living player character is eligible for Marauder aggro.]]
function AggroGraceRules.can_target(aggro_suppressed: boolean): boolean
    return aggro_suppressed ~= true
end


return table.freeze(AggroGraceRules)
