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




const bool gaux1MipmapEnabled = false;


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
float w(float v,float f)
 {
   return exp(-pow(v/(.9*f),2.));
 }
 vec3 w(vec2 v)
 {
   vec3 f=DecodeNormal(texture2DLod(gnormal,v.xy,0).xy);
   return f;
 }
 float x(in float f)
 {
   return 2.f*near*far/(far+near-(2.f*f-1.f)*(far-near));
 }
 float v(vec2 v)
 {
   return x(texture2D(depthtex1,v).x);
 }
 vec4 v(in vec2 v,in float f)
 {
   vec4 d=vec4(v.xy,0.,0.),t=gbufferProjectionInverse*vec4(d.x*2.f-1.f,d.y*2.f-1.f,2.f*f-1.f,1.f);
   t/=t.w;
   return t;
 }
 void main()
 {
   TcZnFJ d=ZrrDhC(texcoord.xy);
   float f=d.JKJbuS;
   int t=0;
   vec4 p=texture2DLod(gaux3,texcoord.xy,0);
   vec3 y=p.xyz;
   float x=Luminance(y.xyz);
   vec3 i=w(texcoord.xy);
   float r=v(texcoord.xy);
   vec2 z=vec2(0.);
   float m=1.,h=.04125*0;
   BNbNTO(m,h,p.w,f,y,r);
   vec4 g=vec4(vec3(mix(.1,.8,pow(f,1.))),1.);
   g=vec4(vec3(mix(g.x,.8,pow(f,1.))),1.);
   g=vec4(vec3(mix(g.x,.8,pow(f,5.))),1.);
   g=mix(g,vec4(1.),vec4(.5));
   float e=2.*AlHSce,n=aQKLwO;
   vec4 D=vec4(0.);
   float G=0.;
   int o=0;
   for(int a=-1;a<=1;a++)
     {
       for(int c=-1;c<=1;c++)
         {
           vec2 s=(vec2(a,c)+z)/vec2(viewWidth,viewHeight)*m,l=texcoord.xy+s.xy;
           l=clamp(l,2./vec2(viewWidth,viewHeight),1.-2./vec2(viewWidth,viewHeight));
           vec4 u=texture2DLod(gaux3,l,t);
           vec3 I=w(l);
           float W=v(l),L=pow(saturate(dot(i,I)),e),N=exp(-(abs(W-r)*n)),A=exp(-xhpnNr(u.xyz,y,h)),S=L*N*A;
           D+=pow(u,g)*S;
           G+=S;
           o++;
         }
     }
   D/=G+.0001;
   D=pow(D,vec4(1.)/g);
   vec3 l=D.xyz;
   if(G<.0001)
     l=y;
   XMOSzd(l,texcoord.xy,rand(texcoord.xy+sin(frameTimeCounter)).xyz);
   vec4 a=texture2DLod(gaux1,texcoord.xy,0);
   a.xyz=mix(a.xyz,l.xyz,vec3(f));
   gl_FragData[0]=a;
   gl_FragData[1]=vec4(l,D.w);
 };
/* DRAWBUFFERS:46 */
