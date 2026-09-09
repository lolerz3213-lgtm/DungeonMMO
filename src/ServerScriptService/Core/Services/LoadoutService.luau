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

local SkillProgressionConfig = require(
    Shared:WaitForChild(
        "SkillProgressionConfig"
    )
)

local CharacterIdentityRules = require(
    Shared:WaitForChild(
        "CharacterIdentityRules"
    )
)

local ProgressionRuntimeState = require(
    Services:WaitForChild(
        "ProgressionRuntimeState"
    )
)

local LoadoutService = {}
LoadoutService.__index = LoadoutService

local function complete(
    character: any
): boolean
    return type(character) == "table"
        and CharacterIdentityRules
            .is_complete(character)
end

local function validate_character(
    character: any,
    slots: any
): any
    if type(slots) ~= "table" then
        return {
            ok = false,
            reason = "InvalidLoadout",
        }
    end

    local seen: {[string]: boolean} = {}
    local cleaned = {}

    for slot = 1,
        SkillProgressionConfig
            .MAX_ACTIVE_SLOTS do

        local skill_id =
            slots[slot]

        if skill_id ~= nil then
            if (
                type(skill_id) ~= "string"
                or skill_id == ""
            ) then
                return {
                    ok = false,
                    reason = "InvalidSkillId",
                }
            end

            if seen[skill_id] then
                return {
                    ok = false,
                    reason = "DuplicateSkill",
                }
            end

            local state =
                character
                    .Progression
                    .Skills[
                        skill_id
                    ]

            if (
                type(state) ~= "table"
                or state.Known ~= true
                or (
                    state.PurchasedRank
                        or 0
                ) < 1
            ) then
                return {
                    ok = false,
                    reason =
                        "SkillNotPurchased",
                }
            end

            seen[skill_id] = true
            cleaned[slot] = skill_id
        end
    end

    for key in pairs(slots) do
        if (
            type(key) == "number"
            and key
                > SkillProgressionConfig
                    .MAX_ACTIVE_SLOTS
            and slots[key] ~= nil
        ) then
            return {
                ok = false,
                reason = "TooManySlots",
            }
        end
    end

    return {
        ok = true,
        slots = cleaned,
    }
end

function LoadoutService.new(
    profile_service: any
): any
    assert(profile_service)

    return setmetatable(
        {
            _profiles = profile_service,
        },
        LoadoutService
    )
end

function LoadoutService.validate(
    character: any,
    requested_slots: any,
    _max_slots: number?
): any
    return validate_character(
        character,
        requested_slots
    )
end

function LoadoutService:auto_equip_first_free(
    user_id: number,
    skill_id: string
): boolean
    local current =
        self._profiles:get_character(
            user_id
        )

    if (
        not current
        or not complete(current)
    ) then
        return false
    end

    local equipped = false

    self._profiles:mutate(
        user_id,
        function(profile: any)
            local character =
                profile.Characters[
                    "Slot"
                        .. tostring(
                            profile.Account
                                .SelectedCharacterSlot
                        )
                ]

            if not complete(character) then
                return
            end

            local state =
                character
                    .Progression
                    .Skills[
                        skill_id
                    ]

            if (
                not state
                or state.Known ~= true
                or (
                    state.PurchasedRank
                        or 0
                ) < 1
            ) then
                return
            end

            for _, existing in pairs(
                character
                    .Progression
                    .Loadout
            ) do
                if existing == skill_id then
                    equipped = true
                    return
                end
            end

            for slot = 1,
                SkillProgressionConfig
                    .MAX_ACTIVE_SLOTS do

                if (
                    character
                        .Progression
                        .Loadout[slot]
                    == nil
                ) then
                    character
                        .Progression
                        .Loadout[slot] =
                        skill_id

                    equipped = true
                    return
                end
            end
        end
    )

    if equipped then
        local refreshed =
            self._profiles:get_character(
                user_id
            )

        if refreshed then
            ProgressionRuntimeState
                .set_character(
                    user_id,
                    refreshed
                )
        end
    end

    return equipped
end

function LoadoutService:set(
    user_id: number,
    requested_slots: any,
    context: string
): any
    if context == "DungeonActive" then
        return {
            ok = false,
            reason =
                "LoadoutLockedDuringEncounter",
        }
    end

    if (
        context ~= "Base"
        and context ~= "DungeonClear"
    ) then
        return {
            ok = false,
            reason =
                "InvalidLoadoutContext",
        }
    end

    local current =
        self._profiles:get_character(
            user_id
        )

    if not current then
        return {
            ok = false,
            reason = "ProfileNotLoaded",
        }
    end

    if not complete(current) then
        return {
            ok = false,
            reason = "IdentityIncomplete",
        }
    end

    local checked =
        validate_character(
            current,
            requested_slots
        )

    if not checked.ok then
        return checked
    end

    local failure: string? = nil

    local ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local character =
                    profile.Characters[
                        "Slot"
                            .. tostring(
                                profile.Account
                                    .SelectedCharacterSlot
                            )
                    ]

                if not complete(character) then
                    failure =
                        "IdentityIncomplete"

                    error(failure)
                end

                local live_check =
                    validate_character(
                        character,
                        requested_slots
                    )

                if not live_check.ok then
                    failure =
                        live_check.reason
                        or "InvalidLoadout"

                    error(failure)
                end

                character
                    .Progression
                    .Loadout =
                    live_check.slots
            end
        )

    if not ok then
        return {
            ok = false,
            reason =
                failure
                or mutation_error
                or "ProfileMutationFailed",
        }
    end

    local refreshed =
        self._profiles:get_character(
            user_id
        )

    if refreshed then
        ProgressionRuntimeState
            .set_character(
                user_id,
                refreshed
            )
    end

    return {
        ok = true,
        slots = checked.slots,
    }
end

function LoadoutService:move_to_slot(
    user_id: number,
    skill_id: any,
    slot: any,
    context: string
): any
    if context == "DungeonActive" then
        return {
            ok = false,
            reason =
                "LoadoutLockedDuringEncounter",
        }
    end

    if (
        context ~= "Base"
        and context ~= "DungeonClear"
    ) then
        return {
            ok = false,
            reason =
                "InvalidLoadoutContext",
        }
    end

    if (
        type(skill_id) ~= "string"
        or skill_id == ""
    ) then
        return {
            ok = false,
            reason = "InvalidSkillId",
        }
    end

    if (
        type(slot) ~= "number"
        or slot % 1 ~= 0
        or slot < 1
        or slot
            > SkillProgressionConfig
                .MAX_ACTIVE_SLOTS
    ) then
        return {
            ok = false,
            reason = "InvalidSlot",
        }
    end

    local current =
        self._profiles:get_character(
            user_id
        )

    if not current then
        return {
            ok = false,
            reason = "ProfileNotLoaded",
        }
    end

    if not complete(current) then
        return {
            ok = false,
            reason = "IdentityIncomplete",
        }
    end

    local final_slots: any = nil
    local failure: string? = nil

    local ok, mutation_error =
        self._profiles:mutate(
            user_id,
            function(profile: any)
                local character =
                    profile.Characters[
                        "Slot"
                            .. tostring(
                                profile.Account
                                    .SelectedCharacterSlot
                            )
                    ]

                if not complete(character) then
                    failure =
                        "IdentityIncomplete"

                    error(failure)
                end

                local skill_state =
                    character
                        .Progression
                        .Skills[
                            skill_id
                        ]

                if (
                    type(skill_state)
                        ~= "table"
                    or skill_state.Known
                        ~= true
                    or (
                        skill_state
                            .PurchasedRank
                            or 0
                    ) < 1
                ) then
                    failure =
                        "SkillNotPurchased"

                    error(failure)
                end

                local desired: any = {}

                for target = 1,
                    SkillProgressionConfig
                        .MAX_ACTIVE_SLOTS do

                    local existing =
                        character
                            .Progression
                            .Loadout[
                                target
                            ]

                    if existing ~= skill_id then
                        desired[target] =
                            existing
                    end
                end

                desired[slot] = skill_id

                local checked =
                    validate_character(
                        character,
                        desired
                    )

                if not checked.ok then
                    failure =
                        checked.reason
                        or "InvalidLoadout"

                    error(failure)
                end

                character
                    .Progression
                    .Loadout =
                    checked.slots

                final_slots =
                    checked.slots
            end
        )

    if not ok then
        return {
            ok = false,
            reason =
                failure
                or mutation_error
                or "ProfileMutationFailed",
        }
    end

    local refreshed =
        self._profiles:get_character(
            user_id
        )

    if refreshed then
        ProgressionRuntimeState
            .set_character(
                user_id,
                refreshed
            )
    end

    return {
        ok = true,
        slots = final_slots,
    }
end

return table.freeze(
    LoadoutService
)