--!strict
local RangerSlowService = require(
    script.Parent.Parent:WaitForChild("RangerSlowService")
)

local target = Instance.new("Model")
target.Name = "RangerSlowTestTarget"
target.Parent = workspace

assert(RangerSlowService.get_multiplier(target) == 1)
assert(RangerSlowService.apply(target, 0.30, 3.0) == true)
assert(math.abs(RangerSlowService.get_multiplier(target) - 0.70) < 0.001)

-- A weaker application refreshes but never weakens the active effect.
assert(RangerSlowService.apply(target, 0.20, 4.0) == true)
assert(math.abs(RangerSlowService.get_multiplier(target) - 0.70) < 0.001)

-- A stronger effect replaces strength without multiplicative stacking.
assert(RangerSlowService.apply(target, 0.40, 4.0) == true)
assert(math.abs(RangerSlowService.get_multiplier(target) - 0.60) < 0.001)

RangerSlowService.clear(target)
assert(RangerSlowService.get_multiplier(target) == 1)

-- Cleanup must remain neutral even after the NPC leaves the data model.
target.Parent = nil
RangerSlowService.clear(target)
assert(RangerSlowService.get_multiplier(target) == 1)
target:Destroy()

print("[RangerSlowServiceTest] PASS")
