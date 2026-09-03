local AnimationClipProvider = game:GetService(
    "AnimationClipProvider"
)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local combat_folder = ReplicatedStorage
    :WaitForChild("Combat")
local shared_folder = combat_folder
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local CombatTypes = require(
    shared_folder:WaitForChild("CombatTypes")
)
local ClientCombatController = require(
    script.Parent:WaitForChild("ClientCombatController")
)

local State = CombatTypes.State
local BasicAttack = CombatConfig.BASIC_ATTACK
local DebugConfig = CombatConfig.DEBUG
local WeaponConfig = CombatConfig.PROTOTYPE_WEAPON

local ATTACK_CLIP_NAMES = {
    Slash1 = "Slice1",
    Slash2 = "Slice2",
    Finisher = "Slice5",
}

local CARRY_WEIGHT_IDLE = 0.70
local CARRY_WEIGHT_WALK = 0.32
local CARRY_WEIGHT_JUMP = 0.20
local CARRY_WEIGHT_FALL = 0.16

local blade_trail: Trail? = nil
local local_state_label: TextLabel? = nil
local server_state_label: TextLabel? = nil

local attack_tracks: {[string]: AnimationTrack} = {}
local animation_instances: {Animation} = {}
local current_attack_track: AnimationTrack? = nil
local carry_track: AnimationTrack? = nil

local last_running_speed = 0
local current_carry_weight = 0

local running_connection: RBXScriptConnection? = nil
local state_connection: RBXScriptConnection? = nil


--[[
Stops and clears loaded animation tracks.

Args:
    None.

Returns:
    None.
]]
local function clear_animation_tracks()
    if running_connection then
        running_connection:Disconnect()
        running_connection = nil
    end

    if state_connection then
        state_connection:Disconnect()
        state_connection = nil
    end

    if current_attack_track
        and current_attack_track.IsPlaying then
        current_attack_track:Stop(0.05)
    end

    if carry_track and carry_track.IsPlaying then
        carry_track:Stop(0.05)
    end

    for _, track in attack_tracks do
        if track.IsPlaying then
            track:Stop(0)
        end
    end

    for _, animation in animation_instances do
        animation:Destroy()
    end

    attack_tracks = {}
    animation_instances = {}

    current_attack_track = nil
    carry_track = nil
    last_running_speed = 0
    current_carry_weight = 0
end


--[[
Creates an AnimationTrack from one imported sequence.

Args:
    animator (Animator): Character Animator.
    sequence (KeyframeSequence): Imported animation clip.

Returns:
    AnimationTrack?: Loaded track on success.
]]
local function create_track(
    animator: Animator,
    sequence: KeyframeSequence
): AnimationTrack?
    local success, content_id = pcall(
        function()
            return AnimationClipProvider
                :RegisterAnimationClip(sequence)
        end
    )

    if not success then
        warn(
            "[Combat Prototype] Could not register "
                .. sequence.Name
                .. ": "
                .. tostring(content_id)
        )
        return nil
    end

    local animation = Instance.new("Animation")

    animation.Name = sequence.Name
        .. "PrototypeAnimation"
    animation.AnimationId = content_id

    local loaded, track = pcall(
        function()
            return animator:LoadAnimation(
                animation
            )
        end
    )

    if not loaded then
        animation:Destroy()
        warn(
            "[Combat Prototype] Could not load "
                .. sequence.Name
                .. ": "
                .. tostring(track)
        )
        return nil
    end

    track.Priority = sequence.Priority
    track.Looped = sequence.Loop

    table.insert(
        animation_instances,
        animation
    )

    return track
end


--[[
Blends the sword carry overlay toward a requested weight.

Args:
    weight (number): Target carry contribution from zero to one.
    fade_time (number): Blend duration in seconds.

Returns:
    None.
]]
local function set_carry_weight(
    weight: number,
    fade_time: number
)
    local track = carry_track

    if not track then
        return
    end

    local clamped = math.clamp(
        weight,
        0,
        1
    )

    current_carry_weight = clamped

    if not track.IsPlaying then
        track:Play(
            fade_time,
            clamped,
            1
        )
        return
    end

    track:AdjustWeight(
        clamped,
        fade_time
    )
end


--[[
Updates carry strength while normal Roblox walk/idle remains active.

Args:
    speed (number): Current Humanoid running speed.

Returns:
    None.
]]
local function on_running(speed: number)
    last_running_speed = speed

    if speed > 0.5 then
        set_carry_weight(
            CARRY_WEIGHT_WALK,
            0.12
        )
    else
        set_carry_weight(
            CARRY_WEIGHT_IDLE,
            0.12
        )
    end
end


--[[
Adjusts only carry weight during jump/fall state changes.

Default Roblox jump and fall animations remain responsible for the
actual body movement.

Args:
    old_state (Enum.HumanoidStateType): Previous state.
    new_state (Enum.HumanoidStateType): New state.

Returns:
    None.
]]
local function on_humanoid_state_changed(
    _old_state: Enum.HumanoidStateType,
    new_state: Enum.HumanoidStateType
)
    if new_state == Enum.HumanoidStateType.Jumping then
        set_carry_weight(
            CARRY_WEIGHT_JUMP,
            0.08
        )
        return
    end

    if new_state == Enum.HumanoidStateType.Freefall then
        set_carry_weight(
            CARRY_WEIGHT_FALL,
            0.10
        )
        return
    end

    if new_state == Enum.HumanoidStateType.Landed
        or new_state == Enum.HumanoidStateType.Running then
        on_running(last_running_speed)
    end
end


--[[
Loads converted one-handed attack tracks and the carry overlay.

Args:
    character (Model): Local player's current character.

Returns:
    None.
]]
local function load_animation_tracks(
    character: Model
)
    clear_animation_tracks()

    if not RunService:IsStudio() then
        warn(
            "[Combat Prototype] Imported clips are "
                .. "Studio-only until published."
        )
        return
    end

    local humanoid = character:WaitForChild(
        "Humanoid",
        5
    ) :: Humanoid?

    if not humanoid then
        warn(
            "[Combat Prototype] Humanoid was not found."
        )
        return
    end

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        warn(
            "[Combat Prototype] Sword animations "
                .. "currently require R15."
        )
        return
    end

    local animator = humanoid:WaitForChild(
        "Animator",
        5
    ) :: Animator?

    if not animator then
        warn(
            "[Combat Prototype] Animator was not found."
        )
        return
    end

    local folder = combat_folder:WaitForChild(
        "PrototypeAnimations",
        5
    )

    if not folder then
        warn(
            "[Combat Prototype] Converted animation "
                .. "folder was not found."
        )
        return
    end

    local loaded_attacks = 0

    for _, attack_id in BasicAttack.ATTACK_ORDER do
        local clip_name =
            ATTACK_CLIP_NAMES[attack_id]
        local sequence = folder:FindFirstChild(
            clip_name
        )

        if sequence
            and sequence:IsA(
                "KeyframeSequence"
            ) then
            local track = create_track(
                animator,
                sequence
            )

            if track then
                attack_tracks[attack_id] = track
                loaded_attacks += 1
            end
        end
    end

    local carry_sequence = folder:FindFirstChild(
        "SwordCarry"
    )

    if carry_sequence
        and carry_sequence:IsA(
            "KeyframeSequence"
        ) then
        carry_track = create_track(
            animator,
            carry_sequence
        )
    end

    if not carry_track then
        warn(
            "[Combat Prototype] SwordCarry overlay "
                .. "was not loaded."
        )
    else
        set_carry_weight(
            CARRY_WEIGHT_IDLE,
            0
        )
    end

    running_connection = humanoid.Running:Connect(
        on_running
    )
    state_connection = humanoid.StateChanged:Connect(
        on_humanoid_state_changed
    )

    print(
        string.format(
            "[Combat Prototype] Loaded %d one-handed "
                .. "attack tracks and sword carry overlay.",
            loaded_attacks
        )
    )
end


--[[
Finds the Trail inside the equipped prototype sword.

Args:
    character (Model): Character expected to own the Tool.

Returns:
    Trail?: Active-frame Trail when available.
]]
local function find_weapon_trail(
    character: Model
): Trail?
    local tool = character:WaitForChild(
        WeaponConfig.TOOL_NAME,
        5
    )

    if not tool or not tool:IsA("Tool") then
        warn(
            "[Combat Prototype] Equipped prototype "
                .. "sword was not found."
        )
        return nil
    end

    local blade = tool:WaitForChild(
        WeaponConfig.BLADE_NAME,
        5
    )

    if not blade or not blade:IsA("BasePart") then
        warn(
            "[Combat Prototype] Sword blade missing."
        )
        return nil
    end

    local trail = blade:WaitForChild(
        WeaponConfig.TRAIL_NAME,
        5
    )

    if not trail or not trail:IsA("Trail") then
        warn(
            "[Combat Prototype] Sword Trail missing."
        )
        return nil
    end

    return trail
end


--[[
Creates the combat diagnostic HUD.

Args:
    None.

Returns:
    None.
]]
local function create_debug_gui()
    local player_gui = player:WaitForChild(
        "PlayerGui"
    )
    local existing = player_gui:FindFirstChild(
        DebugConfig.STATE_GUI_NAME
    )

    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")

    gui.Name = DebugConfig.STATE_GUI_NAME
    gui.ResetOnSpawn = false
    gui.Parent = player_gui

    local frame = Instance.new("Frame")

    frame.Name = "StateFrame"
    frame.Size = UDim2.fromOffset(310, 72)
    frame.Position = UDim2.fromOffset(14, 14)
    frame.BackgroundTransparency = 0.25
    frame.Parent = gui

    local local_label = Instance.new("TextLabel")

    local_label.Name = "LocalState"
    local_label.Size = UDim2.new(
        1,
        -12,
        0,
        28
    )
    local_label.Position = UDim2.fromOffset(
        6,
        7
    )
    local_label.BackgroundTransparency = 1
    local_label.Font = Enum.Font.Code
    local_label.TextSize = 16
    local_label.TextXAlignment =
        Enum.TextXAlignment.Left
    local_label.Text = "Local: Locomotion"
    local_label.Parent = frame

    local server_label = Instance.new("TextLabel")

    server_label.Name = "ServerState"
    server_label.Size = UDim2.new(
        1,
        -12,
        0,
        28
    )
    server_label.Position = UDim2.fromOffset(
        6,
        37
    )
    server_label.BackgroundTransparency = 1
    server_label.Font = Enum.Font.Code
    server_label.TextSize = 16
    server_label.TextXAlignment =
        Enum.TextXAlignment.Left
    server_label.Text = "Server: waiting"
    server_label.Parent = frame

    local_state_label = local_label
    server_state_label = server_label
end


--[[
Plays one converted attack animation.

Args:
    attack_id (string): Combat attack identifier.

Returns:
    None.
]]
local function play_attack_animation(
    attack_id: string
)
    local track = attack_tracks[attack_id]

    if not track then
        warn(
            "[Combat Prototype] No animation for "
                .. attack_id
        )
        return
    end

    if current_attack_track
        and current_attack_track ~= track
        and current_attack_track.IsPlaying then
        current_attack_track:Stop(0.03)
    end

    if track.IsPlaying then
        track:Stop(0)
    end

    current_attack_track = track
    track:Play(0.03, 1, 1)
end


--[[
Updates local presentation after predicted combat state changes.

Args:
    state_name (string): New predicted state.
    attack_id (string): Predicted attack identifier.

Returns:
    None.
]]
local function on_local_state_changed(
    state_name: string,
    attack_id: string
)
    if local_state_label then
        local attack_text = attack_id ~= ""
            and (" / " .. attack_id)
            or ""

        local_state_label.Text =
            "Local: "
            .. state_name
            .. attack_text
    end

    if blade_trail then
        blade_trail.Enabled =
            state_name == State.ACTIVE
    end

    if state_name == State.WIND_UP
        and attack_id ~= "" then
        play_attack_animation(attack_id)
    elseif state_name == State.LOCOMOTION
        and current_attack_track
        and current_attack_track.IsPlaying then
        current_attack_track:Stop(0.05)
        current_attack_track = nil
    end
end


--[[
Updates the HUD from authoritative server combat state.

Args:
    state_name (string): Server-confirmed state.
    attack_id (string): Server-confirmed attack.
    server_timestamp (number): Server state timestamp.

Returns:
    None.
]]
local function on_server_state_changed(
    state_name: string,
    attack_id: string,
    server_timestamp: number
)
    if not server_state_label then
        return
    end

    local attack_text = attack_id ~= ""
        and (" / " .. attack_id)
        or ""

    server_state_label.Text = string.format(
        "Server: %s%s @ %.2f",
        state_name,
        attack_text,
        server_timestamp
    )
end


--[[
Rebuilds animation presentation for a character spawn.

Args:
    character (Model): Newly spawned character.

Returns:
    None.
]]
local function on_character_added(
    character: Model
)
    task.defer(function()
        load_animation_tracks(character)
        blade_trail =
            find_weapon_trail(character)
    end)
end


--[[
Clears presentation references when a character despawns.

Args:
    character (Model): Character being removed.

Returns:
    None.
]]
local function on_character_removing(
    _character: Model
)
    blade_trail = nil
    clear_animation_tracks()
end


create_debug_gui()

ClientCombatController.on_state_changed(
    on_local_state_changed
)
ClientCombatController.on_server_state_changed(
    on_server_state_changed
)

player.CharacterAdded:Connect(
    on_character_added
)
player.CharacterRemoving:Connect(
    on_character_removing
)

if player.Character then
    on_character_added(player.Character)
end
