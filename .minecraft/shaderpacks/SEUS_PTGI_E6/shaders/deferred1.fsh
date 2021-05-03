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




const bool gaux3MipmapEnabled = true;


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
 float t(float f,float t)
 {
   return exp(-pow(f/(.9*t),2.));
 }
 vec3 t(vec2 t)
 {
   vec3 f=DecodeNormal(texture2DLod(gnormal,t.xy,0).xy);
   return f;
 }
 float f(in float f)
 {
   return 2.f*near*far/(far+near-(2.f*f-1.f)*(far-near));
 }
 float v(vec2 t)
 {
   return f(texture2D(depthtex1,t).x);
 }
 vec4 f(in vec2 f,in float t)
 {
   vec4 v=vec4(f.xy,0.,0.),d=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*t-1.f,1.f);
   d/=d.w;
   return d;
 }
 void main()
 {
   TcZnFJ f=ZrrDhC(texcoord.xy);
   float d=f.JKJbuS;
   vec4 i=texture2DLod(gaux3,texcoord.xy,0);
   vec3 g=i.xyz;
   float e=Luminance(g.xyz);
   vec3 m=t(texcoord.xy);
   float o=v(texcoord.xy);
   vec2 y=vec2(0.);
   float h=2.,c=sin(frameTimeCounter)>0.?1.:0.,a=2.*AlHSce,r=aQKLwO;
   vec4 x=vec4(0.),n=vec4(0.);
   float l=0.;
   int D=0;
   for(int z=-1;z<=1;z++)
     {
       for(int u=-1;u<=1;u++)
         {
           vec2 w=(vec2(z,u)+y)/vec2(viewWidth,viewHeight)*h,p=texcoord.xy+w.xy;
           p=clamp(p,4./vec2(viewWidth,viewHeight),1.-4./vec2(viewWidth,viewHeight));
           vec4 s=texture2DLod(gaux3,p,0);
           x+=s;
           n+=s*s;
           D++;
         }
     }
   x/=D+1e-06;
   n/=D+1e-06;
   vec3 u=x.xyz;
   float w=dot(x.xyz,vec3(1.));
   vec4 p=sqrt(max(vec4(0.),n-x*x));
   float z=dot(p.xyz,vec3(6.));
   if(l<.0001)
     u=g;
   gl_FragData[0]=vec4(i.xyz,z);
 };
/* DRAWBUFFERS:6 */
