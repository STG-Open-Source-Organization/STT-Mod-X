#version 330 compatibility


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
#define SHADOW_MAP_BIAS 0.90


#define TEXTURE_RESOLUTION 16 // Resolution of current resource pack. This needs to be set properly for reflections! Make sure to use a resource pack with consistent resolution for correct reflections! [4 8 16 32 64 128 256 512 1024 2048]



const bool compositeMipmapEnabled = false;



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
uniform sampler2D gaux4;

uniform sampler2DShadow shadow;

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

in vec4 skySHR;
in vec4 skySHG;
in vec4 skySHB;

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
uniform int   isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

in vec3 upVector;
in vec3 skyUpColor;
in vec3 worldLightVector;
in vec3 worldSunVector;

uniform int frameCounter;

uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;


in mat4 gbufferPreviousModelViewInverse;
in mat4 gbufferPreviousProjectionInverse;



/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



#include "TAA.inc"




vec4 GetViewPosition(in vec2 coord, in float depth) 
{	
	vec2 tcoord = coord;
	TemporalJitterProjPosInv01(tcoord);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}




vec2 GetNearFragment(vec2 coord, float depth, out float minDepth)
{
	
	
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	vec4 depthSamples;
	depthSamples.x = texture2D(depthtex1, coord + texel * vec2(1.0, 1.0)).x;
	depthSamples.y = texture2D(depthtex1, coord + texel * vec2(1.0, -1.0)).x;
	depthSamples.z = texture2D(depthtex1, coord + texel * vec2(-1.0, 1.0)).x;
	depthSamples.w = texture2D(depthtex1, coord + texel * vec2(-1.0, -1.0)).x;

	vec2 targetFragment = vec2(0.0, 0.0);

	if (depthSamples.x < depth)
		targetFragment = vec2(1.0, 1.0);
	if (depthSamples.y < depth)
		targetFragment = vec2(1.0, -1.0);
	if (depthSamples.z < depth)
		targetFragment = vec2(-1.0, 1.0);
	if (depthSamples.w < depth)
		targetFragment = vec2(-1.0, -1.0);


	minDepth = min(min(min(depthSamples.x, depthSamples.y), depthSamples.z), depthSamples.w);

	return coord + texel * targetFragment;
}



vec3 Fract01(vec3 pos)
{
	vec3 posf = fract(pos);

	for (int i = 0; i < 3; i++)
	{
		if (posf[i] == 0.0)
		{
			posf[i] = 1.0;
		}
	}

	return posf;
}






struct MaterialMask
{
	float sky;
	float land;
	float grass;
	float leaves;
	float hand;
	float entityPlayer;
	float water;
	float stainedGlass;
	float ice;
	float torch;
	float lava;
	float glowstone;
};

float GetMaterialMask(const in int ID, in float matID) 
{
	//Catch last part of sky
	if (matID > 254.0f) 
	{
		matID = 0.0f;
	}

	if (matID == ID) 
	{
		return 1.0f;
	} 
	else 
	{
		return 0.0f;
	}
}

MaterialMask CalculateMasks(float materialID)
{
	MaterialMask mask;

	materialID *= 255.0;

	if (isEyeInWater > 0)
		mask.sky = 0.0f;
	else
	{
		mask.sky = 0.0;
		if (texture2D(depthtex1, texcoord.st).x > 0.999999)
		{
			mask.sky = 1.0;
		}
	}
		//mask.sky = GetMaterialMask(0, materialID);
		//mask.sky = texture2D(depthtex1, texcoord).x > 0.999999 ? 1.0 : 0.0;



	mask.land 			= GetMaterialMask(1, materialID);
	mask.grass 			= GetMaterialMask(2, materialID);
	mask.leaves 		= GetMaterialMask(3, materialID);
	mask.hand 			= GetMaterialMask(4, materialID);
	mask.entityPlayer 	= GetMaterialMask(5, materialID);
	mask.water 			= GetMaterialMask(6, materialID);
	mask.stainedGlass	= GetMaterialMask(7, materialID);
	mask.ice 			= GetMaterialMask(8, materialID);
	mask.torch 			= GetMaterialMask(30, materialID);
	mask.lava 			= GetMaterialMask(31, materialID);
	mask.glowstone 		= GetMaterialMask(32, materialID);

	return mask;
}





#include "FQQrsH.inc"
#include "GBufferData.inc"
vec3 v(vec3 y)
 {
   vec4 v=vec4(y,1.);
   v.xyz+=.5;
   v.xyz-=Fract01(cameraPosition.xyz+.5)-.5;
   v=shadowModelView*v;
   float f=-v.z;
   v=shadowProjection*v;
   v/=v.w;
   float z=sqrt(v.x*v.x+v.y*v.y),i=1.f-SHADOW_MAP_BIAS+z*SHADOW_MAP_BIAS;
   v.xy*=.95f/i;
   v.z=mix(v.z,.5,.8);
   v=v*.5f+.5f;
   v.xy*=.5;
   v.xy+=.5;
   return v.xyz;
 }struct Ray{vec3 dir;vec3 origin;};struct BBRay{vec3 origin;vec3 direction;vec3 inv_direction;ivec3 sign;};
 BBRay v(vec3 v,vec3 y)
 {
   vec3 f=vec3(1.)/y;
   return BBRay(v,y,f,ivec3(f.x<0?1:0,f.y<0?1:0,f.z<0?1:0));
 }
 void v(in BBRay v,in vec3 f[2],out float r,out float y)
 {
   float z,i,x,n;
   r=(f[v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   y=(f[1-v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   z=(f[v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   i=(f[1-v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   x=(f[v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   n=(f[1-v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   r=max(max(r,z),x);
   y=min(min(y,i),n);
 }
 vec2 e(inout float v)
 {
   return fract(sin(vec2(v+=.1,v+=.1))*vec2(43758.5,22578.1));
 }
 vec3 t(vec2 v)
 {
   vec2 f=vec2(v.xy*vec2(viewWidth,viewHeight))/64.;
   const vec2 s[16]=vec2[16](vec2(-1,-1),vec2(0,-.333333),vec2(-.5,.333333),vec2(.5,-.777778),vec2(-.75,-.111111),vec2(.25,.555556),vec2(-.25,-.555556),vec2(.75,.111111),vec2(-.875,.777778),vec2(.125,-.925926),vec2(-.375,-.259259),vec2(.625,.407407),vec2(-.625,-.703704),vec2(.375,-.037037),vec2(-.125,.62963),vec2(.875,-.481482));
   if(v.x<2./viewWidth||v.x>1.-2./viewWidth||v.y<2./viewHeight||v.y>1.-2./viewHeight)
     ;
   else
      f+=s[int(mod(frameCounter,4))]*.5;
   f=(floor(f*64.)+.5)/64.;
   vec3 i=texture2D(noisetex,f).xyz,z=vec3(sqrt(.2),sqrt(2.),1.61803);
   i.x=(i.x>.5?1.-i.x:i.x)*2.;
   i.y=(i.y>.5?1.-i.y:i.y)*2.;
   i.z=(i.z>.5?1.-i.z:i.z)*2.;
   return i;
 }
 vec3 e(vec3 v,inout float y,int z)
 {
   vec2 f=t(texcoord.xy+vec2(y+=.1,y+=.1)).xy;
   f=fract(f+e(y)*.1);
   float i=6.28319*f.x,x=sqrt(f.y);
   vec3 s=normalize(cross(v,vec3(0.,1.,1.))),w=cross(v,s),n=s*cos(i)*x+w*sin(i)*x+v.xyz*sqrt(1.-f.y);
   return n;
 }
 float e(vec3 y,vec3 z,vec3 f,int x)
 {
   vec3 i=bqzMKV(y),d=v(i+z*.99);
   float s=.5,r=shadow2DLod(shadow,vec3(d.xy,d.z-.0006*s),3).x;
   r*=saturate(dot(worldLightVector,z));
   return r;
 }
 float t(vec3 y,vec3 z,vec3 f,int x)
 {
   if(rainStrength>.99)
     return 0.f;
   vec3 i=v(y);
   float s=.5,r=shadow2DLod(shadow,vec3(i.xy,i.z-.0006*s),0).x;
   r*=saturate(dot(worldLightVector,z));
   return r*(1.-rainStrength);
 }
 vec3 e()
 {
   vec3 v=cameraPosition.xyz+.5-Fract01(cameraPosition.xyz+.5),i=previousCameraPosition+.5-Fract01(previousCameraPosition+.5);
   return v-i;
 }
 vec3 e(vec3 y,vec3 z)
 {
   vec2 v=wvLPci(jXfIYx(bqzMKV(y)+z+1.));
   vec3 f=ZrrDhC(v).kLqMlH;
   return f;
 }
 vec3 t()
 {
   vec2 v=wvLPci(jrwNAE(texcoord.xy)+e()/VpEHlC());
   vec3 z=ZrrDhC(v).kLqMlH;
   return z;
 }
 bool t(ivec3 y,BBRay f)
 {
   vec3 z=vec3(y),i=vec3(y)+1.,x=mix(z,i,vec3(.5));
   float s=mix(.25,0.,saturate(distance(f.origin,x)*.5-1.));
   vec3 r[2]=vec3[2](mix(z,i,vec3(s)),mix(z,i,vec3(1.-s)));
   float w,n;
   v(f,r,w,n);
   return w<=n;
 }
 vec3 x(float y,float v,float z,vec3 f)
 {
   vec3 i;
   i.x=z*cos(y);
   i.y=z*sin(y);
   i.z=v;
   vec3 s=abs(f.y)<.999?vec3(0,0,1):vec3(1,0,0),x=normalize(cross(f,vec3(0.,1.,1.))),w=cross(x,f);
   return x*i.x+w*i.y+f*i.z;
 }
 vec3 t(vec2 v,float f,vec3 y)
 {
   float z=2*3.14159*v.x,i=sqrt((1-v.y)/(1+(f*f-1)*v.y)),r=sqrt(1-i*i);
   return x(z,i,r,y);
 }
 float x(float v)
 {
   return 2./(v*v+1e-07)-2.;
 }
 vec3 v(in vec2 v,in float y,in vec3 f)
 {
   float z=x(y),i=2*3.14159*v.x,r=pow(v.y,1.f/(z+1.f)),w=sqrt(1-r*r);
   return x(i,r,w,f);
 }
 float x(float v,float y)
 {
   return 1./(v*(1.-y)+y);
 }
 void f(inout vec3 v,in vec3 y)
 {
   vec3 z=normalize(y.xyz),f=v;
   float i=dot(f,z);
   f=normalize(v-z*saturate(i)*.5);
   v=f;
 }
 float f(in vec2 v)
 {
   return texture2D(depthtex1,v.xy).x;
 }
 vec4 d(in vec2 v)
 {
   float z=f(v);
   vec4 i=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*z-1.f,1.f);
   i/=i.w;
   return i;
 }
 vec4 d(in vec2 v,in float y)
 {
   vec4 f=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*y-1.f,1.f);
   f/=f.w;
   return f;
 }
 vec3 s(vec3 y)
 {
   vec4 v=gbufferProjection*vec4(y,1.);
   vec3 z=v.xyz/v.w,f=.5*z+.5;
   return f;
 }
 void d(inout vec3 v,in vec3 y,in vec3 z,vec3 f,float i)
 {
   float s=length(y);
   #ifdef FADE_TO_ATMOSPHERE
   float r=length(y)/far;
   r=pow(r,6.)*.07+pow(r,2.)*.003;
   #else
   float x=length(y)/300.;
   x=pow(x,3.)*.002;
   #endif
   x*=pow(eyeBrightnessSmooth.y/240.f,6.f);
   x=clamp(x,0.,.03);
   x/=saturate(f.y)*2.+1.;
   vec3 w=vec3(.2,.45,1.);
   v*=exp(-x*w*100.67);
   v+=AtmosphericScattering(normalize(f),worldSunVector,1.,x)*.9*mix(i,1.,.5)*mix(1.,.35,wetness)*.001;
 }
 void e(inout vec3 v,in vec3 y,in vec3 z,vec3 f,float x)
 {
   float i=length(y);
   i*=pow(eyeBrightnessSmooth.y/240.f,6.f);
   i*=rainStrength;
   float r=pow(exp(-i*1e-05),4.);
   r=max(r,.5);
   vec3 s=vec3(dot(skyUpColor,vec3(1.)))*.05;
   v=mix(s,v,vec3(r));
 }
 vec4 d(float z,float r,vec3 y,vec3 i,vec3 w,vec3 n,vec3 d,float l,float g)
 {
   float c=1.;
   #ifdef SUNLIGHT_LEAK_FIX
   c=saturate(g*100.);
   #endif
   z=max(z-.05,0.);
   r=0.;
   float m=z*z,o=fract(frameCounter*.0123456);
   vec3 p=t(texcoord.xy).xyz*.99+.005,h=t(texcoord.xy+.1).xyz,G=reflect(d,v(p.xy,m,w));
   if(dot(G,w)<0.)
     G=reflect(G,w);
   #ifdef REFLECTION_SCREEN_SPACE_TRACING
   bool a=false;
   {
     const int R=8;
     float b=.25*-i.z;
     b=mix(b,.8,.5)*2.;
     float B=.07*-i.z;
     B=mix(B,1.,.5);
     B=.6;
     vec2 T=texcoord.xy;
     vec3 j=i.xyz,P=normalize((gbufferModelView*vec4(G.xyz,0.)).xyz);
     float S=0.;
     for(int D=0;D<R;D++)
       {
         float F=float(D),H=(F+.5)/float(R);
         S=b*H;
         vec3 N=i.xyz+P*S;
         vec2 C=s(N).xy;
         TemporalJitterProjPos01(C);
         vec3 Z=GetViewPosition(C.xy,f(C.xy)).xyz;
         float u=length(N)-length(Z)-.02;
         if(u>0.&&u<B&&C.x>0.&&C.x<1.&&C.y>0.&&C.y<1.)
           {
             a=true;
             T=C.xy;
             j=Z.xyz;
             break;
           }
       }
     vec3 D=(gbufferModelViewInverse*vec4(j,1.)).xyz;
     D+=Fract01(cameraPosition.xyz+.5)+.5;
     if(a)
       {
         vec3 C=pow(texture2DLod(composite,T.xy,0).xyz,vec3(2.2));
         S*=saturate(dot(-d,w))*2.;
         return vec4(C*80.,S/4.);
       }
   }
   #endif
   vec3 D=y+w*(.001+l*.1);
   D+=Fract01(cameraPosition.xyz+.5);
   vec3 B=D;
   D=xkpggD(D);
   int C=Tsmicx(),T=VpEHlC();
   Ray S;
   S.origin=D*C-vec3(1.,1.,1.);
   S.dir=G;
   BBRay j=v(S.origin,S.dir);
   vec3 b=vec3(1.),P=vec3(0.);
   float N=0.;
   for(int R=0;R<1;R++)
     {
       vec3 F=vec3(floor(S.origin)),H=abs(vec3(length(S.dir))/(S.dir+.0001)),k=sign(S.dir),Z=(sign(S.dir)*(F-S.origin)+sign(S.dir)*.5+.5)*H,u;
       vec4 M=vec4(0.);
       vec3 L=vec3(0.);
       float I=.5;
       for(int E=0;E<REFLECTION_TRACE_LENGTH;E++)
         {
           L=F/float(C);
           vec2 A=PoXKdv(L,C);
           M=texture2DLod(shadowcolor,A,0);
           if(abs(M.w*255.-130.)<.5)
             {
               float V=dot(F+.5-S.origin,F+.5-S.origin),O=saturate(pow(saturate(dot(S.dir,normalize(F+.5-S.origin))),56.*V)*5.-1.)*5.;
               P+=.01525*b*colorTorchlight*I*O*GI_LIGHT_TORCH_INTENSITY;
             }
           else
             {
               if(M.w*255.<254.f&&E!=0)
                 {
                   break;
                 }
             }
           u=step(Z.xyz,Z.yzx)*step(Z.xyz,Z.zxy);
           Z+=u*H;
           F+=u*k;
           I=1.;
         }
       if(M.w*255.<1.f||M.w*255.>254.f)
         {
           vec3 E=max(vec3(0.),AtmosphericScattering(S.dir,worldSunVector,1.));
           E=ModulateSkyForRain(E,colorSkylight,rainStrength);
           E*=b;
           E*=saturate(dot(S.dir,vec3(0.,1.,0.))*100.)*.9+.1;
           P+=E*.1;
           N=1000.;
           break;
         }
       vec3 E=-(u*k),A[2]=vec3[2](F,F+1.);
       float V,Y;
       v(j,A,V,Y);
       N=V;
       vec3 O=mod(S.origin+S.dir*V,vec3(1.))-.5;
       vec2 q=vec2(0.);
       q+=vec2(O.z*k.x,-O.y)*u.x;
       q+=vec2(O.x,-O.z*k.y)*u.y;
       q+=vec2(-O.x*k.z,-O.y)*u.z;
       vec3 U=(S.origin+S.dir*V)/float(C);
       vec2 X=textureSize(gcolor,0);
       vec4 W=texture2DLod(shadowcolor1,PoXKdv(L,C),0);
       vec2 K=W.xy;
       K=(floor(K*X/TEXTURE_RESOLUTION)+.5)/(X/TEXTURE_RESOLUTION);
       vec2 J=K+q.xy*(TEXTURE_RESOLUTION/X);
       vec3 Q=pow(texture2D(gcolor,J).xyz,vec3(2.2));
       Q*=mix(vec3(1.),M.xyz/(W.w+1e-05),vec3(W.z));
       if(M.w*255.>1.f&&M.w*255.<128.f)
         {
           vec3 ab=saturate(M.xyz);
           b*=Q;
         }
       if(M.w*255.>131.&&M.w*255.<137.&&M.w*255.!=134.)
         b*=Q,P+=.05*b*GI_LIGHT_BLOCK_INTENSITY;
       vec3 ac=vec3(0.),ad=vec3(0.);
       if(abs(E.x)>.5)
         ac=vec3(0.,1.,0.),ad=vec3(0.,0.,1.);
       if(abs(E.y)>.5)
         ac=vec3(1.,0.,0.),ad=vec3(0.,0.,1.);
       if(abs(E.z)>.5)
         ac=vec3(1.,0.,0.),ad=vec3(0.,1.,0.);
       ac*=1.;
       ad*=1.;
       vec3 ae=e(L,E);
       ae+=e(L+ac/float(C),E);
       ae+=e(L-ac/float(C),E);
       ae+=e(L+ad/float(C),E);
       ae+=e(L-ad/float(C),E);
       ae*=.2;
       P+=ae*b;
       const float af=2.4;
       P+=t(B+S.dir*V-1.,E,G,C)*b*af*colorSunlight*c;
     }
   P*=1.;
   vec3 E=normalize(i.xyz)*(length(i.xyz)+N);
   e(P,E,normalize(i.xyz),normalize(y.xyz),1.);
   vec3 R=normalize(-d+G);
   float L=saturate(dot(w,G)),F=saturate(dot(w,-d)),A=saturate(dot(w,R)),O=saturate(dot(G,R)),Z=r*.98+.02,V=pow(1.-O,5.),H=Z+(1.-Z)*V,u=m/2.,M=x(L,u)*x(F+.8,u);
   N*=saturate(dot(-d,w))*2.;
   return vec4(P,saturate(N/4.));
 }
 vec4 n(float v)
 {
   float z=v*v,i=z*v;
   vec4 f;
   f.x=-i+3*z-3*v+1;
   f.y=3*i-6*z+4;
   f.z=-3*i+3*z+3*v+1;
   f.w=i;
   return f/6.f;
 }
 vec4 n(in sampler2D v,in vec2 f)
 {
   vec2 z=vec2(viewWidth,viewHeight);
   f*=z;
   f-=.5;
   float y=fract(f.x),i=fract(f.y);
   f.x-=y;
   f.y-=i;
   vec4 S=n(y),w=n(i),s=vec4(f.x-.5,f.x+1.5,f.y-.5,f.y+1.5),r=vec4(S.x+S.y,S.z+S.w,w.x+w.y,w.z+w.w),d=s+vec4(S.y,S.w,w.y,w.w)/r,x=texture2DLod(v,vec2(d.x,d.z)/z,0),a=texture2DLod(v,vec2(d.y,d.z)/z,0),E=texture2DLod(v,vec2(d.x,d.w)/z,0),t=texture2DLod(v,vec2(d.y,d.w)/z,0);
   float C=r.x/(r.x+r.y),u=r.z/(r.z+r.w);
   return mix(mix(t,E,C),mix(a,x,C),u);
 }
 bool s(vec3 y,vec3 v)
 {
   vec3 f=normalize(cross(dFdx(y),dFdy(y))),i=normalize(v-y),z=normalize(i);
   return distance(y,v)<.05;
 }
 vec3 w(vec2 v)
 {
   vec2 z=vec2(viewWidth,viewHeight),i=1./z,f=v*z,y=floor(f-.5)+.5,r=f-y,x=r*r,w=r*x;
   float s=.5;
   vec2 d=-s*w+2.*s*x-s*r,n=(2.-s)*w-(3.-s)*x+1.,a=-(2.-s)*w+(3.-2.*s)*x+s*r,S=s*w-s*x,C=n+a,t=i*(y+a/C);
   vec3 E=texture2DLod(gaux1,vec2(t.x,t.y),0).xyz;
   vec2 M=i*(y-1.),u=i*(y+2.);
   vec4 Z=vec4(texture2DLod(gaux1,vec2(t.x,M.y),0).xyz,1.)*(C.x*d.y)+vec4(texture2DLod(gaux1,vec2(M.x,t.y),0).xyz,1.)*(d.x*C.y)+vec4(E,1.)*(C.x*C.y)+vec4(texture2DLod(gaux1,vec2(u.x,t.y),0).xyz,1.)*(S.x*C.y)+vec4(texture2DLod(gaux1,vec2(t.x,u.y),0).xyz,1.)*(C.x*S.y);
   return max(vec3(0.),Z.xyz*(1./Z.w));
 }
 void main()
 {
   GBufferData v=GetGBufferData();
   GBufferDataTransparent f=GetGBufferDataTransparent();
   MaterialMask i=CalculateMasks(v.materialID),S=CalculateMasks(f.materialID);
   bool y=f.depth<v.depth;
   if(y)
     v.depth=f.depth,v.normal=f.normal,v.smoothness=f.smoothness,v.metalness=0.,v.mcLightmap=f.mcLightmap,S.sky=0.;
   vec4 r=GetViewPosition(texcoord.xy,v.depth),w=gbufferModelViewInverse*vec4(r.xyz,1.),C=gbufferModelViewInverse*vec4(r.xyz,0.);
   vec3 z=normalize(r.xyz),n=normalize(C.xyz),x=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz),a=normalize((gbufferModelViewInverse*vec4(v.geoNormal,0.)).xyz);
   float s=length(r.xyz);
   vec4 t=vec4(0.);
   float E=UymEaA(v.smoothness,v.metalness);
   if(E>.0001&&S.sky<.5)
     t=d(1.-v.smoothness,v.metalness,w.xyz,r.xyz,x.xyz,a,n.xyz,i.leaves,v.mcLightmap.y);
   vec4 M=texture2DLod(composite,texcoord.xy,0);
   M.xyz=pow(M.xyz,vec3(2.2));
   if(y)
     {
       vec3 g=GetViewPosition(texcoord.xy,texture2DLod(depthtex1,texcoord.xy,0).x).xyz;
       float m=length(g.xyz),F=m-s;
       vec3 Z=f.normal-f.geoNormal*1.05;
       float c=saturate(F*.5);
       vec2 u=texcoord.xy+Z.xy/(s+.2)*c;
       M.xyz=pow(texture2DLod(composite,u.xy,0).xyz,vec3(2.2));
       g=GetViewPosition(u.xy,texture2DLod(depthtex1,u.xy,0).x).xyz;
       r=GetViewPosition(u.xy,texture2DLod(gdepthtex,u.xy,0).x);
       m=length(g.xyz);
       s=length(r.xyz);
       F=m-s;
       if(S.water>.5)
         {
           M.xyz*=exp(vec3(1.,.4,.1)*-(F+2.1)*.2);
           vec3 b=vec3(.2,.8,.8)*.0001;
           b=(b*colorSunlight*.5+b*colorSkylight)*f.mcLightmap.y;
           M.xyz=mix(b,M.xyz,vec3(exp(-F*.2)));
           t.xyz*=.8;
         }
       if(S.stainedGlass>.5)
         {
           vec3 B=normalize(f.albedo.xyz+.0001)*pow(length(f.albedo.xyz),.5);
           M.xyz*=mix(vec3(1.),B,vec3(pow(f.albedo.w,.2)));
           M.xyz*=mix(vec3(1.),B,vec3(pow(f.albedo.w,.2)));
         }
     }
   M.xyz=pow(M.xyz,vec3(1./2.2));
   gl_FragData[0]=texture2DLod(gcolor,texcoord.xy,0);
   gl_FragData[1]=vec4(M.xyz,v.smoothness);
   gl_FragData[2]=t;
 };
/* DRAWBUFFERS:036 */