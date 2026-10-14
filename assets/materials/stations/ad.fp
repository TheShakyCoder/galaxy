#version 140
in mediump vec2 var_texcoord0;
out vec4 out_fragColor;
uniform sampler2D tex0;
void main() { out_fragColor=vec4(texture(tex0,var_texcoord0).rgb,1.0); }
