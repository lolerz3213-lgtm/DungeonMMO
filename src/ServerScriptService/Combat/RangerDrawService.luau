--!strict
-- Server-owned Longbow draw timing and replicated presentation attributes.

local Workspace = game:GetService("Workspace")

local RangerDrawService = {}

local DRAWING_ATTRIBUTE = "RangerDrawing"
local STARTED_AT_ATTRIBUTE = "RangerDrawStartedAt"

export type DrawRecord = {
    character: Model,
    started_at: number,
}

local records: {[Player]: DrawRecord} = {}

--[[
Writes replicated draw presentation state to one character.

Args:
    character (Model): Character receiving the presentation attributes.
    active (boolean): Whether the Longbow is currently being drawn.
    server_started_at (number): Replicated server timestamp or zero.

Returns:
    None.
]]
local function set_attributes(
    character: Model,
    active: boolean,
    server_started_at: number
)
    character:SetAttribute(DRAWING_ATTRIBUTE, active)
    character:SetAttribute(STARTED_AT_ATTRIBUTE, server_started_at)
end

--[[
Begins a server-authoritative Longbow draw when no draw is already active.

Args:
    player (Player): Ranger beginning the draw.
    character (Model): Current authoritative character.

Returns:
    boolean: True when a new draw record was created.
]]
function RangerDrawService.begin(
    player: Player,
    character: Model
): boolean
    if records[player] ~= nil then
        return false
    end

    records[player] = {
        character = character,
        started_at = os.clock(),
    }

    set_attributes(
        character,
        true,
        Workspace:GetServerTimeNow()
    )

    return true
end

--[[
Returns whether one player currently owns a live Longbow draw record.

Args:
    player (Player): Player to inspect.

Returns:
    boolean: True only while a current-character draw is active.
]]
function RangerDrawService.is_drawing(player: Player): boolean
    local record = records[player]

    if not record then
        return false
    end

    if player.Character ~= record.character
        or not record.character.Parent
    then
        records[player] = nil
        return false
    end

    return true
end

--[[
Releases a Longbow draw and returns the server-observed duration.

Args:
    player (Player): Player releasing the Longbow.

Returns:
    number?: Non-negative draw duration, or nil when no valid draw existed.
]]
function RangerDrawService.release(player: Player): number?
    local record = records[player]

    if not record then
        return nil
    end

    records[player] = nil

    if record.character.Parent then
        set_attributes(record.character, false, 0)
    end

    if player.Character ~= record.character then
        return nil
    end

    return math.max(0, os.clock() - record.started_at)
end

--[[
Cancels a Longbow draw without firing.

Args:
    player (Player): Player whose active draw is cancelled.

Returns:
    boolean: True when an active draw record was removed.
]]
function RangerDrawService.cancel(player: Player): boolean
    local record = records[player]

    if not record then
        return false
    end

    records[player] = nil

    if record.character.Parent then
        set_attributes(record.character, false, 0)
    end

    return true
end

--[[
Clears any stale draw state when a new character becomes authoritative.

Args:
    player (Player): Player whose character lifecycle is changing.
    character (Model): New character receiving neutral draw attributes.

Returns:
    None.
]]
function RangerDrawService.reset_character(
    player: Player,
    character: Model
)
    RangerDrawService.cancel(player)
    set_attributes(character, false, 0)
end

--[[
Removes all Longbow draw state for a leaving player.

Args:
    player (Player): Player leaving the server.

Returns:
    None.
]]
function RangerDrawService.remove_player(player: Player)
    RangerDrawService.cancel(player)
    records[player] = nil
end

return table.freeze(RangerDrawService)
