#version 140
in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in highp vec4 var_light;
out vec4 out_fragColor;
uniform sampler2D tex0;
uniform fs_uniforms { lowp vec4 tint; mediump vec4 finish; };
void main() {
 vec3 base=texture(tex0,var_texcoord0).rgb*tint.rgb;
 vec3 N=normalize(var_normal),L=normalize(var_light.xyz-var_position.xyz),V=normalize(-var_position.xyz);
 float lit=max(dot(N,L),0.0);
 float spec=pow(max(dot(N,normalize(L+V)),0.0),finish.x)*smoothstep(0.0,.15,lit);
 float rim=pow(1.0-max(dot(N,V),0.0),4.0);
 vec3 color=base*(.38+.68*lit)+vec3(1.0,.98,.94)*spec*finish.y;
 color+=vec3(.1,.16,.23)*rim*finish.z;
 // Starlight's pale painted stars retain visibility in shadow; no bloom dependency.
 float star=smoothstep(.67,.91,min(base.g,base.b));
 color=mix(color,max(color,base*.83),star*finish.w);
 out_fragColor=vec4(color,tint.a);
}
