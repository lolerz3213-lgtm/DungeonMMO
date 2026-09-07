--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(Shared:WaitForChild("CombatConfig"))
local PrototypeAnimationFactory = require(
    Shared:WaitForChild("PrototypeAnimationFactory")
)

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Published Sword Animation Fallback Tests] " .. message, 2)
    end
end

check(
    type(PrototypeAnimationFactory.sample_attack_pose) == "function",
    "RED: source-controlled attack poses need a runtime sampler for published play."
)

check(
    type(PrototypeAnimationFactory.get_carry_pose) == "function",
    "published fallback must expose a source-controlled sword carry pose."
)

for _, attack_id in CombatConfig.BASIC_ATTACK.ATTACK_ORDER do
    local definition = CombatConfig.BASIC_ATTACK.ATTACKS[attack_id]
    local total =
        definition.WIND_UP_SECONDS
        + definition.ACTIVE_SECONDS
        + definition.RECOVERY_SECONDS

    local start_pose = PrototypeAnimationFactory.sample_attack_pose(
        attack_id,
        definition,
        0
    )
    local contact_pose = PrototypeAnimationFactory.sample_attack_pose(
        attack_id,
        definition,
        definition.WIND_UP_SECONDS
            + (definition.ACTIVE_SECONDS * 0.55)
    )
    local end_pose = PrototypeAnimationFactory.sample_attack_pose(
        attack_id,
        definition,
        total
    )

    check(
        typeof(start_pose.RightUpperArm) == "CFrame",
        attack_id .. " published fallback must drive the sword shoulder."
    )
    check(
        typeof(contact_pose.RightLowerArm) == "CFrame",
        attack_id .. " published fallback must drive the sword elbow."
    )
    check(
        typeof(end_pose.RightHand) == "CFrame",
        attack_id .. " published fallback must return the sword hand cleanly."
    )
end

local carry_pose = PrototypeAnimationFactory.get_carry_pose()
check(
    typeof(carry_pose.RightUpperArm) == "CFrame"
        and carry_pose.LeftUpperArm == nil,
    "published carry fallback must retain the sword arm without owning the shield arm."
)

print(string.format(
    "[Published Sword Animation Fallback Tests] PASS: %d assertions.",
    assertions
))
