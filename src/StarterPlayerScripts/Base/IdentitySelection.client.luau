--!strict
-- Mandatory Phase 2C.A Base character identity flow.
--
-- The client never changes authoritative identity optimistically.
-- It selects a candidate locally, sends a request, then waits for
-- the next authoritative ProgressionSnapshot before changing stage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local player = Players.LocalPlayer

local Core = ReplicatedStorage
    :WaitForChild("Core")

local Remotes =
    Core:WaitForChild("Remotes")

local progression_snapshot =
    Remotes:WaitForChild(
        "ProgressionSnapshot"
    ) :: RemoteEvent

local identity_selection =
    Remotes:WaitForChild(
        "IdentitySelectionRequest"
    ) :: RemoteEvent

local action_result =
    Remotes:WaitForChild(
        "ProgressionActionResult"
    ) :: RemoteEvent

local ProgressionClientState = require(
    script.Parent.Parent
        :WaitForChild("Core")
        :WaitForChild(
            "ProgressionClientState"
        )
)

local gui = Instance.new("ScreenGui")
gui.Name = "IdentitySelectionUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 250
gui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling
gui.Parent =
    player:WaitForChild("PlayerGui")

local blocker = Instance.new("Frame")
blocker.Name = "MandatoryOverlay"
blocker.Size = UDim2.fromScale(1, 1)
blocker.BackgroundColor3 =
    Color3.fromRGB(8, 10, 14)
blocker.BackgroundTransparency = 0.08
blocker.BorderSizePixel = 0
blocker.Active = true
blocker.Visible = false
blocker.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "SelectionPanel"
panel.AnchorPoint =
    Vector2.new(0.5, 0.5)
panel.Position =
    UDim2.fromScale(0.5, 0.5)
panel.Size =
    UDim2.new(0.82, 0, 0.80, 0)
panel.BackgroundColor3 =
    Color3.fromRGB(24, 28, 36)
panel.BorderSizePixel = 0
panel.Parent = blocker

local size_constraint =
    Instance.new("UISizeConstraint")
size_constraint.MinSize =
    Vector2.new(620, 500)
size_constraint.MaxSize =
    Vector2.new(980, 720)
size_constraint.Parent = panel

local panel_corner =
    Instance.new("UICorner")
panel_corner.CornerRadius =
    UDim.new(0, 14)
panel_corner.Parent = panel

local panel_stroke =
    Instance.new("UIStroke")
panel_stroke.Thickness = 2
panel_stroke.Transparency = 0.35
panel_stroke.Color =
    Color3.fromRGB(145, 160, 185)
panel_stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position =
    UDim2.new(0, 28, 0, 20)
title.Size =
    UDim2.new(1, -56, 0, 54)
title.BackgroundTransparency = 1
title.TextColor3 =
    Color3.fromRGB(245, 245, 245)
title.Font =
    Enum.Font.GothamBold
title.TextSize = 32
title.TextXAlignment =
    Enum.TextXAlignment.Left
title.Text =
    "Choose Your Race"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Position =
    UDim2.new(0, 28, 0, 76)
subtitle.Size =
    UDim2.new(1, -56, 0, 48)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 =
    Color3.fromRGB(190, 198, 212)
subtitle.Font =
    Enum.Font.Gotham
subtitle.TextSize = 17
subtitle.TextWrapped = true
subtitle.TextXAlignment =
    Enum.TextXAlignment.Left
subtitle.TextYAlignment =
    Enum.TextYAlignment.Top
subtitle.Parent = panel

local content = Instance.new("Frame")
content.Position =
    UDim2.new(0, 28, 0, 132)
content.Size =
    UDim2.new(1, -56, 1, -230)
content.BackgroundTransparency = 1
content.Parent = panel

local status = Instance.new("TextLabel")
status.Position =
    UDim2.new(0, 28, 1, -88)
status.Size =
    UDim2.new(1, -260, 0, 54)
status.BackgroundTransparency = 1
status.TextColor3 =
    Color3.fromRGB(220, 220, 220)
status.Font =
    Enum.Font.Gotham
status.TextSize = 15
status.TextWrapped = true
status.TextXAlignment =
    Enum.TextXAlignment.Left
status.TextYAlignment =
    Enum.TextYAlignment.Center
status.Text = ""
status.Parent = panel

local confirm = Instance.new("TextButton")
confirm.AnchorPoint =
    Vector2.new(1, 0.5)
confirm.Position =
    UDim2.new(1, -28, 1, -61)
confirm.Size =
    UDim2.fromOffset(190, 48)
confirm.BackgroundColor3 =
    Color3.fromRGB(74, 105, 150)
confirm.TextColor3 =
    Color3.fromRGB(255, 255, 255)
confirm.Font =
    Enum.Font.GothamBold
confirm.TextSize = 18
confirm.Text = "Confirm"
confirm.AutoButtonColor = true
confirm.Parent = panel

local confirm_corner =
    Instance.new("UICorner")
confirm_corner.CornerRadius =
    UDim.new(0, 9)
confirm_corner.Parent = confirm

local current_snapshot: any = {}
local current_stage = ""
local selected_race: string? = nil
local selected_class: string? = nil
local request_pending = false

local race_buttons: {
    [string]: TextButton
} = {}
local class_buttons: {
    [string]: TextButton
} = {}

local function clear_content()
    for _, child in ipairs(
        content:GetChildren()
    ) do
        child:Destroy()
    end

    table.clear(race_buttons)
    table.clear(class_buttons)
end

local function style_card(
    button: TextButton,
    selected: boolean
)
    button.BackgroundColor3 =
        if selected
            then Color3.fromRGB(
                60,
                80,
                108
            )
            else Color3.fromRGB(
                34,
                39,
                49
            )

    local stroke =
        button:FindFirstChildOfClass(
            "UIStroke"
        )

    if stroke then
        stroke.Thickness =
            if selected then 3 else 1

        stroke.Transparency =
            if selected then 0.05 else 0.55
    end
end

local function make_race_card(
    race_id: string,
    heading: string,
    body: string,
    x_scale: number
)
    local button =
        Instance.new("TextButton")

    button.Name = race_id .. "Card"

    button.Position =
        UDim2.new(
            x_scale,
            if x_scale == 0
                then 0
                else 10,
            0,
            0
        )

    button.Size =
        UDim2.new(
            0.5,
            -10,
            1,
            0
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            34,
            39,
            49
        )

    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = content

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 12)

    corner.Parent = button

    local stroke =
        Instance.new("UIStroke")

    stroke.Thickness = 1
    stroke.Transparency = 0.55
    stroke.Color =
        Color3.fromRGB(
            168,
            180,
            205
        )

    stroke.Parent = button

    local name_label =
        Instance.new("TextLabel")

    name_label.Position =
        UDim2.new(0, 20, 0, 18)

    name_label.Size =
        UDim2.new(1, -40, 0, 42)

    name_label.BackgroundTransparency = 1

    name_label.TextColor3 =
        Color3.fromRGB(
            250,
            250,
            250
        )

    name_label.Font =
        Enum.Font.GothamBold

    name_label.TextSize = 25

    name_label.TextXAlignment =
        Enum.TextXAlignment.Left

    name_label.Text = heading
    name_label.Parent = button

    local body_label =
        Instance.new("TextLabel")

    body_label.Position =
        UDim2.new(0, 20, 0, 70)

    body_label.Size =
        UDim2.new(1, -40, 1, -90)

    body_label.BackgroundTransparency = 1

    body_label.TextColor3 =
        Color3.fromRGB(
            210,
            216,
            228
        )

    body_label.Font =
        Enum.Font.Gotham

    body_label.TextSize = 17
    body_label.TextWrapped = true

    body_label.TextXAlignment =
        Enum.TextXAlignment.Left

    body_label.TextYAlignment =
        Enum.TextYAlignment.Top

    body_label.Text = body
    body_label.Parent = button

    race_buttons[race_id] = button

    button.Activated:Connect(
        function()
            if request_pending then
                return
            end

            selected_race = race_id

            for id, card in pairs(
                race_buttons
            ) do
                style_card(
                    card,
                    id == race_id
                )
            end

            status.Text =
                race_id
                .. " selected. "
                .. "Press Confirm to continue."
        end
    )
end

local function show_race_selection(
    legacy: boolean
)
    clear_content()

    title.Text =
        if legacy
            then "Choose Your Race"
            else "Choose Your Race"

    subtitle.Text =
        if legacy
            then (
                "Your existing Fighter progression will be preserved. " ..
                "Earned attribute increases will be translated onto " ..
                "the racial baseline you choose."
            )
            else (
                "Your race sets your starting attributes and racial " ..
                "trait. This choice is permanent for this character."
            )

    selected_race = nil

    make_race_card(
        "Human",
        "Human",
        table.concat({
            "STR 5  •  DEX 4  •  VIT 6  •  INT 5  •  SPI 5",
            "",
            "Human Resolve",
            "Max Health +8%",
            "Basic attack rate -5%",
            "Critical damage +15 percentage points",
            "",
            "Durable and hard-hitting, with stronger survivability.",
        }, "\n"),
        0
    )

    make_race_card(
        "Elf",
        "Elf",
        table.concat({
            "STR 5  •  DEX 6  •  VIT 4  •  INT 5  •  SPI 5",
            "",
            "Elven Grace",
            "Max Health -8%",
            "Basic attack rate +8%",
            "Critical chance +5 percentage points",
            "",
            "Faster and more precise, trading durability for agility.",
        }, "\n"),
        0.5
    )

    confirm.Text = "Confirm Race"
    confirm.Active = true
    confirm.AutoButtonColor = true
    status.Text = "Select Human or Elf."
end

local function show_class_selection()
    clear_content()
    title.Text = "Choose Your Class"
    subtitle.Text = "Your starting class determines your initial combat kit."
    selected_race = nil
    selected_class = nil

    local function make_class_card(
        class_id: string,
        heading: string,
        body: string,
        x_scale: number
    )
        local button = Instance.new("TextButton")
        button.Name = class_id .. "Card"
        button.Position = UDim2.new(
            x_scale,
            if x_scale == 0 then 0 else 10,
            0,
            0
        )
        button.Size = UDim2.new(0.5, -10, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(34, 39, 49)
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = content

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Transparency = 0.55
        stroke.Color = Color3.fromRGB(168, 180, 205)
        stroke.Parent = button

        local name_label = Instance.new("TextLabel")
        name_label.Position = UDim2.new(0, 20, 0, 18)
        name_label.Size = UDim2.new(1, -40, 0, 42)
        name_label.BackgroundTransparency = 1
        name_label.TextColor3 = Color3.fromRGB(250, 250, 250)
        name_label.Font = Enum.Font.GothamBold
        name_label.TextSize = 25
        name_label.TextXAlignment = Enum.TextXAlignment.Left
        name_label.Text = heading
        name_label.Parent = button

        local body_label = Instance.new("TextLabel")
        body_label.Position = UDim2.new(0, 20, 0, 70)
        body_label.Size = UDim2.new(1, -40, 1, -90)
        body_label.BackgroundTransparency = 1
        body_label.TextColor3 = Color3.fromRGB(210, 216, 228)
        body_label.Font = Enum.Font.Gotham
        body_label.TextSize = 16
        body_label.TextWrapped = true
        body_label.TextXAlignment = Enum.TextXAlignment.Left
        body_label.TextYAlignment = Enum.TextYAlignment.Top
        body_label.Text = body
        body_label.Parent = button

        class_buttons[class_id] = button

        button.Activated:Connect(function()
            if request_pending then
                return
            end

            selected_class = class_id

            for id, card in pairs(class_buttons) do
                style_card(card, id == class_id)
            end

            status.Text =
                class_id
                .. " selected. Press Confirm to continue."
        end)
    end

    make_class_card(
        "Fighter",
        "Fighter",
        table.concat({
            "Deliberate melee combat with defence and self-sustain.",
            "",
            "Starting Skills",
            "- Shield Bash",
            "- Mend",
            "",
            "Arc Slash is learned later through the existing skill-book path."
        }, "\n"),
        0
    )

    make_class_card(
        "Mage",
        "Mage",
        table.concat({
            "Ranged magic with protective and healing support.",
            "",
            "Basic Attack",
            "- Spirit Orb: Orb, Orb, larger area Orb",
            "",
            "Starting Skills",
            "- Arcane Ward: protective absorption shield",
            "- Mage Heal: self or aimed ally",
            "",
            "Starts with an Apprentice Arcane Wand."
        }, "\n"),
        0.5
    )

    confirm.Text = "Confirm Class"
    confirm.Active = true
    confirm.AutoButtonColor = true
    status.Text = "Select Fighter or Mage."
end
local function hide_selection()
    blocker.Visible = false
    request_pending = false
    selected_race = nil
    selected_class = nil
end

local function render(
    snapshot: any
)
    current_snapshot =
        if type(snapshot) == "table"
            then snapshot
            else {}

    local identity =
        if type(current_snapshot.Identity)
            == "table"
            then current_snapshot.Identity
            else {}

    local stage =
        if type(identity.CreationStage)
            == "string"
            then identity.CreationStage
            else "RaceSelection"

    if stage ~= current_stage then
        current_stage = stage
        request_pending = false

        print(
            "[Identity Selection] Authoritative stage: "
                .. stage
        )
    end

    if (
        stage == "RaceSelection"
        or stage == "LegacyRaceSelection"
    ) then
        blocker.Visible = true

        show_race_selection(
            stage == "LegacyRaceSelection"
        )

        return
    end

    if stage == "ClassSelection" then
        blocker.Visible = true
        show_class_selection()
        return
    end

    if stage == "Complete" then
        print(
            string.format(
                "[Identity Selection] Complete: %s / %s",
                tostring(identity.RaceId),
                tostring(identity.ClassId)
            )
        )

        hide_selection()
        return
    end

    blocker.Visible = true
    clear_content()

    title.Text =
        "Character Setup Unavailable"

    subtitle.Text =
        "The server returned an unsupported character creation stage."

    confirm.Active = false
    confirm.AutoButtonColor = false
    status.Text =
        "Stage: " .. tostring(stage)
end

confirm.Activated:Connect(
    function()
        if request_pending then
            return
        end

        local identity =
            if type(current_snapshot.Identity)
                == "table"
                then current_snapshot.Identity
                else {}

        local stage =
            identity.CreationStage

        if (
            stage == "RaceSelection"
            or stage == "LegacyRaceSelection"
        ) then
            if not selected_race then
                status.Text =
                    "Select Human or Elf first."
                return
            end

            request_pending = true
            confirm.Active = false
            confirm.AutoButtonColor = false

            status.Text =
                "Saving race choice..."

            identity_selection:FireServer(
                "Race",
                selected_race
            )

            return
        end

        if stage == "ClassSelection" then
            if not selected_class then
                status.Text = "Select Fighter or Mage first."
                return
            end

            request_pending = true
            confirm.Active = false
            confirm.AutoButtonColor = false
            status.Text =
                "Saving " .. selected_class .. " class..."
            identity_selection:FireServer(
                "Class",
                selected_class
            )
        end
    end
)

ProgressionClientState.subscribe(
    function(snapshot)
        render(snapshot)
    end
)

action_result.OnClientEvent:Connect(
    function(payload)
        if type(payload) ~= "table" then
            return
        end

        local action =
            payload.action

        if (
            action ~= "RaceSelection"
            and action ~= "ClassSelection"
            and action ~= "IdentitySelection"
        ) then
            return
        end

        if payload.ok == true then
            status.Text =
                tostring(action)
                .. " saved. "
                .. "Waiting for authoritative snapshot..."

            return
        end

        request_pending = false
        confirm.Active = true
        confirm.AutoButtonColor = true

        status.Text =
            tostring(action)
            .. " blocked: "
            .. tostring(
                payload.reason
                    or "Unknown"
            )
    end
)

task.defer(
    function()
        render(
            ProgressionClientState
                .get_snapshot()
        )

        progression_snapshot:FireServer(
            "Request"
        )
    end
)