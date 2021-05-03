#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec4 color;

varying vec3 normal;

varying vec2 lightmapCoord;
varying vec2 texCoord;

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

void main() {

texCoord = getTexCoord();
lightmapCoord = getLightmapCoord();
normal = getNormal();
color = getColor();
gl_Position = ftransform();
}