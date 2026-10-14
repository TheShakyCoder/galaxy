#version 140
in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
out vec4 out_fragColor;
uniform sampler2D tex0;
uniform fs_uniforms { lowp vec4 tint; };
// View-space dock lighting, confined to the station preview override.
// The existing models, UVs and albedo are used without modification.
void main() {
    vec3 base=texture(tex0,var_texcoord0).rgb;
    vec3 N=normalize(var_normal);
    vec3 V=normalize(-var_position.xyz);
    vec3 key=normalize(vec3(-.55,.75,.85));
    vec3 fill=normalize(vec3(.85,.15,.35));
    vec3 top=normalize(vec3(.2,.95,-.3));
    float kd=max(dot(N,key),0.0);
    float fd=max(dot(N,fill),0.0);
    float td=max(dot(N,top),0.0);
    float spec=pow(max(dot(N,normalize(key+V)),0.0),72.0)*smoothstep(0.0,.15,kd);
    float broad=pow(max(dot(N,normalize(fill+V)),0.0),22.0);
    float fresnel=pow(1.0-max(dot(N,V),0.0),4.0);
    vec3 light=vec3(.14,.18,.23)+kd*vec3(1.02,.91,.75)+fd*vec3(.16,.27,.38);
    vec3 color=base*light;
    color+=mix(vec3(.65,.70,.73),base,.2)*spec*.80;
    color+=vec3(.15,.26,.34)*broad*.45;
    color+=vec3(.25,.40,.53)*fresnel*(.15+.55*td);
    // Existing painted cyan navigation lights remain visible without a bloom pass.
    float emitter=smoothstep(.52,.75,base.g)*smoothstep(.52,.75,base.b)*(1.0-smoothstep(.28,.48,base.r));
    color=mix(color,max(color,base),emitter);
    out_fragColor=vec4(color*tint.rgb,tint.a);
}
