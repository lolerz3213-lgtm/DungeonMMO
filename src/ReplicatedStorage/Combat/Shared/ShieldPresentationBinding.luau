local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ShieldPresentationBinding = {}

local SERVER_TEST_FOLDER_NAME =
    "DungeonMMOLocalPresentationTest"

local function get_server_shield(
    character: Model,
    shield_config: any
): BasePart?
    local shield = character:FindFirstChild(
        shield_config.PART_NAME
    )

    if shield and shield:IsA("BasePart") then
        return shield
    end

    return nil
end

local function hide_server_shield(
    character: Model,
    shield_config: any
)
    local shield = get_server_shield(
        character,
        shield_config
    )

    if shield then
        shield.LocalTransparencyModifier = 1
    end
end

function ShieldPresentationBinding.get_visual_name(
    shield_config: any
): string
    return shield_config.PART_NAME .. "ClientVisual"
end

local function get_presentation_parent(): Instance
    if RunService:IsClient() then
        local camera = Workspace.CurrentCamera

        if camera then
            return camera
        end
    end

    local existing = Workspace:FindFirstChild(
        SERVER_TEST_FOLDER_NAME
    )

    if existing and existing:IsA("Folder") then
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = SERVER_TEST_FOLDER_NAME
    folder.Parent = Workspace

    return folder
end

local function apply_visual_properties(
    visual: BasePart,
    shield_config: any
)
    visual.Size = shield_config.SIZE
    visual.Anchored = true
    visual.CanCollide = false
    visual.CanTouch = false
    visual.CanQuery = false
    visual.Massless = true
    visual.CastShadow = false
    visual.Transparency = 0
    visual.LocalTransparencyModifier = 0
end

local function create_visual(
    character: Model,
    shield_config: any
): BasePart
    local server_shield = get_server_shield(
        character,
        shield_config
    )
    local visual: BasePart

    if server_shield then
        visual = server_shield:Clone()
    else
        local part = Instance.new("Part")
        part.Color = Color3.fromRGB(88, 94, 104)
        part.Material = Enum.Material.Metal
        part.CFrame = CFrame.new(0, -1000, 0)
        visual = part
    end

    visual.Name =
        ShieldPresentationBinding.get_visual_name(
            shield_config
        )

    for _, descendant in visual:GetDescendants() do
        if descendant:IsA("JointInstance")
            or descendant:IsA("Constraint")
            or descendant:IsA("Attachment") then
            descendant:Destroy()
        end
    end

    apply_visual_properties(
        visual,
        shield_config
    )

    visual:SetAttribute(
        "DungeonMMOIntentionalRelease",
        false
    )

    visual.Destroying:Connect(function()
        if visual:GetAttribute(
            "DungeonMMOIntentionalRelease"
        ) ~= true then
            warn(
                "[Combat Prototype] Shield camera visual "
                    .. "was destroyed unexpectedly."
            )
        end
    end)

    visual.Parent = get_presentation_parent()

    print(
        "[Combat Prototype] Shield camera visual created."
    )

    return visual
end

function ShieldPresentationBinding.ensure_visual(
    character: Model,
    shield_config: any,
    current_visual: BasePart?,
    _timeout_seconds: number
): (BasePart?, string)
    hide_server_shield(
        character,
        shield_config
    )

    local visual_name =
        ShieldPresentationBinding.get_visual_name(
            shield_config
        )
    local presentation_parent =
        get_presentation_parent()

    if current_visual
        and current_visual.Parent
        and current_visual.Name == visual_name then
        if current_visual.Parent ~= presentation_parent then
            current_visual.Parent = presentation_parent

            print(
                "[Combat Prototype] Shield camera visual "
                    .. "reparented to current camera."
            )
        end

        apply_visual_properties(
            current_visual,
            shield_config
        )

        return current_visual, "CameraClientVisual"
    end

    local existing = presentation_parent:FindFirstChild(
        visual_name
    )

    if existing and existing:IsA("BasePart") then
        apply_visual_properties(
            existing,
            shield_config
        )
        return existing, "CameraClientVisual"
    end

    if existing then
        existing:Destroy()
    end

    return create_visual(
        character,
        shield_config
    ), "CameraClientVisual"
end

function ShieldPresentationBinding.set_visual_cframe(
    visual: BasePart?,
    desired_cframe: CFrame
)
    if not visual or not visual.Parent then
        return
    end

    visual.Transparency = 0
    visual.LocalTransparencyModifier = 0
    visual.CFrame = desired_cframe
end

function ShieldPresentationBinding.release_visual(
    character: Model?,
    shield_config: any,
    visual: BasePart?
)
    if visual and visual.Parent then
        visual:SetAttribute(
            "DungeonMMOIntentionalRelease",
            true
        )
        visual:Destroy()
    end

    if character then
        local server_shield = get_server_shield(
            character,
            shield_config
        )

        if server_shield then
            server_shield.LocalTransparencyModifier = 0
        end
    end

    local folder = Workspace:FindFirstChild(
        SERVER_TEST_FOLDER_NAME
    )

    if folder
        and folder:IsA("Folder")
        and #folder:GetChildren() == 0 then
        folder:Destroy()
    end
end

return ShieldPresentationBinding
