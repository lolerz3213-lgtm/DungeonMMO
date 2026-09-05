local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local ShieldPresentationBinding = require(
    shared_folder:WaitForChild("ShieldPresentationBinding")
)

local ShieldConfig = CombatConfig.PROTOTYPE_SHIELD
local assertions = 0

local function expect(condition: boolean, message: string)
    assertions += 1

    if not condition then
        error("[Shield Presentation Binding Tests] " .. message)
    end
end

local function make_character(include_grip: boolean): Model
    local character = Instance.new("Model")
    local root = Instance.new("Part")
    local shield = Instance.new("Part")

    root.Name = ShieldConfig.ATTACH_PART_NAME
    root.Anchored = true
    root.CFrame = CFrame.new(0, 3, 0)
    root.Parent = character

    shield.Name = ShieldConfig.PART_NAME
    shield.Anchored = false
    shield.CFrame = CFrame.new(-2, 3, 0)
    shield.Parent = character

    if include_grip then
        local grip = Instance.new("Motor6D")

        grip.Name = ShieldConfig.GRIP_NAME
        grip.Part0 = root
        grip.Part1 = shield
        grip.C0 = root.CFrame:ToObjectSpace(shield.CFrame)
        grip.Parent = root
    end

    return character
end

local replicated_character = make_character(true)
local replicated_grip, replicated_source =
    ShieldPresentationBinding.resolve(
        replicated_character,
        ShieldConfig,
        0
    )

expect(replicated_grip ~= nil, "Existing replicated grip must resolve.")
expect(replicated_source == "Replicated", "Existing grip must be preferred.")
expect(
    replicated_grip ~= nil
        and replicated_grip.Name == ShieldConfig.GRIP_NAME,
    "Existing grip name must remain authoritative."
)
replicated_character:Destroy()

local fallback_character = make_character(false)
local fallback_grip, fallback_source =
    ShieldPresentationBinding.resolve(
        fallback_character,
        ShieldConfig,
        0
    )

expect(fallback_grip ~= nil, "Missing replicated grip must get a fallback.")
expect(fallback_source == "ClientFallback", "Fallback path must be reported.")
expect(
    fallback_grip ~= nil
        and fallback_grip.Part0 ~= nil
        and fallback_grip.Part1 ~= nil,
    "Fallback grip must connect attachment part to shield."
)
expect(
    fallback_grip ~= nil
        and fallback_grip.Name
            == ShieldConfig.GRIP_NAME .. "ClientFallback",
    "Fallback grip needs a distinct presentation-only name."
)
fallback_character:Destroy()

print(
    "[Shield Presentation Binding Tests] PASS: "
        .. assertions
        .. " assertions."
)
