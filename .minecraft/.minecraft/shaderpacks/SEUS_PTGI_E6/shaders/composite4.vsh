#version 130

#include "Common.inc"

out vec4 texcoord;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float rainStrength;
uniform vec3 skyColor;
uniform float sunAngle;

uniform mat4 shadowModelViewInverse;

uniform int worldTime;

out vec3 lightVector;
out vec3 upVector;

out float timeSunriseSunset;
out float timeNoon;
out float timeMidnight;
out float timeSkyDark;

out vec3 colorSunlight;
out vec3 colorSkylight;
out vec3 colorSunglow;
out vec3 colorBouncedSunlight;
out vec3 colorScatteredSunlight;
out vec3 colorTorchlight;
out vec3 colorWaterMurk;
out vec3 colorWaterBlue;
out vec3 colorSkyTint;

out vec3 worldLightVector;
out vec3 worldSunVector;

out vec3 skyUpColor;

float CubicSmooth(in float x)
{
	return x * x * (3.0f - 2.0f * x);
}

float clamp01(float x)
{
	return clamp(x, 0.0, 1.0);
}

//#define HALF_RES_TRACE


void main() {
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;

	worldSunVector = normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
	worldLightVector = worldSunVector;

	if (sunAngle < 0.5f) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
		worldSunVector *= -1.0;
	}

	vec3 sunVector = normalize(sunPosition);

	upVector = normalize(upPosition);
	
	#ifdef HALF_RES_TRACE
	gl_Position.xy *= 0.5;
	gl_Position.xy -= 0.5;
	texcoord.st *= 0.5;
	#endif
	
	//gl_Position.x *= 0.51;
	//gl_Position.x -= 0.49;
	// gl_Position.xy *= 0.5;

	//texcoord.x *= 0.51;


	float timePow = 6.0f;

	float LdotUp = dot(upVector, sunVector);
	float LdotDown = dot(-upVector, sunVector);

	timeNoon = 1.0 - pow(1.0 - clamp01(LdotUp), timePow);
	timeSunriseSunset = 1.0 - timeNoon;
	timeMidnight = CubicSmooth(CubicSmooth(clamp01(LdotDown * 20.0f + 0.4)));
	timeMidnight = 1.0 - pow(1.0 - timeMidnight, 2.0);
	timeSunriseSunset *= 1.0 - timeMidnight;
	timeNoon *= 1.0 - timeMidnight;

	// timeSkyDark = clamp01(LdotDown);
	// timeSkyDark = pow(timeSkyDark, 3.0f);
	timeSkyDark = 0.0f;



	skyUpColor = AtmosphericScattering(vec3(0.0, 1.0, 0.0), worldSunVector, 0.0);
	skyUpColor = ModulateSkyForRain(skyUpColor, skyUpColor, rainStrength);



	float horizonTime = CubicSmooth(clamp01((1.0 - abs(LdotUp)) * 7.0f - 6.0f));
	
}
