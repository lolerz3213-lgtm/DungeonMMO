--!strict
local ProgressionConfig = {}

ProgressionConfig.MAX_LEVEL = 10
local XP_TO_NEXT_LEVEL = table.freeze({
    [1] = 100,
    [2] = 150,
    [3] = 200,
    [4] = 275,
    [5] = 350,
    [6] = 450,
    [7] = 575,
    [8] = 725,
    [9] = 900,
})

function ProgressionConfig.get_required_xp(level: number): number?
    assert(level >= 1 and level % 1 == 0, "level must be a positive integer")
    if level >= ProgressionConfig.MAX_LEVEL then return nil end
    return XP_TO_NEXT_LEVEL[level]
end

function ProgressionConfig.level_entitlement(level: number): number
    return math.clamp(math.floor(level) - 1, 0, ProgressionConfig.MAX_LEVEL - 1)
end

return table.freeze(ProgressionConfig)
