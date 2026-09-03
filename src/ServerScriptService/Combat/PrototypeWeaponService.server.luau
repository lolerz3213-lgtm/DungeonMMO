local Players = game:GetService("Players")

local PrototypeWeaponFactory = require(
    script.Parent:WaitForChild("PrototypeWeaponFactory")
)

local TOOL_NAME = "PrototypeSword"


--[[
Destroys existing prototype swords from a player and character.

Args:
    player (Player): Player whose old prototype weapons are removed.
    character (Model): Current character model.

Returns:
    None.
]]
local function remove_existing_tools(
    player: Player,
    character: Model
)
    local backpack = player:FindFirstChildOfClass("Backpack")

    if backpack then
        local backpack_tool = backpack:FindFirstChild(TOOL_NAME)

        if backpack_tool then
            backpack_tool:Destroy()
        end
    end

    local equipped_tool = character:FindFirstChild(TOOL_NAME)

    if equipped_tool then
        equipped_tool:Destroy()
    end
end


--[[
Creates and equips the prototype sword for one character spawn.

Args:
    player (Player): Player receiving the prototype sword.
    character (Model): Spawned character that will equip the Tool.

Returns:
    None.
]]
local function equip_prototype_sword(
    player: Player,
    character: Model
)
    local humanoid = character:WaitForChild(
        "Humanoid",
        5
    )

    if not humanoid or not humanoid:IsA("Humanoid") then
        warn(
            "[Combat Prototype] Could not equip sword: "
                .. "Humanoid missing."
        )
        return
    end

    local backpack = player:WaitForChild(
        "Backpack",
        5
    )

    if not backpack or not backpack:IsA("Backpack") then
        warn(
            "[Combat Prototype] Could not equip sword: "
                .. "Backpack missing."
        )
        return
    end

    remove_existing_tools(player, character)

    local tool = PrototypeWeaponFactory.create_tool()

    tool.Parent = backpack
    humanoid:EquipTool(tool)

    print(
        "[Combat Prototype] Prototype sword equipped."
    )
end


--[[
Connects prototype weapon setup to one Player.

Args:
    player (Player): Player whose character spawns are observed.

Returns:
    None.
]]
local function register_player(player: Player)
    player.CharacterAdded:Connect(
        function(character)
            equip_prototype_sword(
                player,
                character
            )
        end
    )

    if player.Character then
        equip_prototype_sword(
            player,
            player.Character
        )
    end
end


Players.PlayerAdded:Connect(register_player)

for _, player in Players:GetPlayers() do
    register_player(player)
end
