#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec4 color;

varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 worldPosition;

varying vec2 lightmapCoord;
varying vec2 texCoord;

varying float waterMaterial;
varying float material;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

attribute vec4 mc_Entity;

uniform float frameTimeCounter;

vec4 getColor() {
	return gl_Color;
}

vec4 getPosition(in mat4 position1, in mat4 position2, in vec4 position3) {
	return position1*position2*position3;
}

vec3 getNormal() {
	return normalize(gl_NormalMatrix*gl_Normal);
}

vec3 getWorldPosition(in vec4 position) {
	return position.xyz + cameraPosition;
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

vec2 getLightmapCoord() {
	return (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
}

float getWaterMaterial() {
bool conditions = false;
if (mc_Entity.x == 8.0 || mc_Entity.x == 9.0) conditions = true;
return conditions? 1.0:0.0;
}

float getMaterial() {
bool conditions = false;
if (mc_Entity.x == 8.0 || mc_Entity.x == 9.0) conditions = true;
return conditions? 0.2:0.1;
}

float calculateWaterMovement(in vec3 position, in vec3 worldPosition, in float wavePower, in vec2 lightmapCoord) {

float movement = 3.1415927*frameTimeCounter;
vec3 waves = vec3(clamp((frameTimeCounter/40),0.0,0.05));

waves.y *= sin(movement + worldPosition.y - worldPosition.z + worldPosition.y + worldPosition.z - worldPosition.z + worldPosition.x);
waves *= clamp(lightmapCoord.t,0.0,1.0);

	return position.y+(worldPosition.y*waves.y)*wavePower;
}

void main() {

vec4 position = getPosition(gbufferModelViewInverse,gl_ModelViewMatrix,gl_Vertex);
material = getMaterial();
texCoord = getTexCoord();
waterMaterial = getWaterMaterial();
lightmapCoord = getLightmapCoord();
worldPosition = getWorldPosition(position);

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

position.y = (waterMaterial == 1.0)? calculateWaterMovement(position.xyz,worldPosition,0.0065,lightmapCoord):position.y;

normal = getNormal();
color = getColor();
gl_Position = getPosition(gl_ProjectionMatrix,gbufferModelView,position);
}