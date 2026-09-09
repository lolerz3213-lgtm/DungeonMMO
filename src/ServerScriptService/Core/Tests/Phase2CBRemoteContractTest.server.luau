--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")

local expected = {
    "EquipmentSnapshot",
    "EquipmentEquipRequest",
    "EquipmentUnequipRequest",
    "EquipmentActionResult",
    "TrainerSnapshot",
    "TrainerSnapshotRequest",
}

local missing = {}
for _, name in ipairs(expected) do
    local remote = Remotes:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteEvent") then
        table.insert(missing, name)
    end
end

if #missing > 0 then
    error(
        "[Phase 2C.B Remote Contract Tests] RED: missing RemoteEvents: "
            .. table.concat(missing, ", ")
    )
end

print("[Phase 2C.B Remote Contract Tests] PASS: all equipment/trainer remotes exist.")
