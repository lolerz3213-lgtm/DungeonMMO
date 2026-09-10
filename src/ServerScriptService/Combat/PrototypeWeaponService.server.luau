--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local EquipmentPresentationRules = require(
    Shared:WaitForChild("EquipmentPresentationRules")
)
local PrototypeWeaponFactory = require(
    script.Parent:WaitForChild("PrototypeWeaponFactory")
)
local PrototypeWandFactory = require(
    script.Parent:WaitForChild("PrototypeWandFactory")
)

local TOOL_NAMES = table.freeze({
    "PrototypeSword",
    "PrototypeArcaneWand",
})

local function remove_existing_tools(
    player: Player,
    character: Model
)
    local backpack =
        player:FindFirstChildOfClass("Backpack")

    for _, name in TOOL_NAMES do
        if backpack then
            local tool = backpack:FindFirstChild(name)
            if tool then
                tool:Destroy()
            end
        end

        local equipped =
            character:FindFirstChild(name)

        if equipped then
            equipped:Destroy()
        end
    end
end

local function equip_tool(
    player: Player,
    character: Model,
    tool: Tool
)
    local humanoid =
        character:WaitForChild(
            "Humanoid",
            5
        )
    local backpack =
        player:WaitForChild(
            "Backpack",
            5
        )

    if not humanoid
        or not humanoid:IsA("Humanoid")
        or not backpack
        or not backpack:IsA("Backpack")
    then
        tool:Destroy()
        return
    end

    tool.Parent = backpack
    humanoid:EquipTool(tool)
end

local function refresh_weapon(
    player: Player,
    character: Model
)
    local item_id =
        player:GetAttribute(
            EquipmentPresentationRules
                .WEAPON_ITEM_ATTRIBUTE
        )

    remove_existing_tools(
        player,
        character
    )

    if EquipmentPresentationRules
        .show_sword(item_id)
    then
        equip_tool(
            player,
            character,
            PrototypeWeaponFactory.create_tool()
        )
    elseif EquipmentPresentationRules
        .show_wand(item_id)
    then
        equip_tool(
            player,
            character,
            PrototypeWandFactory.create_tool()
        )
    end
end

local function register_player(
    player: Player
)
    player.CharacterAdded:Connect(
        function(character)
            task.defer(
                refresh_weapon,
                player,
                character
            )
        end
    )

    player:GetAttributeChangedSignal(
        EquipmentPresentationRules
            .WEAPON_ITEM_ATTRIBUTE
    ):Connect(function()
        local character = player.Character
        if character then
            refresh_weapon(
                player,
                character
            )
        end
    end)

    if player.Character then
        refresh_weapon(
            player,
            player.Character
        )
    end
end

Players.PlayerAdded:Connect(register_player)

for _, player in Players:GetPlayers() do
    register_player(player)
end
