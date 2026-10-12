#version 140
in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in highp vec4 var_light;
out vec4 out_fragColor;
uniform sampler2D tex0;
uniform fs_uniforms { lowp vec4 tint; };
void main() {
    vec3 base = texture(tex0, var_texcoord0).rgb * tint.rgb;
    vec3 N = normalize(var_normal);
    vec3 L = normalize(var_light.xyz - var_position.xyz);
    vec3 V = normalize(-var_position.xyz);
    vec3 H = normalize(L + V);
    float diffuse = max(dot(N,L),0.0);
    float specular = pow(max(dot(N,H),0.0),64.0) * smoothstep(0.0,.15,diffuse);
    float rim = pow(1.0-max(dot(N,V),0.0),4.0);
    // Restrained metal response; existing tex0, tint and light contracts retained.
    vec3 color = base*(.30+.76*diffuse) + mix(vec3(.36),base,.35)*specular*.65;
    color += vec3(.09,.16,.19)*rim*.24;
    float emitter = step(.64,base.g)*step(.64,base.b)*(1.0-step(.40,base.r));
    color = mix(color,max(color,base*.85),emitter);
    out_fragColor = vec4(color,tint.a);
}
