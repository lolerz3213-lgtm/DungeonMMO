--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local progression_snapshot=remotes:WaitForChild("ProgressionSnapshot") :: RemoteEvent
local loadout_request=remotes:WaitForChild("LoadoutRequest") :: RemoteEvent
local action_result=remotes:WaitForChild("ProgressionActionResult") :: RemoteEvent
local ProgressionClientState=require(script.Parent:WaitForChild("ProgressionClientState"))

local gui=Instance.new("ScreenGui")
gui.Name="CharacterSkillsMenu"
gui.ResetOnSpawn=false
gui.DisplayOrder=165
gui.Parent=player:WaitForChild("PlayerGui")
local open=Instance.new("TextButton")
open.Name="OpenSkills"
open.Position=UDim2.fromOffset(344,16)
open.Size=UDim2.fromOffset(96,42)
open.Text="Skills"
open.TextScaled=true
open.Parent=gui
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.52)
panel.Size=UDim2.fromOffset(620,430)
panel.BackgroundColor3=Color3.fromRGB(24,26,32)
panel.BackgroundTransparency=0.06
panel.Visible=false
panel.Parent=gui
local title=Instance.new("TextLabel")
title.Position=UDim2.fromOffset(16,10); title.Size=UDim2.fromOffset(500,38); title.BackgroundTransparency=1; title.TextColor3=Color3.fromRGB(245,245,245); title.TextXAlignment=Enum.TextXAlignment.Left; title.TextScaled=true; title.Text="Character > Skills"; title.Parent=panel
local close=Instance.new("TextButton")
close.Position=UDim2.fromOffset(560,10); close.Size=UDim2.fromOffset(44,38); close.Text="X"; close.Parent=panel
local status=Instance.new("TextLabel")
status.Position=UDim2.fromOffset(16,52); status.Size=UDim2.fromOffset(588,34); status.BackgroundTransparency=1; status.TextColor3=Color3.fromRGB(215,215,215); status.TextXAlignment=Enum.TextXAlignment.Left; status.Text="Select a learned skill, then choose a slot."; status.Parent=panel

local skill_ids={"ShieldBash","Mend","ArcSlash","WindStrike","ArcaneWard","MageHeal"}
local skill_buttons:{[string]:TextButton}={}
for index,skill_id in ipairs(skill_ids) do
    local button=Instance.new("TextButton")
    button.Name=skill_id
    button.Position=UDim2.fromOffset(16,96+(index-1)*54)
    button.Size=UDim2.fromOffset(260,44)
    button.TextXAlignment=Enum.TextXAlignment.Left
    button.Text="  "..skill_id
    button.Parent=panel
    skill_buttons[skill_id]=button
end

local slot_buttons:{[number]:TextButton}={}
for slot=1,6 do
    local row=math.floor((slot-1)/2)
    local col=(slot-1)%2
    local button=Instance.new("TextButton")
    button.Name="SkillSlot"..slot
    button.Position=UDim2.fromOffset(310+col*145,96+row*70)
    button.Size=UDim2.fromOffset(132,58)
    button.Text="Slot "..slot.."\n(empty)"
    button.TextWrapped=true
    button.Parent=panel
    slot_buttons[slot]=button
end

local selected_skill:string?=nil
local latest:any={}
local function render(snapshot:any)
    latest=snapshot or {}
    local skills=if type(latest.Skills)=="table" then latest.Skills else {}
    local loadout=if type(latest.Loadout)=="table" then latest.Loadout else {}
    for _,skill_id in ipairs(skill_ids) do
        local state=skills[skill_id]
        local button=skill_buttons[skill_id]
        local known=type(state)=="table" and state.Known==true and (tonumber(state.Rank) or 0)>=1
        local suffix=if known then string.format("R%d",tonumber(state.Rank) or 0) else "Locked"
        local selected=selected_skill==skill_id
        if not known and selected then
            selected_skill=nil
            selected=false
        end
        button.Text=(if selected then "▶ " else "  ")..skill_id.."  •  "..suffix
        button.BackgroundTransparency=if selected then 0 else 0.2
        button.Active=known
        button.AutoButtonColor=known
    end
    for slot=1,6 do
        local id=loadout[slot]
        slot_buttons[slot].Text=string.format("Slot %d\n%s",slot,if type(id)=="string" then id else "(empty)")
    end
end

for skill_id,button in pairs(skill_buttons) do
    button.Activated:Connect(function()
        local state=type(latest.Skills)=="table" and latest.Skills[skill_id] or nil
        local known=type(state)=="table" and state.Known==true and (tonumber(state.Rank) or 0)>=1
        if not known then
            status.Text=skill_id.." is not learned yet."
            return
        end
        selected_skill=skill_id
        status.Text="Selected "..skill_id..". Click the destination slot."
        render(latest)
    end)
end
for slot,button in pairs(slot_buttons) do
    button.Activated:Connect(function()
        if not selected_skill then
            status.Text="Select a learned skill first, then click its destination slot."
            return
        end
        status.Text="Moving "..selected_skill.." to Slot "..tostring(slot).."..."
        loadout_request:FireServer(selected_skill,slot)
    end)
end

open.Activated:Connect(function()
    panel.Visible=not panel.Visible
    if panel.Visible then progression_snapshot:FireServer("Request") end
end)
close.Activated:Connect(function() panel.Visible=false end)
action_result.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" or payload.action~="Loadout" then return end
    if payload.ok==true then
        selected_skill=nil
        status.Text="Skill moved. Select another learned skill to place it."
        render(ProgressionClientState.get_snapshot())
    else
        status.Text="Loadout blocked: "..tostring(payload.reason or "Unknown")
    end
end)
ProgressionClientState.subscribe(render)
render(ProgressionClientState.get_snapshot())
task.defer(function() progression_snapshot:FireServer("Request") end)
