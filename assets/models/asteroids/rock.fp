#version 140
in mediump vec3 var_normal;
in mediump vec4 var_color;
in highp vec3 var_rock_position;
in mediump float var_fade;
in highp vec3 var_view_position;
in mediump vec3 var_surface_normal;
in mediump float var_heat;
out vec4 frag_color;
uniform sampler2D surface;
uniform fs_uniforms { mediump vec4 tint; mediump vec4 analysis; };
float bayer2(vec2 p) { return 2.0*p.x+3.0*p.y-4.0*p.x*p.y; }
void main() {
    vec2 pixel=floor(gl_FragCoord.xy);
    float threshold=(4.0*bayer2(mod(pixel,2.0))+bayer2(mod(floor(pixel/2.0),2.0))+.5)/16.0;
    if(var_fade<=threshold) discard;
    // A single shared periodic field; three planar samples have no UV seams.
    vec3 p=var_rock_position*2.5;
    vec3 weights=pow(abs(normalize(var_surface_normal)),vec3(4.0));
    weights/=max(dot(weights,vec3(1.0)),.001);
    vec3 detail=texture(surface,p.yz).rgb*weights.x+texture(surface,p.zx).rgb*weights.y+texture(surface,p.xy).rgb*weights.z;
    // Fade subpixel detail instead of allowing a sparkling grain field.
    float resolved=1.0-smoothstep(.015,.08,length(fwidth(p)));
    float height=mix(.5,detail.r,resolved);
    vec3 n=normalize(var_normal),v=normalize(-var_view_position);
    vec3 dx=dFdx(var_view_position),dy=dFdy(var_view_position);
    vec3 r1=cross(dy,n),r2=cross(n,dx);float det=dot(dx,r1);
    // Relative scale keeps a 10 m and a 50 m rock's surface response consistent.
    float scale=length(dFdx(var_view_position))/max(length(dFdx(var_rock_position)),.00001);
    vec3 perturb=(dFdx(height)*r1+dFdy(height)*r2)*scale*.022;
    n=normalize(max(abs(det),.000001)*n-sign(det)*perturb);
    float key=max(dot(n,normalize(vec3(-.5,.7,1))),0.0);
    float fill=max(dot(n,normalize(vec3(.8,-.3,.2))),0.0);
    vec3 light=vec3(.20)+vec3(.98,.92,.82)*key+vec3(.12,.16,.23)*fill;
    float cavity=mix(1.0,.78+.35*detail.b,resolved);
    vec3 rock=var_color.rgb*mix(.55,1.45,height)*cavity;
    vec3 colour=rock*light*mix(tint.rgb,vec3(1.4),analysis.x*.85);
    float rim=pow(1.0-max(dot(n,v),0.0),4.0);
    colour+=vec3(.08,.105,.14)*rim;
    // Explicit per-player analysis gate: neither tint nor resource is guessed.
    float veins=smoothstep(.22,.72,detail.g)*resolved*clamp(analysis.x,0.0,1.0);
    colour=mix(colour,normalize(max(tint.rgb,vec3(.001)))*(.45+.4*key),veins*.85);
    // Short-lived, resource-neutral warmth only at exposed fracture edges.
    float edge=smoothstep(.18,.43,length(var_rock_position));
    colour+=vec3(.65,.24,.055)*var_heat*edge;
    frag_color=vec4(colour,1.0);
}
