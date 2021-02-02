#version 120

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

/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define SATURATION_BOOST 0.2f 			//How saturated the final image should be. 0 is unchanged saturation. Higher values create more saturated image

//Define one of these, not more, not less.
	//#define TONEMAP_NATURAL
	#define TONEMAP_FILMIC

//#define LOCAL_OPERATOR
					//Use local operator when tone mapping. Local operators increase image sharpness and local contrast but can cause haloing
#define RAINDROPS	
	
#define MOTIONBLUR

#define DOF						
	//#define CHROMATIC_ABERRATION_DOF

#define LENS_FLARE				
	#define BIG_RAINBOW
const float LENS_STRENGTH = 0.1;

#define MOON_GLOW
	
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////


uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D noisetex;
uniform sampler2D gaux1;

varying vec4 texcoord;
varying vec3 lightVector;

uniform int worldTime;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float centerDepthSmooth;
uniform float frameTimeCounter;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform int   isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   fogMode;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeMidnight;

#define BANDING_FIX_FACTOR 1.15f




/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
vec3 	GetTexture(in sampler2D tex, in vec2 coord) {				//Perform a texture lookup with BANDING_FIX_FACTOR compensation
	return pow(texture2D(tex, coord).rgb, vec3(BANDING_FIX_FACTOR + 1.2f));
}

vec3 	GetTextureLod(in sampler2D tex, in vec2 coord, in int level) {				//Perform a texture lookup with BANDING_FIX_FACTOR compensation
	return pow(texture2DLod(tex, coord, level).rgb, vec3(BANDING_FIX_FACTOR + 1.2f));
}

vec3 	GetTexture(in sampler2D tex, in vec2 coord, in int LOD) {	//Perform a texture lookup with BANDING_FIX_FACTOR compensation and lod offset
	return pow(texture2D(tex, coord, LOD).rgb, vec3(BANDING_FIX_FACTOR));
}

float 	GetDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).x;
}

float 	GetDepthLinear(in vec2 coord) {					//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
	return 2.0f * near * far / (far + near - (2.0f * texture2D(gdepthtex, coord).x - 1.0f) * (far - near));
}

vec3 	GetColorTexture(in vec2 coord) {
	return GetTextureLod(gnormal, coord.st, 0).rgb;
}

float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(gdepth, coord).r;
}

vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	vec2 resolution = vec2(viewWidth, viewHeight);

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

bool 	GetMaterialMask(in vec2 coord, in int ID) {
	float	  matID = floor(GetMaterialIDs(coord) * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return true;
	} else {
		return false;
	}
}

bool  	GetWaterMask(in vec2 coord) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	float matID = floor(GetMaterialIDs(coord) * 55255.0f);

	if (matID >= 35.0f && matID <= 51) {
		return true;
	} else {
		return false;
	}
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

void 	DepthOfField(inout vec3 color)
{

	float cursorDepth = centerDepthSmooth;

	bool isHand = GetMaterialMask(texcoord.st, 5);
	
	
	const float blurclamp = 0.514;  // max blur amount
	const float bias = 0.075;	//aperture - bigger values for shallower depth of field
	
	
	vec2 aspectcorrect = vec2(1.0, aspectRatio) * 1.7;

	float depth = texture2D(gdepthtex, texcoord.st).x;
		  depth += float(isHand) * 0.00000000006f;

	float factor = (depth - cursorDepth);
	 
	vec2 dofblur = vec2(factor * bias)*3.55;

	vec3 col = vec3(0.0);
	col += GetColorTexture(texcoord.st);

#ifdef CHROMATIC_ABERRATION_DOF
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,0.4 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,0.29 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.67,0.15 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( 0.1,0.0 )*aspectcorrect) * dofblur).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( 0.07,-0.15 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,-0.29 )*aspectcorrect) * dofblur).b;       
    col.b += GetColorTexture(texcoord.st + (vec2( -0.25,-0.37 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,-0.4 )*aspectcorrect) * dofblur).b; 
    col.b += GetColorTexture(texcoord.st + (vec2( -0.45,0.37 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,0.29 )*aspectcorrect) * dofblur).b;
    col.b += GetColorTexture(texcoord.st + (vec2( 0.07,0.15 )*aspectcorrect) * dofblur).b; 
    col.b += GetColorTexture(texcoord.st + (vec2( -0.7,0.0 )*aspectcorrect) * dofblur).b;  
    col.b += GetColorTexture(texcoord.st + (vec2( -0.67,-0.15 )*aspectcorrect) * dofblur).b;       
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,-0.29 )*aspectcorrect) * dofblur).b;       
    col.b += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur).b;
   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur*0.9).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.67,0.15 )*aspectcorrect) * dofblur*0.9).b;            
    col.b += GetColorTexture(texcoord.st + (vec2( 0.07,-0.15 )*aspectcorrect) * dofblur*0.9).b;            
    col.b += GetColorTexture(texcoord.st + (vec2( -0.25,-0.37 )*aspectcorrect) * dofblur*0.9).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.25,0.37 )*aspectcorrect) * dofblur*0.9).b;
    col.b += GetColorTexture(texcoord.st + (vec2( 0.07,0.15 )*aspectcorrect) * dofblur*0.9).b;             
    col.b += GetColorTexture(texcoord.st + (vec2( -0.67,-0.15 )*aspectcorrect) * dofblur*0.9).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur*0.9).b;   
   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,0.29 )*aspectcorrect) * dofblur*0.7).b;
    col.b += GetColorTexture(texcoord.st + (vec2( 0.1,0.0 )*aspectcorrect) * dofblur*0.7).b;       
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,-0.29 )*aspectcorrect) * dofblur*0.7).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,-0.4 )*aspectcorrect) * dofblur*0.7).b;     
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,0.29 )*aspectcorrect) * dofblur*0.7).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.7,0.0 )*aspectcorrect) * dofblur*0.7).b;      
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,-0.29 )*aspectcorrect) * dofblur*0.7).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,0.4 )*aspectcorrect) * dofblur*0.7).b;
                   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,0.29 )*aspectcorrect) * dofblur*0.4).b;
    col.b += GetColorTexture(texcoord.st + (vec2( 0.1,0.0 )*aspectcorrect) * dofblur*0.4).b;       
    col.b += GetColorTexture(texcoord.st + (vec2( -0.01,-0.29 )*aspectcorrect) * dofblur*0.4).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,-0.4 )*aspectcorrect) * dofblur*0.4).b;     
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,0.29 )*aspectcorrect) * dofblur*0.4).b;
    col.b += GetColorTexture(texcoord.st + (vec2( -0.7,0.0 )*aspectcorrect) * dofblur*0.4).b;      
    col.b += GetColorTexture(texcoord.st + (vec2( -0.59,-0.29 )*aspectcorrect) * dofblur*0.4).b;   
    col.b += GetColorTexture(texcoord.st + (vec2( -0.3,0.4 )*aspectcorrect) * dofblur*0.4).b;      

    ///////////////////////////////
   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur).g;   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur).g;  
    col.g += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur).g; 
    col.g += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur).g;  
    col.g += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur).g;       
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur).g;       
    col.g += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur).g;
   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur*0.9).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur*0.9).g;            
    col.g += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur*0.9).g;            
    col.g += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur*0.9).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur*0.9).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur*0.9).g;             
    col.g += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur*0.9).g;   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur*0.9).g;    
   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.7).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.7).g;       
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.7).g;    
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.7).g;      
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.7).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.7).g;      
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.7).g;   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.7).g;
                   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.4).g;
    col.g += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.4).g;       
    col.g += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.4).g;    
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.4).g;      
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.4).g;
    col.g += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.4).g;      
    col.g += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.4).g;   
    col.g += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.4).g;       

    ///////////////////////////////
   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,0.4 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.45,0.37 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,0.29 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( -0.07,0.15 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.7,0.0 )*aspectcorrect) * dofblur).r;   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.67,-0.15 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,-0.29 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,-0.4 )*aspectcorrect) * dofblur).r;  
    col.r += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,0.29 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.67,0.15 )*aspectcorrect) * dofblur).r; 
    col.r += GetColorTexture(texcoord.st + (vec2( -0.1,0.0 )*aspectcorrect) * dofblur).r;  
    col.r += GetColorTexture(texcoord.st + (vec2( -0.07,-0.15 )*aspectcorrect) * dofblur).r;       
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,-0.29 )*aspectcorrect) * dofblur).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.45,-0.37 )*aspectcorrect) * dofblur).r;
   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.45,0.37 )*aspectcorrect) * dofblur*0.9).r;
    col.r += GetColorTexture(texcoord.st + (vec2( -0.07,0.15 )*aspectcorrect) * dofblur*0.9).r;            
    col.r += GetColorTexture(texcoord.st + (vec2( 0.67,-0.15 )*aspectcorrect) * dofblur*0.9).r;            
    col.r += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur*0.9).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur*0.9).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.67,0.15 )*aspectcorrect) * dofblur*0.9).r;             
    col.r += GetColorTexture(texcoord.st + (vec2( -0.07,-0.15 )*aspectcorrect) * dofblur*0.9).r;   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.45,-0.37 )*aspectcorrect) * dofblur*0.9).r;    
   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,0.29 )*aspectcorrect) * dofblur*0.7).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.7,0.0 )*aspectcorrect) * dofblur*0.7).r;       
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,-0.29 )*aspectcorrect) * dofblur*0.7).r;    
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,-0.4 )*aspectcorrect) * dofblur*0.7).r;      
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,0.29 )*aspectcorrect) * dofblur*0.7).r;
    col.r += GetColorTexture(texcoord.st + (vec2( -0.1,0.0 )*aspectcorrect) * dofblur*0.7).r;      
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,-0.29 )*aspectcorrect) * dofblur*0.7).r;    
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,0.4 )*aspectcorrect) * dofblur*0.7).r;
                   
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,0.29 )*aspectcorrect) * dofblur*0.4).r;
    col.r += GetColorTexture(texcoord.st + (vec2( 0.7,0.0 )*aspectcorrect) * dofblur*0.4).r;       
    col.r += GetColorTexture(texcoord.st + (vec2( 0.59,-0.29 )*aspectcorrect) * dofblur*0.4).r;    
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,-0.4 )*aspectcorrect) * dofblur*0.4).r;      
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,0.29 )*aspectcorrect) * dofblur*0.4).r;
    col.r += GetColorTexture(texcoord.st + (vec2( -0.1,0.0 )*aspectcorrect) * dofblur*0.4).r;      
    col.r += GetColorTexture(texcoord.st + (vec2( 0.01,-0.29 )*aspectcorrect) * dofblur*0.4).r;    
    col.r += GetColorTexture(texcoord.st + (vec2( 0.3,0.4 )*aspectcorrect) * dofblur*0.4).r;        
	
#else

	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur);
	col += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur);	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur);
	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( -0.37,0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( 0.37,-0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( -0.15,-0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( -0.15,0.37 )*aspectcorrect) * dofblur*0.9);
	col += GetColorTexture(texcoord.st + (vec2( 0.37,0.15 )*aspectcorrect) * dofblur*0.9);		
	col += GetColorTexture(texcoord.st + (vec2( -0.37,-0.15 )*aspectcorrect) * dofblur*0.9);	
	col += GetColorTexture(texcoord.st + (vec2( 0.15,-0.37 )*aspectcorrect) * dofblur*0.9);	
	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.7);
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.7);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.7);
			
	col += GetColorTexture(texcoord.st + (vec2( 0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord.st + (vec2( 0.4,0.0 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.29,-0.29 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,-0.4 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,0.29 )*aspectcorrect) * dofblur*0.4);
	col += GetColorTexture(texcoord.st + (vec2( -0.4,0.0 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( -0.29,-0.29 )*aspectcorrect) * dofblur*0.4);	
	col += GetColorTexture(texcoord.st + (vec2( 0.0,0.4 )*aspectcorrect) * dofblur*0.4);	
	
#endif

	color = col/41;	
}


void 	Vignette(inout vec3 color) {
	float dist = distance(texcoord.st, vec2(0.5f)) * 2.0f;
		  dist /= 1.5142f;

		  dist = pow(dist, 1.1f);

	color.rgb *= 1.0f - dist;

}

float  	CalculateDitherPattern1() {
	int[16] ditherPattern = int[16] (0 , 9 , 3 , 11,
								 	 13, 5 , 15, 7 ,
								 	 4 , 12, 2,  10,
								 	 16, 8 , 14, 6 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 17.0f;
}

void 	MotionBlur(inout vec3 color) {
	float depth = GetDepth(texcoord.st);
	vec4 currentPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);

	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * 0.12f;
	float maxVelocity = 0.05f;
		 velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));


	bool isHand = GetMaterialMask(texcoord.st, 5);
	velocity *= 1.0f - float(isHand);

	int samples = 0;

	float dither = CalculateDitherPattern1();

	color.rgb = vec3(0.0f);

	for (int i = 0; i < 2; ++i) {
		vec2 coord = texcoord.st + velocity * (i - 0.5);
			 coord += vec2(dither) * 1.2f * velocity;

		if (coord.x > 0.0f && coord.x < 1.0f && coord.y > 0.0f && coord.y < 1.0f) {

			color += GetColorTexture(coord).rgb;
			samples += 1;

		}
	}

	color.rgb /= samples;


}

void CalculateExposure(inout vec3 color) {
	float exposureMax = 1.55f;
		  exposureMax *= mix(1.0f, 0.25f, timeSunrise);
		  exposureMax *= mix(1.0f, 0.25f, timeSunset);
		  exposureMax *= mix(1.0f, 0.0f, timeMidnight);
		  exposureMax *= mix(1.0f, 0.25f, rainStrength);
	float exposureMin = 0.07f;
	float exposure = pow(eyeBrightnessSmooth.y / 240.0f, 6.0f) * exposureMax + exposureMin;

	//exposure = 1.0f;

	color.rgb /= vec3(exposure);
}

void TonemapVorontsov(inout vec3 color) {
	//color = pow(color, vec3(2.2f)); 			//Put gcolor back into linear space
	color.rgb *= 75000.0f;
	
	//Natural
	//Properties
		// float tonemapContrast 		= 0.95f;
		// float tonemapSaturation 	= 1.2f + SATURATION_BOOST; 
		// float tonemapDecay			= 210.0f;
		// float tonemapCurve			= 100.0f;

	//Filmic
		float tonemapContrast 		= 1.1f;
		float tonemapSaturation 	= 1.2f + SATURATION_BOOST; 
		float tonemapDecay			= 121000.0f;
		float tonemapCurve			= 1.0f;
		
	color.rgb += 0.001f;
	
	vec3 colorN = normalize(color.rgb);
	
	vec3 clrfr = color.rgb/colorN.rgb;
	     clrfr = pow(clrfr.rgb, vec3(tonemapContrast));
		 
	colorN.rgb = pow(colorN.rgb, vec3(tonemapSaturation));
	
	color.rgb = clrfr.rgb * colorN.rgb;

	color.rgb = (color.rgb * (1.0 + color.rgb/tonemapDecay))/(color.rgb + tonemapCurve);

	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));

	color.rgb *= 1.0f;
}

void TonemapReinhard(inout vec3 color) {
	//color.rgb = pow(color.rgb, vec3(2.2f));			//Put color into linear space

	color.rgb *= 100000.0f;
	color.rgb = color.rgb / (1.0f + color.rgb);

	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f)); //Put color into gamma space for correct display
	color.rgb *= 1.0f;
}


void TonemapReinhardLum(inout vec3 color) {
	//color.rgb = pow(color.rgb, vec3(2.2f));			//Put color into linear space

	color.rgb *= 100000.0f;

	float lum = dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));

	float white = 21.0f;
	float lumTonemap = (lum * (1.0f + (lum / white))) / (1.0f + lum);


	float factor = lumTonemap / lum;

	color.rgb *= factor;

	//color.rgb = color.rgb / (color.rgb + 1.0f);

	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f)); //Put color into gamma space for correct display
	color.rgb *= 1.1f;
}


void SaturationBoost(inout vec3 color) {
	float satBoost = 0.04f;

	color.r = color.r * (1.05f + satBoost * 2.3f) - (color.g * satBoost) - (color.b * satBoost);
	color.g = color.g * (1.05f + satBoost * 2.1f) - (color.r * satBoost) - (color.b * satBoost);
	color.b = color.b * (1.0f + satBoost * 2.2f) - (color.r * satBoost) - (color.g * satBoost);
}

void TonemapReinhardLinearHybrid(inout vec3 color) {

	color.rgb *= 25000.0f;
	color.rgb = color.rgb / (1.0f + color.rgb);

	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f)); //Put color into gamma space for correct display
	color.rgb *= 1.21f;
}

void SphericalTonemap(inout vec3 color)
{

	color.rgb = clamp(color.rgb, vec3(0.0f), vec3(1.0f));

	vec3 signedColor = color.rgb * 2.0f - 1.0f;

	vec3 sphericalColor = sqrt(1.0f - signedColor.rgb * signedColor.rgb);
		 sphericalColor = sphericalColor * 0.5f + 0.5f;
		 sphericalColor *= color.rgb;

	float sphericalAmount = 0.3f;

	color.rgb += sphericalColor.rgb * sphericalAmount;
	color.rgb *= 0.95f;
}

void LowtoneSaturate(inout vec3 color)
{
	color.rgb *= 1.125f;
	color.rgb -= 0.125f;
	color.rgb = clamp(color.rgb, vec3(0.0f), vec3(1.0f));
}

void ColorGrading(inout vec3 color)
{
	vec3 c = color.rgb;

	//warm
	c.rgb = max(vec3(0.0f), c.rgb * 1.1f - 0.1f);

		 c.r *= 0.895f;
		
		 c.g *= 0.95f;
		 
		 c.b *= 1.14f;

	// //cool

	 	//c.r *= 1.02f;
		//c.g *= 1.0f; 
		//c.b *= 1.21f;
		//c.b *= 1.14f;

	color.rgb = c.rgb;
}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct BloomDataStruct
{
	vec3 blur0;
	vec3 blur1;
	vec3 blur2;
	vec3 blur3;
	vec3 blur4;
	vec3 blur5;
	vec3 blur6;

	vec3 bloom;
} bloomData;





/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void 	CalculateBloom(inout BloomDataStruct bloomData) {		//Retrieve previously calculated bloom textures

	//constants for bloom bloomSlant
	const float    bloomSlant = 0.0f;
	const float[7] bloomWeight = float[7] (pow(7.0f, bloomSlant),
										   pow(6.0f, bloomSlant),
										   pow(5.0f, bloomSlant),
										   pow(4.0f, bloomSlant),
										   pow(3.0f, bloomSlant),
										   pow(2.0f, bloomSlant),
										   1.0f
										   );

	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	bloomData.blur0  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	2.0f 	)) + 	vec2(0.0f, 0.0f)		+ vec2(0.000f, 0.000f)	).rgb * bloomWeight[0], vec3(1.0f + 1.2f));
	bloomData.blur1  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	3.0f 	)) + 	vec2(0.0f, 0.25f)		+ vec2(0.000f, 0.025f)	).rgb * bloomWeight[1], vec3(1.0f + 1.2f));
	bloomData.blur2  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	4.0f 	)) + 	vec2(0.125f, 0.25f)		+ vec2(0.025f, 0.025f)	).rgb * bloomWeight[2], vec3(1.0f + 1.2f));
	bloomData.blur3  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	5.0f 	)) + 	vec2(0.1875f, 0.25f)	+ vec2(0.050f, 0.025f)	).rgb * bloomWeight[3], vec3(1.0f + 1.2f));
	bloomData.blur4  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	6.0f 	)) + 	vec2(0.21875f, 0.25f)	+ vec2(0.075f, 0.025f)	).rgb * bloomWeight[4], vec3(1.0f + 1.2f));
	bloomData.blur5  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	7.0f 	)) + 	vec2(0.25f, 0.25f)		+ vec2(0.100f, 0.025f)	).rgb * bloomWeight[5], vec3(1.0f + 1.2f));
	bloomData.blur6  =  pow(BicubicTexture(gcolor, (texcoord.st - recipres * 0.5f) * (1.0f / pow(2.0f, 	8.0f 	)) + 	vec2(0.28f, 0.25f)		+ vec2(0.125f, 0.025f)	).rgb * bloomWeight[6], vec3(1.0f + 1.2f));

 	bloomData.bloom  = bloomData.blur0;
 	bloomData.bloom += bloomData.blur1;
 	bloomData.bloom += bloomData.blur2;
 	bloomData.bloom += bloomData.blur3;
 	bloomData.bloom += bloomData.blur4;
 	bloomData.bloom += bloomData.blur5;
 	bloomData.bloom += bloomData.blur6;

}


void TonemapReinhard07(inout vec3 color, in BloomDataStruct bloomData)
{
	//Per-channel
	// vec3 n = vec3(0.9f);
	// vec3 g = vec3(0.00001f);
	// color.rgb = pow(color.rgb, n) / (pow(color.rgb, n) + pow(g, n));

	//Luminance
	float n = 0.6f;
	float lum = dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
	float g = 0.000019f + lum * 0.0f;
	float white = 0.1f;
	float compressed = pow((lum * (1.0f + (lum / white))), n) / (pow(lum, n) + pow(g, n));

	float s = clamp(1.0f - compressed * 0.65f, 0.0f, 1.0f) * 0.65f;
	color.r = pow((color.r / lum), s) * (compressed);
	color.g = pow((color.g / lum), s) * (compressed);
	color.b = pow((color.b / lum), s) * (compressed);




	//color.rgb *= 30000.0f;



	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
	color.rgb = max(vec3(0.0f), color.rgb * 1.15f - 0.15f);
	color.rgb *= 1.1f;
}


void 	AddRainFogScatter(inout vec3 color, in BloomDataStruct bloomData)
{
	const float    bloomSlant = 0.0f;
	const float[7] bloomWeight = float[7] (pow(7.0f, bloomSlant),
										   pow(6.0f, bloomSlant),
										   pow(5.0f, bloomSlant),
										   pow(4.0f, bloomSlant),
										   pow(3.0f, bloomSlant),
										   pow(2.0f, bloomSlant),
										   1.0f
										   );

	vec3 fogBlur = bloomData.blur0 * bloomWeight[6] + 
			       bloomData.blur1 * bloomWeight[5] + 
			       bloomData.blur2 * bloomWeight[4] + 
			       bloomData.blur3 * bloomWeight[3] + 
			       bloomData.blur4 * bloomWeight[2] + 
			       bloomData.blur5 * bloomWeight[1] + 
			       bloomData.blur6 * bloomWeight[0];

	float fogTotalWeight = 	1.0f * bloomWeight[0] + 
			       			1.0f * bloomWeight[1] + 
			       			1.0f * bloomWeight[2] + 
			       			1.0f * bloomWeight[3] + 
			       			1.0f * bloomWeight[4] + 
			       			1.0f * bloomWeight[5] + 
			       			1.0f * bloomWeight[6];

	fogBlur /= fogTotalWeight;

	float linearDepth = GetDepthLinear(texcoord.st);

	float fogDensity = 0.043f * (rainStrength);
		  //fogDensity += texture2D(composite, texcoord.st).g * 0.1f;
	float visibility = 1.0f / (pow(exp(linearDepth * fogDensity), 1.0f));
	float fogFactor = 1.0f - visibility;
		  fogFactor = clamp(fogFactor, 0.0f, 1.0f);
		  fogFactor *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 6.0f));

	// bool waterMask = GetWaterMask(texcoord.st);
	// fogFactor = mix(fogFactor, 0.0f, float(waterMask));

	color = mix(color, fogBlur, fogFactor * 1.0f);
}


void TonemapReinhard05(inout vec3 color, BloomDataStruct bloomData)
{

	//color.b *= 0.85f;

	#ifdef TONEMAP_NATURAL
	float averageLuminance = 0.00010f;
	#endif
	#ifdef TONEMAP_FILMIC
	float averageLuminance = 0.000055f;
	#endif



	#ifdef TONEMAP_NATURAL
	float contrast = 0.85f;
	#endif
	#ifdef TONEMAP_FILMIC
	float contrast = 0.99f;
	#endif

	#ifdef TONEMAP_NATURAL
	float adaptation = 0.75f;
	#endif

	#ifdef TONEMAP_FILMIC
	float adaptation = 0.75f;
	#endif

	float lum = Luminance(color.rgb);
	vec3 blur = bloomData.blur1;
	     blur += bloomData.blur2;


	#ifdef LOCAL_OPERATOR
	vec3 ILocal = vec3(Luminance(blur));
		 ILocal -= pow(Luminance(bloomData.blur2), 4.1f) * 100000000000.0f;
		 ILocal = max(vec3(0.000000000001f), ILocal);

		 //ILocal = vec3(sMax * 2.25f);
	#endif



	#ifdef LOCAL_OPERATOR
	vec3 IGlobal = vec3(averageLuminance);
	vec3 IAverage = mix(ILocal, IGlobal, vec3(adaptation));
	#else
	vec3 IAverage = vec3(averageLuminance);
	#endif

	vec3 value = color.rgb / (color.rgb + IAverage);




	#ifdef TONEMAP_NATURAL
	color.rgb = value * 2.195f - 0.00f;
	color.rgb = pow(color.rgb, vec3(0.99f));
	#endif

	#ifdef TONEMAP_FILMIC
	color.rgb = value * 1.195f - 0.00f;
	#endif


	color.rgb = min(color.rgb, vec3(1.0f));


	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
	//color.rgb -= vec3(0.025f);
}


float distratio(vec2 pos, vec2 pos2, float ratio) {
    float xvect = pos.x*ratio-pos2.x*ratio;
    float yvect = pos.y-pos2.y;
    return sqrt(xvect*xvect + yvect*yvect);
}
float gen_circular_lens(vec2 center, float size) {
    return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,10.0);
}
vec2 noisepattern(vec2 pos) {
    return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
} 

void RainDrops(inout vec3 color){
    if (rainStrength > 0.01) {
        const float pi = 0.5f;
		float lightmap = pow(eyeBrightness.y/255.0, 6.0f);	
		float fake_refract = 1.0-sin(worldTime/5.14159265359 + texcoord.x*30.0 + texcoord.y*30.0);	
	    vec3 watercolor = GetTexture(gaux1, texcoord.st + fake_refract * 0.015 * lightmap).rgb;	
        float raindrops = 0.0;
    	float time2 = frameTimeCounter;
		
		float gen = cos(time2*pi)*1.5+0.5;
        vec2 pos = noisepattern(vec2(0.9347*floor(time2*0.5+0.5),-0.2533282*floor(time2*0.5+0.5)));
        raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;
		
		gen = cos(time2*pi)*0.5+0.5;
 	    pos = noisepattern(vec2(0.785282*floor(time2*0.5+0.5),-0.285282*floor(time2*0.5+0.5)));
        raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

        gen = sin(time2*pi)*0.5+0.5;
        pos = noisepattern(vec2(-0.347*floor(time2*0.5+0.5),0.6847*floor(time2*0.5+0.5)));
        raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

        gen = cos(time2*pi)*0.5+0.5;
        pos = noisepattern(vec2(0.3347*floor(time2*0.5+0.5),-0.2533282*floor(time2*0.5+0.5)));
        raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

        gen = cos(time2*pi)*0.5+0.5;
        pos = noisepattern(vec2(0.385282*floor(time2*0.5+0.5),-0.285282*floor(time2*0.5+0.5)));
        raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;
		
			if (isEyeInWater < 0.9) {
                color.rgb += raindrops * watercolor;
	        }
	}
}





void LowlightFuzziness(inout vec3 color, in BloomDataStruct bloomData)
{
	float lum = Luminance(color.rgb);
	float factor = 1.0f - clamp(lum * 50000000.0f, 0.0f, 1.0f);
	      //factor *= factor * factor;


	float time = frameTimeCounter * 4.0f;
	vec2 coord = texture2D(noisetex, vec2(time, time / 64.0f)).xy;
	vec3 snow = BicubicTexture(noisetex, (texcoord.st + coord) / (512.0f / vec2(viewWidth, viewHeight))).rgb;	//visual snow
	vec3 snow2 = BicubicTexture(noisetex, (texcoord.st + coord) / (128.0f / vec2(viewWidth, viewHeight))).rgb;	//visual snow

	vec3 rodColor = vec3(0.2f, 0.4f, 1.0f);
	vec3 rodLight = dot(color.rgb + snow.r * 0.0000000005f, vec3(0.0f, 0.6f, 0.4f)) * rodColor;
	color.rgb = mix(color.rgb, rodLight, vec3(factor));	//visual acuity loss

	color.rgb += snow.rgb * snow2.rgb * snow.rgb * 0.000000002f;


}
void LensFlare(inout vec3 color)
{
 
vec3 tempColor2 = vec3(0.0);
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;
vec3 sP = sunPosition;
 
      vec4 tpos = vec4(sP,1.0)*gbufferProjection;
      tpos = vec4(tpos.xyz/tpos.w,1.0);
      vec2 lPos = tpos.xy / tpos.z;
      lPos = (lPos + 1.0f)/2.0f;
      //lPos = clamp(lPos, vec2(0.001f), vec2(0.999f));
      vec2 checkcoord = lPos;
     
      if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f && timeMidnight < 1.0)
      {
         vec2 checkcoord;
         
         float sunmask = 0.0f;
         float sunstep = -4.5f;
         float masksize = 0.004f;
               
 
         for (int a = 0; a < 4; a++)
         {
            for(int b = 0; b < 4; b++)
            {
               checkcoord = lPos + vec2(pw*a*5.0f,ph*5.0f*b);
               
               bool sky = false;
               
               float matID = GetMaterialIDs(checkcoord);      //Gets texture that has all material IDs stored in it
               matID = floor(matID * 255.0f);      //Scale texture from 0-1 float to 0-255 integer format
 
               //Catch last part of sky
               if (matID > 254.0f) {
                  matID = 0.0f;
               }
 
               if (matID == 0) {
                  sky = true;
               } else {
                  sky = false;
               }
 
 
               if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f)
               {
                  if (sky == true)
                  {
                     sunmask = 1.0f;
                  }
                  else
                  {
                     sunmask = 0.0f;
                  }
               }
            }
         }
         
         
            sunmask *= 0.34 * (1.0f - timeMidnight);
            sunmask *= (1.0f - rainStrength);
           
         if (sunmask > 0.02)
         {
         //Detect if sun is on edge of screen
            float edgemaskx = clamp(distance(lPos.x, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
            float edgemasky = clamp(distance(lPos.y, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
         
            vec3 lenscolorSunrise = vec3(1.1,0.0,0.0) * timeSunrise;
			vec3 lenscolorNoon 	  = vec3(1.0,0.8,0.7) * timeNoon;
			vec3 lenscolorSunset  = vec3(1.2,0.0,0.0) * timeSunset;
			
			vec3 lenscolor = lenscolorSunrise + lenscolorNoon + lenscolorSunset;      
                 
         ////Darken colors if the sun is visible
            float centermask = 1.0 - clamp(distance(lPos.xy, vec2(0.5f, 0.5f))*2.0, 0.0, 1.0);
                  centermask = pow(centermask, 1.0f);
                  centermask *= sunmask;
         
            color.r *= (1.0 - centermask * (1.0f - timeMidnight));
            color.g *= (1.0 - centermask * (1.0f - timeMidnight));
            color.b *= (1.0 - centermask * (1.0f - timeMidnight));
         
         
         //Adjust global flare settings
            const float flaremultR = 1.0f;
            const float flaremultG = 1.0f;
            const float flaremultB = 1.5f;
         
            float flarescale = 1.0f;
            const float flarescaleconst = 1.0f;
         
         
         //Flare gets bigger at center of screen
         
            //flarescale *= (1.0 - centermask);
         
                 
                 
                 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW_RAINBOW
                 
 //lens
 //Lens
 
   
       
        float flarescale2 = 1.1f;
       
        float flarescale3 = 2.0f;
       
        float flarescale4 = 1.5f;
 
    vec3 tempColor = vec3(0.0);
       
        vec3 tempColor3 = vec3(0.0);
       
        vec3 tempColor4 = vec3(0.0);
                 
        vec2 resolution = vec2(viewWidth, viewHeight);
 
        float PI = 3.141592;
 
        vec2 uv = (texcoord.xy);
 
        float random = fract(sin(dot(sunPosition.xy, vec2(12.9898, 78.233)))* 43758.5453);
       
                random - 0.25f;
 
                if (random < 0.25f)
                {
                        random = 0.25f;
                }
       
        float c = 0.0;
        float dx = uv.x - 0.5;
        float dy = uv.y - 0.5;
        c = (atan(dy, dx) / PI + 1.0) * 1.0;
        float t = (sin(random) + 1.0) * 1.0;
        c = tan(c * t * 1000.0);
       
       
        vec4 tempColor2 = vec4(c, c, c, 1.0 );
       
       
                if (tempColor2.r < 0.7f)
                {
                        tempColor2.r = 0.7f;
                }
                else if (tempColor2.r > 1.0f)
                {
                        tempColor2.r = 1.0f;
                }
               
                sin(tempColor2);
 
                //color.r = tempColor2.r;
                //color.g = tempColor2.r;
                //color.b = tempColor2.r;
                 
 
 
#ifdef BIG_RAINBOW 
//-------------------Red--------------------------------------------------------------------------------------
 
                        vec2 flare_Red_scale = vec2(0.9f*flarescale2, 0.9f*flarescale2);
                          float flare_Red_pow = 4.25f;
                          float flare_Red_fill = 10.0f;
                          float flare_Red_offset = -0.0f;
                        vec2 flare_Red_pos = vec2(  ((1.0 - lPos.x)*(flare_Red_offset + 1.0) - (flare_Red_offset*0.5))  *aspectRatio*flare_Red_scale.x,  ((1.0 - lPos.y)*(flare_Red_offset + 1.0) - (flare_Red_offset*0.5))  *flare_Red_scale.y);
                       
                       
                        float flare_Red_ = distance(flare_Red_pos, vec2(texcoord.s*aspectRatio*flare_Red_scale.x, texcoord.t*flare_Red_scale.y));
                                  flare_Red_ = 0.5 - flare_Red_;
                                  flare_Red_ = clamp(flare_Red_*flare_Red_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Red_ = sin(flare_Red_*1.57075);
                                 
                                  flare_Red_ = pow(flare_Red_, 1.1f);
                                 
                                  flare_Red_ *= flare_Red_pow;                
                                 
                                 
                                  //subtract
                                  vec2 flare_RedD_scale = vec2(0.58*flarescale2, 0.58*flarescale2);
                                  float flare_RedD_pow = 8.0f;
                                  float flare_RedD_fill = 1.4f;
                                  float flare_RedD_offset = -0.2f;
                                vec2 flare_RedD_pos = vec2(  ((1.0 - lPos.x)*(flare_RedD_offset + 1.0) - (flare_RedD_offset*0.5))  *aspectRatio*flare_RedD_scale.x,  ((1.0 - lPos.y)*(flare_RedD_offset + 1.0) - (flare_RedD_offset*0.5))  *flare_RedD_scale.y);
                       
                       
                                float flare_RedD_ = distance(flare_RedD_pos, vec2(texcoord.s*aspectRatio*flare_RedD_scale.x, texcoord.t*flare_RedD_scale.y));
                                        flare_RedD_ = 0.5 - flare_RedD_;
                                        flare_RedD_ = clamp(flare_RedD_*flare_RedD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_RedD_ = sin(flare_RedD_*1.57075);
                                        flare_RedD_ = pow(flare_RedD_, 0.9f);
                                 
                                        flare_RedD_ *= flare_RedD_pow;
                                 
                                flare_Red_ = clamp(flare_Red_ - flare_RedD_, 0.0, 10.0);
                                flare_Red_ *= sunmask;
                                 
                                        tempColor.r += flare_Red_*1.0f*flaremultR * tempColor2.r;
                                        tempColor.g += flare_Red_*0.0f*flaremultG * tempColor2.r;
                                        tempColor.b += flare_Red_*0.0f*flaremultB * tempColor2.r;              
               
//--------------------------------------------------------------------------------------
   
//-------------------Orange--------------------------------------------------------------------------------------
 
                        vec2 flare_Orange_scale = vec2(0.86f*flarescale2, 0.86f*flarescale2);
                          float flare_Orange_pow = 4.25f;
                          float flare_Orange_fill = 12.0f;
                          float flare_Orange_offset = -0.0f;
                        vec2 flare_Orange_pos = vec2(  ((1.0 - lPos.x)*(flare_Orange_offset + 1.0) - (flare_Orange_offset*0.5))  *aspectRatio*flare_Orange_scale.x,  ((1.0 - lPos.y)*(flare_Orange_offset + 1.0) - (flare_Orange_offset*0.5))  *flare_Orange_scale.y);
                       
                       
                        float flare_Orange_ = distance(flare_Orange_pos, vec2(texcoord.s*aspectRatio*flare_Orange_scale.x, texcoord.t*flare_Orange_scale.y));
                                  flare_Orange_ = 0.5 - flare_Orange_;
                                  flare_Orange_ = clamp(flare_Orange_*flare_Orange_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Orange_ = sin(flare_Orange_*1.57075);
                                 
                                  flare_Orange_ = pow(flare_Orange_, 1.1f);
                                 
                                  flare_Orange_ *= flare_Orange_pow;                  
                                 
                                 
                                  //subtract
                                  vec2 flare_OrangeD_scale = vec2(0.5446f*flarescale2, 0.5446f*flarescale2);
                                  float flare_OrangeD_pow = 8.0f;
                                  float flare_OrangeD_fill = 1.4f;
                                  float flare_OrangeD_offset = -0.2f;
                                vec2 flare_OrangeD_pos = vec2(  ((1.0 - lPos.x)*(flare_OrangeD_offset + 1.0) - (flare_OrangeD_offset*0.5))  *aspectRatio*flare_OrangeD_scale.x,  ((1.0 - lPos.y)*(flare_OrangeD_offset + 1.0) - (flare_OrangeD_offset*0.5))  *flare_OrangeD_scale.y);
                       
                       
                                float flare_OrangeD_ = distance(flare_OrangeD_pos, vec2(texcoord.s*aspectRatio*flare_OrangeD_scale.x, texcoord.t*flare_OrangeD_scale.y));
                                        flare_OrangeD_ = 0.5 - flare_OrangeD_;
                                        flare_OrangeD_ = clamp(flare_OrangeD_*flare_OrangeD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_OrangeD_ = sin(flare_OrangeD_*1.57075);
                                        flare_OrangeD_ = pow(flare_OrangeD_, 0.9f);
                                 
                                        flare_OrangeD_ *= flare_OrangeD_pow;
                                 
                                flare_Orange_ = clamp(flare_Orange_ - flare_OrangeD_, 0.0, 10.0);
                                flare_Orange_ *= sunmask;
                                 
                                        tempColor.r += flare_Orange_*1.0f*flaremultR * tempColor2.r;
                                        tempColor.g += flare_Orange_*1.0f*flaremultG * tempColor2.r;
                                        tempColor.b += flare_Orange_*0.0f*flaremultB * tempColor2.r;  
               
//--------------------------------------------------------------------------------------
   
//-------------------Green--------------------------------------------------------------------------------------
 
            vec2 flare_Green_scale = vec2(0.82f*flarescale2, 0.82f*flarescale2);
                          float flare_Green_pow = 4.25f;
                          float flare_Green_fill = 12.0f;
                          float flare_Green_offset = -0.0f;
                        vec2 flare_Green_pos = vec2(  ((1.0 - lPos.x)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *aspectRatio*flare_Green_scale.x,  ((1.0 - lPos.y)*(flare_Green_offset + 1.0) - (flare_Green_offset*0.5))  *flare_Green_scale.y);
                       
                       
                        float flare_Green_ = distance(flare_Green_pos, vec2(texcoord.s*aspectRatio*flare_Green_scale.x, texcoord.t*flare_Green_scale.y));
                                  flare_Green_ = 0.5 - flare_Green_;
                                  flare_Green_ = clamp(flare_Green_*flare_Green_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Green_ = sin(flare_Green_*1.57075);
                                 
                                  flare_Green_ = pow(flare_Green_, 1.1f);
                                 
                                  flare_Green_ *= flare_Green_pow;                    
                                 
                                 
                                  //subtract
                                  vec2 flare_GreenD_scale = vec2(0.5193f*flarescale2, 0.5193f*flarescale2);
                                  float flare_GreenD_pow = 8.0f;
                                  float flare_GreenD_fill = 1.4f;
                                  float flare_GreenD_offset = -0.2f;
                                vec2 flare_GreenD_pos = vec2(  ((1.0 - lPos.x)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *aspectRatio*flare_GreenD_scale.x,  ((1.0 - lPos.y)*(flare_GreenD_offset + 1.0) - (flare_GreenD_offset*0.5))  *flare_GreenD_scale.y);
                       
                       
                                float flare_GreenD_ = distance(flare_GreenD_pos, vec2(texcoord.s*aspectRatio*flare_GreenD_scale.x, texcoord.t*flare_GreenD_scale.y));
                                        flare_GreenD_ = 0.5 - flare_GreenD_;
                                        flare_GreenD_ = clamp(flare_GreenD_*flare_GreenD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_GreenD_ = sin(flare_GreenD_*1.57075);
                                        flare_GreenD_ = pow(flare_GreenD_, 0.9f);
                                 
                                        flare_GreenD_ *= flare_GreenD_pow;
                                 
                                flare_Green_ = clamp(flare_Green_ - flare_GreenD_, 0.0, 10.0);
                                flare_Green_ *= sunmask;
                                 
                                        tempColor.r += flare_Green_*0.0f*flaremultR * tempColor2.r;
                                        tempColor.g += flare_Green_*1.0f*flaremultG * tempColor2.r;
                                        tempColor.b += flare_Green_*0.0f*flaremultB * tempColor2.r;              
               
//--------------------------------------------------------------------------------------
 
//-------------------Blue--------------------------------------------------------------------------------------
 
        vec2 flare_Blue_scale = vec2(0.78f*flarescale2, 0.78f*flarescale2);
                          float flare_Blue_pow = 4.25f;
                          float flare_Blue_fill = 12.0f;
                          float flare_Blue_offset = -0.0f;
                        vec2 flare_Blue_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *aspectRatio*flare_Blue_scale.x,  ((1.0 - lPos.y)*(flare_Blue_offset + 1.0) - (flare_Blue_offset*0.5))  *flare_Blue_scale.y);
                       
                       
                        float flare_Blue_ = distance(flare_Blue_pos, vec2(texcoord.s*aspectRatio*flare_Blue_scale.x, texcoord.t*flare_Blue_scale.y));
                                  flare_Blue_ = 0.5 - flare_Blue_;
                                  flare_Blue_ = clamp(flare_Blue_*flare_Blue_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Blue_ = sin(flare_Blue_*1.57075);
                                 
                                  flare_Blue_ = pow(flare_Blue_, 1.1f);
                                 
                                  flare_Blue_ *= flare_Blue_pow;                      
                                 
                                 
                                  //subtract
                                  vec2 flare_BlueD_scale = vec2(0.494f*flarescale2, 0.494f*flarescale2);
                                  float flare_BlueD_pow = 8.0f;
                                  float flare_BlueD_fill = 1.4f;
                                  float flare_BlueD_offset = -0.2f;
                                vec2 flare_BlueD_pos = vec2(  ((1.0 - lPos.x)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *aspectRatio*flare_BlueD_scale.x,  ((1.0 - lPos.y)*(flare_BlueD_offset + 1.0) - (flare_BlueD_offset*0.5))  *flare_BlueD_scale.y);
                       
                       
                                float flare_BlueD_ = distance(flare_BlueD_pos, vec2(texcoord.s*aspectRatio*flare_BlueD_scale.x, texcoord.t*flare_BlueD_scale.y));
                                        flare_BlueD_ = 0.5 - flare_BlueD_;
                                        flare_BlueD_ = clamp(flare_BlueD_*flare_BlueD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_BlueD_ = sin(flare_BlueD_*1.57075);
                                        flare_BlueD_ = pow(flare_BlueD_, 0.9f);
                                 
                                        flare_BlueD_ *= flare_BlueD_pow;
                                 
                                flare_Blue_ = clamp(flare_Blue_ - flare_BlueD_, 0.0, 10.0);
                                flare_Blue_ *= sunmask;
                                 
                                        tempColor.r += flare_Blue_*0.0f*flaremultR * tempColor2.r;
                                        tempColor.g += flare_Blue_*0.0f*flaremultG * tempColor2.r;
                                        tempColor.b += flare_Blue_*1.0f*flaremultB * tempColor2.r;  
               
//--------------------------------------------------------------------------------------
#endif 
 
//RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_RAINBOW_2_
 
 
//-------------------Red2--------------------------------------------------------------------------------------
 
                        vec2 flare_Red2_scale = vec2(0.9f*flarescale3, 0.9f*flarescale3);
                          float flare_Red2_pow = 4.25f;
                          float flare_Red2_fill = 10.0f;
                          float flare_Red2_offset = -0.0f;
                        vec2 flare_Red2_pos = vec2(  ((1.0 - lPos.x)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *aspectRatio*flare_Red2_scale.x,  ((1.0 - lPos.y)*(flare_Red2_offset + 1.0) - (flare_Red2_offset*0.5))  *flare_Red2_scale.y);
                       
                       
                        float flare_Red2_ = distance(flare_Red2_pos, vec2(texcoord.s*aspectRatio*flare_Red2_scale.x, texcoord.t*flare_Red2_scale.y));
                                  flare_Red2_ = 0.5 - flare_Red2_;
                                  flare_Red2_ = clamp(flare_Red2_*flare_Red2_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Red2_ = sin(flare_Red2_*1.57075);
                                 
                                  flare_Red2_ = pow(flare_Red2_, 1.1f);
                                 
                                  flare_Red2_ *= flare_Red2_pow;                      
                                 
                                 
                                  //subtract
                                  vec2 flare_Red2D_scale = vec2(0.58*flarescale3, 0.58*flarescale3);
                                  float flare_Red2D_pow = 8.0f;
                                  float flare_Red2D_fill = 1.4f;
                                  float flare_Red2D_offset = -0.2f;
                                vec2 flare_Red2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *aspectRatio*flare_Red2D_scale.x,  ((1.0 - lPos.y)*(flare_Red2D_offset + 1.0) - (flare_Red2D_offset*0.5))  *flare_Red2D_scale.y);
                       
                       
                                float flare_Red2D_ = distance(flare_Red2D_pos, vec2(texcoord.s*aspectRatio*flare_Red2D_scale.x, texcoord.t*flare_Red2D_scale.y));
                                        flare_Red2D_ = 0.5 - flare_Red2D_;
                                        flare_Red2D_ = clamp(flare_Red2D_*flare_Red2D_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_Red2D_ = sin(flare_Red2D_*1.57075);
                                        flare_Red2D_ = pow(flare_Red2D_, 0.9f);
                                 
                                        flare_Red2D_ *= flare_Red2D_pow;
                                 
                                flare_Red2_ = clamp(flare_Red2_ - flare_Red2D_, 0.0, 10.0);
                                flare_Red2_ *= sunmask;
                                 
                                        tempColor3.r += flare_Red2_*10.0f*flaremultR * (tempColor2.r / 16);
                                        tempColor3.g += flare_Red2_*0.0f*flaremultG * (tempColor2.r / 16);
                                        tempColor3.b += flare_Red2_*0.0f*flaremultB * (tempColor2.r / 16);            
               
//--------------------------------------------------------------------------------------
   
//-------------------Orange2--------------------------------------------------------------------------------------
 
                        vec2 flare_Orange2_scale = vec2(0.86f*flarescale3, 0.86f*flarescale3);
                          float flare_Orange2_pow = 4.25f;
                          float flare_Orange2_fill = 10.0f;
                          float flare_Orange2_offset = -0.0f;
                        vec2 flare_Orange2_pos = vec2(  ((1.0 - lPos.x)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *aspectRatio*flare_Orange2_scale.x,  ((1.0 - lPos.y)*(flare_Orange2_offset + 1.0) - (flare_Orange2_offset*0.5))  *flare_Orange2_scale.y);
                       
                       
                        float flare_Orange2_ = distance(flare_Orange2_pos, vec2(texcoord.s*aspectRatio*flare_Orange2_scale.x, texcoord.t*flare_Orange2_scale.y));
                                  flare_Orange2_ = 0.5 - flare_Orange2_;
                                  flare_Orange2_ = clamp(flare_Orange2_*flare_Orange2_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Orange2_ = sin(flare_Orange2_*1.57075);
                                 
                                  flare_Orange2_ = pow(flare_Orange2_, 1.1f);
                                 
                                  flare_Orange2_ *= flare_Orange2_pow;                
                                 
                                 
                                  //subtract
                                  vec2 flare_Orange2D_scale = vec2(0.5446f*flarescale3, 0.5446f*flarescale3);
                                  float flare_Orange2D_pow = 8.0f;
                                  float flare_Orange2D_fill = 1.4f;
                                  float flare_Orange2D_offset = -0.2f;
                                vec2 flare_Orange2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *aspectRatio*flare_Orange2D_scale.x,  ((1.0 - lPos.y)*(flare_Orange2D_offset + 1.0) - (flare_Orange2D_offset*0.5))  *flare_Orange2D_scale.y);
                       
                       
                                float flare_Orange2D_ = distance(flare_Orange2D_pos, vec2(texcoord.s*aspectRatio*flare_Orange2D_scale.x, texcoord.t*flare_Orange2D_scale.y));
                                        flare_Orange2D_ = 0.5 - flare_Orange2D_;
                                        flare_Orange2D_ = clamp(flare_Orange2D_*flare_Orange2D_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_Orange2D_ = sin(flare_Orange2D_*1.57075);
                                        flare_Orange2D_ = pow(flare_Orange2D_, 0.9f);
                                 
                                        flare_Orange2D_ *= flare_Orange2D_pow;
                                 
                                flare_Orange2_ = clamp(flare_Orange2_ - flare_Orange2D_, 0.0, 10.0);
                                flare_Orange2_ *= sunmask;
                                 
                                        tempColor3.r += flare_Orange2_*10.0f*flaremultR * (tempColor2.r / 16);
                                        tempColor3.g += flare_Orange2_*5.0f*flaremultG * (tempColor2.r / 16);
                                        tempColor3.b += flare_Orange2_*0.0f*flaremultB * (tempColor2.r / 16);
               
//--------------------------------------------------------------------------------------
   
//-------------------Green2--------------------------------------------------------------------------------------
 
            vec2 flare_Green2_scale = vec2(0.82f*flarescale3, 0.82f*flarescale3);
                          float flare_Green2_pow = 4.25f;
                          float flare_Green2_fill = 10.0f;
                          float flare_Green2_offset = -0.0f;
                        vec2 flare_Green2_pos = vec2(  ((1.0 - lPos.x)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *aspectRatio*flare_Green2_scale.x,  ((1.0 - lPos.y)*(flare_Green2_offset + 1.0) - (flare_Green2_offset*0.5))  *flare_Green2_scale.y);
                       
                       
                        float flare_Green2_ = distance(flare_Green2_pos, vec2(texcoord.s*aspectRatio*flare_Green2_scale.x, texcoord.t*flare_Green2_scale.y));
                                  flare_Green2_ = 0.5 - flare_Green2_;
                                  flare_Green2_ = clamp(flare_Green2_*flare_Green2_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Green2_ = sin(flare_Green2_*1.57075);
                                 
                                  flare_Green2_ = pow(flare_Green2_, 1.1f);
                                 
                                  flare_Green2_ *= flare_Green2_pow;                  
                                 
                                 
                                  //subtract
                                  vec2 flare_Green2D_scale = vec2(0.5193f*flarescale3, 0.5193f*flarescale3);
                                  float flare_Green2D_pow = 8.0f;
                                  float flare_Green2D_fill = 1.4f;
                                  float flare_Green2D_offset = -0.2f;
                                vec2 flare_Green2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *aspectRatio*flare_Green2D_scale.x,  ((1.0 - lPos.y)*(flare_Green2D_offset + 1.0) - (flare_Green2D_offset*0.5))  *flare_Green2D_scale.y);
                       
                       
                                float flare_Green2D_ = distance(flare_Green2D_pos, vec2(texcoord.s*aspectRatio*flare_Green2D_scale.x, texcoord.t*flare_Green2D_scale.y));
                                        flare_Green2D_ = 0.5 - flare_Green2D_;
                                        flare_Green2D_ = clamp(flare_Green2D_*flare_Green2D_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_Green2D_ = sin(flare_Green2D_*1.57075);
                                        flare_Green2D_ = pow(flare_Green2D_, 0.9f);
                                 
                                        flare_Green2D_ *= flare_Green2D_pow;
                                 
                                flare_Green2_ = clamp(flare_Green2_ - flare_Green2D_, 0.0, 10.0);
                                flare_Green2_ *= sunmask;
                                 
                                        tempColor3.r += flare_Green2_*0.0f*flaremultR * (tempColor2.r / 2);
                                        tempColor3.g += flare_Green2_*1.0f*flaremultG * (tempColor2.r / 2);
                                        tempColor3.b += flare_Green2_*0.0f*flaremultB * (tempColor2.r / 2);  
               
//--------------------------------------------------------------------------------------
 
//-------------------Blue2--------------------------------------------------------------------------------------
 
        vec2 flare_Blue2_scale = vec2(0.78f*flarescale3, 0.78f*flarescale3);
                          float flare_Blue2_pow = 4.25f;
                          float flare_Blue2_fill = 10.0f;
                          float flare_Blue2_offset = -0.0f;
                        vec2 flare_Blue2_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *aspectRatio*flare_Blue2_scale.x,  ((1.0 - lPos.y)*(flare_Blue2_offset + 1.0) - (flare_Blue2_offset*0.5))  *flare_Blue2_scale.y);
                       
                       
                        float flare_Blue2_ = distance(flare_Blue2_pos, vec2(texcoord.s*aspectRatio*flare_Blue2_scale.x, texcoord.t*flare_Blue2_scale.y));
                                  flare_Blue2_ = 0.5 - flare_Blue2_;
                                  flare_Blue2_ = clamp(flare_Blue2_*flare_Blue2_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                  flare_Blue2_ = sin(flare_Blue2_*1.57075);
                                 
                                  flare_Blue2_ = pow(flare_Blue2_, 1.1f);
                                 
                                  flare_Blue2_ *= flare_Blue2_pow;                    
                                 
                                 
                                  //subtract
                                  vec2 flare_Blue2D_scale = vec2(0.494f*flarescale3, 0.494f*flarescale3);
                                  float flare_Blue2D_pow = 8.0f;
                                  float flare_Blue2D_fill = 1.4f;
                                  float flare_Blue2D_offset = -0.2f;
                                vec2 flare_Blue2D_pos = vec2(  ((1.0 - lPos.x)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *aspectRatio*flare_Blue2D_scale.x,  ((1.0 - lPos.y)*(flare_Blue2D_offset + 1.0) - (flare_Blue2D_offset*0.5))  *flare_Blue2D_scale.y);
                       
                       
                                float flare_Blue2D_ = distance(flare_Blue2D_pos, vec2(texcoord.s*aspectRatio*flare_Blue2D_scale.x, texcoord.t*flare_Blue2D_scale.y));
                                        flare_Blue2D_ = 0.5 - flare_Blue2D_;
                                        flare_Blue2D_ = clamp(flare_Blue2D_*flare_Blue2D_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
                                        flare_Blue2D_ = sin(flare_Blue2D_*1.57075);
                                        flare_Blue2D_ = pow(flare_Blue2D_, 0.9f);
                                 
                                        flare_Blue2D_ *= flare_Blue2D_pow;
                                 
                                flare_Blue2_ = clamp(flare_Blue2_ - flare_Blue2D_, 0.0, 10.0);
                                flare_Blue2_ *= sunmask;
                                 
                                        tempColor3.r += flare_Blue2_*0.0f*flaremultR * (tempColor2.r / 2);
                                        tempColor3.g += flare_Blue2_*0.0f*flaremultG * (tempColor2.r / 2);
                                        tempColor3.b += flare_Blue2_*1.0f*flaremultB * (tempColor2.r / 2);
               
//--------------------------------------------------------------------------------------
 
 

 
        color += (tempColor3 / 4.0f);
        color += (tempColor4 / 1.0f);
    color += (tempColor * 1.0f);
                 
                 
                 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


			//anamorphic lens2
			  vec2 flareANA2scale = vec2(2.0*flarescale, 2.0*flarescale);
			  float flareANA2pow = 3.00;
			  float flareANA2fill = 1.02;
			  float flareANA2offset = 0.576;
			vec2 flareANA2pos = vec2(  ((1.0 - lPos.x)*(flareANA2offset + 1.0) - (flareANA2offset*0.5))  *aspectRatio*flareANA2scale.x,  ((1.0 - lPos.y)*(flareANA2offset + 1.0) - (flareANA2offset*0.5))  *flareANA2scale.y);
			
			
			float flareANA2 = distance(flareANA2pos, vec2(texcoord.s*aspectRatio*flareANA2scale.x, texcoord.t*flareANA2scale.y));
				  flareANA2 = 0.05 - flareANA2;
				  flareANA2 = clamp(flareANA2*flareANA2fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA2 = sin(flareANA2*10.0);
				  flareANA2 *= sunmask;
				  flareANA2 = pow(flareANA2, 1.0);
				  
				  flareANA2 *= flareANA2pow;
				  
				  	color.r += flareANA2*1.2*flaremultR;
					color.g += flareANA2*0.4*flaremultG;
					color.b += flareANA2*0.25*flaremultB;
					
			//anamorphic lens3
			  vec2 flareANA3scale = vec2(0.35*flarescale, 10.0*flarescale);
			  float flareANA3pow = 2.0;
			  float flareANA3fill = 0.8;
			  float flareANA3offset = -2.0;
			  
			vec2 flareANA3pos = vec2(  ((1.0 - lPos.x)*(flareANA3offset + 1.0) - (flareANA3offset*0.5))  *aspectRatio*flareANA3scale.x,  ((1.0 - lPos.y)*(flareANA3offset + 1.0) - (flareANA3offset*0.5))  *flareANA3scale.y);
			
			
			float flareANA3 = distance(flareANA3pos, vec2(texcoord.s*aspectRatio*flareANA3scale.x, texcoord.t*flareANA3scale.y));
				  flareANA3 = 0.5 - flareANA3;
				  flareANA3 = clamp(flareANA3*flareANA3fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA3 = sin(flareANA3*1.57075);
				  flareANA3 *= sunmask;
				  flareANA3 = pow(flareANA3, 1.1);
				  
				  flareANA3 *= flareANA3pow;
				  
				  	color.r += flareANA3*0.7 * timeNoon;
					color.g += flareANA3*0.5 * timeNoon;
					color.b += flareANA3*0.6 * timeNoon;
		




//Center white flare
			vec2 flare1scale = vec2(1.7f*flarescale, 1.7f*flarescale);
			float flare1pow = 6.0f;
			vec2 flare1pos = vec2(lPos.x*aspectRatio*flare1scale.x, lPos.y*flare1scale.y);
			
			
			float flare1 = distance(flare1pos, vec2(texcoord.s*aspectRatio*flare1scale.x, texcoord.t*flare1scale.y));
				  flare1 = 0.5 - flare1;
				  flare1 = clamp(flare1, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare1 *= sunmask;
				  flare1 = pow(flare1, 1.8f);
				  
				  flare1 *= flare1pow;
				  
				  	color.r += flare1*0.7f*flaremultR;
					color.g += flare1*0.4f*flaremultG;
					color.b += flare1*0.2f*flaremultB;	
				  			
							
							
			//Center white flare
			  vec2 flare1Bscale = vec2(0.5f*flarescale, 0.5f*flarescale);
			  float flare1Bpow = 1.0f;
			vec2 flare1Bpos = vec2(lPos.x*aspectRatio*flare1Bscale.x, lPos.y*flare1Bscale.y);
			
			
			float flare1B = distance(flare1Bpos, vec2(texcoord.s*aspectRatio*flare1Bscale.x, texcoord.t*flare1Bscale.y));
				  flare1B = 0.5 - flare1B;
				  flare1B = clamp(flare1B, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare1B *= sunmask;
				  flare1B = pow(flare1B, 1.8f);
				  
				  flare1B *= flare1Bpow;
				  
				  	color.r += flare1B*0.7f*flaremultR;
					color.g += flare1B*0.2f*flaremultG;
					color.b += flare1B*0.0f*flaremultB;	
				  
				  
			//Wide red flare
			vec2 flare2pos = vec2(lPos.x*aspectRatio*0.2, lPos.y);
			
			float flare2 = distance(flare2pos, vec2(texcoord.s*aspectRatio*0.2, texcoord.t));
				  flare2 = 0.3 - flare2;
				  flare2 = clamp(flare2, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare2 *= sunmask;
				  flare2 = pow(flare2, 1.8f);
				  	
					color.r += flare2*1.8f*flaremultR;
					color.g += flare2*0.6f*flaremultG;
					color.b += flare2*0.0f*flaremultB;
					
					
					
			//Wide red flare
			vec2 flare2posB = vec2(lPos.x*aspectRatio*0.2, lPos.y*4.0);
			
			float flare2B = distance(flare2posB, vec2(texcoord.s*aspectRatio*0.2, texcoord.t*4.0));
				  flare2B = 0.3 - flare2B;
				  flare2B = clamp(flare2B, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare2B *= sunmask;
				  flare2B = pow(flare2B, 1.8f);
				  	
					color.r += flare2B*1.2f*flaremultR;
					color.g += flare2B*0.5f*flaremultG;
					color.b += flare2B*0.0f*flaremultB;
					
					
					
			//Far blue flare MAIN
			  vec2 flare3scale = vec2(2.0f*flarescale, 2.0f*flarescale);
			  float flare3pow = 0.7f;
			  float flare3fill = 10.0f;
			  float flare3offset = -0.5f;
			vec2 flare3pos = vec2(  ((1.0 - lPos.x)*(flare3offset + 1.0) - (flare3offset*0.5))  *aspectRatio*flare3scale.x,  ((1.0 - lPos.y)*(flare3offset + 1.0) - (flare3offset*0.5))  *flare3scale.y);
			
			
			float flare3 = distance(flare3pos, vec2(texcoord.s*aspectRatio*flare3scale.x, texcoord.t*flare3scale.y));
				  flare3 = 0.5 - flare3;
				  flare3 = clamp(flare3*flare3fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3 = sin(flare3*1.57075);
				  flare3 *= sunmask;
				  flare3 = pow(flare3, 1.1f);
				  
				  flare3 *= flare3pow;			
				  
				  
				  //subtract from blue flare
				  vec2 flare3Bscale = vec2(1.4f*flarescale, 1.4f*flarescale);
				  float flare3Bpow = 1.0f;
				  float flare3Bfill = 2.0f;
				  float flare3Boffset = -0.65f;
				vec2 flare3Bpos = vec2(  ((1.0 - lPos.x)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *aspectRatio*flare3Bscale.x,  ((1.0 - lPos.y)*(flare3Boffset + 1.0) - (flare3Boffset*0.5))  *flare3Bscale.y);
			
			
				float flare3B = distance(flare3Bpos, vec2(texcoord.s*aspectRatio*flare3Bscale.x, texcoord.t*flare3Bscale.y));
					flare3B = 0.5 - flare3B;
					flare3B = clamp(flare3B*flare3Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare3B = sin(flare3B*1.57075);
					flare3B *= sunmask;
					flare3B = pow(flare3B, 0.9f);
				  
					flare3B *= flare3Bpow;
				  
				flare3 = clamp(flare3 - flare3B, 0.0, 10.0);
				  
				  
				  	color.r += flare3*0.0f*flaremultR;
					color.g += flare3*0.3f*flaremultG;
					color.b += flare3*1.0f*flaremultB;

					
					
					
			//Far blue flare MAIN 2
			  vec2 flare3Cscale = vec2(3.2f*flarescale, 3.2f*flarescale);
			  float flare3Cpow = 1.5f;
			  float flare3Cfill = 10.0f;
			  float flare3Coffset = -0.0f;
			vec2 flare3Cpos = vec2(  ((1.0 - lPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);
			
			
			float flare3C = distance(flare3Cpos, vec2(texcoord.s*aspectRatio*flare3Cscale.x, texcoord.t*flare3Cscale.y));
				  flare3C = 0.5 - flare3C;
				  flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3C = sin(flare3C*1.57075);
				  
				  flare3C = pow(flare3C, 1.1f);
				  
				  flare3C *= flare3Cpow;			
				  
				  
				  //subtract from blue flare
				  vec2 flare3Dscale = vec2(2.1f*flarescale, 2.1f*flarescale);
				  float flare3Dpow = 2.7f;
				  float flare3Dfill = 1.4f;
				  float flare3Doffset = -0.05f;
				vec2 flare3Dpos = vec2(  ((1.0 - lPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);
			
			
				float flare3D = distance(flare3Dpos, vec2(texcoord.s*aspectRatio*flare3Dscale.x, texcoord.t*flare3Dscale.y));
					flare3D = 0.5 - flare3D;
					flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare3D = sin(flare3D*1.57075);
					flare3D = pow(flare3D, 0.9f);
				  
					flare3D *= flare3Dpow;
				  
				flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
				flare3C *= sunmask;
				  
				  	color.r += flare3C*0.4f*flaremultR;
					color.g += flare3C*0.7f*flaremultG;
					color.b += flare3C*1.0f*flaremultB;							
					
					
					
					
					
					
					
					
					
			//far small pink flare
			  vec2 flare4scale = vec2(4.5f*flarescale, 4.5f*flarescale);
			  float flare4pow = 0.3f;
			  float flare4fill = 3.0f;
			  float flare4offset = -4.1f;
			vec2 flare4pos = vec2(  ((1.0 - lPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);
			
			
			float flare4 = distance(flare4pos, vec2(texcoord.s*aspectRatio*flare4scale.x, texcoord.t*flare4scale.y));
				  flare4 = 0.5 - flare4;
				  flare4 = clamp(flare4*flare4fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4 = sin(flare4*1.57075);
				  flare4 *= sunmask;
				  flare4 = pow(flare4, 1.1f);
				  
				  flare4 *= flare4pow;
				  
				  	color.r += flare4*0.6f*flaremultR;
					color.g += flare4*0.0f*flaremultG;
					color.b += flare4*0.8f*flaremultB;							
					
					
					
			//far small pink flare2
			  vec2 flare4Bscale = vec2(7.5f*flarescale, 7.5f*flarescale);
			  float flare4Bpow = 0.4f;
			  float flare4Bfill = 2.0f;
			  float flare4Boffset = -4.0f;
			vec2 flare4Bpos = vec2(  ((1.0 - lPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);
			
			
			float flare4B = distance(flare4Bpos, vec2(texcoord.s*aspectRatio*flare4Bscale.x, texcoord.t*flare4Bscale.y));
				  flare4B = 0.5 - flare4B;
				  flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4B = sin(flare4B*1.57075);
				  flare4B *= sunmask;
				  flare4B = pow(flare4B, 1.1f);
				  
				  flare4B *= flare4Bpow;
				  
				  	color.r += flare4B*0.4f*flaremultR;
					color.g += flare4B*0.0f*flaremultG;
					color.b += flare4B*0.8f*flaremultB;						
					
					
					
			//far small pink flare3
			  vec2 flare4Cscale = vec2(37.5f*flarescale, 37.5f*flarescale);
			  float flare4Cpow = 1.0f;
			  float flare4Cfill = 1.0f;
			  float flare4Coffset = 0.0f;
			vec2 flare4Cpos = vec2(  ((1.0 - lPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);
			
			
			float flare4C = distance(flare4Cpos, vec2(texcoord.s*aspectRatio*flare4Cscale.x, texcoord.t*flare4Cscale.y));
				  flare4C = 1.0 - flare4C;
				  flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4C = sin(flare4C*1.57075);
				  flare4C *= sunmask;
				  flare4C = pow(flare4C, 1.1f);
				  
				  flare4C *= flare4Cpow;
				  
				  	color.r += flare4C*0.2f*flaremultR;
					color.g += flare4C*0.6f*flaremultG;
					color.b += flare4C*0.8f*flaremultB;						
					
					
					
			//far small pink flare4
			  vec2 flare4Dscale = vec2(67.5f*flarescale, 67.5f*flarescale);
			  float flare4Dpow = 1.0f;
			  float flare4Dfill = 2.0f;
			  float flare4Doffset = -4.35f;
			vec2 flare4Dpos = vec2(  ((1.0 - lPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);
			
			
			float flare4D = distance(flare4Dpos, vec2(texcoord.s*aspectRatio*flare4Dscale.x, texcoord.t*flare4Dscale.y));
				  flare4D = 0.5 - flare4D;
				  flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4D = sin(flare4D*1.57075);
				  flare4D *= sunmask;
				  flare4D = pow(flare4D, 1.1f);
				  
				  flare4D *= flare4Dpow;
				  
				  	color.r += flare4D*0.2f*flaremultR;
					color.g += flare4D*0.2f*flaremultG;
					color.b += flare4D*0.8f*flaremultB;						
					
					
								
			//far small pink flare5
			  vec2 flare4Escale = vec2(60.5f*flarescale, 60.5f*flarescale);
			  float flare4Epow = 1.0f;
			  float flare4Efill = 3.0f;
			  float flare4Eoffset = -0.3393f;
			vec2 flare4Epos = vec2(  ((1.0 - lPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);
			
			
			float flare4E = distance(flare4Epos, vec2(texcoord.s*aspectRatio*flare4Escale.x, texcoord.t*flare4Escale.y));
				  flare4E = 0.5 - flare4E;
				  flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4E = sin(flare4E*1.57075);
				  flare4E *= sunmask;
				  flare4E = pow(flare4E, 1.1f);
				  
				  flare4E *= flare4Epow;
				  
				  	color.r += flare4E*0.2f*flaremultR;
					color.g += flare4E*0.2f*flaremultG;
					color.b += flare4E*0.6f*flaremultB;					
					
								
								
			//far small pink flare5
			  vec2 flare4Fscale = vec2(20.5f*flarescale, 20.5f*flarescale);
			  float flare4Fpow = 3.0f;
			  float flare4Ffill = 3.0f;
			  float flare4Foffset = -0.4713f;
			vec2 flare4Fpos = vec2(  ((1.0 - lPos.x)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *aspectRatio*flare4Fscale.x,  ((1.0 - lPos.y)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *flare4Fscale.y);
			
			
			float flare4F = distance(flare4Fpos, vec2(texcoord.s*aspectRatio*flare4Fscale.x, texcoord.t*flare4Fscale.y));
				  flare4F = 0.5 - flare4F;
				  flare4F = clamp(flare4F*flare4Ffill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4F = sin(flare4F*1.57075);
				  flare4F *= sunmask;
				  flare4F = pow(flare4F, 1.1f);
				  
				  flare4F *= flare4Fpow;
				  
				  	color.r += flare4F*0.6f*flaremultR;
					color.g += flare4F*0.1f*flaremultG;
					color.b += flare4F*0.1f*flaremultB;						
					
					
					
					
					
					
					
					
					
					
					
					
			//
			  vec2 flare5scale = vec2(3.2f*flarescale , 3.2f*flarescale );
			  float flare5pow = 13.4f;
			  float flare5fill = 1.0f;
			  float flare5offset = -2.0f;
			vec2 flare5pos = vec2(  ((1.0 - lPos.x)*(flare5offset + 1.0) - (flare5offset*0.5))  *aspectRatio*flare5scale.x,  ((1.0 - lPos.y)*(flare5offset + 1.0) - (flare5offset*0.5))  *flare5scale.y);
			
			
			float flare5 = distance(flare5pos, vec2(texcoord.s*aspectRatio*flare5scale.x, texcoord.t*flare5scale.y));
				  flare5 = 0.5 - flare5;
				  flare5 = clamp(flare5*flare5fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare5 *= sunmask;
				  flare5 = pow(flare5, 1.9f);
				  
				  flare5 *= flare5pow;
				  
				  	color.r += flare5*0.9f*flaremultR;
					color.g += flare5*0.4f*flaremultG;
					color.b += flare5*0.3f*flaremultB;						
					
					
					/*
			//Soft blue strip 
			  vec2 flare5Bscale = vec2(0.5f*flarescale , 3.5f*flarescale );
			  float flare5Bpow = 1.4f;
			  float flare5Bfill = 2.0f;
			  float flare5Boffset = -4.9f;
			vec2 flare5Bpos = vec2(  ((1.0 - lPos.x)*(flare5Boffset + 1.0) - (flare5Boffset*0.5))  *aspectRatio*flare5Bscale.x,  ((1.0 - lPos.y)*(flare5Boffset + 1.0) - (flare5Boffset*0.5))  *flare5Bscale.y);
			
			
			float flare5B = distance(flare5Bpos, vec2(texcoord.s*aspectRatio*flare5Bscale.x, texcoord.t*flare5Bscale.y));
				  flare5B = 0.1 - flare5B;
				  flare5B = clamp(flare5B*flare5Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare5B *= sunmask;
				  flare5B = pow(flare5B, 1.4f);
				  
				  flare5B *= flare5Bpow;
				  
				  	color.r += flare5B*0.9f*flaremultR;
					color.g += flare5B*0.3f*flaremultG;
					color.b += flare5B*0.0f*flaremultB;						
					*/
					
					
					
			//close ring flare red
			  vec2 flare6scale = vec2(1.2f*flarescale, 1.2f*flarescale);
			  float flare6pow = 0.2f;
			  float flare6fill = 5.0f;
			  float flare6offset = -1.9f;
			vec2 flare6pos = vec2(  ((1.0 - lPos.x)*(flare6offset + 1.0) - (flare6offset*0.5))  *aspectRatio*flare6scale.x,  ((1.0 - lPos.y)*(flare6offset + 1.0) - (flare6offset*0.5))  *flare6scale.y);
			
			
			float flare6 = distance(flare6pos, vec2(texcoord.s*aspectRatio*flare6scale.x, texcoord.t*flare6scale.y));
				  flare6 = 0.5 - flare6;
				  flare6 = clamp(flare6*flare6fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare6 = pow(flare6, 1.6f);
				  flare6 = sin(flare6*3.1415);
				  flare6 *= sunmask;

				  
				  flare6 *= flare6pow;
				  
				  	color.r += flare6*0.6f*flaremultR;
					color.g += flare6*0.0f*flaremultG;
					color.b += flare6*0.0f*flaremultB;						
					
					
					
			//close ring flare green
			  vec2 flare6Bscale = vec2(1.1f*flarescale, 1.1f*flarescale);
			  float flare6Bpow = 0.2f;
			  float flare6Bfill = 5.0f;
			  float flare6Boffset = -1.9f;
			vec2 flare6Bpos = vec2(  ((1.0 - lPos.x)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *aspectRatio*flare6Bscale.x,  ((1.0 - lPos.y)*(flare6Boffset + 1.0) - (flare6Boffset*0.5))  *flare6Bscale.y);
			
			
			float flare6B = distance(flare6Bpos, vec2(texcoord.s*aspectRatio*flare6Bscale.x, texcoord.t*flare6Bscale.y));
				  flare6B = 0.5 - flare6B;
				  flare6B = clamp(flare6B*flare6Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare6B = pow(flare6B, 1.6f);
				  flare6B = sin(flare6B*3.1415);
				  flare6B *= sunmask;

				  
				  flare6B *= flare6Bpow;
				  
				  	color.r += flare6B*0.0f*flaremultR;
					color.g += flare6B*0.4f*flaremultG;
					color.b += flare6B*0.0f*flaremultB;						
					
					
			
			//close ring flare blue
			  vec2 flare6Cscale = vec2(0.9f*flarescale, 0.9f*flarescale);
			  float flare6Cpow = 0.2f;
			  float flare6Cfill = 5.0f;
			  float flare6Coffset = -1.9f;
			vec2 flare6Cpos = vec2(  ((1.0 - lPos.x)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *aspectRatio*flare6Cscale.x,  ((1.0 - lPos.y)*(flare6Coffset + 1.0) - (flare6Coffset*0.5))  *flare6Cscale.y);
			
			
			float flare6C = distance(flare6Cpos, vec2(texcoord.s*aspectRatio*flare6Cscale.x, texcoord.t*flare6Cscale.y));
				  flare6C = 0.5 - flare6C;
				  flare6C = clamp(flare6C*flare6Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare6C = pow(flare6C, 1.8f);
				  flare6C = sin(flare6C*3.1415);
				  flare6C *= sunmask;

				  
				  flare6C *= flare6Cpow;
				  
				  	color.r += flare6C*0.0f*flaremultR;
					color.g += flare6C*0.0f*flaremultG;
					color.b += flare6C*0.4f*flaremultB;						
					
					
					
					
			//far red ring

			  vec2 flare7scale = vec2(0.4f*flarescale, 0.4f*flarescale);
			  float flare7pow = 0.2f;
			  float flare7fill = 10.0f;
			  float flare7offset = 2.6f;
			vec2 flare7pos = vec2(  ((1.0 - lPos.x)*(flare7offset + 1.0) - (flare7offset*0.5))  *aspectRatio*flare7scale.x,  ((1.0 - lPos.y)*(flare7offset + 1.0) - (flare7offset*0.5))  *flare7scale.y);
			
			
			float flare7 = distance(flare7pos, vec2(texcoord.s*aspectRatio*flare7scale.x, texcoord.t*flare7scale.y));
				  flare7 = 0.5 - flare7;
				  flare7 = clamp(flare7*flare7fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare7 = pow(flare7, 1.9f);
				  flare7 = sin(flare7*3.1415);
				  flare7 *= sunmask;

				  
				  flare7 *= flare7pow;
				  
				  	color.r += flare7*1.0f*flaremultR;
					color.g += flare7*0.0f*flaremultG;
					color.b += flare7*0.0f*flaremultB;				
					
					
					
			//far blue ring

			  vec2 flare7Dscale = vec2(0.39f*flarescale, 0.39f*flarescale);
			  float flare7Dpow = 0.1f;
			  float flare7Dfill = 10.0f;
			  float flare7Doffset = 2.6f;
			vec2 flare7Dpos = vec2(  ((1.0 - lPos.x)*(flare7Doffset + 1.0) - (flare7Doffset*0.5))  *aspectRatio*flare7Dscale.x,  ((1.0 - lPos.y)*(flare7Doffset + 1.0) - (flare7Doffset*0.5))  *flare7Dscale.y);
			
			
			float flare7D = distance(flare7Dpos, vec2(texcoord.s*aspectRatio*flare7Dscale.x, texcoord.t*flare7Dscale.y));
				  flare7D = 0.5 - flare7D;
				  flare7D = clamp(flare7D*flare7Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare7D = pow(flare7D, 1.9f);
				  flare7D = sin(flare7D*3.1415);
				  flare7D *= sunmask;

				  
				  flare7D *= flare7Dpow;
				  
				  	color.r += flare7D*0.0f*flaremultR;
					color.g += flare7D*0.6f*flaremultG;
					color.b += flare7D*0.0f*flaremultB;				
					
					
					
			//far red glow

			  vec2 flare7Bscale = vec2(0.2f*flarescale, 0.2f*flarescale);
			  float flare7Bpow = 0.1f;
			  float flare7Bfill = 2.0f;
			  float flare7Boffset = 2.9f;
			vec2 flare7Bpos = vec2(  ((1.0 - lPos.x)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *aspectRatio*flare7Bscale.x,  ((1.0 - lPos.y)*(flare7Boffset + 1.0) - (flare7Boffset*0.5))  *flare7Bscale.y);
			
			
			float flare7B = distance(flare7Bpos, vec2(texcoord.s*aspectRatio*flare7Bscale.x, texcoord.t*flare7Bscale.y));
				  flare7B = 0.5 - flare7B;
				  flare7B = clamp(flare7B*flare7Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare7B = pow(flare7B, 1.9f);
				  flare7B = sin(flare7B*3.1415*0.5);
				  flare7B *= sunmask;

				  
				  flare7B *= flare7Bpow;
				  
				  	color.r += flare7B*1.0f*flaremultR;
					color.g += flare7B*0.0f*flaremultG;
					color.b += flare7B*0.0f*flaremultB;	
			
			
			#ifdef EDGE_BLUE_STRIP
			//Edge blue strip 1
			  vec2 flare8scale = vec2(0.3f*flarescale, 40.5f*flarescale);
			  float flare8pow = 0.5f;
			  float flare8fill = 12.0f;
			  float flare8offset = 1.0f;
			vec2 flare8pos = vec2(  ((1.0 - lPos.x)*(flare8offset + 1.0) - (flare8offset*0.5))  *aspectRatio*flare8scale.x,  ((lPos.y)*(flare8offset + 1.0) - (flare8offset*0.5))  *flare8scale.y);
			
			
			float flare8 = distance(flare8pos, vec2(texcoord.s*aspectRatio*flare8scale.x, texcoord.t*flare8scale.y));
				  flare8 = 0.5 - flare8;
				  flare8 = clamp(flare8*flare8fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare8 *= sunmask;
				  flare8 = pow(flare8, 1.4f);
				  
				  flare8 *= flare8pow;
				  flare8 *= edgemaskx;
				  
				  	color.r += flare8*0.0f*flaremultR;
					color.g += flare8*0.3f*flaremultG;
					color.b += flare8*0.8f*flaremultB;					
			
		
		
			//Edge blue strip 1
			  vec2 flare9scale = vec2(0.2f*flarescale, 5.5f*flarescale);
			  float flare9pow = 1.9f;
			  float flare9fill = 2.0f;
			  vec2 flare9offset = vec2(1.0f, 0.0f);
			vec2 flare9pos = vec2(  ((1.0 - lPos.x)*(flare9offset.x + 1.0) - (flare9offset.x*0.5))  *aspectRatio*flare9scale.x,  ((1.0 - lPos.y)*(flare9offset.y + 1.0) - (flare9offset.y*0.5))  *flare9scale.y);
			
			
			float flare9 = distance(flare9pos, vec2(texcoord.s*aspectRatio*flare9scale.x, texcoord.t*flare9scale.y));
				  flare9 = 0.5 - flare9;
				  flare9 = clamp(flare9*flare9fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare9 *= sunmask;
				  flare9 = pow(flare9, 1.4f);
				  
				  flare9 *= flare9pow;
				  flare9 *= edgemaskx;
				  
				  	color.r += flare9*0.2f*flaremultR;
					color.g += flare9*0.4f*flaremultG;
					color.b += flare9*0.9f*flaremultB;		
			#endif		
					
					
		//SMALL SWEEPS		///////////////////////////////						
						
			//mid orange sweep
			  vec2 flare10scale = vec2(6.0f*flarescale, 6.0f*flarescale);
			  float flare10pow = 1.9f;
			  float flare10fill = 1.1f;
			  float flare10offset = -0.7f;
			vec2 flare10pos = vec2(  ((1.0 - lPos.x)*(flare10offset + 1.0) - (flare10offset*0.5))  *aspectRatio*flare10scale.x,  ((1.0 - lPos.y)*(flare10offset + 1.0) - (flare10offset*0.5))  *flare10scale.y);
			
			
			float flare10 = distance(flare10pos, vec2(texcoord.s*aspectRatio*flare10scale.x, texcoord.t*flare10scale.y));
				  flare10 = 0.5 - flare10;
				  flare10 = clamp(flare10*flare10fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare10 = sin(flare10*1.57075);
				  flare10 *= sunmask;
				  flare10 = pow(flare10, 1.1f);
				  
				  flare10 *= flare10pow;			
				  
				  
				  //subtract
				  vec2 flare10Bscale = vec2(5.1f*flarescale, 5.1f*flarescale);
				  float flare10Bpow = 1.5f;
				  float flare10Bfill = 1.0f;
				  float flare10Boffset = -0.77f;
				vec2 flare10Bpos = vec2(  ((1.0 - lPos.x)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *aspectRatio*flare10Bscale.x,  ((1.0 - lPos.y)*(flare10Boffset + 1.0) - (flare10Boffset*0.5))  *flare10Bscale.y);
			
			
				float flare10B = distance(flare10Bpos, vec2(texcoord.s*aspectRatio*flare10Bscale.x, texcoord.t*flare10Bscale.y));
					flare10B = 0.5 - flare10B;
					flare10B = clamp(flare10B*flare10Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare10B = sin(flare10B*1.57075);
					flare10B *= sunmask;
					flare10B = pow(flare10B, 0.9f);
				  
					flare10B *= flare10Bpow;
				  
				flare10 = clamp(flare10 - flare10B, 0.0, 10.0);
				  
				  
				  	color.r += flare10*0.8f*flaremultR;
					color.g += flare10*0.2f*flaremultG;
					color.b += flare10*0.0f*flaremultB;				
					
					
			//mid blue sweep
			  vec2 flare10Cscale = vec2(6.0f*flarescale, 6.0f*flarescale);
			  float flare10Cpow = 1.9f;
			  float flare10Cfill = 1.1f;
			  float flare10Coffset = -0.6f;
			vec2 flare10Cpos = vec2(  ((1.0 - lPos.x)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *aspectRatio*flare10Cscale.x,  ((1.0 - lPos.y)*(flare10Coffset + 1.0) - (flare10Coffset*0.5))  *flare10Cscale.y);
			
			
			float flare10C = distance(flare10Cpos, vec2(texcoord.s*aspectRatio*flare10Cscale.x, texcoord.t*flare10Cscale.y));
				  flare10C = 0.5 - flare10C;
				  flare10C = clamp(flare10C*flare10Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare10C = sin(flare10C*1.57075);
				  flare10C *= sunmask;
				  flare10C = pow(flare10C, 1.1f);
				  
				  flare10C *= flare10Cpow;			
				  
				  
				  //subtract
				  vec2 flare10Dscale = vec2(5.1f*flarescale, 5.1f*flarescale);
				  float flare10Dpow = 1.5f;
				  float flare10Dfill = 1.0f;
				  float flare10Doffset = -0.67f;
				vec2 flare10Dpos = vec2(  ((1.0 - lPos.x)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *aspectRatio*flare10Dscale.x,  ((1.0 - lPos.y)*(flare10Doffset + 1.0) - (flare10Doffset*0.5))  *flare10Dscale.y);
			
			
				float flare10D = distance(flare10Dpos, vec2(texcoord.s*aspectRatio*flare10Dscale.x, texcoord.t*flare10Dscale.y));
					flare10D = 0.5 - flare10D;
					flare10D = clamp(flare10D*flare10Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare10D = sin(flare10D*1.57075);
					flare10D *= sunmask;
					flare10D = pow(flare10D, 0.9f);
				  
					flare10D *= flare10Dpow;
				  
				flare10C = clamp(flare10C - flare10D, 0.0, 10.0);
				  
				  
				  	color.r += flare10C*0.0f*flaremultR;
					color.g += flare10C*0.2f*flaremultG;
					color.b += flare10C*0.9f*flaremultB;	
		//////////////////////////////////////////////////////////

        //RedGlow1
 
           vec2 flare11scale = vec2(1.5f*flarescale, 1.5f*flarescale);
           float flare11pow = 1.1f;
           float flare11fill = 2.0f;
           float flare11offset = -0.523f;
         vec2 flare11pos = vec2(  ((1.0 - lPos.x)*(flare11offset + 1.0) - (flare11offset*0.5))  *aspectRatio*flare11scale.x,  ((1.0 - lPos.y)*(flare11offset + 1.0) - (flare11offset*0.5))  *flare11scale.y);
         
         
         float flare11 = distance(flare11pos, vec2(texcoord.s*aspectRatio*flare11scale.x, texcoord.t*flare11scale.y));
              flare11 = 0.5 - flare11;
              flare11 = clamp(flare11*flare11fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare11 = pow(flare11, 2.9f);
              flare11 *= sunmask;
 
             
              flare11 *= flare11pow;
             
                 color.r += flare11*1.0f*flaremultR;
               color.g += flare11*0.2f*flaremultG;
               color.b += flare11*0.0f*flaremultB;      
               
               
         //PurpleGlow2
 
           vec2 flare12scale = vec2(2.5f*flarescale, 2.5f*flarescale);
           float flare12pow = 0.5f;
           float flare12fill = 2.0f;
           float flare12offset = -0.323f;
         vec2 flare12pos = vec2(  ((1.0 - lPos.x)*(flare12offset + 1.0) - (flare12offset*0.5))  *aspectRatio*flare12scale.x,  ((1.0 - lPos.y)*(flare12offset + 1.0) - (flare12offset*0.5))  *flare12scale.y);
         
         
         float flare12 = distance(flare12pos, vec2(texcoord.s*aspectRatio*flare12scale.x, texcoord.t*flare12scale.y));
              flare12 = 0.5 - flare12;
              flare12 = clamp(flare12*flare12fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare12 = pow(flare12, 2.9f);
              flare12 *= sunmask;
 
             
              flare12 *= flare12pow;
             
                 color.r += flare12*0.7f*flaremultR;
               color.g += flare12*0.3f*flaremultG;
               color.b += flare12*0.0f*flaremultB;      
               
               
               
         //BlueGlow3
 
           vec2 flare13scale = vec2(1.0f*flarescale, 1.0f*flarescale);
           float flare13pow = 1.5f;
           float flare13fill = 2.0f;
           float flare13offset = +0.138f;
         vec2 flare13pos = vec2(  ((1.0 - lPos.x)*(flare13offset + 1.0) - (flare13offset*0.5))  *aspectRatio*flare13scale.x,  ((1.0 - lPos.y)*(flare13offset + 1.0) - (flare13offset*0.5))  *flare13scale.y);
         
         
         float flare13 = distance(flare13pos, vec2(texcoord.s*aspectRatio*flare13scale.x, texcoord.t*flare13scale.y));
              flare13 = 0.5 - flare13;
              flare13 = clamp(flare13*flare13fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare13 = pow(flare13, 2.9f);
              flare13 *= sunmask;
 
             
              flare13 *= flare13pow;
             
               color.r += flare13*0.5f*flaremultR;
               color.g += flare13*0.3f*flaremultG;
               color.b += flare13*0.0f*flaremultB;      		
	
			  color.rgb = clamp(color.rgb, 0.0, 10.0);


	
				
					
	
         
 
         }
   }
}

void MoonGlow(inout vec3 color)
{
    vec4 tpos = vec4(moonPosition, 1.0) * gbufferProjection;
   tpos = vec4(tpos.xyz / tpos.w, 1.0);
   
    vec2 lPos = tpos.xy / tpos.z;
    lPos = (lPos + 1.0f) / 2.0f;
   
    vec2 checkcoord = lPos;
    
    if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f && timeNoon < 1.0) 
    {
      float sunmask = 0.0f;
   
        for (int i = 0; i < 4; i++) 
        {
         for(int j = 0; j < 4; j++) 
            {
            checkcoord = lPos + vec2((1.0 / viewWidth) * i * 5.0f, (1.0 / viewHeight) * 5.0f * j);

            float matID = GetMaterialIDs(checkcoord);
            
            if (floor(matID * 255.0f) == 0) 
            {
               if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f) 
               {
                  sunmask = 1.0f;
               }
            }
         }
      }
      
      sunmask *= 0.34 * (1.0f - timeNoon);
      sunmask *= (1.0f - rainStrength);
            
      if (sunmask > 0.02)
      {  
         vec2 flareScale = vec2(0.35f, 7.0f);
         vec2 flarePos = vec2(lPos.x * aspectRatio * flareScale.x, lPos.y * flareScale.y);
             
         float flare = distance(flarePos, vec2(texcoord.s * aspectRatio * flareScale.x, texcoord.t * flareScale.y));
         flare = 0.5 - flare;
         flare = clamp(flare * 2.0f, 0.0f, 1.0f) * clamp(-moonPosition.z, 0.0f, 0.5f);
         flare *= sunmask;
         flare = pow(flare, 1.0f);
         
         color.r += flare * 0.50f * 0.4f;
         color.g += flare * 0.50f * 0.7f;
         color.b += flare * 0.85f * 1.0f;   
      }
   }
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec3 color = GetColorTexture(texcoord.st);	//Sample gcolor texture

#ifdef MOTIONBLUR
	MotionBlur(color);
#endif
	
#ifdef DOF	
	DepthOfField(color);
#endif



	CalculateBloom(bloomData);			//Gather bloom textures
	color = mix(color, bloomData.bloom, vec3(0.0095f));

	AddRainFogScatter(color, bloomData);

	//vec3 highpass = (GetColorTexture(texcoord.st).rgb - bloomData.blur0);

	//color += bloomData.blur5;

	LowlightFuzziness(color, bloomData);

	Vignette(color);

	CalculateExposure(color);

	//TonemapVorontsov(color);
	//TonemapReinhard(color);
	//TonemapReinhardLum(color);
	//TonemapReinhard07(color, bloomData);
	TonemapReinhard05(color, bloomData);
	

	//TonemapReinhardLinearHybrid(color);
	//SphericalTonemap(color);
	SaturationBoost(color);
	SaturationBoost(color);

	//color.rgb += highpass * 10000.0f;
	//LowtoneSaturate(color);

	ColorGrading(color);

#ifdef RAINDROPS
   	    RainDrops(color);
	#endif
	
#ifdef LENS_FLARE
    LensFlare(color);
#endif	

#ifdef MOON_GLOW
	MoonGlow(color);
#endif
	
	gl_FragColor = vec4(color.rgb, 1.0f);

}