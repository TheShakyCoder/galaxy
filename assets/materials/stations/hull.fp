#version 140
in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in highp vec4 var_light;
out vec4 out_fragColor;
uniform sampler2D tex0;
uniform fs_uniforms { lowp vec4 tint; highp vec4 beacon_clock; };
void main() {
    vec3 base=texture(tex0,var_texcoord0).rgb;
    vec3 N=normalize(var_normal),L=normalize(var_light.xyz-var_position.xyz),V=normalize(-var_position.xyz);
    // Small per-pixel surface relief from the authored panel seams. Derivatives
    // reuse the albedo sample; no normal-map texture or runtime noise field.
    float height=dot(base,vec3(.2126,.7152,.0722));
    vec3 dp1=dFdx(var_position.xyz),dp2=dFdy(var_position.xyz);
    vec3 r1=cross(dp2,N),r2=cross(N,dp1);float det=dot(dp1,r1);
    N=normalize(max(abs(det),.00001)*N-sign(det)*(dFdx(height)*r1+dFdy(height)*r2)*.7);
    float diffuse=max(dot(N,L),0.0);
    float spec=pow(max(dot(N,normalize(L+V)),0.0),52.0)*smoothstep(0.0,.15,diffuse);
    float rim=pow(1.0-max(dot(N,V),0.0),4.0);
    vec3 color=base*(.28+.75*diffuse)+mix(vec3(.28),base,.4)*spec*.60+vec3(.08,.12,.17)*rim*.23;
    // Reserved atlas cells are emitters. RGB avoids alpha-mask and
    // premultiplication dependence; the station profile supplies mipmaps.
    vec2 cell=floor(clamp(var_texcoord0,0.0,.9999)*4.0);
    float id=cell.x+(3.0-cell.y)*4.0;
    float solid=step(5.5,id)*(1.0-step(8.5,id))+step(12.5,id)*(1.0-step(13.5,id));
    float windows=(1.0-step(.4,abs(id-5.0)))*smoothstep(.35,.65,base.r);
    float nav=1.0-step(.6,abs(id-7.5));
    float blink=mix(1.0,.35+.65*step(.4,fract(beacon_clock.x*.75+id*.13)),nav);
    color=mix(color,base*blink,max(solid,windows));
    // Keep the legacy tint property compatible; its RGB ambient boost does not
    // wash out the authored finish. Alpha retains the existing opacity contract.
    out_fragColor=vec4(color,tint.a);
}
