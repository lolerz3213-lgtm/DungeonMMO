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

local SkillDefinitions = require(
    Shared:WaitForChild(
        "SkillProgressionDefinitions"
    )
)

local ClassDefinitions = require(
    Shared:WaitForChild(
        "ClassProgressionDefinitions"
    )
)

local CharacterIdentityRules = require(
    Shared:WaitForChild(
        "CharacterIdentityRules"
    )
)

local ItemDefinitions = require(
    Shared:WaitForChild(
        "ItemDefinitions"
    )
)

local InventoryService = require(
    Services:WaitForChild(
        "InventoryService"
    )
)

local ProgressionRuntimeState = require(
    Services:WaitForChild(
        "ProgressionRuntimeState"
    )
)

local SkillProgressionService = {}
SkillProgressionService.__index =
    SkillProgressionService

local function rejected(
    reason: string
): any
    return {
        ok = false,
        reason = reason,
    }
end

local function identity_complete(
    character: any
): boolean
    return type(character) == "table"
        and CharacterIdentityRules
            .is_complete(character)
end

local function allocated(
    character: any
): number
    local total = 0

    for skill_id, state in pairs(
        character.Progression.Skills
    ) do
        if (
            type(state) == "table"
            and state.Known == true
        ) then
            local definition =
                SkillDefinitions.get(
                    skill_id
                )

            if definition then
                local rank =
                    state.PurchasedRank or 0

                for purchased_rank = 1, rank do
                    local free_starter =
                        purchased_rank == 1
                        and state.StarterGranted
                            == true

                    if not free_starter then
                        total +=
                            SkillProgressionConfig
                                .get_rank_cost(
                                    definition.Tier,
                                    purchased_rank
                                )
                                or 0
                    end
                end
            end
        end
    end

    return total
end

function SkillProgressionService.get_allocated_sp(
    character: any
): number
    if not identity_complete(character) then
        return 0
    end

    return allocated(character)
end

function SkillProgressionService
    .get_available_sp_for_character(
        character: any
    ): number

    if not identity_complete(character) then
        return 0
    end

    return math.max(
        0,
        (
            character.Progression
                .SkillPointEntitlement
                or 0
        )
            - allocated(character)
    )
end

function SkillProgressionService.new(
    profile_service: any,
    inventory_service: any,
    loadout_service: any
): any
    assert(
        profile_service
            and inventory_service
            and loadout_service
    )

    return setmetatable(
        {
            _profiles = profile_service,
            _inventory = inventory_service,
            _loadout = loadout_service,
        },
        SkillProgressionService
    )
end

function SkillProgressionService:get_available_sp(
    user_id: number
): number
    local character =
        self._profiles:get_character(
            user_id
        )

    if not character then
        return 0
    end

    return SkillProgressionService
        .get_available_sp_for_character(
            character
        )
end

function SkillProgressionService:learn_skill(
    user_id: number,
    skill_id: string,
    source_item_id: string
): any
    local definition =
        SkillDefinitions.get(skill_id)

    if not definition then
        return rejected("UnknownSkill")
    end

    local current_character =
        self._profiles:get_character(
            user_id
        )

    if not current_character then
        return rejected("ProfileNotLoaded")
    end

    if not identity_complete(
        current_character
    ) then
        return rejected("IdentityIncomplete")
    end

    local item =
        ItemDefinitions.get(
            source_item_id
        )

    if (
        not item
        or item.Kind ~= "SkillBook"
        or item.SkillId ~= skill_id
        or item.Learnable ~= true
    ) then
        return rejected("WrongSkillBook")
    end

    local result: any = nil
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

                if not identity_complete(
                    character
                ) then
                    failure =
                        "IdentityIncomplete"

                    error(failure)
                end

                local class_id =
                    character.Identity.ClassId

                if (
                    type(class_id) ~= "string"
                    or not ClassDefinitions
                        .can_teach(
                            class_id,
                            skill_id
                        )
                ) then
                    failure =
                        "ClassCannotTeachSkill"

                    error(failure)
                end

                local progression =
                    character.Progression

                local existing =
                    progression.Skills[
                        skill_id
                    ]

                if (
                    existing
                    and existing.Known == true
                ) then
                    failure = "AlreadyKnown"
                    error(failure)
                end

                local cost =
                    SkillProgressionConfig
                        .get_rank_cost(
                            definition.Tier,
                            1
                        )
                        or 0

                if (
                    SkillProgressionService
                        .get_available_sp_for_character(
                            character
                        )
                        < cost
                ) then
                    failure = "InsufficientSP"
                    error(failure)
                end

                local removed =
                    InventoryService
                        .apply_remove_from_character(
                            character,
                            source_item_id,
                            1
                        )

                if not removed.ok then
                    failure =
                        "SkillBookNotOwned"

                    error(failure)
                end

                local archived =
                    if (
                        existing
                        and type(
                            existing.Proficiency
                        ) == "number"
                    )
                        then existing.Proficiency
                        else 0

                progression.Skills[
                    skill_id
                ] = {
                    Known = true,
                    StarterGranted = false,
                    PurchasedRank = 1,
                    Proficiency = archived,
                }

                result = {
                    ok = true,
                    skill_id = skill_id,
                    rank = 1,
                    cost = cost,
                }
            end
        )

    if not ok then
        return rejected(
            failure
                or mutation_error
                or "ProfileMutationFailed"
        )
    end

    self._loadout:auto_equip_first_free(
        user_id,
        skill_id
    )

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

    return result
end

function SkillProgressionService:purchase_rank(
    user_id: number,
    skill_id: string
): any
    local definition =
        SkillDefinitions.get(skill_id)

    if not definition then
        return rejected("UnknownSkill")
    end

    local current_character =
        self._profiles:get_character(
            user_id
        )

    if not current_character then
        return rejected("ProfileNotLoaded")
    end

    if not identity_complete(
        current_character
    ) then
        return rejected("IdentityIncomplete")
    end

    local result: any = nil
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

                if not identity_complete(
                    character
                ) then
                    failure =
                        "IdentityIncomplete"

                    error(failure)
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
                ) then
                    failure =
                        "SkillNotKnown"

                    error(failure)
                end

                local current =
                    state.PurchasedRank
                        or 0

                local target =
                    current + 1

                if target > definition.MaxRank then
                    failure = "MaxRank"
                    error(failure)
                end

                local threshold =
                    SkillProgressionConfig
                        .get_threshold(
                            definition.Tier,
                            target
                        )

                if (
                    threshold
                    and (
                        state.Proficiency
                            or 0
                    ) < threshold
                ) then
                    failure =
                        "ProficiencyThresholdNotMet"

                    error(failure)
                end

                local cost =
                    SkillProgressionConfig
                        .get_rank_cost(
                            definition.Tier,
                            target
                        )
                        or 0

                if (
                    SkillProgressionService
                        .get_available_sp_for_character(
                            character
                        )
                        < cost
                ) then
                    failure =
                        "InsufficientSP"

                    error(failure)
                end

                state.PurchasedRank =
                    target

                result = {
                    ok = true,
                    skill_id = skill_id,
                    rank = target,
                    cost = cost,
                }
            end
        )

    if not ok then
        return rejected(
            failure
                or mutation_error
                or "ProfileMutationFailed"
        )
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

    return result
end

function SkillProgressionService:respec_skills(
    user_id: number
): any
    local current_character =
        self._profiles:get_character(
            user_id
        )

    if not current_character then
        return rejected("ProfileNotLoaded")
    end

    if not identity_complete(
        current_character
    ) then
        return rejected("IdentityIncomplete")
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

                if not identity_complete(
                    character
                ) then
                    failure =
                        "IdentityIncomplete"

                    error(failure)
                end

                local progression =
                    character.Progression

                for _, state in pairs(
                    progression.Skills
                ) do
                    if (
                        type(state)
                            == "table"
                        and state.Known
                            == true
                    ) then
                        state.PurchasedRank =
                            if state
                                .StarterGranted
                                == true
                                then 1
                                else 0
                    end
                end

                local cleaned = {}

                for slot = 1,
                    SkillProgressionConfig
                        .MAX_ACTIVE_SLOTS do

                    local skill_id =
                        progression.Loadout[
                            slot
                        ]

                    local state =
                        skill_id
                        and progression
                            .Skills[
                                skill_id
                            ]

                    if (
                        state
                        and (
                            state.PurchasedRank
                                or 0
                        ) >= 1
                    ) then
                        cleaned[slot] =
                            skill_id
                    end
                end

                progression.Loadout =
                    cleaned

                progression
                    .RespecCounters
                    .Skills =
                    (
                        progression
                            .RespecCounters
                            .Skills
                            or 0
                    )
                    + 1
            end
        )

    if not ok then
        return rejected(
            failure
                or mutation_error
                or "ProfileMutationFailed"
        )
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

        available_sp =
            self:get_available_sp(
                user_id
            ),

        respec_count =
            refreshed
            and refreshed
                .Progression
                .RespecCounters
                .Skills
            or nil,
    }
end

function SkillProgressionService
    :grant_arc_slash_first_clear(
        user_id: number,
        transaction_id: string
    ): any

    if (
        type(transaction_id) ~= "string"
        or transaction_id == ""
    ) then
        return rejected(
            "InvalidTransactionId"
        )
    end

    local result: any = nil

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

                local rewards =
                    character
                        .Progression
                        .OneTimeRewards

                if type(rewards) ~= "table" then
                    rewards = {}

                    character
                        .Progression
                        .OneTimeRewards =
                        rewards
                end

                if (
                    rewards
                        .ArcSlashFirstClear
                        == true
                ) then
                    result = {
                        ok = true,
                        already_applied = true,
                        item_id =
                            "arc_slash_book_bound",
                        transaction_id =
                            transaction_id,
                    }

                    return
                end

                local added =
                    InventoryService
                        .apply_item_to_character(
                            character,
                            "arc_slash_book_bound",
                            1
                        )

                if not added.ok then
                    error(
                        added.reason
                            or "ArcSlashBookGrantFailed"
                    )
                end

                rewards.ArcSlashFirstClear =
                    true

                result = {
                    ok = true,
                    already_applied = false,
                    item_id =
                        "arc_slash_book_bound",
                    transaction_id =
                        transaction_id,
                    total_quantity =
                        added.total_quantity,
                }
            end
        )

    if not ok then
        return rejected(
            mutation_error
                or "ProfileMutationFailed"
        )
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

    return result
end

return table.freeze(
    SkillProgressionService
)