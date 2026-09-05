--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttributeConfig = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("AttributeConfig"))
local ProfileSchema = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProfileSchema"))
local ProgressionRuntimeState = {}
local states:{[number]:any} = {}
local function default_progression():any return ProfileSchema.create_default(0).Characters.Slot1.Progression end
function ProgressionRuntimeState.set_character(user_id:number, character_or_progression:any)
    local p=if type(character_or_progression)=="table" and type(character_or_progression.Progression)=="table" then character_or_progression.Progression else character_or_progression
    states[user_id]=ProfileSchema.deep_clone(if type(p)=="table" then p else default_progression())
end
function ProgressionRuntimeState.clear_character(user_id:number) states[user_id]=nil end
function ProgressionRuntimeState.get_snapshot(user_id:number):any return ProfileSchema.deep_clone(states[user_id] or default_progression()) end
function ProgressionRuntimeState.get_attribute(user_id:number,name:string):number
    local p=states[user_id]; local v=p and p.Attributes and p.Attributes[name]
    return if type(v)=="number" then v else AttributeConfig.BASE_VALUE
end
function ProgressionRuntimeState.get_physical_multiplier(user_id:number):number return AttributeConfig.physical_multiplier(ProgressionRuntimeState.get_attribute(user_id,"Strength")) end
function ProgressionRuntimeState.get_heal_multiplier(user_id:number):number return AttributeConfig.heal_multiplier(ProgressionRuntimeState.get_attribute(user_id,"Spirit")) end
function ProgressionRuntimeState.get_max_health(user_id:number):number return AttributeConfig.max_health(ProgressionRuntimeState.get_attribute(user_id,"Vitality")) end
function ProgressionRuntimeState.apply_max_health(player:Player)
    local character=player.Character; if not character then return end
    local humanoid=character:FindFirstChildOfClass("Humanoid"); if not humanoid then return end
    local previous_max=humanoid.MaxHealth
    local new_max=ProgressionRuntimeState.get_max_health(player.UserId)
    humanoid.MaxHealth=new_max
    if humanoid.Health>new_max then humanoid.Health=new_max
    elseif humanoid.Health>=previous_max-0.001 then humanoid.Health=new_max end
end
return table.freeze(ProgressionRuntimeState)
