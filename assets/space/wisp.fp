#version 140
in mediump vec2 uv;
in mediump float visibility;
out vec4 frag_color;
void main() {
    float edge=max(1.0-dot(uv,uv),0.0);
    float fold=.6+.2*sin(uv.x*9.0+sin(uv.y*8.0))+.15*sin(uv.x*18.0-uv.y*13.0);
    float alpha=edge*edge*fold*visibility*.035;
    frag_color=vec4(.34,.37,.40,alpha);
}
