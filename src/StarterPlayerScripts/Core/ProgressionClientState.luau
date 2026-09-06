--!strict
local ProgressionClientState = {}
local snapshot:any = nil
local listeners:{(any)->()} = {}

local function deep_clone(value:any):any
    if type(value)~="table" then return value end
    local out={}
    for key,child in pairs(value) do out[key]=deep_clone(child) end
    return out
end

function ProgressionClientState.apply_snapshot(payload:any)
    if type(payload)~="table" then return end
    snapshot=deep_clone(payload)
    for _,listener in ipairs(listeners) do task.defer(listener,deep_clone(snapshot)) end
end
function ProgressionClientState.get_snapshot():any return deep_clone(snapshot or {}) end
function ProgressionClientState.get_skill_for_slot(slot:number):string?
    local loadout=snapshot and snapshot.Loadout
    local value=if type(loadout)=="table" then loadout[slot] else nil
    return if type(value)=="string" and value~="" then value else nil
end
function ProgressionClientState.subscribe(listener:(any)->()):()->()
    table.insert(listeners,listener)
    local active=true
    return function()
        if not active then return end
        active=false
        local index=table.find(listeners,listener)
        if index then table.remove(listeners,index) end
    end
end
return table.freeze(ProgressionClientState)
