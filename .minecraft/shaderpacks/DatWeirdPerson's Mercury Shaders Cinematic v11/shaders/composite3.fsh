#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:0 */

const float lensFlareStrength				= 1.0;
const float dirtyLensStrength				= 1.0;

const float depthOfFieldStrength			= 3.0;
const float depthOfFieldQuality			= 60.0;
const float depthOfFieldShape			= 3.0;
const float variableLodStrength			= 1.0;
const float nearsightedIntensity			= 0.25;

const bool colortex1MipmapEnabled 	= true;
const bool compositeMipmapEnabled 	= true;
const bool colortex5MipmapEnabled	= true;
const bool colortex0MipmapEnabled	= true;

const bool warmShaderTone				= false;
const bool lensFlare 							= true;
const bool filmGrain							= true;

const bool depthOfField						= true;
const bool smoothDoF						= true;
const bool variableLod						= true;
const bool nearsighted						= false;

const bool dirtyLens							= true;
const bool circles								= true;
const bool hexagons							= true;
const bool dirt									= true;

varying vec3 lightVector;
varying vec3 lightColor;

varying vec2 texCoord;

varying float timeMidnight;
varying float timeTransition;
varying float timeSunrise;
varying float timeSunset;
varying float essentialsQuality;

uniform vec3 sunPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex1;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float centerDepthSmooth;

uniform int isEyeInWater;

float pw = 1.0/viewWidth;
float ph = 1.0/viewHeight;
bool eyeIsInWater = bool(isEyeInWater);

struct positionStruct{

vec4 tPos;
vec4 fragPosition;
vec4 currentPosition;

vec2 lightPos;

float truePos;

}Position;

struct visibilityFactorStruct{

float sunVisibility;
float sunraysVisibility;
float rayVisibility;
float rayVisibility2;
float rayVisibility3;

}VisibilityFactor;

struct materialStruct{

bool landMaterial;
bool handMaterial;

}Material;

const vec2 offset1[60] = vec2[60] (
vec2(  0.1000,  0.0000 ),
vec2(  0.0500,  0.0866 ),
vec2( -0.0500,  0.0866 ),
vec2( -0.1000,  0.0000 ),
vec2( -0.0500, -0.0866 ),
vec2(  0.0500, -0.0866 ),
vec2(  0.2000,  0.0000 ),
vec2(  0.1000,  0.1732 ),
vec2( -0.1000,  0.1732 ),
vec2( -0.2000,  0.0000 ),
vec2( -0.1000, -0.1732 ),
vec2(  0.1000, -0.1732 ),
vec2(  0.3000,  0.0000 ),
vec2(  0.1500,  0.2598 ),
vec2( -0.1500,  0.2598 ),
vec2( -0.3000,  0.0000 ),
vec2( -0.1500, -0.2598 ),
vec2(  0.1500, -0.2598 ),
vec2(  0.4000,  0.0000 ),
vec2(  0.2000,  0.3464 ),
vec2( -0.2000,  0.3464 ),
vec2( -0.4000,  0.0000 ),
vec2( -0.2000, -0.3464 ),
vec2(  0.2000, -0.3464 ),
vec2(  0.5000,  0.0000 ),
vec2(  0.2500,  0.4330 ),
vec2( -0.2500,  0.4330 ),
vec2( -0.5000,  0.0000 ),
vec2( -0.2500, -0.4330 ),
vec2(  0.2500, -0.4330 ),
vec2(  0.6000,  0.0000 ),
vec2(  0.3000,  0.5196 ),
vec2( -0.3000,  0.5196 ),
vec2( -0.6000,  0.0000 ),
vec2( -0.3000, -0.5196 ),
vec2(  0.3000, -0.5196 ),
vec2(  0.7000,  0.0000 ),
vec2(  0.3500,  0.6062 ),
vec2( -0.3500,  0.6062 ),
vec2( -0.7000,  0.0000 ),
vec2( -0.3500, -0.6062 ),
vec2(  0.3500, -0.6062 ),
vec2(  0.8000,  0.0000 ),
vec2(  0.4000,  0.6928 ),
vec2( -0.4000,  0.6928 ),
vec2( -0.8000,  0.0000 ),
vec2( -0.4000, -0.6928 ),
vec2(  0.4000, -0.6928 ),
vec2(  0.9000,  0.0000 ),
vec2(  0.4500,  0.7794 ),
vec2( -0.4500,  0.7794 ),
vec2( -0.9000,  0.0000 ),
vec2( -0.4500, -0.7794 ),
vec2(  0.4500, -0.7794 ),
vec2(  1.0000,  0.0000 ),
vec2(  0.5000,  0.8660 ),
vec2( -0.5000,  0.8660 ),
vec2( -1.0000,  0.0000 ),
vec2( -0.5000, -0.8660 ),
vec2(  0.5000, -0.8660 ));
		
const vec2 offset2[60] = vec2[60]  (
vec2(  0.0000,  0.2500 ),
vec2( -0.2165,  0.1250 ),
vec2( -0.2165, -0.1250 ),
vec2( -0.0000, -0.2500 ),
vec2(  0.2165, -0.1250 ),
vec2(  0.2165,  0.1250 ),
vec2(  0.0000,  0.5000 ),
vec2( -0.2500,  0.4330 ),
vec2( -0.4330,  0.2500 ),
vec2( -0.5000,  0.0000 ),
vec2( -0.4330, -0.2500 ),
vec2( -0.2500, -0.4330 ),
vec2( -0.0000, -0.5000 ),
vec2(  0.2500, -0.4330 ),
vec2(  0.4330, -0.2500 ),
vec2(  0.5000, -0.0000 ),
vec2(  0.4330,  0.2500 ),
vec2(  0.2500,  0.4330 ),
vec2(  0.0000,  0.7500 ),
vec2( -0.2565,  0.7048 ),
vec2( -0.4821,  0.5745 ),
vec2( -0.6495,  0.3750 ),
vec2( -0.7386,  0.1302 ),
vec2( -0.7386, -0.1302 ),
vec2( -0.6495, -0.3750 ),
vec2( -0.4821, -0.5745 ),
vec2( -0.2565, -0.7048 ),
vec2( -0.0000, -0.7500 ),
vec2(  0.2565, -0.7048 ),
vec2(  0.4821, -0.5745 ),
vec2(  0.6495, -0.3750 ),
vec2(  0.7386, -0.1302 ),
vec2(  0.7386,  0.1302 ),
vec2(  0.6495,  0.3750 ),
vec2(  0.4821,  0.5745 ),
vec2(  0.2565,  0.7048 ),
vec2(  0.0000,  1.0000 ),
vec2( -0.2588,  0.9659 ),
vec2( -0.5000,  0.8660 ),
vec2( -0.7071,  0.7071 ),
vec2( -0.8660,  0.5000 ),
vec2( -0.9659,  0.2588 ),
vec2( -1.0000,  0.0000 ),
vec2( -0.9659, -0.2588 ),
vec2( -0.8660, -0.5000 ),
vec2( -0.7071, -0.7071 ),
vec2( -0.5000, -0.8660 ),
vec2( -0.2588, -0.9659 ),
vec2( -0.0000, -1.0000 ),
vec2(  0.2588, -0.9659 ),
vec2(  0.5000, -0.8660 ),
vec2(  0.7071, -0.7071 ),
vec2(  0.8660, -0.5000 ),
vec2(  0.9659, -0.2588 ),
vec2(  1.0000, -0.0000 ),
vec2(  0.9659,  0.2588 ),
vec2(  0.8660,  0.5000 ),
vec2(  0.7071,  0.7071 ),
vec2(  0.5000,  0.8660 ),
vec2(  0.2588,  0.9659 ));

const vec2 offset3[60] = vec2[60](
vec2(  0.2165,  0.1250 ),
vec2(  0.0000,  0.2500 ),
vec2( -0.2165,  0.1250 ),
vec2( -0.2165, -0.1250 ),
vec2( -0.0000, -0.2500 ),
vec2(  0.2165, -0.1250 ),
vec2(  0.4330,  0.2500 ),
vec2(  0.0000,  0.5000 ),
vec2( -0.4330,  0.2500 ),
vec2( -0.4330, -0.2500 ),
vec2( -0.0000, -0.5000 ),
vec2(  0.4330, -0.2500 ),
vec2(  0.6495,  0.3750 ),
vec2(  0.0000,  0.7500 ),
vec2( -0.6495,  0.3750 ),
vec2( -0.6495, -0.3750 ),
vec2( -0.0000, -0.7500 ),
vec2(  0.6495, -0.3750 ),
vec2(  0.8660,  0.5000 ),
vec2(  0.0000,  1.0000 ),
vec2( -0.8660,  0.5000 ),
vec2( -0.8660, -0.5000 ),
vec2( -0.0000, -1.0000 ),
vec2(  0.8660, -0.5000 ),
vec2(  0.2163,  0.3754 ),
vec2( -0.2170,  0.3750 ),
vec2( -0.4333, -0.0004 ),
vec2( -0.2163, -0.3754 ),
vec2(  0.2170, -0.3750 ),
vec2(  0.4333,  0.0004 ),
vec2(  0.4328,  0.5004 ),
vec2( -0.2170,  0.6250 ),
vec2( -0.6498,  0.1246 ),
vec2( -0.4328, -0.5004 ),
vec2(  0.2170, -0.6250 ),
vec2(  0.6498, -0.1246 ),
vec2(  0.6493,  0.6254 ),
vec2( -0.2170,  0.8750 ),
vec2( -0.8663,  0.2496 ),
vec2( -0.6493, -0.6254 ),
vec2(  0.2170, -0.8750 ),
vec2(  0.8663, -0.2496 ),
vec2(  0.2160,  0.6259 ),
vec2( -0.4340,  0.5000 ),
vec2( -0.6500, -0.1259 ),
vec2( -0.2160, -0.6259 ),
vec2(  0.4340, -0.5000 ),
vec2(  0.6500,  0.1259 ),
vec2(  0.4325,  0.7509 ),
vec2( -0.4340,  0.7500 ),
vec2( -0.8665, -0.0009 ),
vec2( -0.4325, -0.7509 ),
vec2(  0.4340, -0.7500 ),
vec2(  0.8665,  0.0009 ),
vec2(  0.2158,  0.8763 ),
vec2( -0.6510,  0.6250 ),
vec2( -0.8668, -0.2513 ),
vec2( -0.2158, -0.8763 ),
vec2(  0.6510, -0.6250 ),
vec2(  0.8668,  0.2513 ));

vec3 nvec3(in vec4 pos) {
	return pos.xyz/pos.w;
}

float length3(in vec3 v) {
	return sqrt(dot(v,v));
}

vec4 getFragPosition(in vec4 currentPosition) {
vec4 fragPosition = gbufferProjectionInverse * currentPosition;
fragPosition /= fragPosition.w;

if (eyeIsInWater) fragPosition.xy *= gbufferProjection[1][1]*tan(atan(1.0/gbufferProjection[1][1])*0.85);

	return fragPosition;
}

vec4 getCurrentPosition(in vec2 coordinates, in float pixelDepth) {	
	return vec4(coordinates.s * 2.0f - 1.0f, coordinates.t * 2.0f - 1.0f, 2.0f * pixelDepth - 1.0f, 1.0f);
}

vec4 getTPos() {
vec4 tPos = vec4(sunPosition,1.0)*gbufferProjection;
tPos = vec4(nvec3(tPos),1.0);
	return tPos;
}

vec3 finalizeColoredLens(in vec3 lens) {
	return clamp((lens)*0.2,0.0,0.1)*1.0;
}

vec3 grain(inout vec3 color, in float strength) {

float grain1 = texture2D(noisetex,(texCoord*frameTimeCounter)*512).r;
float grain2 = texture2D(noisetex,(texCoord*frameTimeCounter)*256).r;
float grain3 = texture2D(noisetex,(texCoord*frameTimeCounter)*128).r;

float filmGrain = (grain1+grain2+grain3)/3;

return mix(color,vec3(filmGrain),strength);
}

const vec3 lensPattern[8] = vec3[8](
vec3(0.1,0.1,0.02),
vec3(-0.12,0.07,0.02),
vec3(-0.11,-0.13,0.02),
vec3(0.1,-0.1,0.02),

vec3(0.07,0.15,0.02),
vec3(-0.08,0.17,0.02),
vec3(-0.14,-0.07,0.02),
vec3(0.15,-0.19,0.02)

);

vec2 getLightPos(in vec4 tPos, in float distance) {
vec2 lightPos = tPos.st/tPos.z*distance;
lightPos = (lightPos + 1.0f)/2.0f;	
	return lightPos;
}

const vec2 coords2[10] = vec2[10](
vec2(0.14,0.78),
vec2(0.37,0.42),
1-vec2(0.31,0.76),

vec2(0.07,0.26),
vec2(0.78,0.89),
vec2(0.48,0.75),

vec2(0.9,0.64),
vec2(0.3,0.1),
vec2(0.97,0.3),
vec2(0.6,0.1));

const vec2 coords[10] = vec2[10](

vec2(0.5),
1-vec2(0.15),
1-vec2(0.05,0.5),

vec2(0.15),
vec2(0.05,0.75),
vec2(0.75,0.05),

1-vec2(0.75,0.05),
vec2(0.6,0.8),
1-vec2(0.3,0.8),
vec2(0.0));

float distanceRatio(in vec2 pos, in vec2 pos2) {
float xvect = pos.x*aspectRatio-pos2.x*aspectRatio;
float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}

float finalizeLens(in float lens) {
	return clamp((lens)*0.2,0.0,0.1)*1.0;
}

float yDistAxis(in float degrees, in vec2 lightPos) {
		return abs((lightPos.y-lightPos.x*(degrees))-(texCoord.y-texCoord.x*(degrees)));
}

float generateHexagonLens(in vec2 center, in float size) {

size *= 1000;
size *= (viewHeight/1.0 + viewWidth/1.0) / 3000.0;

vec2 texel = vec2(pw,ph);
vec2 v = (center / texel) - (texCoord / texel);
   
vec2 topBottomEdge = vec2(0,1);
vec2 leftEdges = vec2(cos(30*3.14159 / 180), sin(30*3.14159 / 180));
vec2 rightEdges = vec2(cos(30*3.14159 / 180), sin(30*3.14159 / 180));

float dot1 = dot(abs(v), topBottomEdge);
float dot2 = dot(abs(v), leftEdges);
float dot3 = dot(abs(v), rightEdges);

float dotMax = max(max((dot1), (dot2)), (dot3));
  
	return pow(max(0.0, mix(0.0, mix(1.0, 1.0, floor(size - dotMax*1.1 + 0.99 )), floor(size - dotMax + 0.99 ))),3.0)*0.0002;
}

float generateFlatLens(in vec2 lightPos, in float size, in float angle) {
	return pow(max(1.0 - yDistAxis(angle,lightPos),0.1),size);
}

float drawCircle(in positionStruct Position, in vec3 vector, in float size) {
	return pow(max(dot(normalize(Position.fragPosition.xyz),vector),0.0),size);
}

float generateSolidCircularLens(in vec2 center, in float size) {
	return 1-pow(min(distanceRatio(texCoord,center),size)/size,3.0);
}

float getTruePos(in vec4 tPos) {
	return pow(clamp(dot(-lightVector*timeTransition,tPos.xyz)/length3(tPos.xyz),0.0,1.0),0.25);	
}

bool isMaterial(in float aux, in float value, in float value2) {
	return (aux < value2 && aux > value)? true:false;
}

void getLensFlare(inout vec3 color, in visibilityFactorStruct Visibility, in positionStruct Position, in materialStruct Material) {

vec3 purple = vec3(0.58,0.10,0.76);
vec3 lightBlue = vec3(0.0,0.56,0.97);

float flatline = generateFlatLens(Position.lightPos,100.0,0)*Position.truePos*VisibilityFactor.sunVisibility;

float hexagon = generateHexagonLens(getLightPos(Position.tPos,-1),0.05)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon2 = generateHexagonLens(getLightPos(Position.tPos,-0.3),0.1)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon3 = generateHexagonLens(getLightPos(Position.tPos,-2.5),0.2)*Position.truePos*VisibilityFactor.sunVisibility;

float hexagon4 = generateHexagonLens(getLightPos(Position.tPos,0.6),0.3)*Position.truePos*VisibilityFactor.sunVisibility;
float fillHexagon4 = generateHexagonLens(getLightPos(Position.tPos,0.6),0.29)*Position.truePos*VisibilityFactor.sunVisibility;

float hexagon8 = generateHexagonLens(getLightPos(Position.tPos,-2),0.02)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon6 = generateHexagonLens(getLightPos(Position.tPos,-2.6),0.03)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon7 = generateHexagonLens(getLightPos(Position.tPos,-3.6),0.05)*Position.truePos*VisibilityFactor.sunVisibility;

float hexagon9 = generateHexagonLens(getLightPos(Position.tPos,2),0.02)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon10 = generateHexagonLens(getLightPos(Position.tPos,2.6),0.03)*Position.truePos*VisibilityFactor.sunVisibility;
float hexagon11 = generateHexagonLens(getLightPos(Position.tPos,3.6),0.05)*Position.truePos*VisibilityFactor.sunVisibility;

float circle = generateSolidCircularLens(getLightPos(Position.tPos,0.5),0.1)*Position.truePos*VisibilityFactor.sunVisibility;

float circle6 = generateSolidCircularLens(getLightPos(Position.tPos,-6),0.1)*Position.truePos*VisibilityFactor.sunVisibility;
float fillCircle6 = generateSolidCircularLens(getLightPos(Position.tPos,-6),0.09)*Position.truePos*VisibilityFactor.sunVisibility;

float circle3 = generateSolidCircularLens(getLightPos(Position.tPos,-6),0.2)*Position.truePos*VisibilityFactor.sunVisibility;
float fillCircle3 = generateSolidCircularLens(getLightPos(Position.tPos,-6),0.19)*Position.truePos*VisibilityFactor.sunVisibility;

float circle7 = generateSolidCircularLens(getLightPos(Position.tPos,-3),0.2)*Position.truePos*VisibilityFactor.sunVisibility;
float fillCircle7 = generateSolidCircularLens(getLightPos(Position.tPos,-3),0.19)*Position.truePos*VisibilityFactor.sunVisibility;

float circle4 = generateSolidCircularLens(getLightPos(Position.tPos,-4),0.015)*Position.truePos*VisibilityFactor.sunVisibility;
float circle5 = generateSolidCircularLens(getLightPos(Position.tPos,-4.6),0.03)*Position.truePos*VisibilityFactor.sunVisibility;
float circle2 = generateSolidCircularLens(getLightPos(Position.tPos,-5.6),0.05)*Position.truePos*VisibilityFactor.sunVisibility;

float circle8 = generateSolidCircularLens(getLightPos(Position.tPos,4),0.015)*Position.truePos*VisibilityFactor.sunVisibility;
float circle9 = generateSolidCircularLens(getLightPos(Position.tPos,4.6),0.03)*Position.truePos*VisibilityFactor.sunVisibility;
float circle10 = generateSolidCircularLens(getLightPos(Position.tPos,5.6),0.05)*Position.truePos*VisibilityFactor.sunVisibility;

float disk = generateSolidCircularLens(getLightPos(Position.tPos,-3),0.11)*Position.truePos*VisibilityFactor.sunVisibility;
float fillDisk = generateSolidCircularLens(getLightPos(Position.tPos,-2.5),0.1)*Position.truePos*VisibilityFactor.sunVisibility;

float disk2 = generateSolidCircularLens(getLightPos(Position.tPos,-5),0.15)*Position.truePos*VisibilityFactor.sunVisibility;
float fillDisk2 = generateSolidCircularLens(getLightPos(Position.tPos,-4.9),0.14)*Position.truePos*VisibilityFactor.sunVisibility;

float disk3 = generateSolidCircularLens(getLightPos(Position.tPos,-2),0.16)*Position.truePos*VisibilityFactor.sunVisibility;
float fillDisk3 = generateSolidCircularLens(getLightPos(Position.tPos,-1.9),0.15)*Position.truePos*VisibilityFactor.sunVisibility;

float disk4 = generateSolidCircularLens(getLightPos(Position.tPos,-4),0.09)*Position.truePos*VisibilityFactor.sunVisibility;
float fillDisk4 = generateSolidCircularLens(getLightPos(Position.tPos,-3.9),0.08)*Position.truePos*VisibilityFactor.sunVisibility;

float disk5 = generateSolidCircularLens(getLightPos(Position.tPos,-1),0.13)*Position.truePos*VisibilityFactor.sunVisibility;
float fillDisk5 = generateSolidCircularLens(getLightPos(Position.tPos,-0.9),0.12)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow = generateSolidCircularLens(Position.lightPos,0.15)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow = generateSolidCircularLens(Position.lightPos,0.14)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow2 = generateSolidCircularLens(Position.lightPos,0.2)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow2 = generateSolidCircularLens(Position.lightPos,0.19)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow3 = generateSolidCircularLens(Position.lightPos,0.25)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow3 = generateSolidCircularLens(Position.lightPos,0.24)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow4 = generateHexagonLens(Position.lightPos,0.15)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow4 = generateHexagonLens(Position.lightPos,0.14)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow5 = generateHexagonLens(Position.lightPos,0.2)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow5 = generateHexagonLens(Position.lightPos,0.19)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow6 = generateHexagonLens(Position.lightPos,0.25)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow6 = generateHexagonLens(Position.lightPos,0.24)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow7 = generateHexagonLens(getLightPos(Position.tPos,-5),0.1)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow7 = generateHexagonLens(getLightPos(Position.tPos,-5),0.09)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow8 = generateHexagonLens(getLightPos(Position.tPos,-6),0.15)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow8 = generateHexagonLens(getLightPos(Position.tPos,-6),0.14)*Position.truePos*VisibilityFactor.sunVisibility;

float rainbow9 = generateHexagonLens(getLightPos(Position.tPos,-7),0.2)*Position.truePos*VisibilityFactor.sunVisibility;
float fillRainbow9 = generateHexagonLens(getLightPos(Position.tPos,-7),0.19)*Position.truePos*VisibilityFactor.sunVisibility;

float ray3 = generateFlatLens(Position.lightPos,100.0,1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility3;
float ray2 = generateFlatLens(Position.lightPos,100.0,1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility2*(1 - ray3);
float ray1 = generateFlatLens(Position.lightPos,100.0,1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility*(1 - ray3)*(1 - ray2);

vec3 rays = vec3(ray1,ray2,ray3);

float ray6 = generateFlatLens(Position.lightPos,100.0,-1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility3*(1 - float(rays));
float ray5 = generateFlatLens(Position.lightPos,100.0,-1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility2*(1 - ray6)*(1 - float(rays));
float ray4 = generateFlatLens(Position.lightPos,100.0,-1.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility*(1 - ray6)*(1 - ray5)*(1 - float(rays));

vec3 rays2 = vec3(ray4,ray5,ray6);

float ray9 = generateFlatLens(Position.lightPos,100.0,3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility3*(1 - float(rays2));
float ray8 = generateFlatLens(Position.lightPos,100.0,3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility2*(1 - ray9)*(1 - float(rays2));
float ray7 = generateFlatLens(Position.lightPos,100.0,3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility*(1 - ray9)*(1 - ray8)*(1 - float(rays2));

vec3 rays3 = vec3(ray7,ray8,ray9);

float ray12 = generateFlatLens(Position.lightPos,100.0,-3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility3*(1 - float(rays3));
float ray11 = generateFlatLens(Position.lightPos,100.0,-3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility2*(1 - ray12)*(1 - float(rays3));
float ray10 = generateFlatLens(Position.lightPos,100.0,-3.5)*Position.truePos*VisibilityFactor.sunVisibility*VisibilityFactor.rayVisibility*(1 - ray12)*(1 - ray11)*(1 - float(rays3));

vec3 rays4 = vec3(ray10,ray11,ray12);

vec3 lens = vec3(0.0);

lens += finalizeLens(hexagon)*purple*2;
lens += finalizeLens(hexagon2)*purple;
lens += finalizeLens(hexagon3)*purple;

lens += finalizeLens(hexagon4-fillHexagon4)*purple;

lens += finalizeLens(hexagon6)*lightBlue;
lens += finalizeLens(hexagon7)*lightBlue;
lens += finalizeLens(hexagon8)*lightBlue;

lens += finalizeLens(hexagon9)*lightBlue;
lens += finalizeLens(hexagon10)*lightBlue;
lens += finalizeLens(hexagon11)*lightBlue;

lens += finalizeLens(circle8)*purple*2;
lens += finalizeLens(circle9)*purple*2;
lens += finalizeLens(circle10)*purple*2;

lens += finalizeLens(circle)*purple*2;
lens += finalizeLens(circle2)*purple*2;
lens += finalizeLens(circle4)*purple*2;
lens += finalizeLens(circle5)*purple*2;
lens += finalizeLens(circle3-fillCircle3)*purple*2;

lens.b += finalizeLens(circle6-fillCircle6)*4;
lens.b += finalizeLens(circle7-fillCircle7)*4;

lens += finalizeLens(flatline)*purple*2;

lens += finalizeColoredLens(rays)*2;
lens += finalizeColoredLens(rays2)*2;
lens += finalizeColoredLens(rays3)*2;
lens += finalizeColoredLens(rays4)*2;

lens.b += finalizeLens(disk-fillDisk)*4;
lens.b += finalizeLens(disk2-fillDisk2)*4;
lens.b += finalizeLens(disk3-fillDisk3)*4;
lens.b += finalizeLens(disk4-fillDisk4)*4;
lens.b += finalizeLens(disk5-fillDisk5)*4;

lens.r += finalizeLens(rainbow-fillRainbow)* float(Material.landMaterial? 2:1);
lens.g += (finalizeLens(rainbow2-fillRainbow2)*(1 - rainbow)) * float(Material.landMaterial? 2:1);
lens.b += (finalizeLens(rainbow3-fillRainbow3)*(1 - rainbow2))*2;

lens.r += finalizeLens(rainbow4-fillRainbow4)*0.1* float(Material.landMaterial? 2:1);
lens.g += finalizeLens(rainbow5-fillRainbow5)*0.1* float(Material.landMaterial? 2:1);
lens.b += finalizeLens(rainbow6-fillRainbow6)*0.2* float(Material.landMaterial? 3:1);

lens.r += finalizeLens(rainbow7-fillRainbow7)*0.1* float(Material.landMaterial? 10:1);
lens.g += finalizeLens(rainbow8-fillRainbow8)*0.1* float(Material.landMaterial? 10:1);
lens.b += finalizeLens(rainbow9-fillRainbow9)*0.2* float(Material.landMaterial? 20:1);

color = mix(color,vec3(1),clamp((lens*lensFlareStrength)*(1-(0.8*timeMidnight)*timeTransition),0.0,1.0));
}

void getDirtyLens(inout vec3 color, in vec3 brightObjects) {

float lensCoord1 = texture2D(noisetex,texCoord*8).x/3;
float lensCoord2 = texture2D(noisetex,texCoord/2).x*2;

float dirtyLens = lensCoord2+lensCoord1;

dirtyLens += texture2D(noisetex,texCoord).x/2;
dirtyLens += texture2D(noisetex,texCoord*2).x/4;
dirtyLens += texture2D(noisetex,texCoord*4).x/8;
dirtyLens += texture2D(noisetex,texCoord).x/2;
dirtyLens += texture2D(noisetex,texCoord*2).x/4;
dirtyLens += texture2D(noisetex,texCoord*4).x/8;

dirtyLens -= 1.55;
dirtyLens = 1-dirtyLens;

float circularLens = 0.0;
float hexagonLens = 0.0;

for (int i = 0; i < 8; i++) {
vec3 lensPos = lensPattern[i]*1.128;
lensPos.z *= 1.125/1.25+(i*0.05);
lensPos.t /= aspectRatio;

vec2 coord = lensPos.st + coords[0];
vec2 coord2 = lensPos.st + coords2[0];

vec2 offsetCoord0 = lensPos.st + coords[1];
vec2 offsetCoord1 = lensPos.st + coords[2];
vec2 offsetCoord2 = lensPos.st + coords[3];
vec2 offsetCoord3 = lensPos.st + coords[4];
vec2 offsetCoord4 = lensPos.st + coords[5];
vec2 offsetCoord5 = lensPos.st + coords[6];
vec2 offsetCoord6 = lensPos.st + coords[7];
vec2 offsetCoord7 = lensPos.st + coords[8];
vec2 offsetCoord8 = lensPos.st + coords[9];

vec2 offsetCoord9 = lensPos.st + coords2[1];
vec2 offsetCoord10 = lensPos.st + coords2[2];
vec2 offsetCoord11 = lensPos.st + coords2[3];
vec2 offsetCoord12 = lensPos.st + coords2[4];
vec2 offsetCoord13 = lensPos.st + coords2[5];
vec2 offsetCoord14 = lensPos.st + coords2[6];
vec2 offsetCoord15 = lensPos.st + coords2[7];
vec2 offsetCoord16 = lensPos.st + coords2[8];
vec2 offsetCoord17 = lensPos.st + coords2[9];

circularLens += generateSolidCircularLens(coord,lensPos.z*2.47);
circularLens += generateSolidCircularLens(offsetCoord0,lensPos.z*2.84);
circularLens += generateSolidCircularLens(offsetCoord1,lensPos.z*2.24);
circularLens += generateSolidCircularLens(offsetCoord2,lensPos.z*2.45);
circularLens += generateSolidCircularLens(offsetCoord3,lensPos.z*2.76);
circularLens += generateSolidCircularLens(offsetCoord4,lensPos.z*2.23);
circularLens += generateSolidCircularLens(offsetCoord5,lensPos.z*2.53);
circularLens += generateSolidCircularLens(offsetCoord6,lensPos.z*2.86);
circularLens += generateSolidCircularLens(offsetCoord7,lensPos.z*2.97);

hexagonLens += generateHexagonLens(coord2,lensPos.z*2.47);
hexagonLens += generateHexagonLens(offsetCoord9,lensPos.z*2.84);
hexagonLens += generateHexagonLens(offsetCoord10,lensPos.z*2.24);
hexagonLens += generateHexagonLens(offsetCoord11,lensPos.z*2.75);
hexagonLens += generateHexagonLens(offsetCoord12,lensPos.z*2.45);
hexagonLens += generateHexagonLens(offsetCoord13,lensPos.z*2.76);
hexagonLens += generateHexagonLens(offsetCoord14,lensPos.z*2.23);
hexagonLens += generateHexagonLens(offsetCoord15,lensPos.z*2.53);
hexagonLens += generateHexagonLens(offsetCoord16,lensPos.z*2.86);
hexagonLens += generateHexagonLens(offsetCoord17,lensPos.z*2.97);

}

float dirtyLensFinal = finalizeLens(dirtyLens);
float circularLensFinal = finalizeLens(circularLens);
float hexagonalLensFinal = finalizeLens(hexagonLens);

float mixedDirtyLens = 0;

if (dirt) mixedDirtyLens += dirtyLensFinal;
if (circles) mixedDirtyLens += circularLensFinal;
if (hexagons) mixedDirtyLens += hexagonalLensFinal;

mixedDirtyLens *= 5;

if (eyeIsInWater) color += mixedDirtyLens/10;

mixedDirtyLens *= dirtyLensStrength;

color = mix(color,vec3(1),(mixedDirtyLens*clamp((brightObjects-0.05)*4,0.0,1.0)));
}

void essentials(inout vec3 color, in materialStruct Material, inout vec3 brightObjects) {
vec3 blur = vec3(0.0);
vec3 blur2 = vec3(0.0);
vec3 blur3 = vec3(0.0);

vec2 lensCoord = normalize(texCoord - vec2(0.5));

vec2 lensMovement = vec2(0.0,fract(frameTimeCounter/1000));
lensMovement += vec2(0.5);

float rayCoord = texture2D(noisetex,(lensCoord+(lensMovement*15))*1.5).x;

for (int i = 0; i < essentialsQuality; ++i) {
blur += texture2DLod(colortex1,texCoord+(offset2[i]*vec2(1.0,aspectRatio))*0.01,2).r;
blur += texture2DLod(colortex5,texCoord+(offset2[i]*vec2(1.0,aspectRatio))*0.01,2).a*int(!Material.landMaterial);
blur2 += texture2DLod(colortex3,texCoord+(offset2[i]*vec2(1.0,aspectRatio))*0.01,2).rgb*rayCoord;
blur3 += texture2DLod(colortex5,texCoord-(offset2[i]*vec2(1.0,aspectRatio))*0.05,5).rgb;

}

blur /= essentialsQuality;
blur2 /= essentialsQuality;
blur3 /= essentialsQuality;

blur *= 1+(vec3(1.0,0.4,0.1) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));
blur *= 1-(vec3(0.0,0.6,0.9) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));

blur *= 1+(vec3(0.0,0.3,0.9)*timeMidnight*timeTransition);
blur *= 1-(0.75*timeMidnight*timeTransition);

color = mix(color,vec3(1),blur2);

vec3 blurFinal = mix(color,(blur+blur3)*40,0.1);

color += pow(blurFinal,vec3(2.2));
color /= 1+pow(blurFinal,vec3(2.2));

brightObjects = blur3;
}

void getDoF(inout vec3 color, in float pixelDepth, in materialStruct Material, in float nearsightedDistance) {
float focusPoint = smoothDoF? centerDepthSmooth:texture2D(depthtex1,vec2(0.5)).r;

float focus = clamp((pixelDepth - focusPoint)/20,0.0,0.005);

float lod = variableLod? focus*(100*variableLodStrength):0.0;
focus = nearsighted? focus+(nearsightedDistance*(1 - focus)):focus;

if (!Material.handMaterial) {
for (int i = 0; i < depthOfFieldQuality; ++i) {

vec2 offset = vec2(0.0);
offset = (depthOfFieldShape == 1.0)? offset1[i]:offset;
offset = (depthOfFieldShape == 2.0)? offset2[i]:offset;
offset = (depthOfFieldShape == 3.0)? offset3[i]:offset;
offset *= vec2(1.0,aspectRatio);
offset *= depthOfFieldStrength;

color.r += texture2DLod(colortex0,texCoord+(offset+vec2(0.3,0.0))*focus,lod).r;
color.g += texture2DLod(colortex0,texCoord+offset*focus,lod).g;
color.b += texture2DLod(colortex0,texCoord+(offset-vec2(0.3,0.0))*focus,lod).b;

}
color /= depthOfFieldQuality+1;
}

}

void main() {

vec3 aux = texture2D(colortex4,texCoord).rgb;
vec3 color = texture2D(colortex0,texCoord).rgb;
vec3 brightObjects = vec3(0.0);

float pixelDepth = texture2D(depthtex1,texCoord).r;

Position.tPos = getTPos();
Position.lightPos = getLightPos(Position.tPos,1.0);
Position.truePos = getTruePos(Position.tPos);
Position.currentPosition = getCurrentPosition(texCoord,pixelDepth);
Position.fragPosition = getFragPosition(Position.currentPosition);

float depth = length3(Position.fragPosition.xyz);

float nearsightedDistance = (1-clamp(1*(1-(depth*0.1*nearsightedIntensity)),0.0,1.0))*0.001;

VisibilityFactor.sunVisibility = step(texture2D(colortex4,Position.lightPos).r,0.0);
VisibilityFactor.rayVisibility = drawCircle(Position,lightVector,1);
VisibilityFactor.rayVisibility2 = drawCircle(Position,lightVector,5);
VisibilityFactor.rayVisibility3 = drawCircle(Position,lightVector,10);

Material.landMaterial = bool(aux.g);
Material.handMaterial = isMaterial(aux.g,0.29,0.31);

if (depthOfField) getDoF(color,pixelDepth,Material,nearsightedDistance);
essentials(color,Material,brightObjects);
if (lensFlare) getLensFlare(color,VisibilityFactor,Position,Material);
if (dirtyLens) getDirtyLens(color,brightObjects);

gl_FragData[0] = vec4(filmGrain? grain(color,0.01):color,1.0);
}