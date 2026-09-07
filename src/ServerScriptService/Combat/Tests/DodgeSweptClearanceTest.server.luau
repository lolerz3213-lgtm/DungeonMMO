--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local DodgeClearanceRules = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("DodgeClearanceRules")
)

local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1

    if not condition then
        error("[Dodge Swept Clearance Tests] " .. message, 2)
    end
end

local root_size = Vector3.new(2, 2, 1)
local clearance = 1.25

local probe_size =
    DodgeClearanceRules.get_probe_size(
        root_size,
        clearance
    )

check(
    probe_size.X > root_size.X,
    "probe must be wider than the point/root ray."
)
check(
    probe_size.Z > root_size.Z,
    "probe must cover character depth."
)
check(
    probe_size.Y >= 1
        and probe_size.Y < root_size.Y,
    "probe must cover the lower body without extending into the floor."
)

local margin =
    DodgeClearanceRules.get_safety_margin(
        clearance
    )

check(
    margin > 0 and margin < clearance,
    "swept-volume margin must be positive but smaller than the old point-ray clearance."
)

local requested = 20
local delta = 0.05

check(
    DodgeClearanceRules.limit_speed(
        requested,
        delta,
        nil,
        clearance,
        false
    ) == requested,
    "open path must preserve requested dodge speed."
)

check(
    DodgeClearanceRules.limit_speed(
        requested,
        delta,
        10,
        clearance,
        true
    ) == 0,
    "initial collidable overlap must stop dodge movement."
)

local near_speed =
    DodgeClearanceRules.limit_speed(
        requested,
        delta,
        margin + 0.25,
        clearance,
        false
    )

check(
    near_speed >= 0 and near_speed < requested,
    "near swept collision must reduce speed before overlap."
)

check(
    DodgeClearanceRules.limit_speed(
        requested,
        delta,
        0,
        clearance,
        false
    ) == 0,
    "immediate swept collision must stop travel."
)

print(string.format(
    "[Dodge Swept Clearance Tests] PASS: %d assertions.",
    assertions
))
