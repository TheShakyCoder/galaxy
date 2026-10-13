-- Docked presentation only. No economy, persistence, networking or fitting writes.
local M = {}
local WHITE = vmath.vector4(1,1,1,1)
local INK = vmath.vector4(.82,.88,.89,1)
local CYAN = vmath.vector4(.38,.85,.92,1)
local GOLD = vmath.vector4(.80,.64,.36,1)
local PAGES = {"overview","fitting","ships","map","skins"}
local ICONS = {"command","fitting","hangar","map","livery"}
local LABELS = {"COMMAND","FITTING","HANGAR","SECTOR MAP","LIVERIES"}
local function node(id) return gui.get_node(id) end
local function at(n,x,y,w,h)
    gui.set_position(n,vmath.vector3(x,y,0))
    gui.set_pivot(n,gui.PIVOT_CENTER)
    if w then gui.set_size(n,vmath.vector3(w,h,0)) end
end
local function scale(n,s) gui.set_scale(n,vmath.vector3(s,s,1)) end
local function art(n,name,slice)
    gui.set_texture(n,"console")
    gui.set_size_mode(n,gui.SIZE_MODE_MANUAL)
    gui.play_flipbook(n,name)
    gui.set_color(n,WHITE)
    gui.set_slice9(n,vmath.vector4(slice or 0,slice or 0,slice or 0,slice or 0))
end
local function box(self,x,y,w,h,texture,overview)
    local n=gui.new_box_node(vmath.vector3(x,y,0),vmath.vector3(w,h,0))
    if texture then art(n,texture) end
    gui.move_below(n,node("ship_detail_scrim"))
    if overview then self.console_overview[#self.console_overview+1]=n end
    return n
end
local function text(self,x,y,value,s,overview)
    local n=gui.new_text_node(vmath.vector3(x,y,0),value)
    gui.set_font(n,"default_font")
    gui.set_color(n,INK)
    scale(n,s or 1)
    gui.move_below(n,node("ship_detail_scrim"))
    if overview then self.console_overview[#self.console_overview+1]=n end
    return n
end
local function bar(self,x,y,w,overview)
    local back=box(self,x,y,w,7,nil,overview)
    gui.set_color(back,vmath.vector4(.12,.20,.23,1))
    local fill=box(self,x-w/2,y,w,5,nil,overview)
    gui.set_pivot(fill,gui.PIVOT_W)
    gui.set_color(fill,CYAN)
    return fill
end
local function fit(n,value,width,height,max_scale)
    gui.set_text(n,value)
    gui.set_size(n,vmath.vector3(width/(max_scale or 1),height/(max_scale or 1),0))
    gui.set_line_break(n,true)
    local metrics=resource.get_text_metrics(gui.get_font_resource(gui.get_font(n)),value,{width=width/(max_scale or 1),line_break=true})
    scale(n,math.min(max_scale or 1,height/math.max(1,metrics.height)))
end

function M.init(self)
    self.console_overview={}
    self.console_nav={}
    self.console_rows={}
    local bg=node("background")
    gui.set_texture(bg,"hangars")
    gui.set_size_mode(bg,gui.SIZE_MODE_MANUAL)
    gui.play_flipbook(bg,"accord")
    gui.set_color(bg,WHITE)
    self.console_scrim=box(self,960,540,1920,1080,nil,false)
    gui.set_color(self.console_scrim,vmath.vector4(.005,.014,.025,.68))
    gui.move_above(self.console_scrim,bg)

    at(node("station_header"),960,1032,1912,88); art(node("station_header"),"panel",24)
    at(node("station_footer"),970,73,1420,132); art(node("station_footer"),"panel",24)
    gui.set_enabled(node("station_header_line"),false)
    gui.set_enabled(node("station_footer_line"),false)
    text(self,137,1030,"G A L A X Y",1.18)
    at(node("title"),370,1030,330,42); scale(node("title"),.90)
    gui.set_color(node("title"),INK)
    self.console_authority=text(self,728,1032,"ACCORD PORT AUTHORITY",.71)
    gui.set_color(self.console_authority,CYAN)
    local ids={"tope_label","water_label","iron_label","hydrogen_label"}
    for i,id in ipairs(ids) do
        at(node(id),996+(i-1)*163,1031,158,52); scale(node(id),.78); gui.set_color(node(id),INK)
    end
    at(node("launch_button"),1788,1032,222,68); art(node("launch_button"),"button_gold",20)
    at(node("launch_button_label"),1788,1032,210,40); scale(node("launch_button_label"),1)
    gui.set_text(node("launch_button_label"),"UNDOCK  >")
    at(node("launch_countdown"),1700,969,390,42); scale(node("launch_countdown"),.78)
    at(node("logout_button"),114,66,196,66); art(node("logout_button"),"button",20)
    at(node("logout_button_label"),114,66,190,40); scale(node("logout_button_label"),.86)
    for i,page in ipairs(PAGES) do
        local x=425+(i-1)*266
        local button=self.tab_nodes[page]
        at(button,x,74,258,112); art(button,"button",20)
        local label=node("tab_"..page.."_label")
        at(label,x,45,250,34); scale(label,.92); gui.set_text(label,LABELS[i])
        self.console_nav[page]=box(self,x,92,42,42,ICONS[i],false)
    end
    at(node("ship_overview"),960,954,1050,32); scale(node("ship_overview"),.77)
    gui.set_color(node("ship_overview"),INK)
    gui.set_enabled(node("ship_overview"),false)

    at(node("overview_panel"),182,554,324,804); art(node("overview_panel"),"panel",24)
    at(node("overview_heading"),182,918,300,42); scale(node("overview_heading"),.94)
    gui.move_above(node("overview_heading"),node("overview_panel"))
    at(node("overview_content"),182,559,290,600); scale(node("overview_content"),.92)
    at(node("overview_ship_panel"),960,213,530,108); art(node("overview_ship_panel"),"panel",24)
    at(node("overview_vessel"),960,213,580,104); scale(node("overview_vessel"),.82)
    at(node("overview_ship_heading"),960,157,700,30); scale(node("overview_ship_heading"),.66)
    gui.set_text(node("overview_ship_heading"),"ACTIVE VESSEL / BASE HULL PREVIEW")
    at(node("overview_readiness_panel"),1740,710,324,492); art(node("overview_readiness_panel"),"panel",24)
    at(node("overview_manifest_heading"),1740,918,296,42); scale(node("overview_manifest_heading"),.92)
    at(node("overview_readiness"),1740,512,284,58); scale(node("overview_readiness"),.64)
    at(node("overview_assignments_panel"),1740,302,324,296); art(node("overview_assignments_panel"),"panel",24)
    at(node("overview_assignments_heading"),1740,414,288,36); scale(node("overview_assignments_heading"),.90)
    at(node("overview_assignments"),1740,290,280,192)
    self.console_orbit=box(self,182,827,132,132,"orbital",true)
    self.console_xp=bar(self,182,720,252,true)
    self.console_pilot=text(self,182,660,"",1,true)
    self.console_home=text(self,182,361,"",.95,true)
    self.console_dock=text(self,182,254,"",.83,true)
    local names={"WEAPONS","COMPUTERS","ENGINES","HULL"}
    local icons={"weapon","computer","engine","hull"}
    for i=1,4 do
        local y=838-(i-1)*91
        box(self,1625,y-4,42,42,icons[i],true)
        local label=text(self,1744,y+10,names[i],.75,true)
        local value=text(self,1848,y+10,"0 / 0",.75,true)
        local progress=bar(self,1761,y-22,216,true)
        self.console_rows[i]={label=label,value=value,progress=progress}
    end
    -- The existing tabs retain their layout and interaction geometry.
    -- Replace their panel surfaces, keeping clipping/stencil nodes intact.
    for _,id in ipairs({"shop_panel","owned_panel","forsale_panel","skins_panel","map_panel","ship_stats_panel","ship_detail_panel","confirm_panel"}) do
        art(node(id),"panel",24)
    end
    for _,id in ipairs({"ship_detail_primary","ship_detail_cancel","ship_detail_sell","ship_detail_advance","confirm_yes","confirm_no"}) do art(node(id),"button",20) end
end

function M.page(self,page,faction)
    local swarm=faction=="swarm"
    gui.play_flipbook(node("background"),swarm and "swarm" or "accord")
    gui.set_text(self.console_authority,swarm and "SWARM DOCK CONTROL" or "ACCORD PORT AUTHORITY")
    gui.set_enabled(self.console_scrim,page~="overview")
    for _,n in ipairs(self.console_overview) do gui.set_enabled(n,page=="overview") end
    -- Structured dossier and gauges supersede the earlier dense text block.
    gui.set_enabled(node("overview_content"),false)
    for _,key in ipairs(PAGES) do
        art(self.tab_nodes[key],key==page and "button_active" or "button",20)
        gui.set_color(self.console_nav[key],key==page and CYAN or INK)
        gui.set_color(node("tab_"..key.."_label"),key==page and CYAN or INK)
    end
end

function M.refresh(self,data)
    local vessel=node("overview_vessel")
    fit(vessel,gui.get_text(vessel),490,86,.82)
    local dossier=string.format("%s\n\n%s\nLEVEL %s\n\n%s XP\nNext: %s",data.faction,data.rank,data.level,data.xp,data.next_xp)
    fit(self.console_pilot,dossier,276,235,.97)
    gui.set_text(self.console_home,"HOME PORT\n"..data.home)
    gui.set_text(self.console_dock,"DOCKED AT\n"..data.docked)
    gui.set_size(self.console_xp,vmath.vector3(252*math.min(1,math.max(0,data.xp_fraction)),5,0))
    for i,prefix in ipairs({"W","C","E","H"}) do
        local row=self.console_rows[i]
        local n=data.filled[prefix] or 0
        local total=data.components[prefix] or 0
        gui.set_text(row.value,n.." / "..total)
        gui.set_size(row.progress,vmath.vector3(total>0 and 216*math.min(1,n/total) or 0,5,0))
    end
    fit(node("overview_readiness"),data.summary,278,60,.69)
    fit(node("overview_assignments"),data.assignments,274,196,.78)
end

function M.card(n,color)
    art(n,"row",12)
    gui.set_color(n,vmath.vector4(.65+color.x,.65+color.y,.65+color.z,color.w))
end
return M
