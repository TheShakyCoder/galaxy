-- Callers own externally created textures and must retain them while bound.
-- Bundled resources are retained by stations.script's resource properties.
local M={}
local stations={}
local textures={}
function M.register(station,urls,resources)
    assert(type(station)=="string" and #urls==8,"station requires eight ad slots")
    assert(not stations[station],"station already registered")
    stations[station]=urls
    for name,value in pairs(resources) do textures[name]=value end
end
function M.unregister(station) stations[station]=nil end
function M.set_ad(station,slot,texture)
    local urls=stations[station]
    if not urls then return false,"unknown station" end
    if type(slot)~="number" or slot%1~=0 or slot<1 or slot>8 then return false,"slot must be 1..8" end
    local resource_id=type(texture)=="string" and textures[texture] or texture
    if type(resource_id)~="userdata" then return false,"unknown texture" end
    go.set(urls[slot],"texture0",resource_id)
    return true
end
-- Future visibility instrumentation belongs at the caller after testing screen
-- projection, occlusion and dwell time. Registration/rotation is not an impression.
return M
