--!strict
local SkillProgressionConfig=require(script.Parent:WaitForChild("SkillProgressionConfig"))
local LoadoutSnapshot={}

-- RemoteEvents truncate sparse numeric arrays at gaps. Keep the wire array dense;
-- persisted/server loadouts still use nil, and clients render false as an empty slot.
function LoadoutSnapshot.encode(loadout:any):{any}
    local slots:{any}={}
    for slot=1,SkillProgressionConfig.MAX_ACTIVE_SLOTS do
        local id=if type(loadout)=="table" then loadout[slot] else nil
        slots[slot]=if type(id)=="string" and id~="" then id else false
    end
    return slots
end
return table.freeze(LoadoutSnapshot)
