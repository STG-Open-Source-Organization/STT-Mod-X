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



////////////////////////////////////////////////////ADJUSTABLE VARIABLES/////////////////////////////////////////////////////////

#define TEXTURE_RESOLUTION 128 // Resolution of current resource pack. This needs to be set properly for POM! [16 32 64 128 256 512]

//#define PARALLAX // 3D effect for resource packs with heightmaps. Make sure Texture Resolution is set properly!

#define PARALLAX_SHADOW // Self-shadowing for parallax occlusion mapping. 

#define FORCE_WET_EFFECT // Make all surfaces get wet during rain regardless of specular texture values

#define RAIN_SPLASH_EFFECT // Rain ripples/splashes on water and wet blocks.

#define PARALLAX_DEPTH 1.0 // Depth of parallax effect. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0]

///////////////////////////////////////////////////END OF ADJUSTABLE VARIABLES///////////////////////////////////////////////////




#include "Common.inc"


/* DRAWBUFFERS:0123 */

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform float wetness;
uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform ivec2 atlasSize;

uniform vec3 cameraPosition;
uniform int frameCounter;

uniform mat4 gbufferProjection;

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

uniform float rainStrength;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}

vec4 GetTexture(in sampler2D tex, in vec2 coord)
{
	#ifdef PARALLAX
		vec4 t = vec4(0.0f);
		if (distance < 20.0f)
		{
			t = texture2DLod(tex, coord, 0);
		}
		else
		{
			t = texture2D(tex, coord);
		}
		return t;
	#else
		return texture2D(tex, coord);
	#endif
}

vec2 OffsetCoord(in vec2 coord, in vec2 offset, in int level)
{
	int tileResolution = TEXTURE_RESOLUTION;
	ivec2 atlasTiles = textureSize(texture, 0) / TEXTURE_RESOLUTION;
	ivec2 atlasResolution = tileResolution * atlasTiles;

	coord *= atlasResolution;

	vec2 offsetCoord = coord + mod(offset.xy * atlasResolution, vec2(tileResolution));

	vec2 minCoord = vec2(coord.x - mod(coord.x, tileResolution), coord.y - mod(coord.y, tileResolution));
	vec2 maxCoord = minCoord + tileResolution;

	if (offsetCoord.x > maxCoord.x) {
		offsetCoord.x -= tileResolution;
	} else if (offsetCoord.x < minCoord.x) {
		offsetCoord.x += tileResolution;
	}

	if (offsetCoord.y > maxCoord.y) {
		offsetCoord.y -= tileResolution;
	} else if (offsetCoord.y < minCoord.y) {
		offsetCoord.y += tileResolution;
	}

	offsetCoord /= atlasResolution;

	return offsetCoord;
}

vec2 CalculateParallaxCoord(in vec2 coord, in vec3 viewVector, out vec3 rayOffset, in vec2 texGradX, in vec2 texGradY)
{
	vec2 parallaxCoord = coord.st;
	const int maxSteps = 112;
	vec3 stepSize = vec3(0.001f, 0.001f, 0.15f);

	float parallaxDepth = PARALLAX_DEPTH;

	float parallaxStepSize = 0.5;

	stepSize.xy *= parallaxDepth;
	stepSize *= parallaxStepSize;


	//float heightmap = GetTexture(normals, coord.st).a;
	float heightmap = textureGrad(normals, coord.st, texGradX, texGradY).a;

	//if (viewVector.z < 0.0f)
	//{
		vec3 pCoord = vec3(0.0f, 0.0f, 1.0f);

		//make "pop out"
		//pCoord.st += (viewVector.xy * stepSize.xy) / (viewVector.z * stepSize.z);

		if (heightmap < 1.0f)
		{
			vec3 step = viewVector * stepSize;
			float distAngleWeight = ((distance * 0.6f) * (2.1f - viewVector.z)) / 16.0;
				 step *= distAngleWeight;
				 step *= 1.0f;

			float sampleHeight = heightmap;

			for (int i = 0; sampleHeight < pCoord.z && i < 240; ++i)
			{
				//if (heightmap < pCoord.z)
				pCoord.xy = mix(pCoord.xy, pCoord.xy + step.xy, clamp((pCoord.z - sampleHeight) / (stepSize.z * 0.25 * distAngleWeight / (-viewVector.z + 0.05)), 0.0, 1.0));
				pCoord.z += step.z;
				//pCoord += step;
				//sampleHeight = GetTexture(normals, OffsetCoord(coord.st, pCoord.st, 0)).a;
				sampleHeight = textureGrad(normals, OffsetCoord(coord.st, pCoord.st, 0), texGradX, texGradY).a;

			}


			parallaxCoord.xy = OffsetCoord(coord.st, pCoord.st, 0);
		}

	//}

	rayOffset = pCoord;

	//parallaxCoord.xy = OffsetCoord(coord.st, viewVector.xy * (1.0f - heightmap) * 0.0045f, 0);

	return parallaxCoord;
}

float GetParallaxShadow(in vec2 texcoord, in vec3 lightVector, float baseHeight, in vec2 texGradX, in vec2 texGradY)
{
	float sunVis = 1.0;



	//lightVector = normalize(tbnMatrix * lightVector);

	// lightVector.z *= TEXTURE_RESOLUTION * 0.5;
	lightVector.z *= 64.0;
	lightVector.z /= PARALLAX_DEPTH * 0.5;

	// lightVector = normalize(vec3(1.0, 1.0, 0.5));

	vec3 currCoord = vec3(texcoord, baseHeight);

	float stepSize = 0.0005;

	ivec2 texSize = textureSize(texture, 0);
	currCoord.xy = (floor(currCoord.xy * texSize) + 0.5) / texSize;


	float allTexGrad = dot(abs(texGradX), vec2(1.0)) + dot(abs(texGradY), vec2(1.0));


	// stepSize *= allTexGrad * 500.0 + 1.0;

	for (int i = 0; i < 15; i++)
	{
		currCoord = vec3(OffsetCoord(currCoord.xy, lightVector.xy * stepSize, 0), currCoord.z + lightVector.z * stepSize);
		//float heightSample = GetTexture(normals, currCoord.xy).a;
		float heightSample = textureGrad(normals, currCoord.xy, texGradX, texGradY).a;



		// if (sin(frameTimeCounter) > 0.0)
		// {
		// 	if (heightSample > currCoord.z + 0.015)
		// 	{
		// 		sunVis *= 0.05;
		// 	}
		// }
		// else
		// {
			//float shadowBias = 0.0015 + allTexGrad * 7.0 * (sin(frameTimeCounter) > 0.0 ? 1.0 : 0.0);
			float shadowBias = 0.0015;
			sunVis *= saturate((currCoord.z - heightSample + shadowBias) / 0.01);
			// sunVis *= saturate((currCoord.z - heightSample + shadowBias + 0.04) / 0.08);
		// }

	}

	return sunVis;
}

vec3 Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;
	vec3 p = floor(pos);
	vec3 f = fract(pos);
		 f = f * f * (3.0f - 2.0f * f);

	vec2 uv =  (p.xy + p.z * vec2(17.0f, 37.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f, 37.0f)) + f.xy;
	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	vec3 xy1 = texture2D(noisetex, coord).xyz;
	vec3 xy2 = texture2D(noisetex, coord2).xyz;
	return mix(xy1, xy2, vec3(f.z));
}

vec3 Get3DNoiseNormal(in vec3 pos)
{
	float center = Get3DNoise(pos + vec3( 0.0f, 0.0f, 0.0f)).x * 2.0f - 1.0f;
	float left 	 = Get3DNoise(pos + vec3( 0.1f, 0.0f, 0.0f)).x * 2.0f - 1.0f;
	float up     = Get3DNoise(pos + vec3( 0.0f, 0.1f, 0.0f)).x * 2.0f - 1.0f;

	vec3 noiseNormal;
		 noiseNormal.x = center - left;
		 noiseNormal.y = center - up;

		 noiseNormal.x *= 0.2f;
		 noiseNormal.y *= 0.2f;

		 noiseNormal.b = sqrt(1.0f - noiseNormal.x * noiseNormal.x - noiseNormal.g * noiseNormal.g);
		 noiseNormal.b = 0.0f;

	return noiseNormal.xyz;
}

float GetModulatedRainSpecular(in vec3 pos)
{
	//pos.y += frameTimeCounter * 3.0f;
	pos.xz *= 1.0f;
	pos.y *= 0.2f;

	// pos.y += Get3DNoise(pos.xyz * vec3(1.0f, 0.0f, 1.0f)).x * 2.0f;

	vec3 p = pos;

	float n = Get3DNoise(p).y;
		  n += Get3DNoise(p / 2.0f).x * 2.0f;
		  n += Get3DNoise(p / 4.0f).x * 4.0f;

		  n /= 7.0f;


	n = saturate(n * 0.8 + 0.5) * 0.97;


	return n;
}

float hash(float n) {
 	return fract(cos(n*89.42)*343.42);
}

vec2 hash2(vec2 n) {
 	return vec2(hash(n.x*23.62-300.0+n.y*34.35),hash(n.x*45.13+256.0+n.y*38.89)); 
}

float worley(vec2 c, float time) {
    float dis = 1.0;
    for(int x = -1; x <= 1; x++)
        for(int y = -1; y <= 1; y++){
            vec2 p = floor(c)+vec2(x,y);
            vec2 a = hash2(p) * time;
            vec2 rnd = 0.5+sin(a)*0.5;
            float d = length(rnd+vec2(x,y)-fract(c));
            dis = min(dis, d);
        }
    return dis;
}

float worley5(vec2 c, float time) {
    float w = 0.0;
    float a = 0.5;
    for (int i = 0; i<5; i++) {
        w += worley(c, time)*a;
        c*=2.0;
        time*=2.0;
        a*=0.5;
    }
    return w;
}

float RainRipples(vec2 coord)
{
	// float c = 0;

	// for (int i = 0; i < 3; i++)
	// {
	// 	float n = worley(coord.xy / (64.0 + float(i) * 2.0), frameTimeCounter * 1.0 + float(i) * 2.0);
    
 //    	n = sin(n * 20.0 - frameTimeCounter * 30.0) * 0.5 + 0.5;
        
 //        c += n / 5.0;
	// }

	// return c;

	float c = 0.0;

	for (int i = 0; i < 4; i++)
	{
		vec4 rippleTex = texture2DLod(gaux1, coord, 0);


		float rippleTime = (frameTimeCounter + rippleTex.g * 4.1415 * (i + 1)) * (i * 0.2 + 1);

		float ripple = (sin(rippleTex.r * 10.0 + rippleTime * 20.0) * 0.5 + 0.5) * rippleTex.r;
		ripple *= sin(rippleTex.r * 2.0 + rippleTime * 20.0) * 0.5 + 0.5;

		c += ripple;

		coord += 0.2;

	}


	return c;
}

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

vec3 GetRainNormal(in vec3 pos, inout float wet)
{
	// pos.xz *= 30.0;

	// pos.y += wet * 12.0;


	// pos.y += -pos.x * 0.15;
	// pos.y += frameTimeCounter * 20.0;


	// vec3 n = Get3DNoiseNormal(pos.xyz);
	// n.xy += Get3DNoiseNormal(pos.xzy * 2.0).xy * 0.5;
	// n.xy += Get3DNoiseNormal((pos.xzy + pos.x) * 0.25 + vec3(-frameTimeCounter * 2.0, 0.0, 0.0)).xy * 1.5;

	// // n.xy *= 0.035;
	// n.xy *= 0.5;



	// pos.xz *= 0.2;

	// vec3 n = vec3(0.0, 0.0, 1.0);
	// //n.xy += sin(texture2D(noisetex, pos.xz).xy * 20.0 + frameTimeCounter * 20.0);

	// pos.y += frameTimeCounter * 0.02;
	// n.xy += sin(Get3DNoise(pos.xyz * 64.0).xy * 12.0 + frameTimeCounter * 30.0);
	// pos *= 1.5;
	// n.xy += sin(Get3DNoise(pos.xyz * 64.0 + 0.5).xy * 12.0 + frameTimeCounter * 49.0);
	// // pos.xz *= 3.1;
	// // n.xy += sin(texture2D(noisetex, pos.xz).xy * 8.0 + frameTimeCounter * 30.0);

	// n.xy *= 0.02;

	// pos *= 0.5;

	// float rC = RainRipples(pos.xz);
	// float rR = RainRipples(pos.xz + vec2(0.01, 0.0) * 0.2);
	// float rU = RainRipples(pos.xz + vec2(0.0, 0.01) * 0.2);

	// vec3 n = vec3(0.0, 0.0, 1.0);

	// n.x = rC - rR;
	// n.y = rC - rU;

	// n.xy *= 1.0;

	// n = normalize(n);

	//float frame = mod(floor(frameTimeCounter * 60.0), 1.0);







	// pos.xyz *= 0.5;

	// vec3 n = GetRainAnimationTex(pos.xz, wet);
	// vec3 nR = GetRainAnimationTex(pos.xz + vec2(1.0, 0.0) / 128.0, wet);
	// vec3 nU = GetRainAnimationTex(pos.xz + vec2(0.0, 1.0) / 128.0, wet);
	// vec3 nUR = GetRainAnimationTex(pos.xz + vec2(1.0, 1.0) / 128.0, wet);

	// vec2 fractCoord = fract(pos.xz * 128.0);

	// vec3 lerpX = mix(n, nR, fractCoord.x);
	// vec3 lerpX2 = mix(nU, nUR, fractCoord.x);
	// vec3 lerpY = mix(lerpX, lerpX2, fractCoord.y);

	// // n.xy *= 0.5;
	// // n = lerpY;
	// // n = normalize(lerpY);

	// n.xy *= 2.0;


	// float lod = dot(abs(fwidth(pos.xyz)), vec3(1.0));

	// n.xy *= 1.0 / (1.0 + lod * 10.0);

	// n.xy *= rainStrength;


	pos.xyz *= 0.5;


	vec3 n1 = BilateralRainTex(gaux1, pos.xz, wet);
	vec3 n2 = BilateralRainTex(gaux2, pos.xz, wet);
	vec3 n3 = BilateralRainTex(gaux3, pos.xz, wet);

	pos.x -= frameTimeCounter * 1.5;
	float downfall = texture2D(noisetex, pos.xz * 0.0025).x;
	downfall = saturate(downfall * 1.5 - 0.25);


	vec3 n = n1 * 2.0;
	n += n2 * saturate(downfall * 2.0) * 2.0;
	n += n3 * saturate(downfall * 2.0 - 1.0) * 2.0;
	// n = n3 * 3.0;

	n *= 0.3;

	float lod = dot(abs(fwidth(pos.xyz)), vec3(1.0));

	n.xy *= 1.0 / (1.0 + lod * 5.0);

	// n.xy /= wet + 0.1;
	// n.x = downfall;

	wet = saturate(wet * 1.0 + downfall * (1.0 - wet) * 0.95);
	// wet = downfall * 0.2 + 0.8;

	n.xy *= rainStrength;

	return n;
}

void main() 
{	

	vec2 texGradX = dFdx(texcoord.st);
	vec2 texGradY = dFdy(texcoord.st);



	vec2 textureCoordinate = texcoord.st;


	#ifdef PARALLAX

		vec3 viewVector = normalize(tbnMatrix * viewPos.xyz);
			 //viewVector.x /= 2.0f;
		int tileResolution = TEXTURE_RESOLUTION;
		ivec2 atlasTiles = atlasSize / TEXTURE_RESOLUTION;
		float atlasAspectRatio = atlasTiles.x / atlasTiles.y;
			viewVector.y *= atlasAspectRatio;


			 viewVector = normalize(viewVector);
		vec3 rayOffset;
		 textureCoordinate = CalculateParallaxCoord(texcoord.st, viewVector, rayOffset, texGradX, texGradY);
	#endif


	//vec4 albedo = texture2D(texture, textureCoordinate.st);
	vec4 albedo = textureGrad(texture, textureCoordinate.st, texGradX, texGradY);
	albedo *= color;


	//vec2 lightmap;
	// lightmap.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	// lightmap.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);


	// CurveLightmapSky(lightmap.y);

	vec4 specTex = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 normalTex = vec4(0.0, 1.0, 0.0, 1.0);
	vec3 viewNormal = normal;

		//specTex = texture2D(specular, textureCoordinate.st);
		specTex = textureGrad(specular, textureCoordinate.st, texGradX, texGradY);
		//normalTex = texture2D(normals, textureCoordinate.st);
		normalTex = textureGrad(normals, textureCoordinate.st, texGradX, texGradY);

		

	

	float smoothness = pow(specTex.r, 1.0);
	float metallic = specTex.g;
	float emissive = 0.0;



	float wet = GetModulatedRainSpecular(worldPosition.xyz + cameraPosition.xyz);
	#ifdef RAIN_SPLASH_EFFECT
		vec3 rainNormal = GetRainNormal(worldPosition.xyz + cameraPosition.xyz, wet);
	#else
		vec3 rainNormal = vec3(0.0, 0.0, 1.0);
	#endif
	wet *= saturate(worldNormal.y * 0.5 + 0.5);
	wet *= clamp(blockLight.y * 1.05 - 0.9, 0.0, 0.1) / 0.1;
	wet *= wetness;

	#ifdef FORCE_WET_EFFECT

	#else
	wet *= specTex.b;
	#endif


	float darkFactor = clamp(wet, 0.0f, 0.2f) / 0.2f;

	albedo.rgb = pow(albedo.rgb, vec3(mix(1.0f, 1.15f, darkFactor)));


	smoothness = smoothness * (1.0 - saturate(wet)) + saturate(wet);



	vec3 normalMap = normalize(normalTex.xyz * 2.0 - 1.0);
	normalMap = mix(normalMap, vec3(0.0, 0.0, 1.0), vec3(wet * wet));

	#ifdef RAIN_SPLASH_EFFECT
		normalMap = normalize(normalMap + rainNormal * wet * saturate(worldNormal.y) * vec3(1.0, 1.0, 0.0));
	#endif

	viewNormal = normalize(normalMap) * tbnMatrix;


	vec2 normalEnc = EncodeNormal(viewNormal.xyz);







	float parallaxShadow = 1.0;

	#ifdef PARALLAX
		#ifdef PARALLAX_SHADOW

			float baseHeight = GetTexture(normals, textureCoordinate.st).a;

			if (dot(normalize(sunPosition), viewNormal) > 0.0 && baseHeight < 1.0)
			{
				vec3 lightVector = normalize(sunPosition.xyz);
				lightVector = normalize(tbnMatrix * lightVector);
				lightVector.y *= atlasAspectRatio;
				lightVector = normalize(lightVector);
				parallaxShadow = GetParallaxShadow(textureCoordinate.st, lightVector, baseHeight, texGradX, texGradY);
			}
		#endif
	#endif





	// #ifdef PARALLAX
	// 	vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos.xyz, 0.0)).xyz;

	// 	float reliefDepth = 0.3;
	// 	float height = normalTex.a;
	// 	vec3 worldViewDir = normalize(worldPos.xyz);
	// 	float NdotV = dot(worldNormal.xyz, worldViewDir);

	// 	//float offsetDepth = (reliefDepth * 0.2 + (reliefDepth * 0.8) * NdotV) * (height);
	// 	float offsetDepth = reliefDepth * ((1.0 - height) - 0.0);
	// 	vec3 bottomPos = worldPos.xyz - worldNormal.xyz * offsetDepth;
	// 	float d1 = dot(worldNormal.xyz, bottomPos.xyz - worldPos.xyz);
	// 	float d2 = dot(worldViewDir, worldNormal.xyz);


	// 	vec3 parallaxWorldPos = worldPos.xyz;
	// 	if (d2 < 0.0)
	// 	{
	// 		parallaxWorldPos += worldViewDir * (d1 / d2);
	// 	}


	// 	parallaxWorldPos = (gbufferModelView * vec4(parallaxWorldPos.xyz, 0.0)).xyz;

	// 	vec4 projPos = gbufferProjection * vec4(parallaxWorldPos.xyz, 1.0);
	// 	projPos /= projPos.w;
	// 	projPos = projPos * 0.5 + 0.5;

	// 	gl_FragDepth = projPos.z;
	// #endif





	//Calculate torchlight average direction
	vec3 Q1 = dFdx(viewPos.xyz);
	vec3 Q2 = dFdy(viewPos.xyz);
	float st1 = dFdx(blockLight.x);
	float st2 = dFdy(blockLight.x);

	st1 /= dot(fwidth(viewPos.xyz), vec3(0.333333));
	st2 /= dot(fwidth(viewPos.xyz), vec3(0.333333));
	vec3 T = (Q1*st2 - Q2*st1);
	T = normalize(T + normal.xyz * 0.0002);
	T = -cross(T, normal.xyz);

	T = normalize(T + normal * 0.01);
	T = normalize(T + normal * 0.85 * (blockLight.x));


	float torchLambert = pow(saturate(dot(T, viewNormal.xyz) * 1.0 + 0.0), 1.0);
	torchLambert += pow(saturate(dot(T, viewNormal.xyz) * 0.4 + 0.6), 1.0) * 0.5;

	if (dot(T, normal.xyz) > 0.99)
	{
		torchLambert = pow(torchLambert, 2.0) * 0.45;
	}

	// albedo.rgb = texture2DLod(gaux1, worldPosition.xz, 0).rgb;


	vec2 mcLightmap = blockLight;
	mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
	mcLightmap.x = mcLightmap.x * torchLambert * 1.0;
	mcLightmap.x = pow(mcLightmap.x, 0.25);
	mcLightmap.x += rand(vertexPos.xy + sin(frameTimeCounter)).x * (1.5 / 255.0);


	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(mcLightmap.xy, emissive, parallaxShadow);
	gl_FragData[2] = vec4(normalEnc.xy, blockLight.x, albedo.a);
	gl_FragData[3] = vec4(smoothness, metallic, (materialIDs + 0.1) / 255.0, albedo.a);



}