local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatTypes = require(shared_folder:WaitForChild("CombatTypes"))
local MendPresentationRules = require(
    shared_folder:WaitForChild("MendPresentationRules")
)

local State = CombatTypes.State
local HEAL_COLOR = Color3.fromRGB(78, 255, 126)
local PLUS_LIFETIME_SECONDS = 0.75

type CharacterRecord = {
    character: Model,
    motors: {Motor6D},
    root_motor: Motor6D?,
    waist_motor: Motor6D?,
    right_hip: Motor6D?,
    right_knee: Motor6D?,
    left_hip: Motor6D?,
    left_knee: Motor6D?,
    right_shoulder: Motor6D?,
    left_shoulder: Motor6D?,
    effect_attachment: Attachment?,
    effect_highlight: Highlight?,
    last_pulse_serial: number,
    was_mending: boolean,
    receiving_connection: RBXScriptConnection?,
    pulse_connection: RBXScriptConnection?,
}

local records: {[Model]: CharacterRecord} = {}


--[[
Finds the first Motor6D with one of the requested names.

Args:
    character (Model): Character whose rig is searched.
    names ({string}): Candidate Motor6D names.

Returns:
    Motor6D?: Matching joint when present.
]]
local function find_motor(
    character: Model,
    names: {string}
): Motor6D?
    for _, descendant in character:GetDescendants() do
        if not descendant:IsA("Motor6D") then
            continue
        end

        for _, name in names do
            if descendant.Name == name then
                return descendant
            end
        end
    end

    return nil
end


--[[
Returns the first body part suitable for Mend particles.

Args:
    character (Model): Character receiving the visual effect.

Returns:
    BasePart?: Preferred torso/root presentation part.
]]
local function find_effect_part(character: Model): BasePart?
    local part = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")

    return part and part:IsA("BasePart") and part or nil
end


--[[
Resets every joint touched by the procedural Mend pose.

Args:
    record (CharacterRecord): Character presentation record.

Returns:
    None.
]]
local function reset_pose(record: CharacterRecord)
    for _, motor in record.motors do
        if motor.Parent then
            motor.Transform = CFrame.identity
        end
    end
end


--[[
Applies the locked one-knee treatment pose to one character.

Args:
    record (CharacterRecord): Character presentation record.

Returns:
    None.
]]
local function apply_kneel_pose(record: CharacterRecord)
    local rules = MendPresentationRules

    if record.root_motor then
        record.root_motor.Transform = rules.get_root_transform()
    end
    if record.waist_motor then
        record.waist_motor.Transform = rules.get_waist_transform()
    end
    if record.right_hip then
        record.right_hip.Transform = rules.get_right_hip_transform()
    end
    if record.right_knee then
        record.right_knee.Transform = rules.get_right_knee_transform()
    end
    if record.left_hip then
        record.left_hip.Transform = rules.get_left_hip_transform()
    end
    if record.left_knee then
        record.left_knee.Transform = rules.get_left_knee_transform()
    end
    if record.right_shoulder then
        record.right_shoulder.Transform = rules.get_right_shoulder_transform()
    end
    if record.left_shoulder then
        record.left_shoulder.Transform = rules.get_left_shoulder_transform()
    end
end


--[[
Builds the continuous green particle/glow effect for a Mend recipient.

Args:
    record (CharacterRecord): Recipient presentation record.

Returns:
    None.
]]
local function create_receiving_effect(record: CharacterRecord)
    if record.effect_attachment then
        return
    end

    local part = find_effect_part(record.character)

    if not part then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "MendHealingAttachment"
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MendHealingParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(HEAL_COLOR)
    emitter.LightEmission = 0.7
    emitter.Rate = 30
    emitter.Lifetime = NumberRange.new(0.55, 0.95)
    emitter.Speed = NumberRange.new(0.7, 1.4)
    emitter.Acceleration = Vector3.new(0, 1.2, 0)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.16),
        NumberSequenceKeypoint.new(0.7, 0.10),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Parent = attachment

    local highlight = Instance.new("Highlight")
    highlight.Name = "MendChannelGlow"
    highlight.FillColor = HEAL_COLOR
    highlight.FillTransparency = 0.72
    highlight.OutlineColor = HEAL_COLOR
    highlight.OutlineTransparency = 0.45
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = record.character

    record.effect_attachment = attachment
    record.effect_highlight = highlight
end


--[[
Destroys continuous Mend recipient effects immediately on completion/cancel.

Args:
    record (CharacterRecord): Recipient presentation record.

Returns:
    None.
]]
local function destroy_receiving_effect(record: CharacterRecord)
    if record.effect_attachment then
        record.effect_attachment:Destroy()
        record.effect_attachment = nil
    end

    if record.effect_highlight then
        record.effect_highlight:Destroy()
        record.effect_highlight = nil
    end
end


--[[
Returns a deterministic horizontal offset for one floating heal plus.

Args:
    pulse_serial (number): Replicated pulse sequence number.
    plus_index (number): One-based plus within the pulse burst.

Returns:
    Vector3: Small world-space billboard offset.
]]
local function get_plus_offset(
    pulse_serial: number,
    plus_index: number
): Vector3
    local seed = (pulse_serial * 37) + (plus_index * 19)
    local x = ((seed % 13) - 6) * 0.10
    local z = (((seed * 7) % 11) - 5) * 0.08
    local y = 1.2 + (plus_index * 0.22)

    return Vector3.new(x, y, z)
end


--[[
Spawns one rising green plus billboard for a heal pulse.

Args:
    character (Model): Character receiving the pulse.
    offset (Vector3): Initial world-space billboard offset.

Returns:
    None.
]]
local function spawn_plus(character: Model, offset: Vector3)
    local adornee = character:FindFirstChild("Head")
        or find_effect_part(character)

    if not adornee or not adornee:IsA("BasePart") then
        return
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "MendHealingPlus"
    gui.Adornee = adornee
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(34, 34)
    gui.StudsOffsetWorldSpace = offset
    gui.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = "+"
    label.TextColor3 = HEAL_COLOR
    label.TextStrokeTransparency = 0.35
    label.TextScaled = true
    label.Parent = gui

    TweenService:Create(
        gui,
        TweenInfo.new(PLUS_LIFETIME_SECONDS, Enum.EasingStyle.Quad),
        {StudsOffsetWorldSpace = offset + Vector3.new(0, 1.5, 0)}
    ):Play()
    TweenService:Create(
        label,
        TweenInfo.new(PLUS_LIFETIME_SECONDS),
        {TextTransparency = 1, TextStrokeTransparency = 1}
    ):Play()

    Debris:AddItem(gui, PLUS_LIFETIME_SECONDS + 0.1)
end


--[[
Spawns a small burst of green pluses for one authoritative heal pulse.

Args:
    record (CharacterRecord): Mend recipient record.
    pulse_serial (number): Replicated pulse sequence number.

Returns:
    None.
]]
local function show_pulse(record: CharacterRecord, pulse_serial: number)
    for plus_index = 1, 3 do
        spawn_plus(
            record.character,
            get_plus_offset(pulse_serial, plus_index)
        )
    end
end


--[[
Synchronises continuous effects from replicated Mend attributes.

Args:
    record (CharacterRecord): Character presentation record.

Returns:
    None.
]]
local function sync_receiving_effect(record: CharacterRecord)
    local receiving = record.character:GetAttribute(
        MendPresentationRules.ATTRIBUTE_RECEIVING
    ) == true

    if receiving then
        create_receiving_effect(record)
    else
        destroy_receiving_effect(record)
    end
end


--[[
Handles an authoritative Mend pulse serial change.

Args:
    record (CharacterRecord): Character presentation record.

Returns:
    None.
]]
local function on_pulse_changed(record: CharacterRecord)
    local value = record.character:GetAttribute(
        MendPresentationRules.ATTRIBUTE_PULSE_SERIAL
    )
    local serial = type(value) == "number" and value or 0
    local receiving = record.character:GetAttribute(
        MendPresentationRules.ATTRIBUTE_RECEIVING
    ) == true

    if receiving and serial > record.last_pulse_serial then
        show_pulse(record, serial)
    end

    record.last_pulse_serial = serial
end


--[[
Creates presentation tracking for one spawned character.

Args:
    character (Model): Character to track.

Returns:
    None.
]]
local function track_character(character: Model)
    task.defer(function()
        if not character.Parent then
            return
        end

        local motors = {}
        local function motor(names: {string}): Motor6D?
            local found = find_motor(character, names)
            if found then
                table.insert(motors, found)
            end
            return found
        end

        local pulse_value = character:GetAttribute(
            MendPresentationRules.ATTRIBUTE_PULSE_SERIAL
        )
        local record: CharacterRecord = {
            character = character,
            motors = motors,
            root_motor = motor({"Root", "RootJoint"}),
            waist_motor = motor({"Waist"}),
            right_hip = motor({"RightHip"}),
            right_knee = motor({"RightKnee"}),
            left_hip = motor({"LeftHip"}),
            left_knee = motor({"LeftKnee"}),
            right_shoulder = motor({"RightShoulder"}),
            left_shoulder = motor({"LeftShoulder"}),
            effect_attachment = nil,
            effect_highlight = nil,
            last_pulse_serial = type(pulse_value) == "number" and pulse_value or 0,
            was_mending = false,
            receiving_connection = nil,
            pulse_connection = nil,
        }

        record.receiving_connection = character:GetAttributeChangedSignal(
            MendPresentationRules.ATTRIBUTE_RECEIVING
        ):Connect(function()
            sync_receiving_effect(record)
        end)
        record.pulse_connection = character:GetAttributeChangedSignal(
            MendPresentationRules.ATTRIBUTE_PULSE_SERIAL
        ):Connect(function()
            on_pulse_changed(record)
        end)

        records[character] = record
        sync_receiving_effect(record)
    end)
end


--[[
Stops presentation tracking for one despawned character.

Args:
    character (Model): Character being removed.

Returns:
    None.
]]
local function untrack_character(character: Model)
    local record = records[character]

    if not record then
        return
    end

    if record.receiving_connection then
        record.receiving_connection:Disconnect()
    end
    if record.pulse_connection then
        record.pulse_connection:Disconnect()
    end

    reset_pose(record)
    destroy_receiving_effect(record)
    records[character] = nil
end


--[[
Applies/clears the kneeling pose after normal character animation evaluation.

Args:
    None.

Returns:
    None.
]]
local function render_mending()
    for character, record in records do
        if not character.Parent then
            continue
        end

        local mending = character:GetAttribute("CombatState") == State.MENDING

        if mending then
            apply_kneel_pose(record)
            record.was_mending = true
        elseif record.was_mending then
            reset_pose(record)
            record.was_mending = false
        end
    end
end


--[[
Hooks character lifecycle events for one player.

Args:
    tracked_player (Player): Player whose characters should render Mend.

Returns:
    None.
]]
local function track_player(tracked_player: Player)
    tracked_player.CharacterAdded:Connect(track_character)
    tracked_player.CharacterRemoving:Connect(untrack_character)

    if tracked_player.Character then
        track_character(tracked_player.Character)
    end
end


Players.PlayerAdded:Connect(track_player)
Players.PlayerRemoving:Connect(function(leaving_player)
    if leaving_player.Character then
        untrack_character(leaving_player.Character)
    end
end)

for _, tracked_player in Players:GetPlayers() do
    track_player(tracked_player)
end

RunService:BindToRenderStep(
    "CombatMendPresentation",
    Enum.RenderPriority.Last.Value - 1,
    render_mending
)
