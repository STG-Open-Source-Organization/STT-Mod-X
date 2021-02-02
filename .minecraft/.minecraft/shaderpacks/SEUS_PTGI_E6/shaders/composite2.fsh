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


#define TEXTURE_RESOLUTION 16 // Resolution of current resource pack. This needs to be set properly for reflections! Make sure to use a resource pack with consistent resolution for correct reflections! [4 8 16 32 64 128 256 512 1024 2048]


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

in vec3 upVector;


uniform int frameCounter;

#include "FQQrsH.inc"
#include "GBufferData.inc"

 float t(float v,float t)
 {
   return exp(-pow(v/(.9*t),2.));
 }
 vec3 t(vec2 v)
 {
   vec3 t=DecodeNormal(texture2DLod(gnormal,v.xy,0).xy);
   return t;
 }
 float v(in float v)
 {
   return 2.f*near*far/(far+near-(2.f*v-1.f)*(far-near));
 }
 float e(vec2 v)
 {
   return texture2D(depthtex1,v).x;
 }
 float s(vec2 t)
 {
   return v(texture2D(depthtex1,t).x);
 }
 vec4 e(in vec2 v,in float t)
 {
   vec4 f=vec4(v.xy,0.,0.),r=gbufferProjectionInverse*vec4(f.x*2.f-1.f,f.y*2.f-1.f,2.f*t-1.f,1.f);
   r/=r.w;
   return r;
 }
 float s(vec3 v,vec3 t)
 {
   return dot(abs(v-t),vec3(.3333));
 }
 vec3 p(vec2 v)
 {
   vec2 f=vec2(v.xy*vec2(viewWidth,viewHeight))/64.;
   f=(floor(f*64.)+.5)/64.;
   vec3 t=texture2D(noisetex,f).xyz,z=vec3(sqrt(.2),sqrt(2.),1.61803);
   t=mod(t+vec3(z)*mod(frameCounter,64),vec3(1.));
   t.x=(t.x>.5?1.-t.x:t.x)*2.;
   t.y=(t.y>.5?1.-t.y:t.y)*2.;
   t.z=(t.z>.5?1.-t.z:t.z)*2.;
   return t;
 }
 vec3 e(float v,float t,float f,vec3 y)
 {
   vec3 r;
   r.x=f*cos(v);
   r.y=f*sin(v);
   r.z=t;
   vec3 z=abs(y.y)<.999?vec3(0,0,1):vec3(1,0,0),s=normalize(cross(y,vec3(0.,1.,1.))),e=cross(s,y);
   return s*r.x+e*r.y+y*r.z;
 }
 vec3 e(vec2 t,float v,vec3 f)
 {
   float s=2*3.14159*t.x,y=sqrt((1-t.y)/(1+(v*v-1)*t.y)),z=sqrt(1-y*y);
   return e(s,y,z,f);
 }
 vec3 d(vec3 v)
 {
   vec4 t=gbufferProjection*vec4(v,1.);
   vec3 f=t.xyz/t.w,z=.5*f+.5;
   return z;
 }
 float n(float v)
 {
   return 2./(v*v+1e-07)-2.;
 }
 vec3 d(in vec2 v,in float t,in vec3 f)
 {
   float s=n(t),z=2*3.14159*v.x,y=pow(v.y,1.f/(s+1.f)),h=sqrt(1-y*y);
   return e(z,y,h,f);
 }
 float f(vec2 v)
 {
   return texture2DLod(composite,v,0).w;
 }
 void main()
 {
   GBufferData z=GetGBufferData();
   GBufferDataTransparent r=GetGBufferDataTransparent();
   bool y=r.depth<z.depth;
   if(y)
     z.normal=r.normal,z.smoothness=r.smoothness,z.metalness=0.,z.mcLightmap=r.mcLightmap,z.depth=r.depth;
   vec4 d=e(texcoord.xy,z.depth),h=gbufferModelViewInverse*vec4(d.xyz,1.),i=gbufferModelViewInverse*vec4(d.xyz,0.);
   vec3 x=normalize(d.xyz),l=normalize(i.xyz),n=normalize((gbufferModelViewInverse*vec4(z.normal,0.)).xyz);
   float a=v(z.depth),m=1.-z.smoothness,g=m*m,c=UymEaA(z.smoothness,z.metalness);
   int o=0;
   vec4 w=texture2DLod(gaux3,texcoord.xy,o);
   float u=Luminance(w.xyz);
   if(c<.001)
     {
       gl_FragData[0]=vec4(w);
       return;
     }
   vec3 D=z.normal,b=reflect(l,n);
   float G=length(fwidth(b)),L=10.4*1;
   L*=min(g*15.,1.1);
   L*=w.w;
   vec2 U=p(texcoord.xy).xy*.99+.005,W=vec2(0.);
   W=U-.5;
   float H=0.,q=1.1,T=1.,I=16.,B=20.,V=20.,M=mfsXsz(180.,z.totalTexGrad)/(g+.0001),X=mfsXsz(200.,z.totalTexGrad);
   vec4 P=vec4(0.),F=vec4(0.);
   float j=0.;
   vec4 N=vec4(vec3(.125),1.);
   N.xyz=vec3(1.);
   N.xyz*=w.w*.95+.05;
   float E=z.smoothness;
   int C=0;
   for(int A=-1;A<=1;A++)
     {
       for(int Z=-1;Z<=1;Z++)
         {
           vec2 Y=(vec2(A,Z)+W)/vec2(viewWidth,viewHeight)*L,S=texcoord.xy+Y.xy;
           float R=length(Y*vec2(viewWidth,viewHeight));
           S=clamp(S,4./vec2(viewWidth,viewHeight),1.-4./vec2(viewWidth,viewHeight));
           vec4 Q=texture2DLod(gaux3,S,o);
           vec3 O=t(S);
           float K=s(S),J=pow(saturate(dot(D,O)),M),k=exp(-(abs(K-a)*q)),ab=exp(-(s(Q.xyz,w.xyz)*H)),ac=exp(-abs(E-f(S))*X),ad=J*k*ab*ac;
           P+=pow(Q,N)*ad;
           j+=ad;
           F+=Q;
           C++;
         }
     }
   P/=j+.0001;
   P=pow(P,vec4(1.)/N);
   vec4 S=P;
   if(j<.0001)
     S=w;
   gl_FragData[0]=vec4(S);
 };

/* DRAWBUFFERS:6 */