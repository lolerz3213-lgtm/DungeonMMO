--!strict

local ReplicatedStorage = game:GetService(
    "ReplicatedStorage"
)

local ServerScriptService = game:GetService(
    "ServerScriptService"
)

local Shared = ReplicatedStorage
    :WaitForChild("Core")
    :WaitForChild("Shared")

local Services = ServerScriptService
    :WaitForChild("Core")
    :WaitForChild("Services")

local AttributeConfig = require(
    Shared:WaitForChild("AttributeConfig")
)

local RaceDefinitions = require(
    Shared:WaitForChild("RaceDefinitions")
)

local ProgressionRuntimeState = require(
    Services:WaitForChild(
        "ProgressionRuntimeState"
    )
)

local AttributeService = {}
AttributeService.__index = AttributeService

local ALLOWED: {[string]: boolean} = {
    Strength = true,
    Dexterity = true,
    Vitality = true,
    Intellect = true,
    Spirit = true,
}

local function integer(
    value: any
): boolean
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
        and value % 1 == 0
end

local function rejected(
    reason: string
): any
    return {
        ok = false,
        reason = reason,
    }
end

local function baseline_for(
    character: any
): any?
    if type(character) ~= "table" then
        return nil
    end

    local identity =
        character.Identity

    if type(identity) ~= "table" then
        return nil
    end

    if identity.CreationStage ~= "Complete" then
        return nil
    end

    local race_id =
        identity.RaceId

    if type(race_id) ~= "string" then
        return nil
    end

    return RaceDefinitions.get_base_attributes(
        race_id
    )
end

local function copy_attributes(
    attributes: any
): any
    return {
        Strength = attributes.Strength,
        Dexterity = attributes.Dexterity,
        Vitality = attributes.Vitality,
        Intellect = attributes.Intellect,
        Spirit = attributes.Spirit,
    }
end

local function evaluate(
    character: any,
    desired: any,
    allow_decrease: boolean
): any
    local baseline =
        baseline_for(character)

    if not baseline then
        return rejected("IdentityIncomplete")
    end

    if type(desired) ~= "table" then
        return rejected("InvalidAttributes")
    end

    for name in pairs(desired) do
        if not ALLOWED[name] then
            return rejected("UnknownAttribute")
        end
    end

    local current =
        character.Progression.Attributes

    local spent = 0

    for name in pairs(ALLOWED) do
        local value =
            desired[name]

        local racial_minimum =
            baseline[name]

        if (
            not integer(value)
            or value < racial_minimum
        ) then
            return rejected(
                "InvalidAttributeValue"
            )
        end

        local current_value =
            current[name]
                or racial_minimum

        if (
            not allow_decrease
            and value < current_value
        ) then
            return rejected(
                "DecreaseRequiresRespec"
            )
        end

        spent +=
            value - racial_minimum
    end

    local entitlement =
        character.Progression
            .AttributePointEntitlement
            or 0

    if spent > entitlement then
        return rejected(
            "InsufficientAttributePoints"
        )
    end

    return {
        ok = true,
        spent_points = spent,
        available_points =
            entitlement - spent,
        attributes =
            copy_attributes(desired),
    }
end

function AttributeService.new(
    profile_service: any
): any
    assert(
        profile_service ~= nil,
        "AttributeService requires ProfileService."
    )

    return setmetatable(
        {
            _profiles = profile_service,
        },
        AttributeService
    )
end

function AttributeService.get_available_points(
    character: any
): number
    local baseline =
        baseline_for(character)

    if not baseline then
        return 0
    end

    local progression =
        character.Progression

    local attributes =
        progression.Attributes

    local spent = 0

    for _, name in ipairs(
        AttributeConfig.get_names()
    ) do
        local racial_minimum =
            baseline[name]

        local value =
            attributes[name]
                or racial_minimum

        spent += math.max(
            0,
            value - racial_minimum
        )
    end

    local entitlement =
        progression.AttributePointEntitlement
            or 0

    return math.max(
        0,
        entitlement - spent
    )
end

function AttributeService:preview(
    user_id: number,
    desired: any
): any
    local character =
        self._profiles:get_character(
            user_id
        )

    if not character then
        return rejected(
            "ProfileNotLoaded"
        )
    end

    return evaluate(
        character,
        desired,
        false
    )
end

function AttributeService:commit(
    user_id: number,
    desired: any
): any
    local preview =
        self:preview(
            user_id,
            desired
        )

    if not preview.ok then
        return preview
    end

    local result: any = nil

    local ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local selected_slot =
                    profile.Account
                        .SelectedCharacterSlot

                local character =
                    profile.Characters[
                        "Slot"
                            .. tostring(
                                selected_slot
                            )
                    ]

                local checked =
                    evaluate(
                        character,
                        desired,
                        false
                    )

                if not checked.ok then
                    error(checked.reason)
                end

                character
                    .Progression
                    .Attributes =
                    copy_attributes(
                        desired
                    )

                result = checked
            end
        )

    if not ok then
        return rejected(
            mutation_error
                or "ProfileMutationFailed"
        )
    end

    local character =
        self._profiles:get_character(
            user_id
        )

    if character then
        ProgressionRuntimeState
            .set_character(
                user_id,
                character
            )
    end

    return result
end

function AttributeService:respec(
    user_id: number
): any
    local character =
        self._profiles:get_character(
            user_id
        )

    if not character then
        return rejected(
            "ProfileNotLoaded"
        )
    end

    local baseline =
        baseline_for(character)

    if not baseline then
        return rejected(
            "IdentityIncomplete"
        )
    end

    local result: any = nil

    local ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local selected_slot =
                    profile.Account
                        .SelectedCharacterSlot

                local live_character =
                    profile.Characters[
                        "Slot"
                            .. tostring(
                                selected_slot
                            )
                    ]

                local live_baseline =
                    baseline_for(
                        live_character
                    )

                if not live_baseline then
                    error(
                        "IdentityIncomplete"
                    )
                end

                local progression =
                    live_character.Progression

                progression.Attributes =
                    copy_attributes(
                        live_baseline
                    )

                progression
                    .RespecCounters
                    .Attributes =
                    (
                        progression
                            .RespecCounters
                            .Attributes
                            or 0
                    )
                    + 1

                result = {
                    ok = true,

                    available_points =
                        progression
                            .AttributePointEntitlement
                            or 0,

                    respec_count =
                        progression
                            .RespecCounters
                            .Attributes,
                }
            end
        )

    if not ok then
        return rejected(
            mutation_error
                or "ProfileMutationFailed"
        )
    end

    local updated =
        self._profiles:get_character(
            user_id
        )

    if updated then
        ProgressionRuntimeState
            .set_character(
                user_id,
                updated
            )
    end

    return result
end

return table.freeze(AttributeService)