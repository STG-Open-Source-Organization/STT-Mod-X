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

float d(float f,float y)
 {
   return exp(-pow(f/(.9*y),2.));
 }
 vec3 d(vec2 d)
 {
   vec3 f=DecodeNormal(texture2DLod(gnormal,d.xy,0).xy);
   return f;
 }
 float f(in float f)
 {
   return 2.f*near*far/(far+near-(2.f*f-1.f)*(far-near));
 }
 float p(vec2 v)
 {
   return f(texture2D(depthtex1,v).x);
 }
 vec4 f(in vec2 f,in float y)
 {
   vec4 v=vec4(f.xy,0.,0.),d=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*y-1.f,1.f);
   d/=d.w;
   return d;
 }
 float p(vec3 f,vec3 y)
 {
   return dot(abs(f-y),vec3(.3333));
 }
 void main()
 {
   TcZnFJ f=ZrrDhC(texcoord.xy);
   float v=f.JKJbuS;
   int y=0;
   vec4 t=texture2DLod(gaux3,texcoord.xy,0);
   vec3 i=t.xyz;
   float e=Luminance(i.xyz),r=t.w;
   vec3 g=d(texcoord.xy);
   float G=p(texcoord.xy);
   vec2 s=vec2(0.);
   #if GI_FILTER_QUALITY==1
   s=rand(texcoord.xy+sin(frameTimeCounter)).xy-.5;
   #endif
   float h=9.*1,z=3.;
   BNbNTO(h,z,t.w,v,i,G);
   float x=12.*AlHSce,n=aQKLwO;
   vec4 a=vec4(0.);
   float D=0.;
   vec4 w=vec4(vec3(1.),1.);
   int m=0;
   for(int l=-1;l<=1;l++)
     {
       for(int Y=-1;Y<=1;Y++)
         {
           vec2 o=(vec2(l,Y)+s)/vec2(viewWidth,viewHeight)*h,c=texcoord.xy+o.xy;
           c=clamp(c,2./vec2(viewWidth,viewHeight),1.-2./vec2(viewWidth,viewHeight));
           vec4 u=texture2DLod(gaux3,c,y);
           vec3 I=d(c);
           float T=p(c),L=pow(saturate(dot(g,I)),x),N=exp(-(abs(T-G)*n)),A=exp(-xhpnNr(u.xyz,i,z)),S=L*N*A;
           a+=pow(u,w)*S;
           D+=S;
           m++;
         }
     }
   a/=D+.0001;
   a=pow(a,vec4(1.)/w);
   vec3 c=a.xyz;
   if(D<.0001)
     c=i;
   XMOSzd(c,texcoord.xy,rand(texcoord.xy+sin(frameTimeCounter)).xyz);
   gl_FragData[0]=vec4(c,a.w);
 };

/* DRAWBUFFERS:6 */