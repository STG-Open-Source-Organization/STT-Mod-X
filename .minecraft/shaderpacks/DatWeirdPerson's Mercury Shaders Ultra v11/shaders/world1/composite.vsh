#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec3 timedColor;
varying vec3 baseColor;
varying vec3 lightColor;
varying vec3 lightVector;

varying vec2 texCoord;

varying float lightValue;
varying float lightJitter;
varying float eyeAdaptation;
varying float timeMidnight;
varying float timeSunrise;
varying float timeSunset;
varying float timeNoon;
varying float timeTransition;

uniform vec3 sunPosition;

uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform int worldTime;
uniform int heldItemId;

float time = worldTime;

vec3 getLightVector() {
return (worldTime < 12700 || worldTime > 23250)? normalize(sunPosition):normalize(-sunPosition);
}

vec3 getTimedColors() {

vec3 sunriseColor = vec3(0.0,0.05,0.1)*timeSunrise;
vec3 noonColor = vec3(0.0,0.0,0.0)*timeNoon;
vec3 sunsetColor = vec3(0.0,0.05,0.1)*timeSunset;
vec3 midnightColor = vec3(0.25,0.15,0.0)*timeMidnight;

	return (sunriseColor+noonColor+sunsetColor+midnightColor)*timeTransition;
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

float getLightValue() {
float value = 0.0;

value = (heldItemId == 50)? 1.0:value; // Torch
value = (heldItemId == 76)? 0.6:value; // Redstone Torch
value = (heldItemId == 91)? 1.4:value; // Jack o'Lantern
value = (heldItemId == 89)? 1.5:value; // Glowstone
value = (heldItemId == 327)? 0.5:value; // Lava Bucket
value = (heldItemId == 169)? 1.3:value; // Sea Lantern

return value;
}

float getLightJitter() {
	return 1-sin(frameTimeCounter*7+cos(frameTimeCounter*1.9*2))*0.03;
}

float getEyeAdaptation() {
	return mix(1.0,0.0,(pow(eyeBrightnessSmooth.y / 240.0f, 2.0f)));
}

float getMidnightTime() {
	return ((clamp(time, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(time, 23000.0, 24000.0) - 23000.0) / 1000.0);
}

float getSunriseTime() {
	return ((clamp(time, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(time, 0.0, 4000.0)/4000.0));
}

float getSunsetTime() {
	return ((clamp(time, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(time, 12000.0, 12750.0) - 12000.0) / 750.0);
}

float getNoonTime() {
	return ((clamp(time, 0.0, 4000.0)) / 4000.0) - ((clamp(time, 8000.0, 12000.0) - 8000.0) / 4000.0);
}

float getTimeTransition() {
	return 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22000.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
}

void main() {

timeMidnight = getMidnightTime();
timeSunrise = getSunriseTime();
timeSunset = getSunsetTime();
timeNoon = getNoonTime();
timeTransition = getTimeTransition();
eyeAdaptation = getEyeAdaptation();
lightVector = getLightVector();
texCoord = getTexCoord();
lightValue = getLightValue();
lightJitter = getLightJitter();
timedColor = getTimedColors();
lightColor = vec3(0.7,0.5,0.23);
baseColor = vec3(0.1,0.1,0.2);
gl_Position = ftransform();

}