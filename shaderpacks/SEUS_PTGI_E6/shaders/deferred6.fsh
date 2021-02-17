#version 130

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



/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////



#include "Common.inc"


#define SHADOW_MAP_BIAS 0.9

#define VARIABLE_PENUMBRA_SHADOWS	// Contact-hardening (area) shadows

#define GI_RENDER_RESOLUTION 1 // Render resolution of GI. 0 = High. 1 = Low. Set to 1 for faster but blurrier GI. [0 1]

#define RAYLEIGH_AMOUNT 1.0 // Density of atmospheric scattering. [0.5 1.0 1.5 2.0 3.0 4.0]

#define WATER_REFRACT_IOR 1.2


#define TORCHLIGHT_BRIGHTNESS 1.0 // Brightness of torch light. [0.5 1.0 2.0 3.0 4.0]



const int 		shadowMapResolution 	= 4096;
const float 	shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 180.0 240.0]
const float 	shadowIntervalSize 		= 1.0f;
const bool 		shadowHardwareFiltering0 = true;

const bool 		shadowtexMipmap = true;
const bool 		shadowtex1Mipmap = false;
const bool 		shadowtex1Nearest = false;
const bool 		shadowcolor0Mipmap = false;
const bool 		shadowcolor0Nearest = false;
const bool 		shadowcolor1Mipmap = false;
const bool 		shadowcolor1Nearest = false;

const float shadowDistanceRenderMul = 1.0f;

const int 		RGB8 					= 0;
const int 		RGBA8 					= 0;
const int 		RGBA16 					= 0;
const int 		RGBA16F 				= 0;
const int 		RGBA32F 				= 0;
const int 		RG16 					= 0;
const int 		RGB16 					= 0;
const int 		gcolorFormat 			= RGB8;
const int 		gdepthFormat 			= RGBA16;
const int 		gnormalFormat 			= RGBA16;
const int 		compositeFormat 		= RGBA16;
const int 		gaux1Format 			= RGBA32F;
const int 		gaux2Format 			= RGBA32F;
const int 		gaux3Format 			= RGBA16;
const int 		gaux4Format 			= RGBA16;


const int 		superSamplingLevel 		= 0;

const float		sunPathRotation 		= -40.0f;

const int 		noiseTextureResolution  = 64;

const float 	ambientOcclusionLevel 	= 0.06f;


const bool gaux3MipmapEnabled = false;
const bool gaux1MipmapEnabled = false;

const bool gaux4Clear = false;

const float wetnessHalflife = 100.0;
const float drynessHalflife = 100.0;



uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D depthtex1;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

uniform sampler2DShadow shadow;


in vec4 texcoord;
in vec3 lightVector;
in vec3 sunVector;
in vec3 upVector;

uniform int worldTime;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 skyColor;

uniform int   isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   fogMode;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;

in vec3 colorSunlight;
in vec3 colorSkylight;
in vec3 colorTorchlight;

in vec4 skySHR;
in vec4 skySHG;
in vec4 skySHB;

in vec3 worldLightVector;
in vec3 worldSunVector;

uniform int heldBlockLightValue;

in float contextualFogFactor;

uniform int frameCounter;

in float heldLightBlacklist;

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

vec4 GetViewPositionRaw(in vec2 coord, in float depth) 
{	
	vec4 tcoord = vec4(coord.xy, 0.0, 0.0);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.s * 2.0f - 1.0f, tcoord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	
	return fragposition;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}


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



vec3 	CalculateNoisePattern1(vec2 offset, float size) 
{
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture2D(noisetex, coord).xyz;
}

float GetDepthLinear(in vec2 coord) 
{					
	return (near * far) / (texture2D(depthtex1, coord).x * (near - far) + far);
}

vec3 GetNormals(vec2 coord)
{
	return DecodeNormal(texture2D(gnormal, coord).xy);
}

float GetDepth(vec2 coord)
{
	return texture2D(depthtex1, coord).x;
}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "GBufferData.inc"


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
	float fire;
};

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};

/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



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
	mask.fire 			= GetMaterialMask(33, materialID);

	return mask;
}

Intersection 	RayPlaneIntersectionWorld(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.dir * planeRayDist;
		intersectionPos = -intersectionPos;

		intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

Intersection 	RayPlaneIntersection(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin - ray.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.origin + ray.dir * planeRayDist;
		// intersectionPos = -intersectionPos;

		// intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

vec3 BlueNoise(vec2 coord)
{
	vec2 noiseCoord = vec2(coord.st * vec2(viewWidth, viewHeight)) / 64.0;
	//noiseCoord += vec2(frameCounter, frameCounter);
	//noiseCoord += mod(frameCounter, 16.0) / 16.0;
	//noiseCoord += rand(vec2(mod(frameCounter, 16.0) / 16.0, mod(frameCounter, 16.0) / 16.0) + 0.5).xy;
	noiseCoord += vec2(sin(frameCounter * 0.75), cos(frameCounter * 0.75));

	noiseCoord = (floor(noiseCoord * 64.0) + 0.5) / 64.0;

	return texture2D(noisetex, noiseCoord).rgb;
}

vec3 CalculateSunlightVisibility(vec4 screenSpacePosition, MaterialMask mask) {				//Calculates shadows
	if (rainStrength >= 0.99f)
		return vec3(1.0f);



	//if (shadingStruct.direct > 0.0f) {
		float distance = sqrt(  screenSpacePosition.x * screenSpacePosition.x 	//Get surface distance in meters
							  + screenSpacePosition.y * screenSpacePosition.y
							  + screenSpacePosition.z * screenSpacePosition.z);

		vec4 ssp = screenSpacePosition;

		// if (isEyeInWater > 0.5)
		// {
		// 	ssp.xy *= 0.82;
		// }

		vec4 worldposition = vec4(0.0f);
			 worldposition = gbufferModelViewInverse * ssp;		//Transform from screen space to world space


		float yDistanceSquared  = worldposition.y * worldposition.y;

		worldposition = shadowModelView * worldposition;	//Transform from world space to shadow space
		float comparedepth = -worldposition.z;				//Surface distance from sun to be compared to the shadow map

		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;

		float dist = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
		worldposition.xy *= 0.95f / distortFactor;
		worldposition.z = mix(worldposition.z, 0.5, 0.8);
		worldposition = worldposition * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates

		float shadowMult = 0.0f;																			//Multiplier used to fade out shadows at distance
		float shading = 0.0f;

		float fademult = 0.15f;
			shadowMult = clamp((shadowDistance * 1.4f * fademult) - (distance * fademult), 0.0f, 1.0f);	//Calculate shadowMult to fade shadows out

		//move to quadrant
		worldposition.xy *= 0.5;
		worldposition.xy += 0.5;

		if (shadowMult > 0.0) 
		{

			float diffthresh = dist * 1.0f + 0.10f;
				  diffthresh *= 2.0f / (shadowMapResolution / 2048.0f);
				  //diffthresh /= shadingStruct.direct + 0.1f;


			#ifdef PIXEL_SHADOWS
				  //diffthresh += 1.5;
			#endif


			#ifdef ENABLE_SOFT_SHADOWS
			#ifndef VARIABLE_PENUMBRA_SHADOWS

				int count = 0;
				float spread = 1.0f / shadowMapResolution;

				vec3 noise = CalculateNoisePattern1(vec2(0.0), 64.0);

				for (float i = -0.5f; i <= 0.5f; i += 1.0f) 
				{
					for (float j = -0.5f; j <= 0.5f; j += 1.0f) 
					{
						float angle = noise.x * 3.14159 * 2.0;

						mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

						vec2 coord = vec2(i, j) * rot;

						shading += shadow2DLod(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0008f * diffthresh), 0).x;
						count += 1;
					}
				}
				shading /= count;

			#endif
			#endif

			#ifdef VARIABLE_PENUMBRA_SHADOWS

				float vpsSpread = 0.105 / distortFactor;

				float avgDepth = 0.0;
				float minDepth = 11.0;
				int c;

				for (int i = -1; i <= 1; i++)
				{
					for (int j = -1; j <= 1; j++)
					{
						vec2 lookupCoord = worldposition.xy + (vec2(i, j) / shadowMapResolution) * 8.0 * vpsSpread;
						//avgDepth += pow(texture2DLod(shadowtex1, lookupCoord, 2).x, 4.1);
						float depthSample = texture2DLod(shadowtex1, lookupCoord, 2).x;
						minDepth = min(minDepth, depthSample);
						avgDepth += pow(min(max(0.0, worldposition.z - depthSample) * 1.0, 0.025), 2.0);
						c++;
					}
				}

				avgDepth /= c;
				avgDepth = pow(avgDepth, 1.0 / 2.0);

				// float penumbraSize = min(abs(worldposition.z - minDepth), 0.15);
				float penumbraSize = avgDepth;

				//if (mask.leaves > 0.5)
				//{
					//penumbraSize = 0.02;
				//}

				int count = 0;
				float spread = penumbraSize * 0.075 * vpsSpread + 0.75 / shadowMapResolution;

				//vec3 noise = CalculateNoisePattern1(vec2(0.0 + sin(frameTimeCounter)), 64.0);
				// vec3 noise = rand(texcoord.st + sin(frameTimeCounter)).xyz;
				vec3 noise = BlueNoise(texcoord.st);

				diffthresh *= 0.5 + avgDepth * 50.0;

				for (float i = -1.0f; i <= 1.0f; i += 1.0f) 
				{
					for (float j = -1.0f; j <= 1.0f; j += 1.0f) 
					{
						float angle = noise.x * 3.14159 * 2.0;

						mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));

						vec2 coord = vec2(i + noise.y - 0.5, j + noise.y - 0.5) * rot;

						shading += shadow2DLod(shadow, vec3(worldposition.st + coord * spread, worldposition.z - 0.0012f * diffthresh - (noise.z * 0.0001)), 0).x;
						count += 1;
					}
				}
				shading /= count;

			#endif

			#ifndef VARIABLE_PENUMBRA_SHADOWS
			#ifndef ENABLE_SOFT_SHADOWS
				//diffthresh *= 2.0f;
				shading = shadow2DLod(shadow, vec3(worldposition.st, worldposition.z - 0.0006f * diffthresh), 0).x;
			#endif
			#endif

		}

		//shading = mix(1.0f, shading, shadowMult);

		//surface.shadow = shading;

		vec3 result = vec3(shading);


		///*
		#ifdef COLORED_SHADOWS
		float shadowNormalAlpha = texture2DLod(shadowcolor1, worldposition.st, 0).a;

		vec3 noise2 = CalculateNoisePattern1(vec2(0.0), 64.0);

		//worldposition.st += (noise2.xy * 2.0 - 1.0) / shadowMapResolution;

		if (shadowNormalAlpha < 0.5)
		{
			result = mix(vec3(1.0), pow(texture2DLod(shadowcolor, worldposition.st, 0).rgb, vec3(1.6)), vec3(1.0 - shading));
			float solidDepth = texture2DLod(shadowtex1, worldposition.st, 0).x;
			float solidShadow = 1.0 - clamp((worldposition.z - solidDepth) * 1200.0, 0.0, 1.0); 
			result *= solidShadow;
		}
		#endif
		//*/

		result = mix(vec3(1.0), result, shadowMult);

		return result;
	//} else {
	//	return vec3(0.0f);
	//}
}

float RenderSunDisc(vec3 worldDir, vec3 sunDir)
{
	float d = dot(worldDir, sunDir);

	float disc = 0.0;

	//if (d > 0.99)
	//	disc = 1.0;

	float size = 0.00195;
	float hardness = 1000.0;

	disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 30.0));

	disc *= visibility;

	return disc;
}



vec3 ProjectBack(vec3 cameraSpace) 
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 //screenSpace.z = 0.1f;
    return screenSpace;
}


float ScreenSpaceShadow(vec3 origin, vec3 normal, MaterialMask mask)
{
	if (mask.sky > 0.5 || rainStrength >= 0.999)
	{
		return 1.0;
	}

	if (isEyeInWater > 0.5)
	{
		//origin.xy *=
	}

	if (isEyeInWater > 0.5)
	{
		origin.xy /= 0.82;
	}

	vec3 viewDir = normalize(origin.xyz);


	float nearCutoff = 0.50;
	float traceBias = 0.015;


	//Prevent self-intersection issues
	float viewDirDiff = dot(fwidth(viewDir), vec3(0.333333));


	vec3 rayPos = origin;
	vec3 rayDir = lightVector * 0.01;
	rayDir *= viewDirDiff * 2000.001;
	rayDir *= -origin.z * 0.28 + nearCutoff;


	rayPos += rayDir * -origin.z * 0.000017 * traceBias;



	float randomness = rand(texcoord.st + sin(frameTimeCounter)).x;

	rayPos += rayDir * randomness;



	float zThickness = 0.025 * -origin.z;

	float shadow = 1.0;

	float numSamplesf = 64.0;
	//numSamplesf /= -origin.z * 0.125 + nearCutoff;

	int numSamples = int(numSamplesf);


	float shadowStrength = 0.9;

	if (mask.grass > 0.5)
	{
		shadowStrength = 0.6;
	}
	if (mask.leaves > 0.5)
	{
		shadowStrength = 0.4;
	}

	// shadowStrength = pow(shadowStrength, exp2(-length(origin) * 0.05));

	// vec3 prevRayProjPos = ProjectBack(rayPos);

	for (int i = 0; i < 6; i++)
	{
		float fi = float(i) / float(12);

		rayPos += rayDir;

		vec2 rayProjPos = ProjectBack(rayPos).xy;


		TemporalJitterProjPos01(rayProjPos);




		// vec2 pixelPos = floor(rayProjPos.xy * vec2(viewWidth, viewHeight));
		// vec2 pixelPosPrev = floor(prevRayProjPos.xy * vec2(viewWidth, viewHeight));
		// if (pixelPos.x == pixelPosPrev.x || pixelPos.y == pixelPosPrev.y)
		// {
		// 	continue;
		// }

		// prevRayProjPos = rayProjPos;

		/*
		float sampleDepth = GetDepthLinear(rayProjPos.xy);

		float depthDiff = -rayPos.z - sampleDepth;
		*/

		vec3 samplePos = GetViewPositionRaw(rayProjPos.xy, GetDepth(rayProjPos.xy)).xyz;

		float depthDiff = samplePos.z - rayPos.z - 0.02 * -origin.z * traceBias;

		if (depthDiff > 0.0 && depthDiff < zThickness)
		{
			shadow *= 1.0 - shadowStrength;
		}
	}

	return shadow;
}


float OrenNayar(vec3 normal, vec3 eyeDir, vec3 lightDir)
{
	const float PI = 3.14159;
	const float roughness = 0.55;

	// interpolating normals will change the length of the normal, so renormalize the normal.



	// normal = normalize(normal + surface.lightVector * pow(clamp(dot(eyeDir, surface.lightVector), 0.0, 1.0), 5.0) * 0.5);

	// normal = normalize(normal + eyeDir * clamp(dot(normal, eyeDir), 0.0f, 1.0f));

	// calculate intermediary values
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);

	float angleVN = acos(NdotV);
	float angleLN = acos(NdotL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);
	float gamma = dot(eyeDir - normal * dot(eyeDir, normal), lightDir - normal * dot(lightDir, normal));

	float roughnessSquared = roughness * roughness;

	// calculate A and B
	float A = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.57));

	float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));

	float C = sin(alpha) * tan(beta);

	// put it all together
	float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);

	//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
	return clamp(L1, 0.0f, 1.0f);
}


float Get2DNoise(in vec2 pos)
{
	pos.xy += 0.5f;

	vec2 p = floor(pos);
	vec2 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);

	vec2 uv =  p.xy + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	return xy1;
}

float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

float GetCoverage(in float coverage, in float density, in float clouds)
{
	clouds = clamp(clouds - (1.0f - coverage), 0.0f, 1.0f -density) / (1.0f - density);
		clouds = max(0.0f, clouds * 1.1f - 0.1f);
	 clouds = clouds = clouds * clouds * (3.0f - 2.0f * clouds);
	 // clouds = pow(clouds, 1.0f);
	return clouds;
}

float   CalculateSunglow(vec3 npos, vec3 lightVector) {

	float curve = 4.0f;

	vec3 halfVector2 = normalize(-lightVector + npos);
	float factor = 1.0f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

vec4 CloudColor(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float thickness, const bool isShadowPass)
{

	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	//worldPosition.xz /= 1.0f + max(0.0f, length(worldPosition.xz - cameraPosition.xz) / 5000.0f);

	vec3 p = worldPosition.xyz / 150.0f;



	float t = frameTimeCounter * 1.0f;
		  t *= 0.5;


	 p += (Get3DNoise(p * 2.0f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.10f;
	 p.z -= (Get3DNoise(p * 0.25f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 0.45f;
	 p.x -= (Get3DNoise(p * 0.125f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 2.2f;
	p.xz -= (Get3DNoise(p * 0.0525f + vec3(0.0f, t * 0.00f, 0.0f)) * 2.0f - 1.0f) * 2.7f;


	p.x *= 0.5f;
	p.x -= t * 0.01f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 2.0f;	p.x -= t * 0.057f;	vec3 p2 = p;
		  noise += (2.0f - abs(Get3DNoise(p) * 2.0f - 0.0f)) * (0.15f);						p *= 3.0f;	p.xz -= t * 0.035f;	p.x *= 2.0f;	vec3 p3 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.050f);						p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p4 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.015f);						p *= 3.0f;	p.xz -= t * 0.035f;
		  if (!isShadowPass)
		  {
		 		noise += ((Get3DNoise(p))) * (0.022f);												p *= 3.0f;
		  		noise += ((Get3DNoise(p))) * (0.009f);
		  }
		  noise /= 1.475f;

	//cloud edge
	float coverage = 0.701f;
		  coverage = mix(coverage, 0.97f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz * 0.5);
		  coverage *= max(0.0f, 1.0f - dist / 14000.0f);
	float density = 0.1f + rainStrength * 0.3;

	if (isShadowPass)
	{
		return vec4(GetCoverage(0.4f, 0.4f, noise));
	}

	noise = GetCoverage(coverage, density, noise);

	const float lightOffset = 0.4f;



	float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
		  sundiff += (2.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 2.0f - 0.0f)) * (0.55f);
		  				float largeSundiff = sundiff;
		  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);
		  sundiff += (3.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset / 5.0f) * 3.0f - 0.0f)) * (0.045f);
		  sundiff += (3.0f - abs(Get3DNoise(p4 + worldLightVector.xyz * lightOffset / 8.0f) * 3.0f - 0.0f)) * (0.015f);
		  sundiff /= 1.5f;

		  sundiff *= max(0.0f, 1.0f - dist / 14000.0f);

		  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
	float secondOrder 	= pow(clamp(sundiff * 1.1f + 1.45f, 0.0f, 1.0f), 4.0f);
	float firstOrder 	= pow(clamp(largeSundiff * 1.1f + 1.66f, 0.0f, 1.0f), 3.0f);



	float directLightFalloff = firstOrder * secondOrder;
	float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

		  directLightFalloff *= anisoBackFactor;
	 	  directLightFalloff *= mix(11.5f, 1.0f, pow(sunglow, 0.5f));

	//noise *= saturate(1.0 - directLightFalloff);

	vec3 colorDirect = colorSunlight * 51.215f;
		 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.2f, 0.2f), timeMidnight);
		 colorDirect *= 1.0f + pow(sunglow, 2.0f) * 120.0f * pow(directLightFalloff, 1.1f) * (1.0 - rainStrength * 0.8);
		 colorDirect *= 1.0f;


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(0.15f)) * 0.93f;
		 colorAmbient = mix(colorAmbient, vec3(0.4) * Luminance(colorSkylight), vec3(rainStrength));
		 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
		 colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));




	directLightFalloff *= mix(1.0, 0.085, rainStrength);

	//directLightFalloff += (pow(Get3DNoise(p3), 2.0f) * 0.5f + pow(Get3DNoise(p3 * 1.5f), 2.0f) * 0.25f) * 0.02f;
	//directLightFalloff *= Get3DNoise(p2);

	vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));

	color *= 1.0f;

	color = mix(color, color * 0.9, rainStrength);


	vec4 result = vec4(color.rgb, noise);

	return result;

}

void CloudPlane(inout vec3 color, vec3 viewDir, vec3 worldVector, float linearDepth, MaterialMask mask, vec3 worldLightVector, vec3 lightVector)
{
	//Initialize view ray
	//vec4 worldVector = gbufferModelViewInverse * (vec4(-GetScreenSpacePosition(texcoord.st).xyz, 0.0));


	Ray viewRay;

	viewRay.dir = normalize(worldVector.xyz);
	viewRay.origin = vec3(0.0f);

	float sunglow = CalculateSunglow(viewDir, lightVector);



	float cloudsAltitude = 540.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float density = 1.0f;

	float planeHeight = cloudsUpperLimit;
	float stepSize = 25.5f;
	planeHeight -= cloudsThickness * 0.85f;


	Plane pl;
	pl.origin = vec3(0.0f, cameraPosition.y - planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	Intersection i = RayPlaneIntersectionWorld(viewRay, pl);

	vec3 original = color.rgb;

	if (i.angle < 0.0f)
	{
		if (i.distance < linearDepth || mask.sky > 0.5 || linearDepth >= far - 0.1)
		{
			vec4 cloudSample = CloudColor(vec4(i.pos.xyz * 0.5f + vec3(30.0f) + vec3(1000.0, 0.0, 0.0), 1.0f), sunglow, worldLightVector, cloudsAltitude, cloudsThickness, false);
			 	 cloudSample.a = min(1.0f, cloudSample.a * density);


			float cloudDist = length(i.pos.xyz - cameraPosition.xyz);

			const vec3 absorption = vec3(0.2, 0.4, 1.0);

			cloudSample.rgb *= exp(-cloudDist * absorption * 0.0001 * saturate(1.0 - sunglow * 2.0) * (1.0 - rainStrength));

			cloudSample.a *= exp(-cloudDist * (0.0002 + rainStrength * 0.0009));


			//cloudSample.rgb *= sin(cloudDist * 0.3) * 0.5 + 0.5;

			color.rgb = mix(color.rgb, cloudSample.rgb * 1.0f, cloudSample.a);

		}
	}
}

float CloudShadow(vec3 lightVector, vec4 screenSpacePosition)
{
	lightVector = upVector;

	float cloudsAltitude = 540.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float planeHeight = cloudsUpperLimit;

	planeHeight -= cloudsThickness * 0.85f;

	Plane pl;
	pl.origin = vec3(0.0f, planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	//Cloud shadow
	Ray surfaceToSun;
	vec4 sunDir = gbufferModelViewInverse * vec4(lightVector, 0.0f);
	surfaceToSun.dir = normalize(sunDir.xyz);
	vec4 surfacePos = gbufferModelViewInverse * screenSpacePosition;
	surfaceToSun.origin = surfacePos.xyz + cameraPosition.xyz;

	Intersection i = RayPlaneIntersection(surfaceToSun, pl);

	//float cloudShadow = CloudColor(vec4(i.pos.xyz * 30.5f + vec3(30.0f) + vec3(1000.0, 0.0, 0.0), 1.0f), 0.0, worldLightVector, cloudsAltitude, cloudsThickness, false).x;
		  //cloudShadow += CloudColor(vec4(i.pos.xyz * 0.65f + vec3(10.0f) + vec3(i.pos.z * 0.5f, 0.0f, 0.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;

	i.pos *= 0.015;
	i.pos.x -= frameTimeCounter * 0.42;

	float noise = Get2DNoise(i.pos.xz);
	noise += Get2DNoise(i.pos.xz * 0.5);

	noise *= 0.5;

	noise = mix(saturate(noise * 1.0 - 0.3), 1.0, rainStrength);
	noise = pow(noise, 0.5);
	//noise = mix(saturate(noise * 2.6 - 1.0), 1.0, rainStrength);

	noise = noise * noise * (3.0 - 2.0 * noise);

	//noise = GetCoverage(0.6, 0.2, noise);

	float cloudShadow = noise;

		  cloudShadow = min(cloudShadow, 1.0f);
		  cloudShadow = 1.0f - cloudShadow;

	return cloudShadow;
	// return 1.0f;
}

float G1V(float dotNV, float k)
{
	return 1.0 / (dotNV * (1.0 - k) + k);
}

vec3 SpecularGGX(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
	float alpha = roughness * roughness;

	vec3 H = normalize(V + L);

	float dotNL = saturate(dot(N, L));
	float dotNV = saturate(dot(N, V));
	float dotNH = saturate(dot(N, H));
	float dotLH = saturate(dot(L, H));

	float F, D, vis;

	float alphaSqr = alpha * alpha;
	float pi = 3.14159265359;
	float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
	D = alphaSqr / (pi * denom * denom);

	float dotLH5 = pow(1.0f - dotLH, 5.0);
	F = F0 + (1.0 - F0) * dotLH5;

	float k = alpha / 2.0;
	vis = G1V(dotNL, k) * G1V(dotNV, k);

	vec3 specular = vec3(dotNL * D * F * vis) * colorSunlight;

	//specular = vec3(0.1);
	#ifndef PHYSICALLY_BASED_MAX_ROUGHNESS
	specular *= saturate(pow(1.0 - roughness, 0.7) * 2.0);
	#endif


	return specular;
}




#include "FQQrsH.inc"
vec3 e(vec3 v)
 {
   vec3 f=fract(v);
   for(int r=0;r<3;r++)
     {
       if(f[r]==0.)
         f[r]=1.;
     }
   return f;
 }
 vec3 s(vec3 r)
 {
   vec4 v=vec4(r,1.);
   v.xyz+=.5;
   v.xyz-=e(cameraPosition.xyz+.5)-.5;
   v=shadowModelView*v;
   float f=-v.z;
   v=shadowProjection*v;
   v/=v.w;
   float z=sqrt(v.x*v.x+v.y*v.y),w=1.f-SHADOW_MAP_BIAS+z*SHADOW_MAP_BIAS;
   v.xy*=.95f/w;
   v.z=mix(v.z,.5,.8);
   v=v*.5f+.5f;
   v.xy*=.5;
   v.xy+=.5;
   return v.xyz;
 }struct Ray{vec3 dir;vec3 origin;};struct BBRay{vec3 origin;vec3 direction;vec3 inv_direction;ivec3 sign;};
 BBRay e(vec3 v,vec3 z)
 {
   vec3 f=vec3(1.)/z;
   return BBRay(v,z,f,ivec3(f.x<0?1:0,f.y<0?1:0,f.z<0?1:0));
 }
 void e(in BBRay v,in vec3 f[2],out float r,out float z)
 {
   float i,y,w,t;
   r=(f[v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   z=(f[1-v.sign[0]].x-v.origin.x)*v.inv_direction.x;
   i=(f[v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   y=(f[1-v.sign[1]].y-v.origin.y)*v.inv_direction.y;
   w=(f[v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   t=(f[1-v.sign[2]].z-v.origin.z)*v.inv_direction.z;
   r=max(max(r,i),w);
   z=min(min(z,y),t);
 }
 vec2 f(inout float v)
 {
   return fract(sin(vec2(v+=.1,v+=.1))*vec2(43758.5,22578.1));
 }
 vec3 e(vec3 v,inout float z,int r)
 {
   vec2 i=BlueNoise(texcoord.xy+vec2(z+=.1,z+=.1)).xy;
   i=fract(i+f(z)*.1);
   float t=6.28319*i.x,w=sqrt(i.y);
   vec3 s=normalize(cross(v,vec3(0.,1.,1.))),y=cross(v,s),n=s*cos(t)*w+y*sin(t)*w+v.xyz*sqrt(1.-i.y);
   return n;
 }
 float f(vec3 v,vec3 z,vec3 r,int f)
 {
   vec3 i=bqzMKV(v),n=s(i+z*.99);
   float y=.5,w=shadow2DLod(shadow,vec3(n.xy,n.z-.0006*y),3).x;
   w*=saturate(dot(worldLightVector,z));
   return w;
 }
 float s(vec3 v,vec3 z,vec3 r,int f)
 {
   vec3 i=s(v);
   float y=.5,w=shadow2DLod(shadow,vec3(i.xy,i.z-.0006*y),2).x;
   w*=saturate(dot(worldLightVector,z));
   return w;
 }
 vec3 e()
 {
   vec3 f=cameraPosition.xyz+.5-e(cameraPosition.xyz+.5),v=previousCameraPosition+.5-e(previousCameraPosition+.5);
   return f-v;
 }
 vec3 f(vec3 v,vec3 z)
 {
   vec2 f=wvLPci(jXfIYx(bqzMKV(v)+z+1.));
   vec3 w=ZrrDhC(f).kLqMlH;
   return w;
 }
 vec3 f()
 {
   vec2 v=wvLPci(jrwNAE(texcoord.xy)+e()/VpEHlC());
   vec3 f=ZrrDhC(v).kLqMlH;
   return f;
 }
 vec3 t(float v,float z,float s,vec3 f)
 {
   vec3 n;
   n.x=s*cos(v);
   n.y=s*sin(v);
   n.z=z;
   vec3 w=abs(f.y)<.999?vec3(0,0,1):vec3(1,0,0),i=normalize(cross(f,vec3(0.,1.,1.))),y=cross(i,f);
   return i*n.x+y*n.y+f*n.z;
 }
 vec3 f(vec2 v,float z,vec3 f)
 {
   float r=2*3.14159*v.x,w=sqrt((1-v.y)/(1+(z*z-1)*v.y)),i=sqrt(1-w*w);
   return t(r,w,i,f);
 }
 float t(float v)
 {
   return 2./(v*v+1e-07)-2.;
 }
 vec3 s(in vec2 v,in float f,in vec3 z)
 {
   float i=t(f),w=2*3.14159*v.x,r=pow(v.y,1.f/(i+1.f)),y=sqrt(1-r*r);
   return t(w,r,y,z);
 }
 void s(inout vec3 v,in vec3 f)
 {
   vec3 z=normalize(f.xyz),i=v;
   float r=dot(i,z);
   i=normalize(v-z*saturate(r)*.5);
   v=i;
 }
 vec3 w(vec3 v)
 {
   float z=fract(frameCounter*.0123456);
   vec3 i=BlueNoise(texcoord.xy).xyz,n=BlueNoise(texcoord.xy+.1).xyz,w=v,r=e(cameraPosition.xyz+.5)+vec3(0.,1.7,0.),y=r;
   r=xkpggD(r);
   int t=Tsmicx(),s=VpEHlC();
   Ray o;
   o.origin=r*t-vec3(1.,1.,1.);
   o.dir=w;
   BBRay d=e(o.origin,o.dir);
   vec3 c=vec3(1.),x=vec3(0.);
   for(int B=0;B<1;B++)
     {
       vec3 m=vec3(floor(o.origin)),G=abs(vec3(length(o.dir))/(o.dir+.0001)),h=sign(o.dir),p=(sign(o.dir)*(m-o.origin)+sign(o.dir)*.5+.5)*G,S;
       vec4 l=vec4(0.);
       vec3 R=vec3(0.);
       float Y=.5;
       for(int g=0;g<190;g++)
         {
           R=m/float(t);
           vec2 A=PoXKdv(R,t);
           l=texture2DLod(shadowcolor,A,0);
           if(abs(l.w*255.-130.)<.5)
             x+=.06125*c*colorTorchlight*Y;
           else
             {
               if(l.w*255.<254.f&&g!=0)
                 {
                   break;
                 }
             }
           S=step(p.xyz,p.yzx)*step(p.xyz,p.zxy);
           p+=S*G;
           m+=S*h;
           Y=1.;
         }
       if(l.w*255.<1.f||l.w*255.>254.f)
         {
           vec3 g=max(vec3(0.),AtmosphericScattering(o.dir,worldSunVector,0.));
           g+=pow(saturate(dot(o.dir,worldLightVector)),5.)*colorSunlight*7.;
           g*=c;
           g*=saturate(dot(o.dir,vec3(0.,1.,0.))*100.)*.9+.1;
           x+=g*.1;
           break;
         }
       if(l.w*255.>1.f&&l.w*255.<128.f)
         {
           vec3 g=saturate(l.xyz);
           c*=g;
         }
       if(l.w*255.>131.&&l.w*255.<137.)
         x+=.5*c*normalize(l.xyz+.0001);
       if(abs(l.w*255.-141.)<.5)
         x=vec3(0.,0.,0.);
       vec3 g=-(S*h),A[2]=vec3[2](m,m+1.);
       float T,k;
       e(d,A,T,k);
       vec3 a=(o.origin+o.dir*T)/float(t),L=vec3(1.)-abs(g);
       x+=f(R+(n.xyz-.5)/float(t)*2.*L,g)*c;
       const float u=2.4;
       x+=.5*c;
     }
   x*=1.;
   return x;
 }
 vec3 t(vec3 v,vec3 z)
 {
   v+=e(cameraPosition.xyz+.5)-.5;
   vec3 f=jXfIYx(v+z*.1),w=ZrrDhC(wvLPci(f)).kLqMlH;
   return w;
 }
 vec3 w(vec2 v,vec3 f,float z,vec3 r)
 {
   vec3 w=texture2DLod(gaux3,v,0).xyz;
   return w;
 }
 void main()
 {
   GBufferData v=GetGBufferData();
   MaterialMask f=CalculateMasks(v.materialID);
   vec4 i=GetViewPosition(texcoord.xy,v.depth),o=gbufferModelViewInverse*vec4(i.xyz,1.),n=gbufferModelViewInverse*vec4(i.xyz,0.);
   vec3 z=normalize(i.xyz),r=normalize(n.xyz),y=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz);
   float t=length(i.xyz);
   vec3 l=vec3(0.);
   if(f.grass>.5)
     y=vec3(0.,1.,0.);
   vec3 s=w(texcoord.xy,v.normal,v.depth,i.xyz)*10.,c=s*v.albedo.xyz;
   const float g=75.;
   if(t>g)
     {
       vec3 m=FromSH(skySHR,skySHG,skySHB,y);
       m=mix(m,vec3(.2)*(dot(y,vec3(0.,1.,0.))*.35+.65)*Luminance(colorSkylight),vec3(rainStrength));
       m*=v.mcLightmap.y;
       vec3 x=m*v.albedo.xyz*3.5;
       const float S=3.7*TORCHLIGHT_BRIGHTNESS;
       x+=v.mcLightmap.x*colorTorchlight*v.albedo.xyz*.025*S;
       float G=1./(pow(length(o.xyz),2.)+.5);
       x+=v.albedo.xyz*G*heldBlockLightValue*colorTorchlight*.025*S*heldLightBlacklist;
       vec3 e=normalize(v.albedo.xyz+.0001)*pow(length(v.albedo.xyz),1.)*colorSunlight*.13*v.mcLightmap.y;
       x+=e*v.albedo.xyz*10.;
       float h=.3;
       c=mix(c,x,vec3(saturate(t*h-g*h)));
     }
   l.xyz=c;
   float S=24.*(1.-rainStrength),h=dot(y,worldLightVector),x=OrenNayar(y,-r,worldLightVector);
   if(f.leaves>.5)
     x=mix(x,.5,.5);
   if(f.grass>.5)
     v.metalness=0.;
   vec3 e=CalculateSunlightVisibility(i,f);
   #ifdef SUNLIGHT_LEAK_FIX
   float m=saturate(v.mcLightmap.y*100.);
   e*=m;
   #endif
   if(isEyeInWater<1)
     e*=ScreenSpaceShadow(i.xyz,v.normal.xyz,f);
   l+=DoNightEyeAtNight(x*v.albedo.xyz*e*S*colorSunlight,timeMidnight);
   vec3 d=normalize(worldLightVector-r);
   float B=saturate(dot(d,y)),p=pow(1.-dot(d,normalize(-r.xyz)),5.)*.995+.005,G=pow(v.smoothness+.01,5.),A=1./(pow((1.-B)*(G*8000.+.25),1.5)+1.1);
   A*=p;
   A*=saturate(h);
   A*=G*8000.+.25;
   A*=1.-f.water;
   A*=pow(v.mcLightmap.y,.1);
   vec3 R=A*colorSunlight*e*S*.9,T=SpecularGGX(y,-r,worldLightVector,1.-v.smoothness,v.metalness*.98+.02)*S*e;
   if(isEyeInWater<.5)
     l+=DoNightEyeAtNight(T,timeMidnight);
   if(f.sky>.5||v.depth>1.)
     {
       v.albedo.xyz*=1.-saturate((dot(r,worldSunVector)-.95)*50.);
       vec3 a=vec3(RenderSunDisc(r,worldSunVector)),Y=AtmosphericScattering(vec3(r.x,r.y,r.z),worldSunVector,1.);
       Y=ModulateSkyForRain(Y,colorSkylight,rainStrength);
       l.xyz=Y;
       a*=colorSunlight;
       a*=pow(saturate(worldSunVector.y+.1),.9);
       l+=a*8000.*pow(1.-rainStrength,5.);
       CloudPlane(l,z,-r,t,f,worldLightVector,lightVector);
       vec3 V=AtmosphericScattering(vec3(r.x,r.y,r.z),-worldSunVector,1.);
       V=ModulateSkyForRain(V,vec3(.00025),rainStrength);
       l+=V*.00025;
       l+=v.albedo.xyz*normalize(V+1e-07)*.13*vec3(1.,.8,.6);
       l=DoNightEyeAtNight(l,timeMidnight);
       o.xyz=r.xyz*2670.;
     }
   if(f.glowstone>.5)
     l.xyz+=v.albedo.xyz*.8*GI_LIGHT_BLOCK_INTENSITY;
   if(f.torch>.5)
     l.xyz+=v.albedo.xyz*pow(length(v.albedo.xyz),2.)*.5*GI_LIGHT_TORCH_INTENSITY;
   if(f.lava>.5)
     l+=v.albedo.xyz*2.*GI_LIGHT_BLOCK_INTENSITY;
   if(f.fire>.5)
     l+=v.albedo.xyz*3.*GI_LIGHT_TORCH_INTENSITY;
   l*=.001;
   l=LinearToGamma(l);
   l+=rand(texcoord.xy+sin(frameTimeCounter))*(1./65535.);
   gl_FragData[0]=vec4(l.xyz,1.);
 };
/* DRAWBUFFERS:3 */
