--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local ReviveConfig=require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("Shared"):WaitForChild("ReviveConfig"))
local DungeonDeathService=require(ServerScriptService:WaitForChild("Dungeon"):WaitForChild("DungeonDeathService"))
local assertions=0
local function check(v:boolean,m:string) assertions+=1 if not v then error("[Automatic Free Revive Tests] "..m,2) end end
check(ReviveConfig.FREE_REVIVE_DELAY_SECONDS==3,"automatic free revive delay must be exactly three seconds.")
local session={SessionId="auto-revive",State="Active",Members={["801"]={UserId=801,Connected=true,Mode="Active",FreeReviveUsed=false,PaidReviveCount=0}}}
local sessions:any={}
function sessions:get(_id:string) return session end
function sessions:set_member_mode(_id:string,user_id:number,mode:string) session.Members[tostring(user_id)].Mode=mode return {ok=true,session=session} end
function sessions:consume_free_revive(_id:string,user_id:number)
    local m=session.Members[tostring(user_id)]
    if m.FreeReviveUsed then return {ok=false,reason="FreeReviveAlreadyUsed",session=session} end
    if m.Mode~="Dead" and m.Mode~="Spectating" then return {ok=false,reason="MemberNotDead",session=session} end
    m.FreeReviveUsed=true; m.Mode="Reviving"; session.WipeDecisionEndsAt=nil
    return {ok=true,session=session}
end
function sessions:set_wipe_deadline(_id:string,deadline:number?) session.WipeDecisionEndsAt=deadline return {ok=true,session=session} end
function sessions:mark_failed(_id:string,_reason:string) session.State="Failed" return {ok=true,session=session} end
local checkpoint={get_active_checkpoint=function() return {Id="Room2Start",CFrame=CFrame.new(5,3,-112)} end}
local scheduled_delay:number?=nil; local scheduled_callback:(()->())?=nil
local spawn_count=0
local service=DungeonDeathService.new(sessions,checkpoint,"auto-revive",{
    schedule=function(delay:number,callback:()->()) scheduled_delay=delay; scheduled_callback=callback end,
    spawn_player=function(_player:any,_cframe:CFrame) spawn_count+=1 return true end,
    paid_offer_provider=function() return {price=9,paid_number=1} end,
})
local player:any={UserId=801,Name="Auto"}
local died=service:on_player_died(player,CFrame.new())
check(died.ok==true,"first death must be accepted.")
check(session.Members["801"].FreeReviveUsed==true,"first death must consume the free revive immediately.")
check(session.Members["801"].Mode=="Reviving","first death must enter forced Reviving mode.")
check(scheduled_delay==3 and spawn_count==0 and scheduled_callback~=nil,"respawn must be scheduled for exactly three seconds later.")
local automatic_callback = scheduled_callback
if not automatic_callback then
    error("[Automatic Free Revive Tests] Automatic callback was not scheduled.")
end
automatic_callback()
check(spawn_count==1 and session.Members["801"].Mode=="Active","scheduled callback must respawn once and restore Active mode.")
local stale=service:request_free_revive(player)
check(stale.ok==false and stale.reason=="AutomaticFreeRevive","stale manual free-revive requests must never grant a second revive.")

-- A player who disconnects during the forced countdown must not be spawned into a server they left.
session={SessionId="auto-revive-disconnect",State="Active",Members={["802"]={UserId=802,Connected=true,Mode="Active",FreeReviveUsed=false,PaidReviveCount=0}}}
scheduled_delay=nil; scheduled_callback=nil; spawn_count=0
local disconnected_service=DungeonDeathService.new(sessions,checkpoint,"auto-revive-disconnect",{
    schedule=function(delay:number,callback:()->()) scheduled_delay=delay; scheduled_callback=callback end,
    spawn_player=function(_player:any,_cframe:CFrame) spawn_count+=1 return true end,
    paid_offer_provider=function() return {price=9,paid_number=1} end,
})
local disconnected_player:any={UserId=802,Name="DisconnectedAuto"}
check(disconnected_service:on_player_died(disconnected_player,CFrame.new()).ok==true,"disconnect test first death must enter automatic revive.")
session.Members["802"].Connected=false
local disconnected_callback=scheduled_callback
if not disconnected_callback then error("[Automatic Free Revive Tests] Disconnect callback was not scheduled.") end
disconnected_callback()
check(spawn_count==0,"automatic revive callback must not spawn a player who disconnected during the countdown.")
check(session.Members["802"].Mode=="Active" and session.Members["802"].FreeReviveUsed==true,"disconnected countdown completion must preserve the consumed revive and leave the session recoverable as Active.")
print(string.format("[Automatic Free Revive Tests] PASS: %d assertions.",assertions))
