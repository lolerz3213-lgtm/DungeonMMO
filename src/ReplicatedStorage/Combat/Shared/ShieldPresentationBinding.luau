local ShieldPresentationBinding = {}


--[[
Returns the configured attachment part and visible shield part from a character.

The shield part is server-created, but the presentation Motor6D may not always
be replicated to the owning client before presentation starts. This module
keeps that replication timing detail out of DefensePresentation.

Args:
    character (Model): Character containing the shield.
    shield_config (table): CombatConfig.PROTOTYPE_SHIELD.
    timeout_seconds (number): Maximum wait for server-created instances.

Returns:
    BasePart?: Configured attachment part.
    BasePart?: Visible shield part.
    string?: Failure reason when either part is unavailable.
]]
local function resolve_parts(
    character: Model,
    shield_config: any,
    timeout_seconds: number
): (BasePart?, BasePart?, string?)
    local attach_part = character:FindFirstChild(
        shield_config.ATTACH_PART_NAME
    ) or character:WaitForChild(
        shield_config.ATTACH_PART_NAME,
        timeout_seconds
    )

    if not attach_part or not attach_part:IsA("BasePart") then
        return nil, nil, "AttachPartMissing"
    end

    local shield = character:FindFirstChild(
        shield_config.PART_NAME
    ) or character:WaitForChild(
        shield_config.PART_NAME,
        timeout_seconds
    )

    if not shield or not shield:IsA("BasePart") then
        return attach_part, nil, "ShieldPartMissing"
    end

    return attach_part, shield, nil
end


--[[
Finds the replicated server presentation grip or creates a local fallback.

The fallback changes presentation only. Damage, blocking, parry, stamina and
Shield Bash remain fully server-authoritative.

Args:
    character (Model): Character receiving local shield presentation.
    shield_config (table): CombatConfig.PROTOTYPE_SHIELD.
    timeout_seconds (number): Maximum wait for the shield part itself.

Returns:
    Motor6D?: Grip to drive from DefensePresentation.
    string: "Replicated", "ClientFallback", or a failure reason.
]]
function ShieldPresentationBinding.resolve(
    character: Model,
    shield_config: any,
    timeout_seconds: number
): (Motor6D?, string)
    local attach_part, shield, failure = resolve_parts(
        character,
        shield_config,
        timeout_seconds
    )

    if failure then
        return nil, failure
    end

    assert(attach_part ~= nil)
    assert(shield ~= nil)

    local existing = attach_part:FindFirstChild(
        shield_config.GRIP_NAME
    )

    if not existing then
        existing = attach_part:WaitForChild(
            shield_config.GRIP_NAME,
            shield_config.PRESENTATION_GRIP_REPLICATION_WAIT_SECONDS
        )
    end

    if existing and existing:IsA("Motor6D") then
        return existing, "Replicated"
    end

    local fallback = Instance.new("Motor6D")

    fallback.Name = shield_config.GRIP_NAME
        .. "ClientFallback"
    fallback.Part0 = attach_part
    fallback.Part1 = shield
    fallback.C0 = attach_part.CFrame:ToObjectSpace(
        shield.CFrame
    )
    fallback.C1 = CFrame.identity
    fallback.Parent = attach_part

    return fallback, "ClientFallback"
end


return ShieldPresentationBinding
