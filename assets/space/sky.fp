#version 140
in highp vec3 direction;
out vec4 frag_color;
uniform samplerCube fields;
uniform fs_uniforms {
    mediump vec4 cloud_color;
    mediump vec4 edge_color;
    highp vec4 rotation;
    mediump vec4 structure;
    highp vec4 sun_direction;
};
vec3 rotate_q(vec3 v, vec4 q) { return v + 2.0*cross(q.xyz,cross(q.xyz,v)+q.w*v); }
void main() {
    vec3 world = normalize(direction);
    vec3 d = rotate_q(world,rotation);
    vec3 a = texture(fields,d).rgb;
    vec3 b = texture(fields,vec3(d.z,-d.x,-d.y)).rgb;
    float gas = mix(a.r,b.r,structure.y);
    float dust = mix(a.g,b.g,structure.y*.5);
    float cloud = smoothstep(structure.x,structure.x+.43,gas);
    float extinction = smoothstep(.35,.70,dust);
    float body = cloud * (1.0-.88*extinction);
    float filament = pow(max(gas-dust*.63,0.0),2.0)*cloud;
    vec3 color = vec3(.003,.004,.008) + cloud_color.rgb*body + edge_color.rgb*filament;
    // Broad asymmetric landmark, always anchored to a WORLD direction.
    float stellar = max(dot(world,sun_direction.xyz),0.0);
    float halo = pow(stellar,180.0)*.065 + pow(stellar,1800.0)*.23;
    float core = smoothstep(.999985,.999999,stellar)*.85;
    color += edge_color.rgb*halo + vec3(1.0,.95,.86)*core*sun_direction.w;
    float temperature = clamp(a.g*1.6,0.0,1.0);
    vec3 star_color = mix(vec3(.73,.83,1.0),vec3(1.0,.81,.61),temperature);
    float stars = pow(a.b,1.65)*1.65 + a.b*.08;
    color += star_color * stars * structure.z * (1.0-.5*extinction*cloud);
    // A tiny spatial dither removes final grading bands; no temporal noise.
    float dither = fract(dot(gl_FragCoord.xy,vec2(.754877666,.569840296)))-.5;
    frag_color = vec4(clamp(color*structure.w+dither/255.0,0.0,1.0),1.0);
}
