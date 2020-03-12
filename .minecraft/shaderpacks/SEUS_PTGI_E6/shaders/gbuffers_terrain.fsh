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




#define TEXTURE_RESOLUTION 16 // Resolution of current resource pack. This needs to be set properly for reflections! Make sure to use a resource pack with consistent resolution for correct reflections! [4 8 16 32 64 128 256 512 1024 2048]

#define FORCE_WET_EFFECT // Forces all surfaces to get wet when it rains, becoming reflective.

#define RAIN_SPLASH_EFFECT // Rain ripples/splashes on water and wet blocks.

//#define RAIN_SPLASH_BILATERAL // Bilateral filter for rain splash/ripples. When enabled, ripple texture is smoothed (no hard pixel edges) at the cost of performance.



#include "Common.inc"



uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform float wetness;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform ivec2 atlasSize;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 worldPosition;
varying vec4 vertexPos;
varying mat3 tbnMatrix;
varying vec3 viewPos;

varying vec3 normal;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 worldNormal;

varying vec2 blockLight;

varying float materialIDs;

varying float distance;



uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


float CurveBlockLightTorchSource(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

#include "GBufferData.inc"


vec3 GetRainAnimationTex(sampler2D tex, vec2 uv, float wet)
{
	//float frame = mod(floor(float(frameCounter) * 1.0), 60.0);
	// frame = 0.0;

	float frame = mod(floor(frameTimeCounter * 60.0), 60.0);
	vec2 coord = vec2(uv.x, mod(uv.y / 60.0, 1.0) - frame / 60.0);

	vec3 n = texture2D(tex, coord).rgb * 2.0 - 1.0;
	n.y *= -1.0;

	n.xy = pow(abs(n.xy) * 1.0, vec2(2.0 - wet * wet * wet * 1.2)) * sign(n.xy);
	// n.xy = pow(abs(n.xy) * 1.0, vec2(1.0)) * sign(n.xy);

	return n;
}

vec3 BilateralRainTex(sampler2D tex, vec2 uv, float wet)
{
	vec3 n = GetRainAnimationTex(tex, uv.xy, wet);
	vec3 nR = GetRainAnimationTex(tex, uv.xy + vec2(1.0, 0.0) / 128.0, wet);
	vec3 nU = GetRainAnimationTex(tex, uv.xy + vec2(0.0, 1.0) / 128.0, wet);
	vec3 nUR = GetRainAnimationTex(tex, uv.xy + vec2(1.0, 1.0) / 128.0, wet);

	vec2 fractCoord = fract(uv.xy * 128.0);

	vec3 lerpX = mix(n, nR, fractCoord.x);
	vec3 lerpX2 = mix(nU, nUR, fractCoord.x);
	vec3 lerpY = mix(lerpX, lerpX2, fractCoord.y);

	return lerpY;
}

float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	// f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	// f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	// f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0;
	vec2 coord2 = (uv2 + 0.5f) / 64.0;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

vec3 GetRainNormal(in vec3 pos, inout float wet)
{
	if (wetness < 0.01)
	{
		return vec3(0.0, 0.0, 1.0);
	}

	vec3 flowPos = pos;

	pos.xyz *= 0.5;

	#ifdef RAIN_SPLASH_BILATERAL
	vec3 n1 = BilateralRainTex(gaux2, pos.xz, wet);
	// vec3 n2 = BilateralRainTex(gaux2, pos.xz, wet);
	// vec3 n3 = BilateralRainTex(gaux3, pos.xz, wet);
	#else
	vec3 n1 = GetRainAnimationTex(gaux2, pos.xz, wet);
	// vec3 n2 = GetRainAnimationTex(gaux2, pos.xz, wet);
	// vec3 n3 = GetRainAnimationTex(gaux3, pos.xz, wet);
	#endif

	pos.x -= frameTimeCounter * 1.5;
	float downfall = texture2D(noisetex, pos.xz * 0.0025).x;
	downfall = saturate(downfall * 1.5 - 0.25);


	vec3 n = n1 * 1.0;
	// n += n2 * saturate(downfall * 2.0) * 1.0;
	// n += n3 * saturate(downfall * 2.0 - 1.0) * 1.0;
	// n = n3 * 3.0;


	float lod = dot(abs(fwidth(pos.xyz)), vec3(1.0));

	n.xy *= 1.0 / (1.0 + lod * 5.0);

	// n.xy /= wet + 0.1;
	// n.x = downfall;

	wet = saturate(wet * 1.0 + downfall * (1.0 - wet) * 0.95);
	// wet = downfall * 0.2 + 0.8;

	n.xy *= rainStrength;



	vec3 rainSplashNormal = n;


	flowPos.xz *= 12.0;
	flowPos.y += frameTimeCounter * 6.0;

	vec3 rainFlowNormal = vec3(0.0, 0.0, 1.0);
	// rainFlowNormal.xy = vec2(Get3DNoise(flowPos.xyz) * 2.0 - 1.0, Get3DNoise(flowPos.xyz + 2.0) * 2.0 - 1.0) * 0.05;
	// flowPos.xz *= 4.0;
	// rainFlowNormal.xy += vec2(Get3DNoise(flowPos.xyz) * 2.0 - 1.0, Get3DNoise(flowPos.xyz + 2.0) * 2.0 - 1.0) * 0.035;
	// rainFlowNormal = normalize(rainFlowNormal);

	n = mix(rainFlowNormal, rainSplashNormal, saturate(worldNormal.y));

	return n;
}

float GetModulatedRainSpecular(in vec3 pos)
{
	if (wetness < 0.01)
	{
		return 0.0;
	}

	//pos.y += frameTimeCounter * 3.0f;
	pos.xz *= 1.0f;
	pos.y *= 0.2f;

	// pos.y += Get3DNoise(pos.xyz * vec3(1.0f, 0.0f, 1.0f)).x * 2.0f;

	vec3 p = pos;

	float n = Get3DNoise(p);
		  n += Get3DNoise(p / 2.0f) * 2.0f;
		  n += Get3DNoise(p / 4.0f) * 4.0f;

		  n /= 7.0f;


	n = saturate(n * 0.8 + 0.5) * 1.0;


	return n;
}


void main() 
{	
	float lodOffset = 0.0;

	vec4 albedo = texture2D(texture, texcoord.st, lodOffset);
	// vec4 albedo = texture2DLod(texture, texcoord.st, 3);
	albedo *= color;

	// albedo.rgb = vec3(1.0);



	//vec2 lightmap;
	// lightmap.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	// lightmap.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

	vec2 mcLightmap = blockLight;
	mcLightmap.x = CurveBlockLightTorchSource(mcLightmap.x);
	mcLightmap.x = mcLightmap.x * 1.0;
	mcLightmap.x = pow(mcLightmap.x, 0.25);
	mcLightmap.x += rand(vertexPos.xy + sin(frameTimeCounter)).x * (1.5 / 255.0);



	// float wetnessModulator = GetModulatedRainSpecular(worldPosition.xyz);
	float wetnessModulator = 1.0;
	#ifdef RAIN_SPLASH_EFFECT
		vec3 rainNormal = GetRainNormal(worldPosition.xyz, wetnessModulator);
		// rainNormal = mix(vec3(0.0, 0.0, 0.0), rainNormal, vec3(saturate(worldNormal.y)));
	#else
		vec3 rainNormal = vec3(0.0, 0.0, 0.0);
	#endif
	wetnessModulator *= saturate(worldNormal.y * 10.5 + 0.7);
	wetnessModulator *= saturate(abs(2.0 - materialIDs));
	wetnessModulator *= clamp(blockLight.y * 1.05 - 0.7, 0.0, 0.3) / 0.3;
	wetnessModulator *= saturate(wetness * 1.1 - 0.1);





	// CurveLightmapSky(lightmap.y);

	vec4 specTex = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 normalTex = vec4(0.0, 1.0, 0.0, 1.0);
	vec3 viewNormal = normal;

		specTex = texture2D(specular, texcoord.st, lodOffset);
		specTex.r = specTex.r * 0.992; 								// Fix weird specular issue
		normalTex = texture2D(normals, texcoord.st, lodOffset) * 2.0 - 1.0;

		float normalMapStrength = 4.0;

		#ifdef FORCE_WET_EFFECT
		normalMapStrength = mix(normalMapStrength, 0.1, wetnessModulator * wetnessModulator * wetnessModulator * wetnessModulator);
		#endif


		viewNormal = normalize(normalTex.xyz * vec3(normalMapStrength, normalMapStrength, 1.0) + rainNormal * wetnessModulator) * tbnMatrix;

	// vec3 constructedNormal = normalize(cross(dFdx(viewPos), dFdy(viewPos)));
	// viewNormal = constructedNormal;
	

	float smoothness = pow(specTex.r, 1.0);
	float metallic = specTex.g;
	float emissive = specTex.b;



	// Darker albedo when wet
	albedo.rgb = pow(albedo.rgb, vec3(1.0 + wetnessModulator * (1.0 - metallic) * 0.3));


	//vec2 normalEnc = EncodeNormal(viewNormal.xyz);


	//fix normals
	vec3 viewDir = -normalize(viewPos.xyz);
	vec3 relfectDir = reflect(-viewDir, viewNormal);
	// make outright impossible
	viewNormal.xyz = normalize(viewNormal.xyz + (normal / (pow(saturate(dot(viewNormal, viewDir)) + 0.001, 0.5)) * 1.0));
	// viewNormal.xyz = normalize(viewNormal.xyz + (normal / (pow(saturate(dot(viewNormal, relfectDir)) + 0.001, 0.5)) * 1.0));

	// viewNormal.xyz = normalize(viewNormal.xyz + (normal / (saturate(dot(normal, -normalize(viewPos.xyz))) + 0.001)) * 1.0);









	#ifdef FORCE_WET_EFFECT
	smoothness = mix(smoothness, 1.0, saturate(wetnessModulator * 1.0 * saturate(1.0 - metallic)));
	#endif



	// albedo.rgb = vec3(1.0);
	// albedo.rgb = mix(vec3(0.1), albedo.rgb, vec3(metallic));
	// albedo.rgb = mix(albedo.rgb, vec3(1.0), vec3(metallic));
	// albedo.rgb *= 0.5;

	// gl_FragData[0] = albedo;
	// gl_FragData[1] = vec4(mcLightmap.xy, emissive, albedo.a);
	// gl_FragData[2] = vec4(normalEnc.xy, blockLight.x, albedo.a);
	// gl_FragData[3] = vec4(smoothness, metallic, (materialIDs + 0.1) / 255.0, albedo.a);

	// metallic = 1.0;
	// smoothness = 0.7;

	// metallic *= 0.0;

	// albedo.rgb = pow(length(albedo.rgb), 1.5) * normalize(albedo.rgb + 0.00001);


	GBufferData gbuffer;
	gbuffer.albedo = albedo;
	gbuffer.normal = viewNormal.xyz;
	gbuffer.mcLightmap = mcLightmap;
	gbuffer.smoothness = smoothness;
	gbuffer.metalness = metallic;
	gbuffer.materialID = (materialIDs + 0.1) / 255.0;
	gbuffer.emissive = 0.0;
	gbuffer.geoNormal = normal.xyz;
	// gbuffer.totalTexGrad = dot(fwidth(texcoord.st), vec2(0.5));
	gbuffer.totalTexGrad = length(fwidth(texcoord.st)) * (256.0 / 8.0);


	vec4 frag0, frag1, frag2, frag3;

	OutputGBufferDataSolid(gbuffer, frag0, frag1, frag2, frag3);

	gl_FragData[0] = frag0;
	gl_FragData[1] = frag1;
	gl_FragData[2] = frag2;
	//gl_FragData[0] = frag0;

}

/* DRAWBUFFERS:012 */
