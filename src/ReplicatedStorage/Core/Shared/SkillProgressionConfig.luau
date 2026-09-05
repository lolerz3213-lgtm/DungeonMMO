--!strict
local SkillProgressionConfig = {}

SkillProgressionConfig.MAX_ACTIVE_SLOTS = 6

local COSTS = table.freeze({
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
})

local THRESHOLDS = table.freeze({
    Common = table.freeze({[2] = 100, [3] = 300}),
    Uncommon = table.freeze({[2] = 150, [3] = 400}),
    Rare = table.freeze({[2] = 200, [3] = 500}),
    Epic = table.freeze({[2] = 300, [3] = 700}),
    Legendary = table.freeze({[2] = 400, [3] = 900}),
})

function SkillProgressionConfig.get_rank_cost(tier: string, _rank: number): number?
    return COSTS[tier]
end

function SkillProgressionConfig.get_threshold(tier: string, target_rank: number): number?
    local tier_thresholds = THRESHOLDS[tier]
    return if tier_thresholds then tier_thresholds[target_rank] else nil
end

function SkillProgressionConfig.get_max_threshold(tier: string): number
    local tier_thresholds = THRESHOLDS[tier]
    if not tier_thresholds then return 0 end
    local maximum = 0
    for _, value in pairs(tier_thresholds) do
        maximum = math.max(maximum, value)
    end
    return maximum
end

return table.freeze(SkillProgressionConfig)
