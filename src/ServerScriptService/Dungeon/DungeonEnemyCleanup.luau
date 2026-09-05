--!strict
-- Removes defeated dungeon enemies from presentation immediately, then destroys the model shortly after.
local DungeonEnemyCleanup = {}

local RETIRED_ATTRIBUTE = "DungeonEnemyRetired"
local DEFAULT_DESTROY_DELAY_SECONDS = 0.15

local function disable_visual_or_collision(instance: Instance)
    if instance:IsA("BasePart") then
        instance.Transparency = 1
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
    elseif instance:IsA("ParticleEmitter") then
        instance.Enabled = false
    elseif instance:IsA("Trail") then
        instance.Enabled = false
    elseif instance:IsA("Beam") then
        instance.Enabled = false
    elseif instance:IsA("BillboardGui") then
        instance.Enabled = false
    elseif instance:IsA("SurfaceGui") then
        instance.Enabled = false
    end
end

function DungeonEnemyCleanup.retire(model: Model, destroy_delay_seconds: number?): boolean
    if not model:IsA("Model") or model:GetAttribute(RETIRED_ATTRIBUTE) == true then
        return false
    end

    model:SetAttribute(RETIRED_ATTRIBUTE, true)
    for _, descendant in ipairs(model:GetDescendants()) do
        disable_visual_or_collision(descendant)
    end

    local delay_seconds = destroy_delay_seconds
    if type(delay_seconds) ~= "number" then
        delay_seconds = DEFAULT_DESTROY_DELAY_SECONDS
    end
    delay_seconds = math.max(0, delay_seconds)

    task.delay(delay_seconds, function()
        if model.Parent then
            model:Destroy()
        end
    end)

    return true
end

return table.freeze(DungeonEnemyCleanup)
