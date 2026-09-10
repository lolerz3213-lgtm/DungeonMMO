--!strict
local ServerScriptService =
    game:GetService("ServerScriptService")

local ManaService = require(
    ServerScriptService
        :WaitForChild("Combat")
        :WaitForChild("ManaService")
)

local assertions = 0

local function check(
    value: boolean,
    message: string
)
    assertions += 1
    if not value then
        error(
            "[Mana Service Tests] "
                .. message,
            2
        )
    end
end

local subject = Instance.new("Folder")
ManaService.initialize_player(subject)

check(
    ManaService.get(subject) == 100,
    "neutral Mana must initialize full at 100"
)
check(
    ManaService.get_max(subject) == 100,
    "neutral Max Mana must be 100"
)
check(
    subject:GetAttribute("CombatMana") == 100
        and subject:GetAttribute(
            "CombatMaxMana"
        ) == 100,
    "Mana must replicate current/max values"
)
check(
    subject:GetAttribute(
        "CombatManaRegenPerSecond"
    ) == 8,
    "neutral Spirit must replicate 8 Mana/s"
)
check(
    ManaService.try_spend(
        subject,
        20
    ) == true
        and ManaService.get(subject) == 80,
    "20 Mana spend must be atomic"
)
check(
    ManaService.try_spend(
        subject,
        81
    ) == false
        and ManaService.get(subject) == 80,
    "insufficient Mana must reject without partial spend"
)

ManaService.reset_player(subject)

check(
    ManaService.get(subject) == 100,
    "respawn reset must restore full Mana"
)

ManaService.remove_player(subject)

check(
    ManaService.get(subject) == 0,
    "removed owner must have no authoritative Mana record"
)

subject:Destroy()

print(
    string.format(
        "[Mana Service Tests] PASS: %d assertions.",
        assertions
    )
)
