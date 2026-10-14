-- Cosmetic only. Never use these values for gameplay or global math.random.
local M = {}
local families = {
    {name="Ember veil", color={.31,.115,.065}, edge={.39,.23,.13}, threshold=.25},
    {name="Blue cirrus", color={.075,.14,.25}, edge={.19,.29,.39}, threshold=.29},
    {name="Amber shoals", color={.22,.16,.075}, edge={.34,.29,.19}, threshold=.29},
    {name="Violet rift", color={.13,.085,.22}, edge={.25,.18,.32}, threshold=.30},
    {name="Quiet reach", color={.055,.075,.105}, edge={.11,.14,.17}, threshold=.43},
}
function M.seed(id)
    local n=7919
    for i=1,#id do n=(n*131+string.byte(id,i))%2147483647 end
    return n
end
function M.get(id)
    id=type(id)=="string" and id or "sol"
    local seed=M.seed(id); local n=seed
    local function rand() n=n*48271%2147483647; return n/2147483647 end
    local f=families[seed%#families+1]
    local yaw=rand()*math.pi*2;local pitch=(rand()-.5)*1.6
    local mix=rand()*.75;local threshold=f.threshold+(rand()-.5)*.08
    local c,e=f.color,f.edge;local name=f.name
    if id=="sol" then
        name="Sol / Golden wake";c={.24,.16,.095};e={.35,.34,.29};threshold=.24;mix=.14;yaw=.4;pitch=-.32
    elseif id=="polaris" then
        name="Polaris / Crown rift";c={.085,.10,.25};e={.19,.31,.43};threshold=.28;mix=.60;yaw=2.3;pitch=.55
    end
    local angle=rand()*math.pi*2;local elevation=.2+rand()*.5
    if id=="sol" then angle=-.4;elevation=.32 elseif id=="polaris" then angle=.5;elevation=.45 end
    local sun={math.sin(angle)*math.cos(elevation),math.sin(elevation),math.cos(angle)*math.cos(elevation)}
    return {id=id,seed=seed,name=name,color=c,edge=e,yaw=yaw,pitch=pitch,mix=mix,threshold=threshold,
        star_gain=.9+rand()*.3,exposure=1,light_direction=sun,light_color=e}
end
return M
