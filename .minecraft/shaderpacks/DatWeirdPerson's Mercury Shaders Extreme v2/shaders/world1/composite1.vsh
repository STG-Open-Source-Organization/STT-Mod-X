#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec3 lightVector;

varying vec2 texCoord;

varying float timeMidnight;
varying float timeSunrise;
varying float timeSunset;
varying float timeNoon;
varying float timeTransition;

uniform vec3 sunPosition;

uniform int worldTime;

float time = worldTime;

vec3 getLightVector() {
return (worldTime < 12700 || worldTime > 23250)? normalize(sunPosition):normalize(-sunPosition);
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
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
lightVector = getLightVector();
texCoord = getTexCoord();
gl_Position = ftransform();
}