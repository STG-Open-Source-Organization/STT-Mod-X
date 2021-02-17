#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

const float shaderOptimizationLevel = 1.0;

varying vec2 texCoord;

varying float essentialsQuality;

vec2 getTexCoord() {
	return (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
}

float getEssentialsQuality() {
float quality = 0.0;

quality = (shaderOptimizationLevel == 0.0)? 60:quality;
quality = (shaderOptimizationLevel == 1.0)? 30:quality;
quality = (shaderOptimizationLevel == 2.0)? 15:quality;
quality = (shaderOptimizationLevel == 3.0)? 7:quality;
quality = (shaderOptimizationLevel == 4.0)? 3:quality;

return quality;
}

void main() {

essentialsQuality = getEssentialsQuality();
texCoord = getTexCoord();
gl_Position = ftransform();
}