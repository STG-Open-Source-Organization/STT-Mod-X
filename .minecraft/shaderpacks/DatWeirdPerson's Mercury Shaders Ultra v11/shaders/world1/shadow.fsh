#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

varying vec2 texCoord;

varying float isColored;

uniform sampler2D texture;

vec4 getShadowColor() {
vec4 texCoord = texture2D(texture,texCoord);

if (isColored < 0.9) texCoord.rgb = vec3(0.0);

	return texCoord;
}

void main() {

gl_FragData[0] = getShadowColor();
}