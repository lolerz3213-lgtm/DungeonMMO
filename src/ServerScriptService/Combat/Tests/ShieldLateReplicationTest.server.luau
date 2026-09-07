--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(Shared:WaitForChild("CombatConfig"))
local ShieldPresentationBinding = require(
    Shared:WaitForChild("ShieldPresentationBinding")
)

local ShieldConfig = CombatConfig.PROTOTYPE_SHIELD
local assertions = 0

local function check(condition: boolean, message: string)
    assertions += 1
    if not condition then
        error("[Shield Late Replication Tests] " .. message, 2)
    end
end

local function make_character(): (Model, BasePart, BasePart)
    local character = Instance.new("Model")

    local root = Instance.new("Part")
    root.Name = ShieldConfig.ATTACH_PART_NAME
    root.Anchored = true
    root.CFrame = CFrame.new(0, 3, 0)
    root.Parent = character

    local shield = Instance.new("Part")
    shield.Name = ShieldConfig.PART_NAME
    shield.Anchored = false
    shield.CFrame = CFrame.new(-2, 3, 0)
    shield.Parent = character

    return character, root, shield
end

check(
    type(ShieldPresentationBinding.reconcile) == "function",
    "RED: presentation binding must reconcile a local fallback when the replicated server grip arrives late."
)

local character, root, shield = make_character()

local fallback, source = ShieldPresentationBinding.resolve(
    character,
    ShieldConfig,
    0
)

check(
    fallback ~= nil and source == "ClientFallback",
    "test setup must create the client fallback first."
)

local replicated = Instance.new("Motor6D")
replicated.Name = ShieldConfig.GRIP_NAME
replicated.Part0 = root
replicated.Part1 = shield
replicated.C0 = root.CFrame:ToObjectSpace(shield.CFrame)
replicated.C1 = CFrame.identity
replicated.Parent = root

local preferred, preferred_source =
    ShieldPresentationBinding.reconcile(
        character,
        ShieldConfig,
        fallback
    )

check(
    preferred == replicated,
    "late authoritative server grip must replace the fallback."
)
check(
    preferred_source == "Replicated",
    "reconciled binding source must report Replicated."
)
check(
    fallback == nil or fallback.Parent == nil,
    "client fallback must be destroyed after authoritative grip takeover."
)

character:Destroy()

local incomplete_character = Instance.new("Model")

local reconcile_ok, incomplete_grip, incomplete_source = pcall(
    function()
        return ShieldPresentationBinding.reconcile(
            incomplete_character,
            ShieldConfig,
            nil
        )
    end
)

check(
    reconcile_ok == true,
    "reconcile must not throw while character parts are being removed."
)
check(
    incomplete_grip == nil,
    "incomplete character must not create a presentation grip."
)
check(
    incomplete_source == "AttachPartMissing",
    "incomplete character must report AttachPartMissing without yielding."
)

incomplete_character:Destroy()

local startup_character, startup_root, _startup_shield =
    make_character()

local early_fallback, early_source =
    ShieldPresentationBinding.reconcile(
        startup_character,
        ShieldConfig,
        nil
    )

check(
    early_fallback ~= nil
        and early_source == "ClientFallback",
    "startup race setup must create the early reconciliation fallback."
)

local late_resolved, late_source =
    ShieldPresentationBinding.resolve(
        startup_character,
        ShieldConfig,
        0.01
    )

local fallback_count = 0
for _, child in startup_root:GetChildren() do
    if child:IsA("Motor6D")
        and child.Name
            == ShieldConfig.GRIP_NAME .. "ClientFallback" then
        fallback_count += 1
    end
end

check(
    late_resolved == early_fallback
        and late_source == "ClientFallback"
        and fallback_count == 1,
    "startup resolver must reuse the fallback created by reconciliation instead of creating a second grip."
)

startup_character:Destroy()

print(string.format(
    "[Shield Late Replication Tests] PASS: %d assertions.",
    assertions
))
