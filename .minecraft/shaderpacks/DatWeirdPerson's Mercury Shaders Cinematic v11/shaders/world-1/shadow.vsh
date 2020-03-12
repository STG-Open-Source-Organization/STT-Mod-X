#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

const float shadowMapBias = 0.9;

varying vec2 texCoord;

varying float isColored;

uniform vec3 cameraPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform float frameTimeCounter;

vec4 getPosition(in mat4 position1, in mat4 position2, in vec4 position3) {
	return position1*position2*position3;
}

vec3 getWorldPosition(in vec4 position) {
	return position.xyz + cameraPosition;
}

vec3 calculateMovement(in vec3 position, in vec3 worldPosition, in float wavePower, in bool waveTop, in float randomPos, in vec2 lightmapCoord) {

float movement = 3.1415927*frameTimeCounter;

vec3 waves = vec3(clamp((frameTimeCounter/40),0.0,0.05));

waves.x *= sin(movement - (worldPosition.x + randomPos*100) + worldPosition.z + worldPosition.y - worldPosition.z + worldPosition.y - worldPosition.x);
waves.z *= sin(movement + (worldPosition.x - randomPos*100) - worldPosition.z + worldPosition.y + worldPosition.z - worldPosition.z + worldPosition.x);
if (waveTop) waves = (float(gl_MultiTexCoord0.t < mc_midTexCoord.t) == 1)? waves:vec3(0.0);
waves *= lightmapCoord.t;

	return position+(worldPosition*waves)*wavePower;
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

vec2 getLightmapCoord() {
	return (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
}

float getDistance() {
	return sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
}

float getDistortFactor(in float dist) {
	return (1.0f - shadowMapBias) + dist * shadowMapBias;
}

float isShadowColored() {
	return (mc_Entity.x == 95 || mc_Entity.x == 160 || mc_Entity.x == 79 || mc_Entity.x == 165 || mc_Entity.x == 90)? 1.0:0.0;
}

float calculateWaterMovement(in vec3 position, in vec3 worldPosition, in float wavePower, in vec2 lightmapCoord) {

float movement = 3.1415927*frameTimeCounter;
vec3 waves = vec3(clamp((frameTimeCounter/40),0.0,0.05));

waves.y *= sin(movement + worldPosition.y - worldPosition.z + worldPosition.y + worldPosition.z - worldPosition.z + worldPosition.x);
waves *= lightmapCoord.t;

	return position.y+(worldPosition.y*waves.y)*wavePower;
}

void main() {

texCoord = getTexCoord();

vec4 position = getPosition(shadowModelViewInverse,gl_ModelViewMatrix,gl_Vertex);
vec3 worldPosition = getWorldPosition(position);
vec2 lightmapCoord = getLightmapCoord();

isColored = isShadowColored();

position.y = (mc_Entity.x == 111)? calculateWaterMovement(position.xyz,worldPosition,0.0065,lightmapCoord):position.y;											//  Lilypad
position.xyz = (mc_Entity.x == 31)? calculateMovement(position.xyz,worldPosition,0.0025,true,0.7,lightmapCoord):position.xyz;									// Grass and related objects
position.xyz = (mc_Entity.x == 6)? calculateMovement(position.xyz,worldPosition,0.00025,true,0.3,lightmapCoord):position.xyz;									// Saplings
position.xyz = (mc_Entity.x == 32)? calculateMovement(position.xyz,worldPosition,0.0055,true,0.6,lightmapCoord):position.xyz;									// Dead bush
position.xyz = (mc_Entity.x == 30)? calculateMovement(position.xyz,worldPosition,0.0065,true,1.2,lightmapCoord):position.xyz;									// Cobweb
position.xyz = (mc_Entity.x == 51)? calculateMovement(position.xyz,worldPosition,0.0075,true,1.5,lightmapCoord):position.xyz;									// Fire
position.xyz = (mc_Entity.x == 59)? calculateMovement(position.xyz,worldPosition,0.0065,true,1.3,lightmapCoord):position.xyz;									// Fire
position.xyz = (mc_Entity.x == 115)? calculateMovement(position.xyz,worldPosition,0.0003,true,1.9,lightmapCoord):position.xyz;									// Nether Wart
position.xyz = (mc_Entity.x == 106)? calculateMovement(position.xyz,worldPosition,0.00065,false,1.4,lightmapCoord):position.xyz;								// Vines				// Lilypads
position.xyz = (mc_Entity.x == 39 || mc_Entity.x == 40)? calculateMovement(position.xyz,worldPosition,0.004,true,1.6,lightmapCoord):position.xyz;		// Brown and Red Mushrooms
position.xyz = (mc_Entity.x == 38 || mc_Entity.x == 37)? calculateMovement(position.xyz,worldPosition,0.0035,true,0.4,lightmapCoord):position.xyz;		// Flowers
position.xyz = (mc_Entity.x == 103 || mc_Entity.x == 104)? calculateMovement(position.xyz,worldPosition,0.0006,true,1.8,lightmapCoord):position.xyz;	// Pumpkin and Melon Stems
position.xyz = (mc_Entity.x == 141 || mc_Entity.x == 142)? calculateMovement(position.xyz,worldPosition,0.0014,true,2.1,lightmapCoord):position.xyz;	// Carrots and Potatos
position.xyz = (mc_Entity.x == 175 || mc_Entity.x == 83)? calculateMovement(position.xyz,worldPosition,0.00065,false,1.1,lightmapCoord):position.xyz;// Tall entities
position.xyz = (mc_Entity.x == 18 || mc_Entity.x == 161)? calculateMovement(position.xyz,worldPosition,0.0015,false,0.2,lightmapCoord):position.xyz;	// Leaves

gl_Position = getPosition(gl_ProjectionMatrix,shadowModelView,position);

float dist = getDistance();
float distortFactor = getDistortFactor(dist);

gl_Position.xy *= 1.0/distortFactor;
gl_FrontColor = gl_Color;
}