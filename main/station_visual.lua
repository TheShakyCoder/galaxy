local ads=require "main.station_ads"
local assignments=require "main.data.station_ads"
local outposts=require "main.data.outposts"
-- Rotor turn times come from each faction's skin in main/data/outposts.lua.
local M={PERIOD={}}
for _,f in ipairs(outposts.FACTIONS) do M.PERIOD[f]=outposts.skin(f).rotor_period_sec end
function M.create(faction,resources,prefix)
    prefix=prefix or faction.."_outpost"
    local s={faction=faction,prefix=prefix,phase=0,clock=0,speed=1,visible=nil,components={prefix.."#model",prefix.."_rotor#model"},ad_urls={}}
    for i=1,outposts.stat("ad_panels") do local url=prefix.."_ad"..i.."#model";s.ad_urls[i]=url;table.insert(s.components,url) end
    ads.register(prefix,s.ad_urls,resources)
    for i,name in ipairs(assignments[faction]) do assert(ads.set_ad(prefix,i,name)) end
    for i=1,2 do go.set(s.components[i],"light",vmath.vector4(4000,6000,4000,1)) end
    return s
end
function M.update(s,dt,visible)
    if s.visible~=visible then
        s.visible=visible
        for _,url in ipairs(s.components) do msg.post(url,visible and "enable" or "disable") end
    end
    if visible then
        s.clock=(s.clock+dt)%120
        for i=1,2 do go.set(s.components[i],"beacon_clock",vmath.vector4(s.clock,0,0,0)) end
        s.phase=(s.phase+dt*s.speed*math.pi*2/M.PERIOD[s.faction])%(math.pi*2)
        go.set_rotation(vmath.quat_rotation_z(s.phase),s.prefix.."_rotor")
    end
end
function M.light(s,position)
    for i=1,2 do go.set(s.components[i],"light",position) end
end
function M.final(s) ads.unregister(s.prefix) end
return M
