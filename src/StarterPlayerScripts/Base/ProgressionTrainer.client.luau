--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Core"):WaitForChild("Remotes")
local progression_snapshot=remotes:WaitForChild("ProgressionSnapshot") :: RemoteEvent
local action_result=remotes:WaitForChild("ProgressionActionResult") :: RemoteEvent
local attribute_commit=remotes:WaitForChild("AttributeCommitRequest") :: RemoteEvent
local skill_learn=remotes:WaitForChild("SkillLearnRequest") :: RemoteEvent
local skill_rank=remotes:WaitForChild("SkillRankRequest") :: RemoteEvent
local attribute_respec=remotes:WaitForChild("AttributeRespecRequest") :: RemoteEvent
local skill_respec=remotes:WaitForChild("SkillRespecRequest") :: RemoteEvent
local ProgressionClientState=require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ProgressionClientState"))
local ProgressionTrainerRules=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ProgressionTrainerRules"))

local gui=Instance.new("ScreenGui")
gui.Name="ProgressionTrainerUi"; gui.ResetOnSpawn=false; gui.DisplayOrder=180; gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5); panel.Size=UDim2.fromOffset(700,560); panel.BackgroundColor3=Color3.fromRGB(24,26,32); panel.BackgroundTransparency=0.04; panel.Visible=false; panel.Parent=gui
local title=Instance.new("TextLabel")
title.Position=UDim2.fromOffset(18,10); title.Size=UDim2.fromOffset(580,42); title.BackgroundTransparency=1; title.TextColor3=Color3.fromRGB(245,245,245); title.TextXAlignment=Enum.TextXAlignment.Left; title.TextScaled=true; title.Text="Progression Trainer"; title.Parent=panel
local close=Instance.new("TextButton")
close.Position=UDim2.fromOffset(636,10); close.Size=UDim2.fromOffset(46,40); close.Text="X"; close.Parent=panel
local summary=Instance.new("TextLabel")
summary.Position=UDim2.fromOffset(18,58); summary.Size=UDim2.fromOffset(664,32); summary.BackgroundTransparency=1; summary.TextColor3=Color3.fromRGB(220,220,220); summary.TextXAlignment=Enum.TextXAlignment.Left; summary.Text="Level 1 | AP 0 | SP 0"; summary.Parent=panel
local status=Instance.new("TextLabel")
status.Position=UDim2.fromOffset(18,516); status.Size=UDim2.fromOffset(664,30); status.BackgroundTransparency=1; status.TextColor3=Color3.fromRGB(220,220,220); status.TextXAlignment=Enum.TextXAlignment.Left; status.Text="Phase 2B trainer • respecs are Free (TEST)"; status.Parent=panel

local attr_names={"Strength","Dexterity","Vitality","Intellect","Spirit"}
local attr_labels:{[string]:TextLabel}={}
local plus_buttons:{[string]:TextButton}={}
for i,name in ipairs(attr_names) do
    local label=Instance.new("TextLabel")
    label.Position=UDim2.fromOffset(18,100+(i-1)*48); label.Size=UDim2.fromOffset(210,38); label.BackgroundTransparency=0.25; label.TextXAlignment=Enum.TextXAlignment.Left; label.Text="  "..name..": 5"; label.Parent=panel; attr_labels[name]=label
    local plus=Instance.new("TextButton")
    plus.Position=UDim2.fromOffset(234,100+(i-1)*48); plus.Size=UDim2.fromOffset(44,38); plus.Text="+"; plus.Parent=panel; plus_buttons[name]=plus
end
local confirm=Instance.new("TextButton")
confirm.Position=UDim2.fromOffset(18,348); confirm.Size=UDim2.fromOffset(124,40); confirm.Text="Confirm"; confirm.Parent=panel
local cancel=Instance.new("TextButton")
cancel.Position=UDim2.fromOffset(150,348); cancel.Size=UDim2.fromOffset(128,40); cancel.Text="Cancel"; cancel.Parent=panel
local attr_respec_button=Instance.new("TextButton")
attr_respec_button.Position=UDim2.fromOffset(18,398); attr_respec_button.Size=UDim2.fromOffset(260,42); attr_respec_button.Text="Attribute Respec • Free (TEST)"; attr_respec_button.Parent=panel

local skill_ids={"Mend","ShieldBash","ArcSlash"}
local skill_labels:{[string]:TextLabel}={}; local skill_buttons:{[string]:TextButton}={}
for i,id in ipairs(skill_ids) do
    local y=100+(i-1)*92
    local label=Instance.new("TextLabel")
    label.Position=UDim2.fromOffset(310,y); label.Size=UDim2.fromOffset(372,54); label.BackgroundTransparency=0.2; label.TextWrapped=true; label.TextXAlignment=Enum.TextXAlignment.Left; label.Text="  "..id; label.Parent=panel; skill_labels[id]=label
    local button=Instance.new("TextButton")
    button.Position=UDim2.fromOffset(310,y+58); button.Size=UDim2.fromOffset(372,30); button.Text="Unavailable"; button.Parent=panel; skill_buttons[id]=button
end
local skill_respec_button=Instance.new("TextButton")
skill_respec_button.Position=UDim2.fromOffset(310,398); skill_respec_button.Size=UDim2.fromOffset(372,42); skill_respec_button.Text="Skill/SP Respec • Free (TEST)"; skill_respec_button.Parent=panel

local latest:any={}; local preview:any={}
local function reset_preview(snapshot:any?)
    if snapshot~=nil then latest=snapshot or {} end
    preview=ProgressionTrainerRules.create_attribute_preview(latest)
end
local function render(snapshot:any)
    latest=snapshot or {}; if next(preview)==nil then reset_preview() end
    summary.Text=string.format("Level %d | AP %d | SP %d",tonumber(latest.Level) or 1,tonumber(latest.APAvailable) or 0,tonumber(latest.SPAvailable) or 0)
    for _,name in ipairs(attr_names) do attr_labels[name].Text=string.format("  %s: %d",name,tonumber(preview[name]) or 5) end
    local skills=if type(latest.Skills)=="table" then latest.Skills else {}
    for _,id in ipairs(skill_ids) do
        local state=skills[id] or {}
        local rank=tonumber(state.Rank) or 0; local max_rank=tonumber(state.MaxRank) or 3; local prof=tonumber(state.Proficiency) or 0; local threshold=tonumber(state.NextThreshold); local cost=tonumber(state.NextCost)
        local req=if threshold then string.format("%d/%d proficiency",math.floor(prof),math.floor(threshold)) else "no proficiency gate"
        local weapon=""; if type(state.WeaponTags)=="table" and #state.WeaponTags>0 then weapon=" • requires "..table.concat(state.WeaponTags,",") end
        skill_labels[id].Text=string.format("  %s • Rank %d/%d\n  %s%s",id,rank,max_rank,req,weapon)
        local button=skill_buttons[id]
        if id=="ArcSlash" and state.Known~=true then
            button.Text=if state.BookOwned==true then "Learn Arc Slash • 3 SP + Book" else "Arc Slash Book required"
            button.Active=state.BookOwned==true and (tonumber(latest.SPAvailable) or 0)>=3
        elseif rank<max_rank then
            local eligible=threshold==nil or prof>=threshold
            button.Text=string.format("Purchase Rank %d • %d SP",rank+1,cost or 0)
            button.Active=eligible and (tonumber(latest.SPAvailable) or 0)>=(cost or 0)
        else
            button.Text="Max Rank"
            button.Active=false
        end
        button.AutoButtonColor=button.Active
    end
end
for name,button in pairs(plus_buttons) do button.Activated:Connect(function()
    if not ProgressionTrainerRules.can_add_attribute_point(latest,preview) then status.Text="No more Attribute Points available in this preview."; return end
    preview[name]=(tonumber(preview[name]) or 5)+1; render(latest)
end) end
confirm.Activated:Connect(function() status.Text="Saving attributes..."; attribute_commit:FireServer(preview) end)
cancel.Activated:Connect(function() reset_preview(); render(latest); status.Text="Attribute preview cancelled." end)
attr_respec_button.Activated:Connect(function() attribute_respec:FireServer() end)
skill_respec_button.Activated:Connect(function() skill_respec:FireServer() end)
for id,button in pairs(skill_buttons) do button.Activated:Connect(function()
    local state=latest.Skills and latest.Skills[id]
    if not state then return end
    if id=="ArcSlash" and state.Known~=true then skill_learn:FireServer(id) else skill_rank:FireServer(id) end
end) end
close.Activated:Connect(function() panel.Visible=false end)
ProgressionClientState.subscribe(function(snapshot) reset_preview(snapshot); render(latest) end)
action_result.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" then return end
    if payload.action=="Loadout" then return end
    status.Text=if payload.ok==true then tostring(payload.action).." complete." else tostring(payload.action).." blocked: "..tostring(payload.reason or "Unknown")
end)

task.spawn(function()
    local root=Workspace:WaitForChild("BasePrototype",15); if not root then return end
    local trainer=root:WaitForChild("ProgressionTrainer",10); if not trainer then return end
    local prompt=trainer:WaitForChild("ProgressionTrainerPrompt",5)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Triggered:Connect(function()
            panel.Visible=true; reset_preview(ProgressionClientState.get_snapshot()); render(latest); progression_snapshot:FireServer("Request")
        end)
    end
end)
