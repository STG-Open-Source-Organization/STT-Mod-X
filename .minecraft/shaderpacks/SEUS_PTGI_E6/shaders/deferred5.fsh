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
uniform sampler2D depthtex1;
uniform sampler2D gdepthtex;
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
float d(float f,float t)
 {
   return exp(-pow(f/(.9*t),2.));
 }
 vec3 d(vec2 t)
 {
   vec3 f=DecodeNormal(texture2DLod(gnormal,t.xy,0).xy);
   return f;
 }
 float f(in float f)
 {
   return 2.f*near*far/(far+near-(2.f*f-1.f)*(far-near));
 }
 float t(vec2 t)
 {
   return f(texture2D(depthtex1,t).x);
 }
 vec4 f(in vec2 f,in float t)
 {
   vec4 v=vec4(f.xy,0.,0.),d=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*t-1.f,1.f);
   d/=d.w;
   return d;
 }
 float t(vec3 f,vec3 t)
 {
   return dot(abs(f-t),vec3(.3333));
 }
 void main()
 {
   TcZnFJ f=ZrrDhC(texcoord.xy);
   float v=f.JKJbuS;
   int y=0;
   vec4 e=texture2DLod(gaux3,texcoord.xy,0);
   vec3 i=e.xyz;
   float m=Luminance(i.xyz),r=e.w;
   vec3 h=d(texcoord.xy);
   float z=t(texcoord.xy);
   vec2 x=vec2(0.);
   float g=16.*1,l=7.;
   BNbNTO(g,l,e.w,v,i,z);
   float o=24.*AlHSce,n=aQKLwO;
   vec4 D=vec4(0.);
   float a=0.;
   int G=0;
   for(int w=-1;w<=1;w++)
     {
       for(int c=-1;c<=1;c++)
         {
           vec2 s=(vec2(w,c)+x)/vec2(viewWidth,viewHeight)*g,u=texcoord.xy+s.xy;
           float p=length(s*vec2(viewWidth,viewHeight));
           u=clamp(u,4./vec2(viewWidth,viewHeight),1.-4./vec2(viewWidth,viewHeight));
           vec4 L=texture2DLod(gaux3,u,y);
           vec3 W=d(u);
           float I=t(u),S=pow(saturate(dot(h,W)),o),N=exp(-(abs(I-z)*n)),A=exp(-xhpnNr(L.xyz,i,l)),H=S*N*A;
           D+=L*H;
           a+=H;
           G++;
         }
     }
   D/=a+.0001;
   vec3 u=D.xyz;
   if(a<.0001)
     u=i;
   XMOSzd(u,texcoord.xy,rand(texcoord.xy+sin(frameTimeCounter)).xyz);
   gl_FragData[0]=vec4(u,1.);
 };


/* DRAWBUFFERS:6 */
