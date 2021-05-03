#version 130



#include "Common.inc"

/*
 _______ _________ _______  _______  _ 
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _ 
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the LICENSE.txt contained in the root directory of this shaderpack!

*/




const bool gaux3MipmapEnabled = false;


uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepthtex;
uniform sampler2D depthtex1;
uniform sampler2D composite;
uniform sampler2D gdepth;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowcolor;
uniform sampler2D shadowtex1;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

in vec4 texcoord;
in vec3 lightVector;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;
in float timeSkyDark;

in vec3 colorSunlight;
in vec3 colorSkylight;
in vec3 colorSunglow;
in vec3 colorBouncedSunlight;
in vec3 colorScatteredSunlight;
in vec3 colorTorchlight;
in vec3 colorWaterMurk;
in vec3 colorWaterBlue;
in vec3 colorSkyTint;

in vec3 worldSunVector;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;

in vec3 upVector;
in vec3 skyUpColor;

uniform int frameCounter;

#include "FQQrsH.inc"
#include "GBufferData.inc"
float e(float f,float v)
 {
   return exp(-pow(f/(.9*v),2.));
 }
 vec3 e(vec2 v)
 {
   vec3 s=DecodeNormal(texture2DLod(gnormal,v.xy,0).xy);
   return s;
 }
 float t(in float v)
 {
   return 2.f*near*far/(far+near-(2.f*v-1.f)*(far-near));
 }
 float w(vec2 v)
 {
   return texture2D(depthtex1,v).x;
 }
 float f(vec2 v)
 {
   return t(texture2D(depthtex1,v).x);
 }
 vec4 f(in vec2 v,in float f)
 {
   vec4 i=vec4(v.xy,0.,0.),s=gbufferProjectionInverse*vec4(i.x*2.f-1.f,i.y*2.f-1.f,2.f*f-1.f,1.f);
   s/=s.w;
   return s;
 }
 float t(vec3 v,vec3 f)
 {
   return dot(abs(v-f),vec3(.3333));
 }struct MaterialMask{float sky;float land;float grass;float leaves;float hand;float entityPlayer;float water;float stainedGlass;float ice;float torch;float lava;float glowstone;};
 float w(const in int v,in float f)
 {
   if(f>254.f)
     f=0.f;
   if(f==v)
     return 1.f;
   else
      return 0.f;
 }
 MaterialMask s(float v)
 {
   MaterialMask f;
   v*=255.;
   if(isEyeInWater>0)
     f.sky=0.f;
   else
     {
       f.sky=0.;
       if(texture2D(depthtex1,texcoord.xy).x>.999999)
         f.sky=1.;
     }
   f.land=w(1,v);
   f.grass=w(2,v);
   f.leaves=w(3,v);
   f.hand=w(4,v);
   f.entityPlayer=w(5,v);
   f.water=w(6,v);
   f.stainedGlass=w(7,v);
   f.ice=w(8,v);
   f.torch=w(30,v);
   f.lava=w(31,v);
   f.glowstone=w(32,v);
   return f;
 }
 float s(float v,float f)
 {
   return 1./(v*(1.-f)+f);
 }
 vec3 v(vec2 v)
 {
   vec2 f=vec2(v.xy*vec2(viewWidth,viewHeight))/64.;
   f+=vec2(sin(frameCounter*.75),cos(frameCounter*.75));
   f=(floor(f*64.)+.5)/64.;
   return texture2D(noisetex,f).xyz;
 }
 vec3 e(float v,float s,float f,vec3 i)
 {
   vec3 r;
   r.x=f*cos(v);
   r.y=f*sin(v);
   r.z=s;
   vec3 e=abs(i.y)<.999?vec3(0,0,1):vec3(1,0,0),z=normalize(cross(i,vec3(0.,1.,1.))),y=cross(z,i);
   return z*r.x+y*r.y+i*r.z;
 }
 vec3 e(vec2 f,float v,vec3 i)
 {
   float s=2*3.14159*f.x,y=sqrt((1-f.y)/(1+(v*v-1)*f.y)),z=sqrt(1-y*y);
   return e(s,y,z,i);
 }
 vec3 x(vec3 v)
 {
   vec4 f=gbufferProjection*vec4(v,1.);
   vec3 s=f.xyz/f.w,i=.5*s+.5;
   return i;
 }
 float p(float v)
 {
   return 2./(v*v+1e-07)-2.;
 }
 vec3 f(in vec2 v,in float f,in vec3 i)
 {
   float s=p(f),z=2*3.14159*v.x,y=pow(v.y,1.f/(s+1.f)),x=sqrt(1-y*y);
   return e(z,y,x,i);
 }
 void e(inout vec3 f,in vec3 v,in vec3 s,vec3 i,float z)
 {
   float e=length(v);
   #ifdef FADE_TO_ATMOSPHERE
   float r=length(v)/far;
   r=pow(r,6.)*.07+pow(r,2.)*.003;
   #else
   float y=length(v)/300.;
   y=pow(y,3.)*.002;
   #endif
   y*=pow(eyeBrightnessSmooth.y/240.f,6.f);
   y=clamp(y,0.,.03);
   y/=saturate(i.y)*2.+1.;
   vec3 t=vec3(.2,.45,1.);
   f*=exp(-y*t*100.67);
   f+=AtmosphericScattering(normalize(i),worldSunVector,1.,y)*.9*mix(z,1.,.5)*mix(1.,.35,wetness)*.001;
 }
 void f(inout vec3 v,in vec3 f,in vec3 s,vec3 z,float i)
 {
   float y=length(f);
   y*=pow(eyeBrightnessSmooth.y/240.f,6.f);
   y*=rainStrength;
   float e=pow(exp(-y*1e-05),4.);
   vec3 r=vec3(dot(skyUpColor,vec3(1.)))*.001;
   v=mix(r,v,vec3(e));
 }
 void main()
 {
   GBufferData v=GetGBufferData();
   GBufferDataTransparent r=GetGBufferDataTransparent();
   MaterialMask i=s(v.materialID);
   bool y=r.depth<v.depth;
   if(y)
     v.normal=r.normal,v.smoothness=r.smoothness,v.metalness=0.,v.mcLightmap=r.mcLightmap,v.depth=r.depth;
   vec4 d=f(texcoord.xy,v.depth),z=gbufferModelViewInverse*vec4(d.xyz,1.),x=gbufferModelViewInverse*vec4(d.xyz,0.);
   vec3 h=normalize(d.xyz),l=normalize(x.xyz),p=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz);
   float w=t(v.depth),n=1.-v.smoothness,a=n*n,c=UymEaA(v.smoothness,v.metalness);
   int g=0;
   vec4 m=texture2DLod(gaux3,texcoord.xy,g),o=m;
   float G=1.-v.smoothness,D=G*G;
   vec3 M=p,u=-l,k=normalize(reflect(-u,M)+M*D),b=normalize(u+k);
   float U=saturate(dot(M,k)),S=saturate(dot(M,u)),I=saturate(dot(M,b)),E=saturate(dot(k,b)),A=v.metalness*.98+.02,B=pow(1.-E,5.),P=A+(1.-A)*B,L=D/2.,V=s(U,L)*s(S+.8,L),T=U*P*V;
   o.xyz*=mix(vec3(1.),v.albedo.xyz,vec3(v.metalness));
   T=mix(T,1.,v.metalness);
   if(v.depth>.99999)
     T=0.;
   T*=UymEaA(v.smoothness,v.metalness);
   vec4 F=texture2DLod(composite,texcoord.xy,0);
   vec3 C=mix(pow(F.xyz,vec3(2.2)),o.xyz*.01,vec3(T));
   if(i.sky<.5&&!y)
     e(C,d.xyz,h.xyz,l.xyz,1.);
   f(C,d.xyz,h.xyz,l.xyz,1.);
   C=pow(C.xyz,vec3(.454545));
   gl_FragData[0]=vec4(C,F.w);
 };


/* DRAWBUFFERS:3 */