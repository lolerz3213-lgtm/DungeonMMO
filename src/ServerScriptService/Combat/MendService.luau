local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared_folder = ReplicatedStorage
    :WaitForChild("Combat")
    :WaitForChild("Shared")

local MendPresentationRules = require(
    shared_folder:WaitForChild("MendPresentationRules")
)
local SupportTargetRules = require(
    script.Parent:WaitForChild("SupportTargetRules")
)

local MendService = {}

type ChannelRecord = {
    target: Player,
    range_studs: number,
}

local channels: {[Player]: ChannelRecord} = {}


--[[
Returns the living Humanoid and root part for one player's character.

Args:
    player (Player): Candidate player.

Returns:
    Humanoid?, BasePart?: Character parts when available.
]]
local function get_character_parts(player: Player): (Humanoid?, BasePart?)
    local character = player.Character

    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root_part = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root_part or not root_part:IsA("BasePart") then
        return nil, nil
    end

    return humanoid, root_part
end


--[[
Builds one pure targeting candidate for SupportTargetRules.

Args:
    caster (Player): Player using Mend.
    candidate_player (Player): Candidate recipient.
    caster_root (BasePart): Caster root used for ally distance.

Returns:
    table?: Targeting candidate, or nil when character parts are unavailable.
]]
local function build_candidate(
    caster: Player,
    candidate_player: Player,
    caster_root: BasePart
): any?
    local humanoid, root_part = get_character_parts(candidate_player)

    if not humanoid or not root_part then
        return nil
    end

    local is_self = candidate_player == caster
    local distance = is_self
        and 0
        or (root_part.Position - caster_root.Position).Magnitude

    return {
        key = candidate_player,
        is_self = is_self,
        distance = distance,
        health = humanoid.Health,
        max_health = humanoid.MaxHealth,
    }
end


--[[
Returns whether a locked Mend target is still valid for the channel.

Args:
    caster (Player): Player performing Mend.
    target (Player): Locked Mend recipient.
    range_studs (number): Maximum non-self distance.

Returns:
    boolean: True while the target is alive and in range.
]]
local function target_is_valid(
    caster: Player,
    target: Player,
    range_studs: number
): boolean
    local target_humanoid, target_root = get_character_parts(target)
    local _, caster_root = get_character_parts(caster)

    if not target_humanoid
        or target_humanoid.Health <= 0
        or not target_root
        or not caster_root then
        return false
    end

    if caster == target then
        return true
    end

    return (target_root.Position - caster_root.Position).Magnitude
        <= range_studs
end


--[[
Writes replicated Mend presentation attributes to a recipient character.

Args:
    caster (Player): Mend source.
    target (Player): Mend recipient.
    active (boolean): Whether the recipient is actively being Mended.

Returns:
    None.
]]
local function set_receiving_effect(
    caster: Player,
    target: Player,
    active: boolean
)
    local character = target.Character

    if not character then
        return
    end

    if active then
        character:SetAttribute(
            MendPresentationRules.ATTRIBUTE_SOURCE_USER_ID,
            caster.UserId
        )
        character:SetAttribute(
            MendPresentationRules.ATTRIBUTE_PULSE_SERIAL,
            0
        )
        character:SetAttribute(
            MendPresentationRules.ATTRIBUTE_RECEIVING,
            true
        )
        return
    end

    if character:GetAttribute(
        MendPresentationRules.ATTRIBUTE_SOURCE_USER_ID
    ) ~= caster.UserId then
        return
    end

    character:SetAttribute(
        MendPresentationRules.ATTRIBUTE_RECEIVING,
        false
    )
    character:SetAttribute(
        MendPresentationRules.ATTRIBUTE_SOURCE_USER_ID,
        0
    )
end


--[[
Applies clamped healing to one Humanoid.

Args:
    humanoid (Humanoid): Living target Humanoid.
    heal_amount (number): Maximum health to restore.

Returns:
    number: Health actually restored.
]]
function MendService.apply_heal(
    humanoid: Humanoid,
    heal_amount: number
): number
    if heal_amount <= 0
        or humanoid.Health <= 0
        or humanoid.Health >= humanoid.MaxHealth then
        return 0
    end

    local before = humanoid.Health
    humanoid.Health = math.min(
        humanoid.MaxHealth,
        humanoid.Health + heal_amount
    )

    return humanoid.Health - before
end


--[[
Finds the current server-authoritative Mend target.

Args:
    caster (Player): Player using Mend.
    range_studs (number): Maximum range for other players.

Returns:
    Player?: Selected recipient, or nil when nobody needs healing.
]]
function MendService.find_target(
    caster: Player,
    range_studs: number
): Player?
    local _, caster_root = get_character_parts(caster)

    if not caster_root then
        return nil
    end

    local candidates = {}

    for _, candidate_player in Players:GetPlayers() do
        local candidate = build_candidate(
            caster,
            candidate_player,
            caster_root
        )

        if candidate then
            table.insert(candidates, candidate)
        end
    end

    return SupportTargetRules.choose_mend_target(
        candidates,
        range_studs
    )
end


--[[
Locks one recipient for an authoritative Mend channel.

Args:
    caster (Player): Player beginning Mend.
    target (Player): Server-selected recipient.
    range_studs (number): Maximum non-self distance.

Returns:
    boolean: True when the channel target was accepted.
]]
function MendService.start_channel(
    caster: Player,
    target: Player,
    range_studs: number
): boolean
    if not target_is_valid(caster, target, range_studs) then
        return false
    end

    local target_humanoid = get_character_parts(target)

    if not target_humanoid
        or target_humanoid.Health >= target_humanoid.MaxHealth then
        return false
    end

    MendService.cancel_channel(caster)
    channels[caster] = {
        target = target,
        range_studs = range_studs,
    }
    set_receiving_effect(caster, target, true)

    return true
end


--[[
Applies one authoritative Mend pulse to the locked recipient.

Args:
    caster (Player): Player whose channel owns the pulse.
    pulse_heal (number): Maximum health restored by this pulse.

Returns:
    boolean, number: Channel validity and health actually restored.
]]
function MendService.apply_channel_pulse(
    caster: Player,
    pulse_heal: number
): (boolean, number)
    local channel = channels[caster]

    if not channel then
        return false, 0
    end

    if not target_is_valid(
        caster,
        channel.target,
        channel.range_studs
    ) then
        MendService.cancel_channel(caster)
        return false, 0
    end

    local humanoid = get_character_parts(channel.target)

    if not humanoid then
        MendService.cancel_channel(caster)
        return false, 0
    end

    local healed = MendService.apply_heal(humanoid, pulse_heal)
    local character = channel.target.Character

    if character then
        local serial = character:GetAttribute(
            MendPresentationRules.ATTRIBUTE_PULSE_SERIAL
        )
        local next_serial = type(serial) == "number"
            and serial + 1
            or 1

        character:SetAttribute(
            MendPresentationRules.ATTRIBUTE_PULSE_SERIAL,
            next_serial
        )
    end

    return true, healed
end


--[[
Clears the locked target and replicated Mend presentation for one caster.

Args:
    caster (Player): Channel owner to clear.

Returns:
    None.
]]
function MendService.cancel_channel(caster: Player)
    local channel = channels[caster]

    if not channel then
        return
    end

    channels[caster] = nil
    set_receiving_effect(caster, channel.target, false)
end


--[[
Cancels every active Mend channel whose locked recipient is one player.

This is used by combat lifecycle cleanup so a dead recipient loses healing
particles immediately instead of waiting for the next scheduled pulse.

Args:
    target (Player): Recipient whose incoming Mend channels must stop.

Returns:
    {Player}: Casters whose channels were cancelled.
]]
function MendService.cancel_channels_for_target(target: Player): {Player}
    local casters: {Player} = {}

    for caster, channel in channels do
        if channel.target == target then
            table.insert(casters, caster)
        end
    end

    for _, caster in casters do
        MendService.cancel_channel(caster)
    end

    return casters
end


function MendService.get_channel_target(caster: Player): Player?
    local channel = channels[caster]
    return if channel then channel.target else nil
end

return table.freeze(MendService)
