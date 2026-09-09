--!strict
-- Pure completion-summary presentation. Reward grants remain unchanged.

local CompletionRewardPresentation = {}

function CompletionRewardPresentation.lines(completion: any): {string}
    if type(completion) ~= "table" then
        return {"Completion rewards unavailable."}
    end

    local lines = {
        string.format(
            "Completion Gold: +%d",
            math.max(0, math.floor(tonumber(completion.gold_granted) or 0))
        ),
        "Personal loot: " .. tostring(completion.item_id or "Nothing"),
    }

    local book = completion.arc_slash_book

    if (
        type(book) == "table"
        and book.ok == true
        and book.already_applied ~= true
    ) then
        table.insert(lines, "Bonus: Arc Slash Skill Book")
    end

    return lines
end

function CompletionRewardPresentation.text(completion: any): string
    return table.concat(
        CompletionRewardPresentation.lines(completion),
        "\n"
    )
end

return table.freeze(CompletionRewardPresentation)
