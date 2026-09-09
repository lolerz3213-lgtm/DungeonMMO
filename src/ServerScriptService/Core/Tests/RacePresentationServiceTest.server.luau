--!strict

local ServerScriptService =
    game:GetService(
        "ServerScriptService"
    )

local Services =
    ServerScriptService
        :WaitForChild("Core")
        :WaitForChild("Services")

local RacePresentationService = require(
    Services:WaitForChild(
        "RacePresentationService"
    )
)

local assertions = 0


local function check(
    condition: boolean,
    message: string
)
    assertions += 1

    if not condition then
        error(
            "[Race Presentation Service Tests] "
                .. message,
            2
        )
    end
end


local function count_named(
    root: Instance,
    name: string
): number
    local total = 0

    for _, descendant in ipairs(
        root:GetDescendants()
    ) do
        if descendant.Name == name then
            total += 1
        end
    end

    return total
end


local function check_piece(
    head: BasePart,
    piece: BasePart,
    label: string
)
    check(
        piece.Material
            == Enum.Material.SmoothPlastic,
        label .. " must use SmoothPlastic."
    )

    check(
        piece.CanCollide == false
            and piece.CanTouch == false
            and piece.CanQuery == false,
        label .. " must be presentation-only."
    )

    check(
        piece.Massless == true,
        label .. " must be massless."
    )

    local weld =
        piece:FindFirstChildWhichIsA(
            "Weld"
        )

    check(
        weld ~= nil
            and weld.Part0 == head
            and weld.Part1 == piece,
        label .. " must be welded directly to Head."
    )
end


local function corner_local_x_range(
    head: BasePart,
    piece: BasePart
): (number, number)
    local half =
        piece.Size * 0.5

    local minimum =
        math.huge

    local maximum =
        -math.huge

    for _, x in ipairs({
        -half.X,
        half.X,
    }) do
        for _, y in ipairs({
            -half.Y,
            half.Y,
        }) do
            for _, z in ipairs({
                -half.Z,
                half.Z,
            }) do
                local world =
                    piece.CFrame
                        :PointToWorldSpace(
                            Vector3.new(
                                x,
                                y,
                                z
                            )
                        )

                local local_point =
                    head.CFrame
                        :PointToObjectSpace(
                            world
                        )

                minimum =
                    math.min(
                        minimum,
                        local_point.X
                    )

                maximum =
                    math.max(
                        maximum,
                        local_point.X
                    )
            end
        end
    end

    return minimum, maximum
end


local character =
    Instance.new("Model")

character.Name =
    "RacePresentationTestCharacter"


local head =
    Instance.new("Part")

head.Name = "Head"

head.Size =
    Vector3.new(
        2,
        1,
        1
    )

head.CFrame =
    CFrame.new(
        0,
        20,
        0
    )

head.Color =
    Color3.fromRGB(
        230,
        190,
        160
    )

head.Anchored = true
head.Parent = character


local face =
    Instance.new("Attachment")

face.Name =
    "FaceCenterAttachment"

face.Position =
    Vector3.new(
        0,
        0,
        -0.6
    )

face.Parent = head


local hair =
    Instance.new("Attachment")

hair.Name =
    "HairAttachment"

hair.Position =
    Vector3.new(
        0,
        0.6,
        0
    )

hair.Parent = head


local hat =
    Instance.new("Attachment")

hat.Name =
    "HatAttachment"

hat.Position =
    Vector3.new(
        0,
        0.6,
        0
    )

hat.Parent = head


local neck =
    Instance.new("Attachment")

neck.Name =
    "NeckRigAttachment"

neck.Position =
    Vector3.new(
        0,
        -0.5,
        0
    )

neck.Parent = head


character.Parent = workspace


local result =
    RacePresentationService.apply(
        character,
        "Elf"
    )


check(
    result.ok == true,
    "Elf application must succeed."
)

check(
    result.ear_count == 2,
    "Elf application must report two ears."
)


local root =
    character:FindFirstChild(
        RacePresentationService.ROOT_NAME
    )


check(
    root ~= nil
        and root:IsA("Folder"),
    "race visual root must exist."
)


local left =
    root
    and root:FindFirstChild(
        RacePresentationService.ELF_LEFT_NAME
    )

local left_inner =
    root
    and root:FindFirstChild(
        RacePresentationService.ELF_LEFT_NAME
            .. "Inner"
    )

local right =
    root
    and root:FindFirstChild(
        RacePresentationService.ELF_RIGHT_NAME
    )

local right_inner =
    root
    and root:FindFirstChild(
        RacePresentationService.ELF_RIGHT_NAME
            .. "Inner"
    )


check(
    left ~= nil
        and left:IsA("WedgePart"),
    "left outer ear must exist."
)

check(
    left_inner ~= nil
        and left_inner:IsA("WedgePart"),
    "left inner ear must exist."
)

check(
    right ~= nil
        and right:IsA("WedgePart"),
    "right outer ear must exist."
)

check(
    right_inner ~= nil
        and right_inner:IsA("WedgePart"),
    "right inner ear must exist."
)


if (
    left
    and left:IsA("BasePart")
    and left_inner
    and left_inner:IsA("BasePart")
    and right
    and right:IsA("BasePart")
    and right_inner
    and right_inner:IsA("BasePart")
) then

    check_piece(
        head,
        left,
        "left outer ear"
    )

    check_piece(
        head,
        left_inner,
        "left inner ear"
    )

    check_piece(
        head,
        right,
        "right outer ear"
    )

    check_piece(
        head,
        right_inner,
        "right inner ear"
    )


    -- --------------------------------------------------------
    -- DELICATE PROPORTIONS
    -- --------------------------------------------------------

    check(
        math.abs(
            left.Size.Z - 1.35
        ) < 0.001
            and math.abs(
                right.Size.Z - 1.35
            ) < 0.001,
        "outer ears must use restrained 1.35-stud length."
    )

    check(
        left.Size.Y <= 0.35
            and right.Size.Y <= 0.35,
        "outer ears must have a delicate narrow base."
    )

    check(
        left.Size.X <= 0.15
            and right.Size.X <= 0.15,
        "outer ears must remain very thin."
    )

    check(
        left_inner.Size.Z
            < left.Size.Z * 0.70
            and right_inner.Size.Z
                < right.Size.Z * 0.70,
        "inner cartilage must not dominate silhouette."
    )

    check(
        left.Color == head.Color
            and right.Color == head.Color,
        "outer ears must match Head.Color."
    )

    check(
        left_inner.Color ~= head.Color
            and right_inner.Color ~= head.Color,
        "inner ears must retain subtle colour variation."
    )


    -- --------------------------------------------------------
    -- POSITION / DIRECTION
    -- --------------------------------------------------------

    local left_pos =
        head.CFrame
            :PointToObjectSpace(
                left.Position
            )

    local right_pos =
        head.CFrame
            :PointToObjectSpace(
                right.Position
            )

    local left_dir =
        head.CFrame
            :VectorToObjectSpace(
                left.CFrame.LookVector
            )

    local right_dir =
        head.CFrame
            :VectorToObjectSpace(
                right.CFrame.LookVector
            )

    check(
        left_pos.Y > 0.30
            and right_pos.Y > 0.30,
        "ears must remain at proper upper-head height."
    )

    check(
        left_pos.X < -1.0,
        "left ear must originate on left side."
    )

    check(
        right_pos.X > 1.0,
        "right ear must originate on right side."
    )

    check(
        left_dir.X < -0.85,
        "left ear must point strongly outward."
    )

    check(
        right_dir.X > 0.85,
        "right ear must point strongly outward."
    )

    check(
        left_dir.Z > 0.25
            and left_dir.Z < 0.50,
        "left ear must have gentle backward sweep."
    )

    check(
        right_dir.Z > 0.25
            and right_dir.Z < 0.50,
        "right ear must have gentle backward sweep."
    )

    check(
        left_dir.Y > 0
            and left_dir.Y < 0.15,
        "left ear must have only slight upward tilt."
    )

    check(
        right_dir.Y > 0
            and right_dir.Y < 0.15,
        "right ear must have only slight upward tilt."
    )


    -- --------------------------------------------------------
    -- ABSOLUTELY NO CROSSING THROUGH HEAD CENTRE
    -- --------------------------------------------------------

    local left_min_x, left_max_x =
        corner_local_x_range(
            head,
            left
        )

    local right_min_x, right_max_x =
        corner_local_x_range(
            head,
            right
        )

    check(
        left_max_x < -0.10,
        "left outer ear geometry must stay entirely left of centre."
    )

    check(
        right_min_x > 0.10,
        "right outer ear geometry must stay entirely right of centre."
    )

    check(
        left_min_x < -1.5,
        "left ear must still produce a visible outward point."
    )

    check(
        right_max_x > 1.5,
        "right ear must still produce a visible outward point."
    )
end


-- ==========================================================
-- IDEMPOTENCY
-- ==========================================================

RacePresentationService.apply(
    character,
    "Elf"
)

check(
    count_named(
        character,
        RacePresentationService.ROOT_NAME
    ) == 1,
    "reapply must leave one visual root."
)

local second_root =
    character:FindFirstChild(
        RacePresentationService.ROOT_NAME
    )

if second_root then
    check(
        #second_root:GetChildren() == 4,
        "Elf must have exactly four geometry pieces."
    )
else
    check(
        false,
        "Elf visual root must survive reapplication."
    )
end

check(
    count_named(
        character,
        RacePresentationService.ELF_LEFT_NAME
    ) == 1
        and count_named(
            character,
            RacePresentationService.ELF_RIGHT_NAME
        ) == 1,
    "reapply must not duplicate main ears."
)


-- ==========================================================
-- HUMAN CLEARS VISUALS
-- ==========================================================

RacePresentationService.apply(
    character,
    "Human"
)

check(
    character:FindFirstChild(
        RacePresentationService.ROOT_NAME
    ) == nil,
    "Human must clear Elf visuals."
)


-- ==========================================================
-- FALLBACK WITHOUT ATTACHMENTS
-- ==========================================================

face:Destroy()
hair:Destroy()
hat:Destroy()
neck:Destroy()

local fallback =
    RacePresentationService.apply(
        character,
        "Elf"
    )

check(
    fallback.ok == true,
    "attachment-free Elf fallback must succeed."
)

local fallback_root =
    character:FindFirstChild(
        RacePresentationService.ROOT_NAME
    )

local fallback_left =
    fallback_root
    and fallback_root:FindFirstChild(
        RacePresentationService.ELF_LEFT_NAME
    )

if (
    fallback_left
    and fallback_left:IsA("BasePart")
) then
    local fallback_pos =
        head.CFrame
            :PointToObjectSpace(
                fallback_left.Position
            )

    local fallback_dir =
        head.CFrame
            :VectorToObjectSpace(
                fallback_left.CFrame.LookVector
            )

    check(
        fallback_pos.Y > 0.25,
        "fallback ear must stay above head centre."
    )

    check(
        fallback_dir.X < -0.85
            and fallback_dir.Z > 0.25,
        "fallback ear must still point outward and backward."
    )
else
    check(
        false,
        "fallback left ear must exist."
    )
end


-- ==========================================================
-- NIL CLEARS
-- ==========================================================

RacePresentationService.apply(
    character,
    nil
)

check(
    character:FindFirstChild(
        RacePresentationService.ROOT_NAME
    ) == nil,
    "unresolved race must clear Elf visuals."
)


-- ==========================================================
-- MISSING HEAD
-- ==========================================================

head:Destroy()

local missing =
    RacePresentationService.apply(
        character,
        "Elf"
    )

check(
    missing.ok == false
        and missing.reason
            == "HeadNotFound",
    "missing Head must fail safely."
)


character:Destroy()


print(
    string.format(
        "[Race Presentation Service Tests] PASS: %d assertions.",
        assertions
    )
)