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
        error("[Shield Camera Visual Tests] " .. message, 2)
    end
end

local character = Instance.new("Model")

local visual, source =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        nil,
        0
    )

check(visual ~= nil, "visual must not require the replicated shield source.")
check(source == "CameraClientVisual", "camera visual mode must be reported.")
check(visual ~= nil and visual.Parent ~= character, "visual must not be parented to the character.")

local first_visual = visual

local server_shield = Instance.new("Part")
server_shield.Name = ShieldConfig.PART_NAME
server_shield.Size = ShieldConfig.SIZE
server_shield.CFrame = CFrame.new(-2, 3, 0)
server_shield.Parent = character

local after_source, after_source_name =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        visual,
        0
    )

check(after_source == first_visual, "late source replication must not replace the visual.")
check(after_source_name == "CameraClientVisual", "late source replication must preserve camera visual mode.")
check(server_shield.LocalTransparencyModifier == 1, "late source shield must be hidden locally.")

server_shield:Destroy()

local after_destroy, after_destroy_source =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        visual,
        0
    )

check(after_destroy == first_visual, "losing the server shield must not destroy the camera visual.")
check(after_destroy_source == "CameraClientVisual", "visual must stay independent after source destruction.")
check(first_visual ~= nil and first_visual.Parent ~= nil, "camera visual must remain alive.")

first_visual.Transparency = 1
first_visual.LocalTransparencyModifier = 1

local recovered =
    ShieldPresentationBinding.ensure_visual(
        character,
        ShieldConfig,
        first_visual,
        0
    )

check(recovered == first_visual, "visibility recovery must preserve the visual instance.")
check(
    first_visual.Transparency == 0
        and first_visual.LocalTransparencyModifier == 0,
    "ensure_visual must recover accidental transparency."
)

ShieldPresentationBinding.release_visual(
    character,
    ShieldConfig,
    first_visual
)

character:Destroy()

print(string.format(
    "[Shield Camera Visual Tests] PASS: %d assertions.",
    assertions
))
