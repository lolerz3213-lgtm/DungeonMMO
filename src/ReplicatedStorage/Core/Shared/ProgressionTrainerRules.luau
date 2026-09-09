--!strict

local ATTRIBUTE_NAMES = table.freeze({
    "Strength",
    "Dexterity",
    "Vitality",
    "Intellect",
    "Spirit",
})

local ProgressionTrainerRules = {}

local function attributes_from(
    snapshot: any
): any
    if (
        type(snapshot) == "table"
        and type(snapshot.Attributes) == "table"
    ) then
        return snapshot.Attributes
    end

    return {}
end

local function baseline_from(
    snapshot: any
): any
    if (
        type(snapshot) == "table"
        and type(snapshot.AttributeBaseline) == "table"
    ) then
        return snapshot.AttributeBaseline
    end

    return {}
end

local function integer_value(
    value: any,
    fallback: number
): number
    local numeric = tonumber(value)

    if numeric == nil then
        return fallback
    end

    return math.floor(numeric)
end

local function current_and_baseline(
    snapshot: any,
    name: string
): (number, number)
    local attributes =
        attributes_from(snapshot)

    local baseline =
        baseline_from(snapshot)

    local current =
        integer_value(
            attributes[name],
            0
        )

    local racial_baseline =
        integer_value(
            baseline[name],
            current
        )

    current = math.max(
        racial_baseline,
        current
    )

    return current, racial_baseline
end

function ProgressionTrainerRules.create_attribute_preview(
    snapshot: any
): any
    local preview = {}

    for _, name in ipairs(ATTRIBUTE_NAMES) do
        local current =
            current_and_baseline(
                snapshot,
                name
            )

        preview[name] = current
    end

    return preview
end

function ProgressionTrainerRules.pending_attribute_spend(
    snapshot: any,
    preview: any
): number
    local pending = 0

    for _, name in ipairs(ATTRIBUTE_NAMES) do
        local current, racial_baseline =
            current_and_baseline(
                snapshot,
                name
            )

        local desired =
            if type(preview) == "table"
                then integer_value(
                    preview[name],
                    current
                )
                else current

        desired = math.max(
            racial_baseline,
            desired
        )

        pending += math.max(
            0,
            desired - current
        )
    end

    return pending
end

function ProgressionTrainerRules.can_add_attribute_point(
    snapshot: any,
    preview: any
): boolean
    local available =
        if type(snapshot) == "table"
            then math.max(
                0,
                math.floor(
                    tonumber(snapshot.APAvailable)
                        or 0
                )
            )
            else 0

    return ProgressionTrainerRules
        .pending_attribute_spend(
            snapshot,
            preview
        )
        < available
end

return table.freeze(ProgressionTrainerRules)