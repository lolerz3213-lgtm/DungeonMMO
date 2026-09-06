--!strict
local ProgressionHudRules = {}

function ProgressionHudRules.format_summary(
    level: number,
    xp: number,
    gold: number,
    ap_available: number,
    sp_available: number,
    required_xp: number?
): string
    if required_xp == nil then
        return string.format(
            "Level %d | XP MAX | Gold %d | AP %d | SP %d",
            level,
            xp,
            gold,
            ap_available,
            sp_available
        )
    end

    return string.format(
        "Level %d | XP %d/%d | Gold %d | AP %d | SP %d",
        level,
        xp,
        required_xp,
        gold,
        ap_available,
        sp_available
    )
end

return table.freeze(ProgressionHudRules)
