#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:024 */

const bool waterRefract = true;

varying vec4 color;

varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 worldPosition;

varying vec2 lightmapCoord;
varying vec2 texCoord;

varying float waterMaterial;
varying float material;

uniform sampler2D texture;
uniform sampler2D noisetex;

uniform float frameTimeCounter;

vec4 getWaterColor() {
	return (waterMaterial > 0.9)? vec4(0.0,0.5,0.6,0.2):texture2D(texture, texCoord)*color;
}

vec4 getNormals() {
vec2 refractPosition = worldPosition.xz;
			
mat3 tbnMatrix = mat3(
tangent.x, binormal.x, normal.x,
tangent.y, binormal.y, normal.y,
tangent.z, binormal.z, normal.z);

const float sharpness = 1.5;

float frameTime = (waterMaterial > 0.9)? frameTimeCounter / 100:0;
vec2 refCoord = (refractPosition / 40.0) + frameTime;

vec2 refCoord2 = refCoord;
refCoord2.s += refCoord2.s*sharpness;
refCoord2.s += refCoord2.t*sharpness;

vec2 refCoord3 = refCoord;
refCoord3.s += refCoord3.s*sharpness;
refCoord3.s -= refCoord3.t*sharpness;

float refPattern = texture2D(noisetex, refCoord).r*1.6;
refPattern *= 0.15;

refPattern += texture2D(noisetex, refCoord*2.5).r*0.1;
refPattern += texture2D(noisetex, refCoord*5).r*0.075;
refPattern += texture2D(noisetex, refCoord*10).r*0.05;
refPattern += texture2D(noisetex, refCoord*15).r*0.025;
refPattern += texture2D(noisetex, refCoord*20).r*0.015;
refPattern *= 37.5;

refPattern += texture2D(noisetex, refCoord2).r*0.5;

refCoord2 = refCoord;
refCoord2.s += refCoord2.s;
refCoord2.s -= refCoord2.t;

refPattern += texture2D(noisetex, refCoord2*2.5 - frameTime).r*0.10;
refPattern += texture2D(noisetex, refCoord2*5 - frameTime).r*0.09;

refPattern += texture2D(noisetex, refCoord3).r*0.5;

refCoord3 = refCoord;
refCoord3.s += refCoord3.s;
refCoord3.s -= refCoord3.t;

refPattern += texture2D(noisetex, refCoord3*2.5 - frameTime).r*0.10;
refPattern += texture2D(noisetex, refCoord3*5 - frameTime).r*0.09;

float refPattern2 = texture2D(noisetex, refCoord).r*1.6;
refPattern2 *= 0.15;

refPattern2 += texture2D(noisetex, refCoord*2.5).r*0.1;
refPattern2 += texture2D(noisetex, refCoord*5).r*0.075;
refPattern2 *= 37.5;

vec3 bump = normalize(vec3(vec2(refPattern+refPattern2)*0.005,1.0));
bump.xy -= 0.09;

	return waterRefract? vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0):vec4(normal * 0.5 + 0.5,1.0);
}

vec4 getLightmapCoords() {
	return vec4(lightmapCoord.t,material,lightmapCoord.s,1.0);
}

void main() {

gl_FragData[0] = getWaterColor();
gl_FragData[1] = getNormals();
gl_FragData[2] = getLightmapCoords();
}