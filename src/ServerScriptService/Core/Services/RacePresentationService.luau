--!strict

local RacePresentationService = {}

RacePresentationService.ROOT_NAME =
    "DungeonMMORaceVisuals"

RacePresentationService.ELF_LEFT_NAME =
    "ElfEarLeft"

RacePresentationService.ELF_RIGHT_NAME =
    "ElfEarRight"


local function clear_existing(
    character: Model
)
    local existing =
        character:FindFirstChild(
            RacePresentationService.ROOT_NAME
        )

    if existing then
        existing:Destroy()
    end
end


local function attachment_y(
    head: BasePart,
    name: string
): number?
    local attachment =
        head:FindFirstChild(name)

    if (
        attachment
        and attachment:IsA("Attachment")
    ) then
        return attachment.Position.Y
    end

    return nil
end


local function get_ear_height(
    head: BasePart
): number
    local face_y =
        attachment_y(
            head,
            "FaceCenterAttachment"
        )

    local hair_y =
        attachment_y(
            head,
            "HairAttachment"
        )

    local hat_y =
        attachment_y(
            head,
            "HatAttachment"
        )

    local upper_y =
        hair_y
        or hat_y

    if (
        face_y ~= nil
        and upper_y ~= nil
    ) then
        return face_y
            + (
                upper_y - face_y
            ) * 0.72
    end

    if upper_y ~= nil then
        return upper_y
            - head.Size.Y * 0.15
    end

    if face_y ~= nil then
        return face_y
            + head.Size.Y * 0.40
    end

    return head.Size.Y * 0.42
end


local function blend_color(
    from: Color3,
    toward: Color3,
    amount: number
): Color3
    return Color3.new(
        from.R
            + (
                toward.R - from.R
            ) * amount,

        from.G
            + (
                toward.G - from.G
            ) * amount,

        from.B
            + (
                toward.B - from.B
            ) * amount
    )
end


local function get_ear_direction(
    side: number
): Vector3
    -- Delicate Lineage-style sweep:
    --
    -- strong outward component
    -- modest backward component
    -- only a tiny upward component
    --
    -- Approximately:
    -- 21 degrees backward
    -- 3 degrees upward
    return Vector3.new(
        side * 0.93,
        0.055,
        0.36
    ).Unit
end


local function frame_along_direction(
    direction: Vector3
): CFrame
    -- Local -Z points along the ear.
    local back_axis =
        -direction

    local right_axis =
        Vector3.yAxis:Cross(
            back_axis
        )

    if right_axis.Magnitude < 0.001 then
        right_axis =
            Vector3.xAxis
    else
        right_axis =
            right_axis.Unit
    end

    local up_axis =
        back_axis:Cross(
            right_axis
        ).Unit

    return CFrame.fromMatrix(
        Vector3.zero,
        right_axis,
        up_axis,
        back_axis
    )
end


local function configure_piece(
    piece: BasePart,
    color: Color3
)
    piece.Material =
        Enum.Material.SmoothPlastic

    piece.Color = color
    piece.Transparency = 0
    piece.Reflectance = 0

    piece.Anchored = false
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.Massless = true
    piece.CastShadow = false
end


local function weld_piece(
    head: BasePart,
    piece: BasePart,
    local_cframe: CFrame
)
    piece.CFrame =
        head.CFrame
        * local_cframe

    local weld =
        Instance.new("Weld")

    weld.Name =
        piece.Name .. "Weld"

    weld.Part0 = head
    weld.Part1 = piece

    weld.C0 =
        local_cframe

    weld.C1 =
        CFrame.identity

    weld.Parent = piece
end


local function create_ear(
    root: Folder,
    head: BasePart,
    main_name: string,
    side: number
)
    local skin_color =
        head.Color

    -- Deliberately subtle.
    --
    -- The Lineage reference has some warmth inside the ear,
    -- but the inner colour should not look painted bright red.
    local inner_color =
        blend_color(
            skin_color,
            Color3.fromRGB(
                170,
                92,
                96
            ),
            0.18
        )

    local direction =
        get_ear_direction(side)

    local orientation =
        frame_along_direction(
            direction
        )

    local ear_y =
        get_ear_height(head)

    -- --------------------------------------------------------
    -- OUTER EAR
    --
    -- One very slim tapered wedge.
    --
    -- No mirrored second outer wedge: that was responsible
    -- for the blade-like overlap/crossing appearance.
    -- --------------------------------------------------------

    local outer_length =
        1.35

    local root_local =
        Vector3.new(
            side * (
                head.Size.X * 0.5
                - 0.055
            ),
            ear_y - 0.08,
            0.015
        )

    local outer_center =
        root_local
        + direction
            * (
                outer_length * 0.48
            )

    local outer =
        Instance.new("WedgePart")

    outer.Name =
        main_name

    -- X = very thin depth
    -- Y = delicate base height
    -- Z = long taper toward tip
    outer.Size =
        Vector3.new(
            0.14,
            0.34,
            outer_length
        )

    configure_piece(
        outer,
        skin_color
    )

    outer.Parent = root

    local outer_frame =
        CFrame.new(
            outer_center
        )
        * orientation

    weld_piece(
        head,
        outer,
        outer_frame
    )


    -- --------------------------------------------------------
    -- INNER EAR
    --
    -- Small, narrow inset. It follows the same direction and
    -- does not affect the outer silhouette.
    -- --------------------------------------------------------

    local inner_length =
        0.82

    local inner_center =
        root_local
        + direction
            * (
                inner_length * 0.48
            )

    local inner =
        Instance.new("WedgePart")

    inner.Name =
        main_name .. "Inner"

    inner.Size =
        Vector3.new(
            0.148,
            0.15,
            inner_length
        )

    configure_piece(
        inner,
        inner_color
    )

    inner.Parent = root

    -- Tiny forward-facing surface offset prevents z-fighting
    -- while keeping it visually recessed.
    local inner_frame =
        CFrame.new(
            inner_center
        )
        * orientation
        * CFrame.new(
            0,
            -0.018,
            -0.012
        )

    weld_piece(
        head,
        inner,
        inner_frame
    )
end


function RacePresentationService.apply(
    character: Model,
    race_id: string?
): any
    if (
        typeof(character) ~= "Instance"
        or not character:IsA("Model")
    ) then
        return {
            ok = false,
            reason = "InvalidCharacter",
        }
    end

    clear_existing(character)

    if race_id ~= "Elf" then
        return {
            ok = true,
            race_id = race_id,
            ear_count = 0,
        }
    end

    local head =
        character:FindFirstChild("Head")

    if (
        not head
        or not head:IsA("BasePart")
    ) then
        return {
            ok = false,
            reason = "HeadNotFound",
        }
    end

    local root =
        Instance.new("Folder")

    root.Name =
        RacePresentationService.ROOT_NAME

    root.Parent = character

    create_ear(
        root,
        head,
        RacePresentationService.ELF_LEFT_NAME,
        -1
    )

    create_ear(
        root,
        head,
        RacePresentationService.ELF_RIGHT_NAME,
        1
    )

    local left =
        root:FindFirstChild(
            RacePresentationService.ELF_LEFT_NAME
        )

    local right =
        root:FindFirstChild(
            RacePresentationService.ELF_RIGHT_NAME
        )

    if (
        left
        and left:IsA("BasePart")
        and right
        and right:IsA("BasePart")
    ) then
        local left_position =
            head.CFrame
                :PointToObjectSpace(
                    left.Position
                )

        local right_position =
            head.CFrame
                :PointToObjectSpace(
                    right.Position
                )

        local left_direction =
            head.CFrame
                :VectorToObjectSpace(
                    left.CFrame.LookVector
                )

        local right_direction =
            head.CFrame
                :VectorToObjectSpace(
                    right.CFrame.LookVector
                )

        print(
            string.format(
                "[Race Presentation] Delicate Elf ears applied to %s. LeftPos=(%.2f, %.2f, %.2f) RightPos=(%.2f, %.2f, %.2f) LeftDir=(%.2f, %.2f, %.2f) RightDir=(%.2f, %.2f, %.2f)",
                character.Name,
                left_position.X,
                left_position.Y,
                left_position.Z,
                right_position.X,
                right_position.Y,
                right_position.Z,
                left_direction.X,
                left_direction.Y,
                left_direction.Z,
                right_direction.X,
                right_direction.Y,
                right_direction.Z
            )
        )
    end

    return {
        ok = true,
        race_id = "Elf",
        ear_count = 2,
    }
end


return table.freeze(
    RacePresentationService
)