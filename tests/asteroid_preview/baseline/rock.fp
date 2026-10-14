#version 140
in mediump vec3 var_normal;
in mediump vec4 var_color;
in highp vec3 var_rock_position;
in mediump float var_fade;
out vec4 frag_color;
uniform fs_uniforms { mediump vec4 tint; };
float grain(vec3 p) {
    return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);
}
float bayer2(vec2 p) { return 2.0*p.x+3.0*p.y-4.0*p.x*p.y; }
void main() {
    // Screen-door dissolution works in the existing opaque, depth-writing
    // model pass; no transparent sorting or global render changes required.
    vec2 pixel = floor(gl_FragCoord.xy);
    float threshold = (4.0*bayer2(mod(pixel,2.0))+bayer2(mod(floor(pixel/2.0),2.0))+0.5)/16.0;
    if (var_fade <= threshold) discard;
    vec3 n = normalize(var_normal);
    float key = max(dot(n,normalize(vec3(-0.5,0.7,1.0))),0.0);
    float fill = max(dot(n,normalize(vec3(0.8,-0.3,0.2))),0.0);
    float detail = 0.88+0.24*grain(floor(var_rock_position*190.0));
    vec3 light = vec3(0.30)+vec3(0.87,0.83,0.77)*key+vec3(0.15,0.19,0.25)*fill;
    frag_color = vec4(var_color.rgb*detail*light*tint.rgb,1.0);
}
