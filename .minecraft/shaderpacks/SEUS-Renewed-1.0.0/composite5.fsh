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



#include "Common.inc"


/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define TAA_SOFTNESS 0.0 // Softness of temporal anti-aliasing. Default 0.0 [0.0 0.2 0.4 0.6 0.8 1.0]
#define SHARPENING 0.0 // Sharpening of the image. Default 0.0 [0.0 0.2 0.4 0.8 1.0]

#define TAA_ENABLED // Temporal Anti-Aliasing. Utilizes multiple rendered frames to reconstruct an anti-aliased image similar to supersampling. Can cause some artifacts.
//#define TAA_AGGRESSIVE // Makes Temporal Anti-Aliasing more generously blend previous frames. This results in a more stable and smoother image, but causes more noticeable artifacts with movement.

/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:467 */



uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

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
uniform float frameTimeCounter;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform int   isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   fogMode;

varying float timeSunriseSunset;
varying float timeNoon;
varying float timeMidnight;

varying vec3 colorSunlight;
varying vec3 colorSkylight;

uniform float frameTime;

vec3 GetColor(vec2 coord)
{
	return GammaToLinear(texture2D(gnormal, coord).rgb);
}

vec3 BlurV(vec2 coord)
{

	vec3 color = vec3(0.0);

	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);


/*
	float weights[3] = float[3](0.27343750, 0.32812500, 0.03515625);
	float offsets[3] = float[3](0.00000000, 1.33333333, 3.11111111);




	color += GetColor(coord) * weights[0];

	for (int i = 1; i < 3; i++)
	{
		color += GetColor(coord + vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
		color += GetColor(coord - vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
	}
*/

	float weights[5] = float[5](0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625);
	float offsets[5] = float[5](0.00000000, 1.00000000, 2.00000000, 3.00000000, 4.00000000);
	
	color += GetColor(coord) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		color += GetColor(coord + vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
		color += GetColor(coord - vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
	}

	return color;

	//return GetColor(coord);
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

vec2 GetNearFragment(vec2 coord, float depth, out float minDepth)
{
	
	
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	vec4 depthSamples;
	depthSamples.x = texture2D(gdepthtex, coord + texel * vec2(1.0, 1.0)).x;
	depthSamples.y = texture2D(gdepthtex, coord + texel * vec2(1.0, -1.0)).x;
	depthSamples.z = texture2D(gdepthtex, coord + texel * vec2(-1.0, 1.0)).x;
	depthSamples.w = texture2D(gdepthtex, coord + texel * vec2(-1.0, -1.0)).x;

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

vec3 RGBToYUV(vec3 color)
{
	mat3 mat = 		mat3( 0.2126,  0.7152,  0.0722,
				 	-0.09991, -0.33609,  0.436,
				 	 0.615, -0.55861, -0.05639);
				 	
	return color * mat;
}

vec3 YUVToRGB(vec3 color)
{
	mat3 mat = 		mat3(1.000,  0.000,  1.28033,
				 	1.000, -0.21482, -0.38059,
				 	1.000,  2.12798,  0.000);
				 	
	return color * mat;
}

#define COLORPOW 1.0

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	//vec3 color = GammaToLinear(texture2D(gaux3, texcoord.st).rgb);

	vec3 bloomColor = vec3(0.0);

	bloomColor = BlurV(texcoord.st);

	bloomColor = LinearToGamma(bloomColor);


	//color += rand(texcoord.st) * (1.0 / 255.0);

	//Combine TAA here...
	vec3 color = pow(texture2D(gaux3, texcoord.st).rgb, vec3(COLORPOW));	//Sample color texture
	vec3 origColor = color;


	#ifdef TAA_ENABLED


	float depth = texture2D(gdepthtex, texcoord.st).x;

/*
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;
*/

	float minDepth;

	vec2 nearFragment = GetNearFragment(texcoord.st, depth, minDepth);

	float nearDepth = texture2D(gdepthtex, nearFragment).x;

	vec4 projPos = vec4(texcoord.st * 2.0 - 1.0, nearDepth * 2.0 - 1.0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * projPos;
	viewPos.xyz /= viewPos.w;

	// if (length(viewPos.xyz) > far * 0.9)
	// {
	// 	viewPos.xyz *= 0.1;
	// }

	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
	//worldPos.xyz += cameraPosition;

	vec4 worldPosPrev = worldPos;
	//worldPosPrev.xyz -= previousCameraPosition;
	// if (length(viewPos.xyz) < far * 1.0)
	{
		worldPosPrev.xyz += (cameraPosition - previousCameraPosition);
	}

	vec4 viewPosPrev = gbufferPreviousModelView * vec4(worldPosPrev.xyz, 1.0);
	vec4 projPosPrev = gbufferPreviousProjection * vec4(viewPosPrev.xyz, 1.0);
	projPosPrev.xyz /= projPosPrev.w;

	vec2 motionVector = (projPos.xy - projPosPrev.xy);

	float motionVectorMagnitude = length(motionVector) * 10.0;
	float pixelMotionFactor = clamp(motionVectorMagnitude * 500.0, 0.0, 1.0);

	vec2 reprojCoord = texcoord.st - motionVector.xy * 0.5;

	vec2 pixelError = cos((fract(abs(texcoord.st - reprojCoord.xy) * vec2(viewWidth, viewHeight)) * 2.0 - 1.0) * 3.14159) * 0.5 + 0.5;
	vec2 pixelErrorFactor = pow(pixelError, vec2(0.5));

// * frameTime * 0.5

	vec4 prevColor = pow(texture2D(gaux4, reprojCoord.st), vec4(COLORPOW, COLORPOW, COLORPOW, 1.0));
	float prevMinDepth = prevColor.a;

	float motionVectorDiff = (abs(motionVectorMagnitude - prevColor.a));


	vec3 minColor = vec3(1000000.0,1000000.0,1000000.0);
	vec3 maxColor = vec3(0.0,0.0,0.0);
	vec3 avgColor = vec3(0.0,0.0,0.0);
	vec3 avgX = vec3(0.0);
	vec3 avgY = vec3(0.0);

	int c = 0;

	vec3 m1 = vec3(0.0);
	vec3 m2 = vec3(0.0);

	///*
	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 offs = (vec2(float(i), float(j)) / vec2(viewWidth, viewHeight)) * 0.7;
			vec3 samp = pow(texture2D(gaux3, texcoord.xy + offs).rgb, vec3(COLORPOW));
			minColor = min(minColor, samp);
			maxColor = max(maxColor, samp);
			avgColor += samp;

			if (j == 0)
			{
				avgX += samp;
			}

			if (i == 0)
			{
				avgY += samp;
			}

			samp = (RGBToYUV(samp));

			m1 += samp;
			m2 += samp * samp;
			c++;
		}
	}
	avgColor /= c;

	avgX /= 3.0;
	avgY /= 3.0;


#ifdef TAA_AGGRESSIVE
	float colorWindow = 1.9;
#else
	float colorWindow = 1.5;
#endif

	vec3 mu = m1 / c;
	vec3 sigma = sqrt(max(vec3(0.0), m2 / c - mu * mu));
	vec3 minc = mu - (colorWindow) * sigma;
	vec3 maxc = mu + (colorWindow) * sigma;



	//adaptive blur
	//color = mix(color, avgColor, vec3(0.25 - pixelErrorFactor * 0.25));

#ifdef TAA_AGGRESSIVE
	vec3 blendWeight = vec3(0.015);
#else
	vec3 blendWeight = vec3(0.05);
#endif

	//if (abs(ExpToLinearDepth(minDepth) - ExpToLinearDepth(prevMinDepth)) > 1.0 && abs(ExpToLinearDepth(depth) - ExpToLinearDepth(prevMinDepth)) > 1.0)
	//{
		//blendWeight = vec3(1.0);
	//}


	//adaptive sharpen
	vec3 sharpen = (vec3(1.0) - exp(-(color - avgColor) * 15.0)) * 0.06;
	vec3 sharpenX = (vec3(1.0) - exp(-(color - avgX) * 15.0)) * 0.06;
	vec3 sharpenY = (vec3(1.0) - exp(-(color - avgY) * 15.0)) * 0.06;
	color += sharpenX * (0.45 / blendWeight) * pixelErrorFactor.x;
	color += sharpenY * (0.45 / blendWeight) * pixelErrorFactor.y;



	color += clamp(sharpen, -vec3(0.0005), vec3(0.0005)) * SHARPENING * 4.0;



	color = mix(color, avgColor, vec3(TAA_SOFTNESS));

	prevColor.rgb = YUVToRGB(clamp(RGBToYUV(prevColor.rgb), minc, maxc));

	/*
	prevColor.rgb = clamp(prevColor.rgb, minColor, maxColor);


	if (prevColor.r < minColor.r || prevColor.r > maxColor.r ||
		prevColor.g < minColor.g || prevColor.g > maxColor.g ||
		prevColor.b < minColor.b || prevColor.b > maxColor.b )
	{
		//blendWeight = 1.0;
		vec3 difference = clamp((minColor - prevColor.rgb), vec3(0.0), vec3(10000.0));
			 difference += clamp((prevColor.rgb - maxColor), vec3(0.0), vec3(10000.0));

		//blendWeight += difference * 6000.0;
	}
	*/




	blendWeight += vec3(pixelMotionFactor * 0.0);


	//blendWeight = mix(blendWeight, 1.0, clamp(motionVectorDiff * 40.0, 0.0, 1.0));

	blendWeight = clamp(blendWeight, vec3(0.0), vec3(1.0));

	if (depth < 0.7)
	{
		blendWeight = vec3(1.0);
		color = origColor;
	}



	vec3 taa = mix(prevColor.rgb, color, blendWeight);

	//taa.xy += pixelError * 0.01;


	//if (abs(ExpToLinearDepth(minDepth) - ExpToLinearDepth(prevMinDepth)) > 1.0 && abs(ExpToLinearDepth(depth) - ExpToLinearDepth(prevMinDepth)) > 1.0)
	//{
		//taa.r += 0.01;
	//}

	//taa.r += motionVectorDiff * 0.01;
	//taa.r += motionVectorDiff * 0.01;

	//taa = color;


	taa = pow(taa, vec3(1.0 / COLORPOW));

	#else 

	vec3 taa = color.rgb;

	#endif

	gl_FragData[0] = vec4(bloomColor.rgb, 1.0f);
	gl_FragData[1] = vec4(taa, 1.0);
	gl_FragData[2] = vec4(vec3(0.0), 1.0f);

}
