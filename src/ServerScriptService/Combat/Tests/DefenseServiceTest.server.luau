local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")
local combat_folder = ServerScriptService:WaitForChild("Combat")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local DefenseService = require(
    combat_folder:WaitForChild("DefenseService")
)
local StaminaService = require(
    combat_folder:WaitForChild("StaminaService")
)

local assertion_count = 0

local function assert_true(condition: boolean, message: string)
    if not condition then
        error("[Defense Service Tests] " .. message, 2)
    end

    assertion_count += 1
end

local function assert_equal(actual: any, expected: any, message: string)
    assert_true(
        actual == expected,
        string.format(
            "%s Expected %s, received %s.",
            message,
            tostring(expected),
            tostring(actual)
        )
    )
end

local function create_character(name: string): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = CFrame.new(0, 20, 0)
    root.Parent = model
    model.PrimaryPart = root

    return model
end

local function resolve_front_hit(
    player: any,
    character: Model,
    now: number,
    stamina_damage: number,
    parryable: boolean
)
    return DefenseService.resolve({
        attacker = nil,
        target_player = player,
        target_character = character,
        source_kind = "EnemyMelee",
        source_id = "TestStrike",
        attack_position = Vector3.new(0, 20, -4),
        stamina_damage = stamina_damage,
        blockable = true,
        parryable = parryable,
    }, now)
end

local subject = Instance.new("Folder")
subject.Name = "DefenseTestSubject"
subject.Parent = workspace
local fake_player = subject :: any
local character = create_character("DefenseTestCharacter")

StaminaService.initialize_player(fake_player)

DefenseService.begin_dodge(fake_player, character, 10)
local dodged = resolve_front_hit(
    fake_player,
    character,
    10.10,
    30,
    true
)
assert_equal(dodged.outcome, "Dodged", "Active i-frames must win first.")
DefenseService.end_dodge(fake_player)

DefenseService.begin_block(fake_player, character, 20)
local parried = resolve_front_hit(
    fake_player,
    character,
    20.10,
    30,
    true
)
assert_equal(parried.outcome, "Parried", "Opening frontal hit must parry.")
assert_equal(parried.stamina_spent, 0, "Parry must cost no Stamina.")
assert_equal(
    parried.attacker_stagger_seconds,
    CombatConfig.DEFENSE.PARRY_ATTACKER_STAGGER_SECONDS,
    "Parry stagger duration is wrong."
)

local same_press_second_hit = resolve_front_hit(
    fake_player,
    character,
    20.11,
    10,
    true
)
assert_equal(
    same_press_second_hit.outcome,
    "Blocked",
    "One block press may parry only one incoming attack."
)
assert_equal(
    same_press_second_hit.stamina_spent,
    10,
    "Second same-window hit must spend block Stamina."
)

local blocked = resolve_front_hit(
    fake_player,
    character,
    20.30,
    30,
    true
)
assert_equal(blocked.outcome, "Blocked", "Late frontal hit must block.")
assert_equal(blocked.stamina_spent, 30, "Block Stamina cost is wrong.")
assert_equal(
    StaminaService.get(fake_player),
    60,
    "Two blocked hits must leave 60 Stamina after one parry."
)

local rear = DefenseService.resolve({
    attacker = nil,
    target_player = fake_player,
    target_character = character,
    source_kind = "EnemyMelee",
    source_id = "RearStrike",
    attack_position = Vector3.new(0, 20, 4),
    stamina_damage = 30,
    blockable = true,
    parryable = true,
}, 20.31)
assert_equal(rear.outcome, "Hit", "Rear attack must bypass block.")
DefenseService.end_block(fake_player)

StaminaService.reset_player(fake_player)
DefenseService.begin_block(fake_player, character, 30)
local unparryable = resolve_front_hit(
    fake_player,
    character,
    30.05,
    10,
    false
)
assert_equal(
    unparryable.outcome,
    "Blocked",
    "Unparryable frontal hit must fall back to block."
)
DefenseService.end_block(fake_player)

StaminaService.reset_player(fake_player)
local guard_broke = false
local connection = DefenseService.on_guard_break(function(player)
    if player == fake_player then
        guard_broke = true
    end
end)

DefenseService.begin_block(fake_player, character, 40)
local swarm_outcomes = {}

for index = 1, 4 do
    local result = resolve_front_hit(
        fake_player,
        character,
        40.30 + (index * 0.01),
        25,
        true
    )
    table.insert(swarm_outcomes, result.outcome)
end

assert_equal(swarm_outcomes[1], "Blocked", "Swarm hit 1 must block.")
assert_equal(swarm_outcomes[2], "Blocked", "Swarm hit 2 must block.")
assert_equal(swarm_outcomes[3], "Blocked", "Swarm hit 3 must block.")
assert_equal(
    swarm_outcomes[4],
    "GuardBroken",
    "The hit that exhausts Stamina must Guard Break."
)
assert_equal(
    StaminaService.get(fake_player),
    0,
    "Swarm pressure must be able to exhaust Stamina."
)
task.wait()
assert_true(guard_broke, "Guard Break event must fire.")

local post_break = resolve_front_hit(
    fake_player,
    character,
    40.40,
    25,
    true
)
assert_equal(
    post_break.outcome,
    "Hit",
    "A later swarm hit after Guard Break must reach health damage."
)

connection:Disconnect()
DefenseService.clear(fake_player)
StaminaService.remove_player(fake_player)
subject:Destroy()
character:Destroy()

print(
    string.format(
        "[Defense Service Tests] PASS: %d assertions.",
        assertion_count
    )
)
