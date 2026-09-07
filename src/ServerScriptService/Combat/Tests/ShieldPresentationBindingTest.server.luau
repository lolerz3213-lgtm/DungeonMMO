local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

local character = Instance.new("Model")

local shield = Instance.new("Part")
shield.Name = ShieldConfig.PART_NAME
shield.Size = ShieldConfig.SIZE
shield.Anchored = false
shield.CanCollide = false
shield.CFrame = CFrame.new(-2, 3, 0)
shield.Parent = character

local visual, source =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        nil,
        0
    )

expect(visual ~= nil, "Client visual must be created.")
expect(source == "CameraClientVisual", "Camera visual source must be reported.")
expect(visual ~= nil and visual.Parent ~= character, "Client visual must live outside the character model.")
expect(
    visual ~= nil
        and visual.Name
            == ShieldPresentationBinding.get_visual_name(
                ShieldConfig
            ),
    "Client visual must use the configured presentation name."
)
expect(
    visual ~= nil
        and visual.Anchored
        and not visual.CanCollide
        and not visual.CanTouch
        and not visual.CanQuery,
    "Client visual must be presentation-only."
)
expect(shield.LocalTransparencyModifier == 1, "Replicated source shield must be hidden locally while present.")

local reused, reused_source =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        visual,
        0
    )

expect(reused == visual and reused_source == "CameraClientVisual", "ensure_visual must reuse the same visual.")

local target = CFrame.new(4, 5, 6)
ShieldPresentationBinding.set_visual_cframe(visual, target)

expect(visual ~= nil and visual.CFrame == target, "Client visual must accept direct world-space positioning.")
expect(
    visual ~= nil
        and visual.Transparency == 0
        and visual.LocalTransparencyModifier == 0,
    "Client visual must be explicitly kept visible."
)

ShieldPresentationBinding.release_visual(
    character,
    ShieldConfig,
    visual
)

expect(visual == nil or visual.Parent == nil, "release_visual must destroy the client visual.")
expect(shield.LocalTransparencyModifier == 0, "release_visual must restore the source shield locally.")

character:Destroy()

local folder = Workspace:FindFirstChild(
    "DungeonMMOLocalPresentationTest"
)

expect(
    folder == nil or #folder:GetChildren() == 0,
    "test cleanup must leave no presentation visuals behind."
)

print(
    "[Shield Presentation Binding Tests] PASS: "
        .. assertions
        .. " assertions."
)
