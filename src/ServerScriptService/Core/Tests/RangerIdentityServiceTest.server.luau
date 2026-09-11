--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService:WaitForChild("Core")
local ProfileService = require(
    Core:WaitForChild("Services")
        :WaitForChild("ProfileService")
)
local IdentityService = require(
    Core:WaitForChild("Services")
        :WaitForChild("IdentityService")
)
local InMemoryProfileAdapter = require(
    Core:WaitForChild("Adapters")
        :WaitForChild("InMemoryProfileAdapter")
)

local assertions = 0

--[[
Records one assertion with a Ranger-specific failure prefix.

Args:
    value (boolean): Condition that must be true.
    message (string): Failure detail.

Returns:
    None.
]]
local function check(value: boolean, message: string)
    assertions += 1

    if not value then
        error("[Ranger Identity Tests] " .. message, 2)
    end
end

--[[
Counts one item ID in a character inventory.

Args:
    character (any): Persistent character table.
    item_id (string): Item ID to count.

Returns:
    number: Total owned quantity for the requested item.
]]
local function count_item(character: any, item_id: string): number
    local count = 0

    for _, entry in ipairs(character.Inventory or {}) do
        if entry.ItemId == item_id then
            count += tonumber(entry.Quantity) or 0
        end
    end

    return count
end

--[[
Runs fresh-character Ranger identity acceptance for one race.

Args:
    race_id (string): Human or Elf.
    user_id (number): Isolated in-memory profile user ID.

Returns:
    None.
]]
local function run(race_id: string, user_id: number)
    local profiles = ProfileService.new(
        InMemoryProfileAdapter.new()
    )
    local loaded, load_error = profiles:load(user_id)

    check(
        loaded ~= nil and load_error == nil,
        "profile must load"
    )

    local identity = IdentityService.new(profiles)

    check(
        identity:select_race(user_id, race_id).ok == true,
        race_id .. " race selection must succeed"
    )
    check(
        identity:select_base_class(user_id, "Ranger").ok == true,
        race_id .. " Ranger selection must succeed"
    )

    local character = assert(
        profiles:get_character(user_id, 1)
    )

    check(
        character.Identity.RaceId == race_id
            and character.Identity.BaseClassId == "Ranger"
            and character.Identity.ClassId == "Ranger"
            and character.Identity.CreationStage == "Complete",
        "Ranger identity must complete"
    )

    local expected_skills = {
        "PiercingShot",
        "CripplingShot",
        "Volley",
    }

    for slot, skill_id in ipairs(expected_skills) do
        local state = character.Progression.Skills[skill_id]

        check(
            type(state) == "table"
                and state.Known == true
                and state.StarterGranted == true
                and state.PurchasedRank == 1,
            skill_id .. " exact starter state"
        )
        check(
            character.Progression.Loadout[slot] == skill_id,
            skill_id .. " must occupy its starter loadout slot"
        )
    end

    check(
        character.Equipment.Weapon == "apprentice_longbow",
        "Ranger Longbow must be persistently equipped"
    )
    check(
        character.Equipment.OffHand == nil,
        "Ranger starter loadout must leave reserved OffHand empty"
    )
    check(
        count_item(character, "apprentice_longbow") == 1,
        "Ranger must receive exactly one Apprentice Longbow"
    )

    local duplicate = identity:select_base_class(
        user_id,
        "Ranger"
    )
    check(
        duplicate.ok == false
            and duplicate.reason == "ClassSelectionNotAllowed",
        "duplicate class selection must reject"
    )
    check(
        count_item(character, "apprentice_longbow") == 1,
        "duplicate selection must not duplicate Longbow"
    )
end

run("Human", 7511)
run("Elf", 7512)

print(
    string.format(
        "[Ranger Identity Tests] PASS: %d assertions.",
        assertions
    )
)
