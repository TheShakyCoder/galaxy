local profiles=require "main.space_profiles"
local M={}
function M.create()
    return {predicate=render.predicate({"space_sky"}),wisps=render.predicate({"space_wisp"}),visible=false,constants=render.constant_buffer()}
end
function M.configure(state,message)
    state.visible=message.visible==true
    if not state.visible then return end
    local p=profiles.get(message.system_id)
    local c=state.constants
    c.cloud_color=vmath.vector4(p.color[1],p.color[2],p.color[3],1)
    c.edge_color=vmath.vector4(p.edge[1],p.edge[2],p.edge[3],1)
    local q=vmath.quat_rotation_y(p.yaw)*vmath.quat_rotation_x(p.pitch)
    c.rotation=vmath.vector4(q.x,q.y,q.z,q.w)
    c.structure=vmath.vector4(p.threshold,p.mix,p.star_gain,p.exposure)
    c.sun_direction=vmath.vector4(p.light_direction[1],p.light_direction[2],p.light_direction[3],1)
end
function M.draw(state)
    if not state.visible then return end
    local cameras=camera.get_cameras()
    local active
    for i=#cameras,1,-1 do
        if camera.get_enabled(cameras[i]) then active=cameras[i];break end
    end
    if not active then return end
    -- Explicit matrices avoid camera frustum culling of our origin-centred cube.
    render.set_camera()
    render.set_viewport(0,0,render.get_window_width(),render.get_window_height())
    render.set_view(camera.get_view(active))
    render.set_projection(camera.get_projection(active))
    render.disable_state(graphics.STATE_DEPTH_TEST)
    render.disable_state(graphics.STATE_CULL_FACE)
    render.disable_state(graphics.STATE_BLEND)
    render.set_depth_mask(false)
    render.draw(state.predicate,{constants=state.constants})
    render.set_depth_mask(true)
    -- The caller installs the world camera and states immediately afterwards.
end
function M.draw_wisps(state,options)
    if state.visible then render.draw(state.wisps,options) end
end
return M
