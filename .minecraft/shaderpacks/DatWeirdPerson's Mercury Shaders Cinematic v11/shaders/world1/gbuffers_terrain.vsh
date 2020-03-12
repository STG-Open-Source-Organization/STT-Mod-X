#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec4 color;
varying vec4 vTexCoord;
varying vec4 vTexCoordam;

varying vec3 normal;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 viewVector;

varying vec2 lightmapCoord;

varying float dist;
varying float material;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform float frameTimeCounter;

mat3 getTBNMatrix() {
return mat3(
tangent.x, binormal.x, normal.x,
tangent.y, binormal.y, normal.y,
tangent.z, binormal.z, normal.z
);
}

vec4 getColor() {
	return gl_Color;
}

vec4 getPosition(in mat4 position1, in mat4 position2, in vec4 position3) {
	return position1*position2*position3;
}

vec3 getViewVector() {
	return normalize(getTBNMatrix() * (gl_ModelViewMatrix * gl_Vertex).xyz);
}

vec3 getNormal() {
	return normalize(gl_NormalMatrix*gl_Normal);
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
waves *= clamp(lightmapCoord.t,0.0,1.0);

	return position+(worldPosition*waves)*wavePower;
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

vec2 getMidCoord() {
	return (gl_TextureMatrix[0] *  mc_midTexCoord).st;
}

vec2 getLightmapCoord() {
	return (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
}

float getDistance() {
	return length(gl_ModelViewMatrix * gl_Vertex);
}

float getMaterial() {
float material = 1.0;

material = (mc_Entity.x == 50)? 0.4:material; // Torch
material = (mc_Entity.x == 76)? 0.5:material; // Redstone Torch
material = (mc_Entity.x == 91)? 0.6:material; // Jack o'Lantern
material = (mc_Entity.x == 89)? 0.7:material; // Glowstone
material = (mc_Entity.x == 327 || mc_Entity.x == 11 || mc_Entity.x == 10 || mc_Entity.x == 51)? 0.8:material; // Lava, fire, and related items
material = (mc_Entity.x == 169)? 0.9:material; // Sea Lantern

return material;
}

float calculateWaterMovement(in vec3 position, in vec3 worldPosition, in float wavePower, in vec2 lightmapCoord) {

float movement = 3.1415927*frameTimeCounter;
vec3 waves = vec3(clamp((frameTimeCounter/40),0.0,0.05));

waves.y *= sin(movement + worldPosition.y - worldPosition.z + worldPosition.y + worldPosition.z - worldPosition.z + worldPosition.x);
waves *= clamp(lightmapCoord.t,0.0,1.0);

	return position.y+(worldPosition.y*waves.y)*wavePower;
}

void main() {

material = getMaterial();
lightmapCoord = getLightmapCoord();

vec4 position = getPosition(gbufferModelViewInverse,gl_ModelViewMatrix,gl_Vertex);
vec3 worldPosition = getWorldPosition(position);

vec2 texCoord = getTexCoord();
vec2 midCoord = getMidCoord();
vec2 texCoordMinusMid = texCoord-midCoord;

vTexCoordam;
vTexCoordam.pq = abs(texCoordMinusMid)*2;
vTexCoordam.st = min(texCoord,midCoord-texCoordMinusMid);
vTexCoord.xy = sign(texCoordMinusMid)*0.5+0.5;

tangent = vec3(0.0);
binormal = vec3(0.0);

tangent.xyz = (gl_Normal.y > 0.5)? normalize(gl_NormalMatrix * vec3(1.0,  0.0,  0.0)):tangent.xyz;
tangent.xyz = (gl_Normal.x > 0.5)? normalize(gl_NormalMatrix * vec3(0.0,  0.0, -1.0)):tangent.xyz;
tangent.xyz = (gl_Normal.x < -0.5)? normalize(gl_NormalMatrix * vec3(0.0,  0.0,  1.0)):tangent.xyz;
tangent.xyz = (gl_Normal.z > 0.5)? normalize(gl_NormalMatrix * vec3(1.0,  0.0,  0.0)):tangent.xyz;
tangent.xyz = (gl_Normal.z < -0.5)? normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0)):tangent.xyz;
tangent.xyz = (gl_Normal.y < -0.5)? normalize(gl_NormalMatrix * vec3(1.0,  0.0,  0.0)):tangent.xyz;

binormal.xyz = (gl_Normal.y > 0.5)? normalize(gl_NormalMatrix * vec3(0.0,  0.0,  1.0)):binormal.xyz;
binormal.xyz = (gl_Normal.x > 0.5)? normalize(gl_NormalMatrix * vec3(0.0,  -1.0,  0.0)):binormal.xyz;
binormal.xyz = (gl_Normal.x < -0.5)? normalize(gl_NormalMatrix * vec3(0.0,  -1.0,  0.0)):binormal.xyz;
binormal.xyz = (gl_Normal.z > 0.5)? normalize(gl_NormalMatrix * vec3(0.0,  -1.0,  0.0)):binormal.xyz;
binormal.xyz = (gl_Normal.z < -0.5)? normalize(gl_NormalMatrix * vec3(0.0,  -1.0,  0.0)):binormal.xyz;
binormal.xyz = (gl_Normal.y < -0.5)? normalize(gl_NormalMatrix * vec3(0.0,  0.0,  1.0)):binormal.xyz;

position.y = (mc_Entity.x == 111)? calculateWaterMovement(position.xyz,worldPosition,0.0065,lightmapCoord):position.y;											//  Lilypad
position.xyz = (mc_Entity.x == 31)? calculateMovement(position.xyz,worldPosition,0.0025,true,0.7,lightmapCoord):position.xyz;									// Grass and related objects
position.xyz = (mc_Entity.x == 6)? calculateMovement(position.xyz,worldPosition,0.00025,true,0.3,lightmapCoord):position.xyz;									// Saplings
position.xyz = (mc_Entity.x == 32)? calculateMovement(position.xyz,worldPosition,0.0015,true,0.6,lightmapCoord):position.xyz;									// Dead bush
position.xyz = (mc_Entity.x == 30)? calculateMovement(position.xyz,worldPosition,0.0065,true,1.2,lightmapCoord):position.xyz;									// Cobweb
position.xyz = (mc_Entity.x == 51)? calculateMovement(position.xyz,worldPosition,0.0075,true,1.5,lightmapCoord):position.xyz;									// Fire
position.xyz = (mc_Entity.x == 59)? calculateMovement(position.xyz,worldPosition,0.0015,true,1.3,lightmapCoord):position.xyz;									// Wheat
position.xyz = (mc_Entity.x == 115)? calculateMovement(position.xyz,worldPosition,0.0003,true,1.9,lightmapCoord):position.xyz;									// Nether Wart
position.xyz = (mc_Entity.x == 106)? calculateMovement(position.xyz,worldPosition,0.00065,false,1.4,lightmapCoord):position.xyz;								// Vines	
position.xyz = (mc_Entity.x == 39 || mc_Entity.x == 40)? calculateMovement(position.xyz,worldPosition,0.004,true,1.6,lightmapCoord):position.xyz;		// Brown and Red Mushrooms
position.xyz = (mc_Entity.x == 38 || mc_Entity.x == 37)? calculateMovement(position.xyz,worldPosition,0.0035,true,0.4,lightmapCoord):position.xyz;		// Flowers
position.xyz = (mc_Entity.x == 103 || mc_Entity.x == 104)? calculateMovement(position.xyz,worldPosition,0.0006,true,1.8,lightmapCoord):position.xyz;	// Pumpkin and Melon Stems
position.xyz = (mc_Entity.x == 141 || mc_Entity.x == 142)? calculateMovement(position.xyz,worldPosition,0.0014,true,2.1,lightmapCoord):position.xyz;	// Carrots and Potatos
position.xyz = (mc_Entity.x == 175 || mc_Entity.x == 83)? calculateMovement(position.xyz,worldPosition,0.00065,false,1.1,lightmapCoord):position.xyz;// Tall entities
position.xyz = (mc_Entity.x == 18 || mc_Entity.x == 161)? calculateMovement(position.xyz,worldPosition,0.0015,false,0.2,lightmapCoord):position.xyz;	// Leaves

normal = getNormal();
viewVector = getViewVector();
dist = getDistance();
color = getColor();
gl_Position = getPosition(gl_ProjectionMatrix,gbufferModelView,position);
}