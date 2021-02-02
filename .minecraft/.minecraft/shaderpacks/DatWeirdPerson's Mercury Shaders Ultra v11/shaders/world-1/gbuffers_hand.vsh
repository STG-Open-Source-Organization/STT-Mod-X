#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

const bool shakingHand = true;

varying vec4 color;

varying vec3 normal;

varying vec2 lightmapCoord;
varying vec2 texCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

vec4 getPosition(in mat4 position1, in mat4 position2, in vec4 position3) {
	return position1*position2*position3;
}

vec4 getColor() {
	return gl_Color;
}

vec3 getNormal() {
	return normalize(gl_NormalMatrix*gl_Normal);
}

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

vec2 getLightmapCoord() {
	return (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
}

void shakeHand(inout vec4 position) {

position.st += vec2(0.001 * sin(frameTimeCounter), 0.001 * cos(frameTimeCounter * 2));
position.z += (0.01)*sin(frameTimeCounter);
position.z /= 1-sin(frameTimeCounter*7+cos(frameTimeCounter*4))*(0.01/10)*0.2;

}

void main() {

texCoord = getTexCoord();
lightmapCoord = getLightmapCoord();
normal = getNormal();
color = getColor();

vec4 position	= getPosition(gbufferModelViewInverse,gl_ModelViewMatrix,gl_Vertex);

if (shakingHand) shakeHand(position);

gl_Position = getPosition(gl_ProjectionMatrix,gbufferModelView,position);
}