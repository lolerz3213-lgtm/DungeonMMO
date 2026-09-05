local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)

local ShieldConfig = CombatConfig.PROTOTYPE_SHIELD


--[[
Removes any existing prototype shield and root grip from a character.

Args:
    character (Model): Character whose old prototype shield is removed.

Returns:
    None.
]]
local function remove_existing_shield(
    character: Model
)
    local existing = character:FindFirstChild(
        ShieldConfig.PART_NAME
    )

    if existing then
        existing:Destroy()
    end

    for _, descendant in character:GetDescendants() do
        if descendant.Name == ShieldConfig.GRIP_NAME
            and descendant:IsA("Motor6D") then
            descendant:Destroy()
        end
    end
end


--[[
Builds the prototype shield's natural idle world transform.

The shield face points mostly outward along the left forearm while its centre
stays just outside the arm. This avoids depending on the local axis
orientation of an R15 hand or forearm.

Args:
    root_part (BasePart): Character root used for facing.
    reference_part (BasePart): Left forearm used for idle placement.

Returns:
    CFrame: Desired shield world transform.
]]
local function get_idle_shield_cframe(
    root_part: BasePart,
    reference_part: BasePart
): CFrame
    local root_cframe = root_part.CFrame
    local position = reference_part.Position
        - root_cframe.RightVector
            * ShieldConfig.IDLE_OUTWARD_STUDS
        + root_cframe.LookVector
            * ShieldConfig.IDLE_FORWARD_STUDS
        - root_cframe.UpVector
            * ShieldConfig.IDLE_DOWN_STUDS

    local outward = -root_cframe.RightVector
    local facing = (
        outward
        + root_cframe.LookVector
            * ShieldConfig.IDLE_FACE_FORWARD_BLEND
    ).Unit

    return CFrame.lookAt(
        position,
        position + facing,
        root_cframe.UpVector
    )
end


--[[
Creates the prototype shield with a root-owned presentation grip.

The root grip gives the client presentation layer enough freedom to place the
shield naturally beside the forearm in idle and directly in front of the
torso while blocking, without changing defensive hit logic.

Args:
    character (Model): Spawned character receiving the shield.

Returns:
    None.
]]
local function equip_shield(character: Model)
    remove_existing_shield(character)

    local attach_part = character:WaitForChild(
        ShieldConfig.ATTACH_PART_NAME,
        5
    )
    local idle_reference = character:WaitForChild(
        ShieldConfig.IDLE_REFERENCE_PART_NAME,
        5
    )

    if not attach_part
        or not attach_part:IsA("BasePart") then
        warn(
            "[Combat Prototype] Could not equip shield: "
                .. ShieldConfig.ATTACH_PART_NAME
                .. " missing."
        )
        return
    end

    if not idle_reference
        or not idle_reference:IsA("BasePart") then
        warn(
            "[Combat Prototype] Could not equip shield: "
                .. ShieldConfig.IDLE_REFERENCE_PART_NAME
                .. " missing."
        )
        return
    end

    local shield_cframe = get_idle_shield_cframe(
        attach_part,
        idle_reference
    )

    local shield = Instance.new("Part")

    shield.Name = ShieldConfig.PART_NAME
    shield.Size = ShieldConfig.SIZE
    shield.Color = Color3.fromRGB(88, 94, 104)
    shield.Material = Enum.Material.Metal
    shield.Transparency = 0
    shield.Anchored = false
    shield.CanCollide = false
    shield.CanQuery = false
    shield.CanTouch = false
    shield.Massless = true
    shield.CastShadow = false
    shield.CFrame = shield_cframe
    shield.Parent = character

    local grip = Instance.new("Motor6D")

    grip.Name = ShieldConfig.GRIP_NAME
    grip.Part0 = attach_part
    grip.Part1 = shield
    grip.C0 = attach_part.CFrame:ToObjectSpace(
        shield_cframe
    )
    grip.C1 = CFrame.identity
    grip.Parent = attach_part

    print(
        "[Combat Prototype] Prototype shield equipped."
    )
end


--[[
Registers shield setup for one player.

Args:
    player (Player): Player whose character spawns are observed.

Returns:
    None.
]]
local function register_player(player: Player)
    player.CharacterAdded:Connect(equip_shield)

    if player.Character then
        equip_shield(player.Character)
    end
end


Players.PlayerAdded:Connect(register_player)

for _, player in Players:GetPlayers() do
    register_player(player)
end
