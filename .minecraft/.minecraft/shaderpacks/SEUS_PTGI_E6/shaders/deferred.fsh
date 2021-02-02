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

/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//#define HALF_RES_TRACE

/////////INTERNAL VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////INTERNAL VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Do not change the name of these variables or their type. The Shaders Mod reads these lines and determines values to send to the inner-workings
//of the shaders mod. The shaders mod only reads these lines and doesn't actually know the real value assigned to these variables in GLSL.
//Some of these variables are critical for proper operation. Change at your own risk.

const float 	shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 180.0 240.0]
const bool 		shadowHardwareFiltering0 = true;



const int 		noiseTextureResolution  = 64;

const bool gaux1Clear = false;
const bool gaux2Clear = false;
//END OF INTERNAL VARIABLES//



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

in vec3 upVector;

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











#include "FQQrsH.inc"
#include "GBufferData.inc"

vec3 t(vec3 y)
 {
   vec4 v=vec4(y,1.);
   v.xyz+=.5;
   v.xyz-=Fract01(cameraPosition.xyz+.5)-.5;
   v=shadowModelView*v;
   float f=-v.z;
   v=shadowProjection*v;
   v/=v.w;
   float x=sqrt(v.x*v.x+v.y*v.y),z=1.f-SHADOW_MAP_BIAS+x*SHADOW_MAP_BIAS;
   v.xy*=.95f/z;
   v.z=mix(v.z,.5,.8);
   v=v*.5f+.5f;
   v.xy*=.5;
   v.xy+=.5;
   return v.xyz;
 }struct Ray{vec3 dir;vec3 origin;};struct BBRay{vec3 origin;vec3 direction;vec3 inv_direction;ivec3 sign;};
 BBRay t(vec3 v,vec3 y)
 {
   vec3 f=vec3(1.)/y;
   return BBRay(v,y,f,ivec3(f.x<0?1:0,f.y<0?1:0,f.z<0?1:0));
 }
 void t(in BBRay v,in vec3 f[2],out float r,out float y)
 {
   float z,t,x,i;
   r=(f[v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   y=(f[1-v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   z=(f[v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   t=(f[1-v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   x=(f[v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   i=(f[1-v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   r=max(max(r,z),x);
   y=min(min(y,t),i);
 }
 vec2 v(inout float v)
 {
   return fract(sin(vec2(v+=.1,v+=.1))*vec2(43758.5,22578.1));
 }
 float d(vec2 v)
 {
   v*=vec2(viewWidth,viewHeight);
   const float f=1.61803,y=1.32472;
   return fract(dot(v,1./vec2(f,y*y)));
 }
 vec3 f(vec2 v)
 {
   vec2 f=vec2(v.xy*vec2(viewWidth,viewHeight))/64.;
   const vec2 m[16]=vec2[16](vec2(-1,-1),vec2(0,-.333333),vec2(-.5,.333333),vec2(.5,-.777778),vec2(-.75,-.111111),vec2(.25,.555556),vec2(-.25,-.555556),vec2(.75,.111111),vec2(-.875,.777778),vec2(.125,-.925926),vec2(-.375,-.259259),vec2(.625,.407407),vec2(-.625,-.703704),vec2(.375,-.037037),vec2(-.125,.62963),vec2(.875,-.481482));
   if(v.x<2./viewWidth||v.x>1.-2./viewWidth||v.y<2./viewHeight||v.y>1.-2./viewHeight)
     ;
   else
      f+=m[int(mod(frameCounter,8))]*.5;
   f=(floor(f*64.)+.5)/64.;
   vec3 r=texture2D(noisetex,f).xyz,t=vec3(sqrt(.2),sqrt(2.),1.61803);
   r.x=(r.x>.5?1.-r.x:r.x)*2.;
   r.y=(r.y>.5?1.-r.y:r.y)*2.;
   r.z=(r.z>.5?1.-r.z:r.z)*2.;
   return r;
 }
 vec3 d(vec3 v,inout float z,int y)
 {
   vec2 r=f(texcoord.xy+vec2(0.,0.)).xy;
   float t=6.28319*r.x,x=sqrt(r.y);
   vec3 m=normalize(cross(v,vec3(0.,1.,1.))),e=cross(v,m),i=m*cos(t)*x+e*sin(t)*x+v.xyz*sqrt(1.-r.y);
   return i;
 }
 vec3 e(inout float y)
 {
   vec3 r=f(texcoord.xy).xyz;
   r=fract(r+vec3(v(y),v(y).x)*.1);
   r=r*2.-1.;
   r=normalize(r);
   return r;
 }
 float d(vec3 v,vec3 y,vec3 z,int f)
 {
   if(rainStrength>.99)
     return 0.f;
   vec3 r=bqzMKV(v),i=t(r+y*.99);
   float x=.5,e=shadow2DLod(shadow,vec3(i.xy,i.z-.0006*x),3).x;
   e*=saturate(dot(worldLightVector,y));
   return e*(1.-rainStrength);
 }
 float e(vec3 v,vec3 y,vec3 z,int f)
 {
   if(rainStrength>.99)
     return 0.f;
   vec3 r=t(v);
   float x=.5,i=shadow2DLod(shadow,vec3(r.xy,r.z-.0006*x),2).x;
   i*=saturate(dot(worldLightVector,y));
   return i*(1.-rainStrength);
 }
 vec3 d()
 {
   vec3 f=cameraPosition.xyz+.5-Fract01(cameraPosition.xyz+.5),v=previousCameraPosition+.5-Fract01(previousCameraPosition+.5);
   return f-v;
 }
 vec3 d(vec3 v,vec3 y)
 {
   vec2 f=wvLPci(jXfIYx(bqzMKV(v)+y+1.+d()));
   vec3 r=ZrrDhC(f).kLqMlH;
   return r;
 }
 vec3 e()
 {
   vec2 v=wvLPci(jrwNAE(texcoord.xy)+d()/VpEHlC());
   vec3 f=ZrrDhC(v).kLqMlH;
   return f;
 }
 bool e(ivec3 v,BBRay y)
 {
   vec3 f=vec3(v),r=vec3(v)+1.,x=mix(f,r,vec3(.5));
   float z=mix(.25,0.,saturate(distance(y.origin,x)*.5-1.));
   vec3 i[2]=vec3[2](mix(f,r,vec3(z)),mix(f,r,vec3(1.-z)));
   float s,m;
   t(y,i,s,m);
   return s<=m;
 }
 float s(in vec2 v)
 {
   return texture2D(depthtex1,v.xy).x;
 }
 vec4 f(in vec2 v,in float y)
 {
   vec4 f=gbufferProjectionInverse*vec4(v.x*2.f-1.f,v.y*2.f-1.f,2.f*y-1.f,1.f);
   f/=f.w;
   return f;
 }
 vec3 n(vec3 v)
 {
   vec4 f=gbufferProjection*vec4(v,1.);
   vec3 r=f.xyz/f.w,y=.5*r+.5;
   return y;
 }
 vec3 d(vec3 v,vec3 r,vec3 y,vec3 z,vec3 x,MaterialMask i,float w,vec2 m,float g,out float c)
 {
   float o=fract(frameCounter*.0123456);
   c=0.;
   float G=1.;
   #ifdef SUNLIGHT_LEAK_FIX
   G=saturate(w*100.);
   #endif
   vec3 V=d(z,o,0);
   #ifdef GI_SCREEN_SPACE_TRACING
   bool S=false;
   {
     const int W=8;
     float a=.25*-r.z;
     a=mix(a,.8,.5);
     float h=.07*-r.z;
     h=mix(h,1.,.5);
     h=.4;
     vec2 B=texcoord.xy;
     vec3 l=r.xyz,A=normalize((gbufferModelView*vec4(V.xyz,0.)).xyz);
     for(int T=0;T<W;T++)
       {
         float p=float(T),k=(p+.5)/float(W),R=a*k;
         vec3 D=r.xyz+A*R,F=n(D),M=f(F.xy,s(F.xy)).xyz;
         float u=length(D)-length(M)-.02;
         if(u>0.&&u<h)
           {
             S=true;
             B=F.xy;
             l=M.xyz;
             break;
           }
       }
     vec3 T=(gbufferModelViewInverse*vec4(l,1.)).xyz;
     T+=Fract01(cameraPosition.xyz+.5)+.5;
     if(S)
       {
         vec3 b=pow(texture2DLod(gaux4,B.xy-m*.5,0).xyz,vec3(2.2));
         b*=1.-saturate(g*1.1);
         return b*80.;
       }
   }
   #endif
   if(i.leaves>.5)
     ;
   vec3 T=v+y*(.001-i.leaves*.01);
   T+=Fract01(cameraPosition.xyz+.5);
   vec3 W=T;
   T=xkpggD(T);
   int h=Tsmicx();
   Ray B;
   B.origin=T*h-vec3(1.,1.,1.);
   B.dir=V;
   BBRay l=t(B.origin,B.dir);
   vec3 a=vec3(1.),b=vec3(0.);
   float u=0.;
   for(int A=0;A<1;A++)
     {
       vec3 F=vec3(floor(B.origin)),k=abs(vec3(length(B.dir))/(B.dir+.0001)),D=sign(B.dir),p=(sign(B.dir)*(F-B.origin)+sign(B.dir)*.5+.5)*k,M;
       vec4 R=vec4(0.);
       vec3 Y=vec3(0.);
       float I=.5;
       for(int L=0;L<DIFFUSE_TRACE_LENGTH;L++)
         {
           Y=F/float(h);
           vec2 C=PoXKdv(Y,h);
           R=texture2DLod(shadowcolor,C,0);
           u=R.w*255.;
           bool P=abs(u-134.)<.5,E=abs(u-130.)<.5,H=abs(u-140.)<.5,N=abs(u-141)<.5;
           if(P||E||H||N)
             {
               {
                 vec3 O=mix(colorTorchlight,vec3(1.,.1,0.)*.1,float(P));
                 O=mix(O,vec3(1.,.3,.05)*5.,float(H));
                 b+=.01525*a*O*I*GI_LIGHT_TORCH_INTENSITY;
                 c=1.;
               }
             }
           else
             {
               if(u<254.f&&L!=0)
                 {
                   break;
                 }
             }
           M=step(p.xyz,p.yzx)*step(p.xyz,p.zxy);
           p+=M*k;
           F+=M*D;
           I=1.;
         }
       if(u<1.f||u>254.f)
         {
           #ifdef GI_SIMPLE_SKY_TERM
           vec3 O=max(vec3(0.),FromSH(skySHR,skySHG,skySHB,B.dir))*3.;
           #else
           vec3 O=max(vec3(0.),AtmosphericScattering(B.dir,worldSunVector,1.));
           #endif
           O+=vec3(.5,.8,1.)*.001;
           O=ModulateSkyForRain(O,colorSkylight,rainStrength);
           O*=a;
           O*=saturate(dot(B.dir,vec3(0.,1.,0.))*100.)*.9+.1;
           O=DoNightEyeAtNight(O*12.,timeMidnight)/12.;
           c=1.;
           b+=O*.1;
           break;
         }
       if(u>1.f&&u<128.f)
         {
           vec3 L=saturate(R.xyz);
           a*=L;
         }
       if(u>131.&&u<137.)
         b+=.05*a*R.xyz*GI_LIGHT_BLOCK_INTENSITY,c=1.;
       vec3 L=-(M*D);
       b+=d(Y,L)*a*2.;
       vec3 C[2]=vec3[2](F,F+1.);
       float O,H;
       t(l,C,O,H);
       const float P=2.4;
       float E=e(W+B.dir*O-1.,L,V,h);
       b+=DoNightEyeAtNight(E*a*P*colorSunlight*G*12.,timeMidnight)/12.;
       c+=E;
     }
   b/=saturate(dot(z,V))+.01;
   b*=saturate(dot(y,V));
   c=saturate(c);
   return b;
 }
 vec3 f()
 {
   vec3 v=jrwNAE(texcoord.xy),f=lfDeyJ(v),y=xkpggD(f-vec3(1.,1.,0.));
   vec2 r=PoXKdv(y);
   float z=1000.;
   z=min(z,texture2DLod(shadowcolor,PoXKdv(xkpggD(f-vec3(0.,0.,0.)))+vec2(.5,.5)/float(CsiWWB),0).w);
   z=min(z,texture2DLod(shadowcolor,PoXKdv(xkpggD(f-vec3(0.,0.,0.)))+vec2(-.5,-.5)/float(CsiWWB),0).w);
   z=min(z,texture2DLod(shadowcolor,PoXKdv(xkpggD(f-vec3(0.,1.,0.)))+vec2(0.,0.)/float(CsiWWB),0).w);
   z=min(z,texture2DLod(shadowcolor,PoXKdv(xkpggD(f-vec3(0.,-1.,0.)))+vec2(0.,0.)/float(CsiWWB),0).w);
   float x=texture2DLod(shadowcolor,PoXKdv(xkpggD(f-vec3(0.,0.,0.))),0).w;
   if(z*255>254||x*255<254)
     return vec3(0.);
   vec3 i=vec3(0.);
   for(int b=0;b<GI_SECONDARY_SAMPLES;b++)
     {
       float t=sin(frameTimeCounter*1.1)+f.x*.11+f.y*.12+f.z*.13+b*.1;
       vec3 m=normalize(rand(vec2(t))*2.-1.);
       m.x+=m.x==m.y||m.x==m.z?.01:0.;
       m.y+=m.y==m.z?.01:0.;
       vec3 s=f+vec3(1.,1.,1.);
       s=xkpggD(s);
       int c=Tsmicx();
       Ray B;
       B.origin=s*c-vec3(1.,1.,1.);
       B.dir=m;
       vec3 a=vec3(1.);
       for(int T=0;T<1;T++)
         {
           vec3 n=vec3(floor(B.origin)),p=n,w=abs(vec3(length(B.dir))/(B.dir+.0001)),h=sign(B.dir),L=(sign(B.dir)*(n-B.origin)+sign(B.dir)*.5+.5)*w,e;
           vec4 g=vec4(0.);
           float u=0.;
           vec3 l=vec3(0.);
           for(int A=0;A<DIFFUSE_TRACE_LENGTH;A++)
             {
               l=n/float(c);
               vec2 o=PoXKdv(l,c);
               g=texture2DLod(shadowcolor,o,0);
               u=g.w*255.;
               bool W=abs(u-134.)<.5,V=abs(u-130.)<.5,F=abs(u-140.)<.5;
               if(V||W||F)
                 {
                   vec3 G=mix(colorTorchlight,vec3(1.,.1,0.)*.1,float(W));
                   G=mix(G,vec3(1.,.3,.05)*5.,float(F));
                   i+=.01525*a*G*GI_LIGHT_TORCH_INTENSITY;
                 }
               else
                 {
                   if(u<254.f)
                     {
                       break;
                     }
                 }
               e=step(L.xyz,L.yzx)*step(L.xyz,L.zxy);
               L+=e*w;
               n+=e*h;
             }
           float G=1.;
           if(abs(n.x-p.x)<2||abs(n.y-p.y)<2||abs(n.z-p.z)<2)
             G=0.;
           if(u<1.f||u>254.f)
             {
               #ifdef GI_SIMPLE_SKY_TERM
               vec3 A=max(vec3(0.),FromSH(skySHR,skySHG,skySHB,B.dir))*3.;
               #else
               vec3 A=max(vec3(0.),AtmosphericScattering(B.dir,worldSunVector,1.));
               #endif
               A+=vec3(.5,.8,1.)*.001;
               A=ModulateSkyForRain(A,colorSkylight,rainStrength);
               A*=a;
               A*=saturate(dot(B.dir,vec3(0.,1.,0.))*100.)*.9+.1;
               A=DoNightEyeAtNight(A*12.,timeMidnight)/12.;
               i+=A*.1;
               break;
             }
           if(u>1.f&&u<128.f)
             {
               vec3 W=saturate(g.xyz);
               a*=W;
             }
           if(u>131.&&u<137.)
             i+=.05*a*g.xyz*GI_LIGHT_BLOCK_INTENSITY;
           vec3 o=-(e*h);
           const float W=2.4;
           i+=DoNightEyeAtNight(d(l,o,m,c)*W*colorSunlight*a*G*12.,timeMidnight)/12.;
           i+=d(l,o)*a;
         }
     }
   i/=float(GI_SECONDARY_SAMPLES);
   return saturate(i);
 }
 vec4 x(vec2 v)
 {
   vec3 f=jrwNAE(v),y=lfDeyJ(f),t=xkpggD(y);
   vec2 r=PoXKdv(t);
   vec4 z=texture2DLod(shadowcolor,r,0);
   return z;
 }
 vec4 m(float v)
 {
   float f=v*v,m=f*v;
   vec4 r;
   r.x=-m+3*f-3*v+1;
   r.y=3*m-6*f+4;
   r.z=-3*m+3*f+3*v+1;
   r.w=m;
   return r/6.f;
 }
 vec4 m(in sampler2D v,in vec2 f)
 {
   vec2 z=vec2(viewWidth,viewHeight);
   f*=z;
   f-=.5;
   float y=fract(f.x),t=fract(f.y);
   f.x-=y;
   f.y-=t;
   vec4 r=m(y),B=m(t),s=vec4(f.x-.5,f.x+1.5,f.y-.5,f.y+1.5),n=vec4(r.x+r.y,r.z+r.w,B.x+B.y,B.z+B.w),i=s+vec4(r.y,r.w,B.y,B.w)/n,x=texture2DLod(v,vec2(i.x,i.z)/z,0),c=texture2DLod(v,vec2(i.y,i.z)/z,0),o=texture2DLod(v,vec2(i.x,i.w)/z,0),u=texture2DLod(v,vec2(i.y,i.w)/z,0);
   float h=n.x/(n.x+n.y),w=n.z/(n.z+n.w);
   return mix(mix(u,o,h),mix(c,x,h),w);
 }
 bool n(vec3 v,vec3 f)
 {
   vec3 r=normalize(cross(dFdx(v),dFdy(v))),y=normalize(f-v),i=normalize(y);
   float z=.25+length(v)*.04;
   return distance(v,f)<z;
 }
 vec3 w(vec2 v)
 {
   vec2 z=vec2(viewWidth,viewHeight),m=1./z,f=v*z,r=floor(f-.5)+.5,y=f-r,x=y*y,i=y*x;
   float t=.5;
   vec2 B=-t*i+2.*t*x-t*y,s=(2.-t)*i-(3.-t)*x+1.,o=-(2.-t)*i+(3.-2.*t)*x+t*y,n=t*i-t*x,c=s+o,u=m*(r+o/c);
   vec3 W=texture2DLod(gaux1,vec2(u.x,u.y),0).xyz;
   vec2 d=m*(r-1.),L=m*(r+2.);
   vec4 p=vec4(texture2DLod(gaux1,vec2(u.x,d.y),0).xyz,1.)*(c.x*B.y)+vec4(texture2DLod(gaux1,vec2(d.x,u.y),0).xyz,1.)*(B.x*c.y)+vec4(W,1.)*(c.x*c.y)+vec4(texture2DLod(gaux1,vec2(L.x,u.y),0).xyz,1.)*(n.x*c.y)+vec4(texture2DLod(gaux1,vec2(u.x,L.y),0).xyz,1.)*(c.x*n.y);
   return max(vec3(0.),p.xyz*(1./p.w));
 }
 vec2 d(float v,vec2 r,out float f,out vec2 y,out vec4 B)
 {
   float z;
   vec2 t=GetNearFragment(texcoord.xy,v,z);
   f=texture2D(depthtex1,t).x;
   vec4 m=vec4(texcoord.xy*2.-1.,f*2.-1.,1.),i=gbufferProjectionInverse*m;
   i.xyz/=i.w;
   vec4 s=gbufferModelViewInverse*vec4(i.xyz,1.);
   B=s;
   B.xyz+=cameraPosition-previousCameraPosition;
   vec4 n=gbufferPreviousModelView*vec4(B.xyz,1.),c=gbufferPreviousProjection*vec4(n.xyz,1.);
   c.xyz/=c.w;
   y=m.xy-c.xy;
   float W=length(y)*10.,x=clamp(W*500.,0.,1.);
   vec2 L=r.xy-y.xy*.5;
   if(f<.7)
     L=texcoord.xy;
   return L;
 }
 void main()
 {
   GBufferData v=GetGBufferData();
   MaterialMask r=CalculateMasks(v.materialID);
   vec4 B=GetViewPosition(texcoord.xy,v.depth),i=gbufferModelViewInverse*vec4(B.xyz,1.),t=gbufferModelViewInverse*vec4(B.xyz,0.);
   vec3 y=normalize(B.xyz),c=normalize(t.xyz),m=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz),z=normalize((gbufferModelViewInverse*vec4(v.geoNormal,0.)).xyz);
   float x=length(B.xyz),s=dot(v.mcLightmap.xy,vec2(.5));
   if(r.grass>.5)
     m=vec3(0.,1.,0.);
   vec4 L=vec4(texcoord.xy,0.,0.);
   float h;
   vec2 o;
   vec4 u;
   vec2 W=d(v.depth,L.xy,h,o,u),p=W.xy;
   p-=(vec2(mod(frameCounter/2,2),mod(frameCounter,2))-.5)/vec2(viewWidth,viewHeight)*1.5;
   vec3 l=w(p.xy);
   TcZnFJ g=ZrrDhC(W.xy);
   float a=1./(saturate(-dot(v.geoNormal,y))*100.+1.);
   vec4 F=vec4(W.xy,0.,0.);
   TemporalJitterProjPosPrevInv(F);
   vec4 T=gbufferPreviousProjectionInverse*vec4(W.xy*2.-1.,texture2DLod(gaux1,F.xy,0).w*2.-1.,1.);
   T/=T.w;
   vec3 V=(gbufferPreviousModelViewInverse*vec4(T.xyz,1.)).xyz;
   g.tBefeN+=1.;
   g.tBefeN=min(g.tBefeN,2.);
   vec2 G=1./vec2(viewWidth,viewHeight),A=1.-G;
   float O=0.,S=1.-exp2(-g.tBefeN);
   if(!n(u.xyz,V.xyz)||(W.x<G.x||W.x>A.x||W.y<G.y||W.y>A.y)||abs(a-g.vILDot)>.01)
     S=0.,O=.99,g.tBefeN=0.;
   float k;
   vec3 b=d(i.xyz,B.xyz,m.xyz,z,c.xyz,r,v.mcLightmap.y,o,O,k);
   b=mix(b,l,vec3(S));
   g.vILDot=a;
   g.JKJbuS=mix(g.JKJbuS,O,mix(.5,1.,O));
   g.RXCGFO=s;
   vec3 R=f();
   g.kLqMlH=mix(e(),R,vec3(.015));
   vec4 D=DHwTEN(g);
   gl_FragData[0]=vec4(b,saturate(h));
   gl_FragData[1]=vec4(D);
   gl_FragData[2]=vec4(b,1.);
 };

/* DRAWBUFFERS:456 */