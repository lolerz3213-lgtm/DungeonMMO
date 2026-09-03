local CollectionService = game:GetService(
    "CollectionService"
)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)
local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local combat_folder = ServerScriptService
    :WaitForChild("Combat")
local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local module_script = combat_folder:FindFirstChild(
    "CombatTargetRules"
)

if not module_script then
    error(
        "[Combat Target Rules Tests] RED: "
            .. "CombatTargetRules module is missing."
    )
end

local CombatTargetRules = require(module_script)

local assertion_count = 0


--[[
Raises an error when a target-rules assertion fails.

Args:
    condition (boolean): Required test condition.
    message (string): Failure explanation.

Returns:
    None.
]]
local function assert_true(
    condition: boolean,
    message: string
)
    assertion_count += 1

    if not condition then
        error(
            "[Combat Target Rules Tests] "
                .. message
        )
    end
end


--[[
Creates a simple Model with an optional Humanoid.

Args:
    name (string): Model name.
    with_humanoid (boolean): Whether to add a Humanoid.
    health (number?): Initial health when Humanoid exists.

Returns:
    Model: Test target Model.
]]
local function create_target(
    name: string,
    with_humanoid: boolean,
    health: number?
): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace

    if with_humanoid then
        local humanoid = Instance.new("Humanoid")

        humanoid.MaxHealth = 100
        humanoid.Health = health or 100
        humanoid.Parent = model
    end

    return model
end


--[[
Waits briefly for the Studio test player.

Args:
    None.

Returns:
    Player?: First connected player when available.
]]
local function get_test_player(): Player?
    local deadline = os.clock() + 5

    repeat
        local players = Players:GetPlayers()

        if #players > 0 then
            return players[1]
        end

        task.wait(0.05)
    until os.clock() >= deadline

    return nil
end


local npc_tag = CombatConfig.TARGETS
    and CombatConfig.TARGETS.NPC_TAG

assert_true(
    npc_tag ~= nil,
    "CombatConfig.TARGETS.NPC_TAG must exist."
)

local attacker = create_target(
    "TargetRulesAttacker",
    true,
    100
)
local tagged_npc = create_target(
    "TargetRulesTaggedNpc",
    true,
    100
)
local untagged_npc = create_target(
    "TargetRulesUntaggedNpc",
    true,
    100
)
local dead_npc = create_target(
    "TargetRulesDeadNpc",
    true,
    0
)
local no_humanoid = create_target(
    "TargetRulesNoHumanoid",
    false,
    nil
)

CollectionService:AddTag(
    tagged_npc,
    npc_tag
)
CollectionService:AddTag(
    dead_npc,
    npc_tag
)
CollectionService:AddTag(
    no_humanoid,
    npc_tag
)

local valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        tagged_npc
    )

assert_true(
    valid,
    "Tagged living NPC must be accepted: "
        .. tostring(reason)
)

valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        untagged_npc
    )

assert_true(
    not valid and reason == "NotCombatTarget",
    "Untagged NPC must be rejected."
)

valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        dead_npc
    )

assert_true(
    not valid and reason == "Dead",
    "Dead tagged NPC must be rejected."
)

valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        attacker
    )

assert_true(
    not valid and reason == "Self",
    "Attacker must not damage itself."
)

valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        nil
    )

assert_true(
    not valid and reason == "MissingTarget",
    "Missing target must be rejected."
)

valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        no_humanoid
    )

assert_true(
    not valid and reason == "MissingHumanoid",
    "Tagged Model without Humanoid must be rejected."
)

local player = get_test_player()

assert_true(
    player ~= nil,
    "Studio test player must exist."
)

if player then
    local character = player.Character
        or player.CharacterAdded:Wait()

    CollectionService:AddTag(
        character,
        npc_tag
    )

    valid, reason =
        CombatTargetRules.is_damageable(
            attacker,
            character
        )

    assert_true(
        not valid
            and reason
                == "PlayerTargetDisabled",
        "Player character must be rejected."
    )

    CollectionService:RemoveTag(
        character,
        npc_tag
    )
end

for _, model in {
    attacker,
    tagged_npc,
    untagged_npc,
    dead_npc,
    no_humanoid,
} do
    model:Destroy()
end

print(
    string.format(
        "[Combat Target Rules Tests] PASS: "
            .. "%d assertions.",
        assertion_count
    )
)
