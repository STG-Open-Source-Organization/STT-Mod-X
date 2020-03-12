#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:0246 */

varying vec4 color;

varying vec3 normal;

varying vec2 lightmapCoord;
varying vec2 texCoord;

uniform vec4 entityColor;

uniform sampler2D texture;
uniform sampler2D specular;

uniform int entityHurt;

vec4 getNormals() {
	return vec4(normal*0.5+0.5,1.0);
}

vec4 getLightmapCoords() {
	return vec4(lightmapCoord.t,1.0,lightmapCoord.s,1.0);
}

vec4 getEntityColor() {

vec4 albedo = texture2D(texture,texCoord)*color;

albedo -= vec4(0.0,0.004,0.004,0.0)*entityHurt;
albedo += vec4(0.002,0.0,0.0,0.0)*entityHurt;

albedo = mix(albedo,vec4(1),entityColor); 

return albedo;
}

void main() {

gl_FragData[0] = getEntityColor();
gl_FragData[1] = getNormals();
gl_FragData[2] = getLightmapCoords();
gl_FragData[3] = texture2D(specular,texCoord);
}