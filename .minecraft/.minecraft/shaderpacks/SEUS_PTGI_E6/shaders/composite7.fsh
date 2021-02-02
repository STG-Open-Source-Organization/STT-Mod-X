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



#include "Common.inc"


/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define MOTION_BLUR // Motion blur. Makes motion look blurry.

/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////


const bool compositeMipmapEnabled = false;


uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

in vec4 texcoord;
in vec3 lightVector;

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

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;

in vec3 colorSunlight;
in vec3 colorSkylight;

uniform float frameTime;

vec3 GetColorTexture(vec2 coord)
{
	return pow(texture2DLod(composite, coord, 0).rgb, vec3(2.2));
}

float GetDepth(vec2 coord)
{
	return texture2D(depthtex1, coord).x;
}

vec2 GetNearFragment(vec2 coord, float depth)
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

	return coord + texel * targetFragment;
}

void 	MotionBlur(inout vec3 color) {
	float depth = GetDepth(texcoord.st);

	//vec2 nearFragment = GetNearFragment(texcoord.st, depth);
	//depth = GetDepth(nearFragment);



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

	vec2 velocity = (currentPosition - previousPosition).st * 0.1f * (1.0 / frameTime) * 0.012;
	float maxVelocity = 0.05f;
		 velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));


	if (depth < 0.7)
	{
		velocity *= 0.0;
	}

	//bool isHand = GetMaterialMask(texcoord.st, 5);
	//velocity *= 1.0f - float(isHand);

	int samples = 0;

	float dither = rand(texcoord.st).x * 1.0;

	color.rgb = vec3(0.0f);

	for (int i = -2; i <= 2; ++i) {
		vec2 coord = texcoord.st + velocity * (float(i + dither) / 2.0);
			 //coord += vec2(dither) * 1.0f * velocity;

		if (coord.x > 0.0f && coord.x < 1.0f && coord.y > 0.0f && coord.y < 1.0f) {

			color += GetColorTexture(coord).rgb;
			samples += 1;

		}
	}

	color.rgb /= samples;


}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec3 color = vec3(0.0);

	#ifdef MOTION_BLUR
		MotionBlur(color);
	#else
		color = GetColorTexture(texcoord.st);
	#endif




	color = pow(color, vec3(1.0 / 2.2));

	gl_FragData[0] = vec4(color, 1.0);
	//Write color for previous frame here
	gl_FragData[1] = vec4(texture2D(composite, texcoord.st).rgba);

}

/* DRAWBUFFERS:37 */
