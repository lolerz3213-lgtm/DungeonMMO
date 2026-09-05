local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)
local Workspace = game:GetService("Workspace")

local combat_folder = ReplicatedStorage
    :WaitForChild("Combat")
local shared_folder = combat_folder
    :WaitForChild("Shared")

local CombatConfig = require(
    shared_folder:WaitForChild("CombatConfig")
)
local OneHandedAnimationConverter = require(
    shared_folder:WaitForChild(
        "OneHandedAnimationConverter"
    )
)
local PrototypeAnimationFactory = require(
    shared_folder:WaitForChild(
        "PrototypeAnimationFactory"
    )
)

local BasicAttack = CombatConfig.BASIC_ATTACK

local REQUIRED_ATTACKS = {
    "SwordSlice_1_Dummy",
    "SwordSlice_2_Dummy",
    "SwordSlice_3_Dummy",
    "SwordSlice_4_Dummy",
    "SwordSlice_5_Dummy",
}


--[[
Finds the inserted R15 sword animation collection.

Args:
    None.

Returns:
    Instance?: AnimSaves model containing all five source slices.
]]
local function find_source_folder(): Instance?
    for _, descendant in Workspace:GetDescendants() do
        if descendant.Name == "AnimSaves" then
            local complete = true

            for _, source_name in REQUIRED_ATTACKS do
                if not descendant:FindFirstChild(
                    source_name
                ) then
                    complete = false
                    break
                end
            end

            if complete then
                return descendant
            end
        end
    end

    return nil
end


--[[
Returns the complete configured duration for one attack.

Args:
    attack_definition (table): CombatConfig attack definition.

Returns:
    number: Total attack duration in seconds.
]]
local function get_attack_duration(
    attack_definition: any
): number
    return attack_definition.WIND_UP_SECONDS
        + attack_definition.ACTIVE_SECONDS
        + attack_definition.RECOVERY_SECONDS
end


--[[
Creates a clean destination for converted clips.

Args:
    None.

Returns:
    Folder: Empty PrototypeAnimations folder.
]]
local function create_destination(): Folder
    local existing = combat_folder:FindFirstChild(
        "PrototypeAnimations"
    )

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")

    folder.Name = "PrototypeAnimations"
    folder.Parent = combat_folder

    return folder
end


--[[
Converts all five source attack clips.

Args:
    source_folder (Instance): AnimSaves source container.
    destination (Folder): Converted clip destination.

Returns:
    number: Number of attack clips imported.
]]
local function import_attack_clips(
    source_folder: Instance,
    destination: Folder
): number
    local duration_overrides = {
        [1] = get_attack_duration(
            BasicAttack.ATTACKS.Slash1
        ),
        [2] = get_attack_duration(
            BasicAttack.ATTACKS.Slash2
        ),
        [5] = get_attack_duration(
            BasicAttack.ATTACKS.Finisher
        ),
    }

    local count = 0

    for index = 1, 5 do
        local source_name = string.format(
            "SwordSlice_%d_Dummy",
            index
        )
        local source = source_folder:FindFirstChild(
            source_name
        )

        if source
            and source:IsA("KeyframeSequence") then
            local source_duration =
                math.max(source.Length, 0.01)
            local target_duration =
                duration_overrides[index]
                or source_duration

            local converted =
                OneHandedAnimationConverter.convert_attack(
                    source,
                    "Slice" .. index,
                    target_duration
                )

            converted.Parent = destination
            count += 1
        end
    end

    return count
end


--[[
Creates the right-arm sword carry overlay from the source idle.

Args:
    source_folder (Instance): AnimSaves source container.
    destination (Folder): Converted clip destination.

Returns:
    boolean: True when the source idle was found and converted.
]]
local function import_carry_clip(
    source_folder: Instance,
    destination: Folder
): boolean
    local source = source_folder:FindFirstChild(
        "sword_idle_Dummy"
    )

    if not source
        or not source:IsA("KeyframeSequence") then
        return false
    end

    local converted =
        OneHandedAnimationConverter.convert_carry(
            source,
            "SwordCarry"
        )

    converted.Parent = destination

    return true
end


--[[
Creates source-controlled prototype clips when the Studio-only AnimSaves
collection is unavailable (for example in a fresh Rojo build).

The normal playable Dungeon place still prefers AnimSaves when present, so
this fallback does not replace the accepted imported presentation.

Args:
    destination (Folder): Empty PrototypeAnimations folder.

Returns:
    number: Number of attack clips generated.
]]
local function create_fallback_clips(
    destination: Folder
): number
    local clip_names = {
        Slash1 = "Slice1",
        Slash2 = "Slice2",
        Finisher = "Slice5",
    }
    local attack_count = 0

    for _, attack_id in BasicAttack.ATTACK_ORDER do
        local attack_definition =
            BasicAttack.ATTACKS[attack_id]
        local source =
            PrototypeAnimationFactory.create_sequence(
                attack_id,
                attack_definition
            )
        local converted =
            OneHandedAnimationConverter.convert_attack(
                source,
                clip_names[attack_id],
                get_attack_duration(attack_definition)
            )

        source:Destroy()
        converted.Parent = destination
        attack_count += 1
    end

    local carry =
        PrototypeAnimationFactory.create_carry_sequence(
            "SwordCarry"
        )

    carry.Parent = destination

    return attack_count
end


local source_folder = find_source_folder()
local destination = create_destination()

if not source_folder then
    local fallback_attack_count =
        create_fallback_clips(destination)

    warn(
        "[Combat Prototype] AnimSaves folder was not found. "
            .. "Using source-controlled fallback animations."
    )
    print(
        string.format(
            "[Combat Prototype] Generated %d fallback attacks "
                .. "and sword carry overlay.",
            fallback_attack_count
        )
    )
    return
end

local attack_count = import_attack_clips(
    source_folder,
    destination
)
local carry_imported = import_carry_clip(
    source_folder,
    destination
)

print(
    string.format(
        "[Combat Prototype] Converted %d attacks and "
            .. "%d sword carry overlay.",
        attack_count,
        carry_imported and 1 or 0
    )
)
