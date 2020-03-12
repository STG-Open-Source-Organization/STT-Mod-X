// #define FULL_RT_REFLECTIONS // OFF: only surfaces with high smoothness values will render reflections. ON: Allow rougher surfaces to render reflections (higher computational cost). This can cause big slowdowns with lots of semi-rough surfaces!
#define REFLECTION_TRACE_LENGTH 90 // The maximum ray length of ray traced reflections. Higher values result in reflections tracing farther into the world at a higher cost. Lower values can can cause leaking in large indoor areas! [60 90 120 150]
#define DIFFUSE_TRACE_LENGTH 60 // The maximum ray length of path traced diffuse GI. Higher values result in more accurate lighting, taking farther away surfaces into account, at a higher cost. Lower values can cause leaking in large indoor areas! [60 80 100 120]
#define GI_RESPONSIVENESS 3 // How well GI responds to lighting changes over time. Lower settings sacrifice responsiveness for improved stability, better noise reduction, and higher detail in GI. [0 1 2 3]
// #define GI_SCREEN_SPACE_TRACING // Allows for surfaces in screen-space to cast indirect shadows and lighting that wouldn't otherwise (mobs, grass, etc.). If enabled, can leave weird ghosty shadows when GI Responsiveness is low.
#define GI_FILTER_QUALITY 1 // Quality of GI filter. [0 1]
// #define REFLECTION_SCREEN_SPACE_TRACING // Allows for surfaces in screen-space to show up in reflections that wouldn't othwerise (mobs, grass, etc.). 
#define GI_SECONDARY_SAMPLES 1 // How many samples to trace for the secondary GI tracing. Higher samples reduces the "disco floor" artifact mostly seen in reflections at the cost of performance. [1 2 3 4]

#define GI_LIGHT_BLOCK_INTENSITY 1.0 // How bright light from solid blocks is. [0.2 0.4 0.6 0.8 1.0 1.5 2.0 2.5 3.0 4.0 5.0 7.0 10.0]
#define GI_LIGHT_TORCH_INTENSITY 1.0 // How bright light from torches is. [0.2 0.4 0.6 0.8 1.0 1.5 2.0 2.5 3.0 4.0 5.0 7.0 10.0]

// #define GI_SIMPLE_SKY_TERM // Off: Provides true ambient GI light color from sky. On: Uses a simpler less-accurate sky term for GI for better performance

const int wgTerK = 2048;
const int CsiWWB = 4096;


int ZWcrFy(float v)
 {
   return int(floor(v));
 }
 int UCJnwh(int v)
 {
   return v-ZWcrFy(mod(float(v),2.))-0;
 }
 int PrHWFn(int v)
 {
   return v-ZWcrFy(mod(float(v),2.))-1;
 }
 int VpEHlC()
 {
   ivec2 G=ivec2(viewWidth,viewHeight);
   int v=G.x*G.y;
   return UCJnwh(ZWcrFy(floor(pow(float(v),.333333))));
 }
 int Tsmicx()
 {
   ivec2 G=ivec2(wgTerK,wgTerK);
   int v=G.x*G.y;
   return PrHWFn(ZWcrFy(floor(pow(float(v),.333333))));
 }
 vec3 jrwNAE(vec2 v)
 {
   ivec2 G=ivec2(viewWidth,viewHeight);
   int W=G.x*G.y,f=VpEHlC();
   ivec2 i=ivec2(v.x*G.x,v.y*G.y);
   float y=float(i.y/f),x=float(int(i.x+mod(G.x*y,f))/f);
   x+=floor(G.x*y/f);
   vec3 r=vec3(0.,0.,x);
   r.x=mod(i.x+mod(G.x*y,f),f);
   r.y=mod(i.y,f);
   r.xyz=floor(r.xyz);
   r/=f;
   r.xyz=r.xzy;
   return r;
 }
 vec2 wvLPci(vec3 G)
 {
   ivec2 v=ivec2(viewWidth,viewHeight);
   int y=VpEHlC();
   vec3 i=G.xzy*y;
   i=floor(i+1e-05);
   float x=i.z;
   vec2 r;
   r.x=mod(i.x+x*y,v.x);
   float f=i.x+x*y;
   r.y=i.y+floor(f/v.x)*y;
   r+=.5;
   r/=v;
   return r;
 }
 vec3 LyebmI(vec2 G)
 {
   vec2 v=G;
   v.xy/=.5;
   ivec2 i=ivec2(wgTerK,wgTerK);
   int y=i.x*i.y,f=Tsmicx();
   ivec2 r=ivec2(v.x*i.x,v.y*i.y);
   float x=float(r.y/f),z=float(int(r.x+mod(i.x*x,f))/f);
   z+=floor(i.x*x/f);
   vec3 m=vec3(0.,0.,z);
   m.x=mod(r.x+mod(i.x*x,f),f);
   m.y=mod(r.y,f);
   m.xyz=floor(m.xyz);
   m/=f;
   m.xyz=m.xzy;
   return m;
 }
 vec2 PoXKdv(vec3 i,int y)
 {
   i=clamp(i,vec3(0.),vec3(1.));
   ivec2 v=ivec2(wgTerK,wgTerK);
   vec3 G=i.xzy*y;
   G=floor(G+1e-05);
   float x=G.z;
   vec2 r;
   r.x=mod(G.x+x*y,v.x);
   float f=G.x+x*y;
   r.y=G.y+floor(f/v.x)*y;
   r+=.5;
   r/=v;
   r.xy*=.5;
   return r;
 }
 vec2 PoXKdv(vec3 v)
 {
   int G=Tsmicx();
   return PoXKdv(v,Tsmicx());
 }
 vec3 xkpggD(vec3 v,int f)
 {
   return v*=1./f,v=v+vec3(.5),v=clamp(v,vec3(0.),vec3(1.)),v;
 }
 vec3 dToLOr(vec3 v,int f)
 {
   return v*=1./f,v=v+vec3(.5),v;
 }
 vec3 xkpggD(vec3 v)
 {
   return xkpggD(v,Tsmicx());
 }
 vec3 dToLOr(vec3 v)
 {
   return dToLOr(v,Tsmicx());
 }
 vec3 bqzMKV(vec3 v)
 {
   int G=Tsmicx();
   v=v-vec3(.5);
   v*=G;
   return v;
 }
 vec3 jXfIYx(vec3 v)
 {
   int G=VpEHlC();
   v*=1./G;
   v=v+vec3(.5);
   v=clamp(v,vec3(0.),vec3(1.));
   return v;
 }
 vec3 lfDeyJ(vec3 v)
 {
   int G=VpEHlC();
   v=v-vec3(.5);
   v*=G;
   return v;
 }struct TcZnFJ{float tBefeN;float RXCGFO;float vILDot;float JKJbuS;vec3 kLqMlH;};
 vec4 DHwTEN(TcZnFJ v)
 {
   vec4 r;
   r.x=v.tBefeN;
   v.kLqMlH=pow(v.kLqMlH,vec3(.25));
   r.y=PackTwo16BitTo32Bit(v.kLqMlH.x,v.vILDot);
   r.z=PackTwo16BitTo32Bit(v.kLqMlH.y,v.JKJbuS);
   r.w=PackTwo16BitTo32Bit(v.kLqMlH.z,v.RXCGFO);
   return r;
 }
 TcZnFJ wlhHcr(vec4 v)
 {
   TcZnFJ r;
   vec2 G=UnpackTwo16BitFrom32Bit(v.y),i=UnpackTwo16BitFrom32Bit(v.z),f=UnpackTwo16BitFrom32Bit(v.w);
   r.tBefeN=v.x;
   r.vILDot=G.y;
   r.JKJbuS=i.y;
   r.RXCGFO=f.y;
   r.kLqMlH=pow(vec3(G.x,i.x,f.x),vec3(4.));
   return r;
 }
 TcZnFJ ZrrDhC(vec2 v)
 {
   vec2 G=1./vec2(viewWidth,viewHeight),f=vec2(viewWidth,viewHeight);
   v=(floor(v*f)+.5)*G;
   return wlhHcr(texture2DLod(gaux2,v,0));
 }
 float UymEaA(float v,float f)
 {
   float G=1.;
   #ifdef FULL_RT_REFLECTIONS
   G=clamp(pow(v,.125)+f,0.,1.);
   #else
   G=clamp(v*10.-7.,0.,1.);
   #endif
   return G;
 }
 const float aQKLwO=4.,AlHSce=4.;
 void BNbNTO(inout float v,inout float r,float G,float f,vec3 i,float x)
 {
   v*=mix(2.,3.,f);
   float y=dot(i,vec3(1.));
   r*=1.-pow(f,1.);
   r/=G*.1+1e-07;
   r*=4.;
   r*=.75;
   float m=G/(y+1e-07)*.2+4e-08;
   m*=2.;
   m=min(m,1.);
   m=mix(m,1.,pow(f,.25));
   if(x<.12)
     r=0.;
 }
 float xhpnNr(vec3 v,vec3 f,float G)
 {
   float r=dot(abs(v-f),vec3(.3333));
   r*=G;
   r*=.18;
   return r;
 }
 void XMOSzd(inout vec3 v,vec2 G,vec3 f)
 {}
 float mfsXsz(float v,float f)
 {
   return v/(f*20.01+1.);
 };