#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:0135 */

/*
veryLowRes	= 512;
lowRes			= 1024
lowMidRes		= 1536
midRes			= 2048
midHighRes	= 2560
highRes		= 3072
highUltraRes	= 3840
ultraRes 		= 4096
*/

const int RGBA8 								= 0;
const int RGBA16 								= 0;
const int RGB8 									= 0;
const int RGB16 								= 0;
const int RG8 									= 0;
const int RG16 									= 0;
const int R8 										= 0;
const int R16 									= 0;

const int colortex0Format 					= RGB8;
const int colortex1Format 					= RGB8;
const int colortex2Format 					= RGB8;
const int colortex3Format 					= RGB8;
const int colortex4Format 					= RGB8;
const int colortex5Format 					= RGBA8;
const int colortex6Format 					= R8;
const int colortex7Format 					= R8;

const int noiseTextureResolution 		= 56;
const int shadowMapResolution 			= 1;
const int ditherPatternRes					= 8;

const float ssaoQuality						= 32.0;
const float ssaoSpread						= 0.015;
const float grRayDistance					= 1.0;
const float vlRayDistance					= 30.0;
const float shadowFilter2Quality			= 60.0;
const float cloudLayerDepth				= 1.0;
const float cloudDetail						= 1.0;

const float godraysStrength				= 1.0;
const float volumetricLightStrength		= 1.0;
const float volumetricCausticsStrength = 1.0;
const float waterCausticStrength			= 1.0;
const float vignetteStrength					= 0.6;
const float shadowFilter1Strength		= 0.00045;
const float shadowFilter2Strength		= 0.00035;
const float vpsStrength						= 1.0;
const float vpsPower							= 25.0;

float colorVibrance								= 1.6;
float colorContrast								= 0.98;

const float renderQuality						= 1.0;
const float sunPathRotation 				= -40.0;
const float lightSensitivity					= 6.2;
const float fakeShadowDarkness			= 0.8;

const float shadowDistance 		    	= 1;
const float shadowMapBias 				= 0.9;
const float shadowTransparency			= 0.8;

const bool shadowtex0Mipmap 			= true;
const bool shadowtex0Nearest 			= false;
const bool shadowHardwareFiltering0	= false;	
const bool shadowHardwareFiltering1	= true;

const bool lowEndGPUFix					= false;
const bool hexagonGrid						= false;

const bool twoDimensionalCloudPlane	= true;
const bool cloudRayBounce				= false;

const bool godrays							= false;
const bool srGodrays							= false;
const bool volumetricClouds				= false;
const bool volumetricWaterCaustics	= true;
const bool waterCaustics 					= true;
const bool volumetricLight					= false;
const bool sunReflection					= false;
const bool dynamicExposure				= true;

const bool ssao									= true;
const bool whiteWorld						= false;

const bool shadows							= false;
const bool shadowFilter1					= false;
const bool shadowFilter2					= false;
const bool vpsHQ								= true;
const bool vps									= true;

const bool waterFog							= true;
const bool underWaterFog					= true;
const bool fog									= true;

const bool timedColors						= false;
const bool vibrantColors						= true;
const bool colorFilter							= true;
const bool contrastedColors				= true;
const bool rainDesaturation				= false;
const bool nightDesaturation				= false;
const bool lowlightDesaturation			= false;

const bool vignette								= true;
const bool celshading						= false;
const bool fakeShadows						= false;

varying vec3 timedColor;
varying vec3 baseColor;
varying vec3 lightColor;
varying vec3 lightVector;

varying vec2 texCoord;

varying float lightValue;
varying float lightJitter;
varying float eyeAdaptation;
varying float timeMidnight;
varying float timeSunrise;
varying float timeSunset;
varying float timeNoon;
varying float timeTransition;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;

uniform sampler2DShadow shadowtex1;
uniform sampler2DShadow shadowcolor;

uniform float far;
uniform float near;
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform int isEyeInWater;

float pw = 1.0/viewWidth;
float ph = 1.0/viewHeight;
bool eyeIsInWater = bool(isEyeInWater);

struct positionStruct{

vec4 currentPosition;
vec4 wCurrentPosition;
vec4 fragPosition;
vec4 wFragPosition;
vec4 worldPosition;
vec4 wWorldPosition;
vec4 tPos;

vec2 lightPos;

}Position;

struct materialStruct{

bool landMaterial;
bool waterMaterial;
bool translucentMaterials;
bool handMaterial;
bool brightMaterials;

}Material;

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

vec3 offset4[32] = vec3[32](
vec3( -0.134,  0.044, -0.825),
vec3(  0.045, -0.431, -0.529),
vec3( -0.537,  0.195, -0.371),
vec3(  0.525, -0.397,  0.713),
vec3(  0.895,  0.302,  0.139),
vec3( -0.613, -0.408, -0.141),
vec3(  0.307,  0.822,  0.169),
vec3( -0.819,  0.037, -0.388),
vec3(  0.376,  0.009,  0.193),
vec3( -0.006, -0.103, -0.035),
vec3(  0.098,  0.393,  0.019),
vec3(  0.542, -0.218, -0.593),
vec3(  0.526, -0.183,  0.424),
vec3( -0.529, -0.178,  0.684),
vec3(  0.066, -0.657, -0.570),
vec3( -0.214,  0.288,  0.188),
vec3( -0.689, -0.222, -0.192),
vec3( -0.008, -0.212, -0.721),
vec3(  0.053, -0.863,  0.054),
vec3(  0.639, -0.558,  0.289),
vec3( -0.255,  0.958,  0.099),
vec3( -0.488,  0.473, -0.381),
vec3( -0.592, -0.332,  0.137),
vec3(  0.080,  0.756, -0.494),
vec3( -0.638,  0.319,  0.686),
vec3( -0.663,  0.230, -0.634),
vec3(  0.235, -0.547,  0.664),
vec3(  0.164, -0.710,  0.086),
vec3( -0.009,  0.493, -0.038),
vec3( -0.322,  0.147, -0.105),
vec3( -0.554, -0.725,  0.289),
vec3(  0.534,  0.157, -0.250));

vec3 nvec3(in vec4 pos) {
	return pos.xyz/pos.w;
}

float length1(in float v) {
	return sqrt(dot(v,v));
}

float length2(in vec2 v) {
	return sqrt(dot(v,v));
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

vec4 getWorldPosition(in vec4 fragPosition) {
	return gbufferModelViewInverse * fragPosition;
}

vec4 getTPos() {
vec4 tPos = vec4(sunPosition,1.0)*gbufferProjection;
tPos = vec4(nvec3(tPos),1.0);
	return tPos;
}

vec3 saturate(in vec3 color, in float saturation) {
float luma = dot(color,vec3(0.299, 0.587, 0.114));
vec3 chroma = color - luma;

	return (chroma*saturation)+luma;
}

vec3 contrast(in vec3 color, in float contrast) {
float colorLength = length3(color);
vec3 col = color / colorLength;

colorLength = pow(colorLength, contrast);

	return col * colorLength;
}

vec3 finalWorldPosition(in vec4 worldPosition) {
	return vec3(worldPosition.st,worldPosition.z-0.0005);
}

vec3 colorModifier(in vec3 color, in float type, in vec3 value, in float lightVisibility, in float setTime, in bool transition) {
bool multiply = (type == 1.0)? true:false;
bool divide = (type == 2.0)? true:false;
bool subtract = (type == 3.0)? true:false;
bool add = (type == 4.0)? true:false;

if (multiply) return color * (1 - ((value*lightVisibility)* setTime * (transition? timeTransition:1.0)));
if (divide) return color / (1 + ((value*lightVisibility)* setTime * (transition? timeTransition:1.0)));
if (subtract) return color - ((value*lightVisibility)* setTime * (transition? timeTransition:1.0));
if (add) return color + ((value*lightVisibility)* setTime * (transition? timeTransition:1.0));
}

vec3 CCStSS(in vec3 cameraSpace) {
vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
vec3 screenSpace = 0.5 * NDCSpace + 0.5;

    return screenSpace;
}

vec2 getLightPos(in vec4 tPos) {
vec2 lightPos = tPos.st/tPos.z;
lightPos = (lightPos + 1.0f)/2.0f;	
	return lightPos;
}

float generate3DNoise(in vec3 pos, in float frameTime) {
pos.xyz += 0.5f;

vec3 p = floor(pos);
vec3 f = fract(pos);

vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
float xy1 = texture2D(noisetex, coord - vec2(frameTime,0)).x;
float xy2 = texture2D(noisetex, coord2 - vec2(frameTime,0)).x;

return mix(xy1, xy2, f.z);
}

float drawCloud(in vec4 rayWorldPosition, in vec3 dist, in float detail) {

float clouds = 0.0;

float density = 1.0;
float pdensity = 0.4;
float multiplier = 0.7;
float pmultiplier = 0.3;

const float sharpness = 1.5;


vec3 pos = (rayWorldPosition.xyz*detail)+(cameraPosition/dist);

pos.t += pos.t*sharpness;

pos.x -= frameTimeCounter/25;

pos /= twoDimensionalCloudPlane? 1.0:250;

pos += generate3DNoise(pos * pdensity, frameTimeCounter/320)*pmultiplier; pdensity *= 4.0; pmultiplier *= 0.05;
pos += generate3DNoise(pos * pdensity, frameTimeCounter/340)*pmultiplier; pdensity *= 2.1; pmultiplier *= 1.5;
pos += generate3DNoise(pos * pdensity, frameTimeCounter/360)*pmultiplier; pdensity *= 2.4; pmultiplier *= 0.5;
pos += generate3DNoise(pos * pdensity, frameTimeCounter/380)*pmultiplier; pdensity *= 2.9; pmultiplier *= 0.5;
pos += generate3DNoise(pos * pdensity, frameTimeCounter/400)*pmultiplier; pdensity *= 2.1; pmultiplier *= 0.5;
pos += generate3DNoise(pos * pdensity, frameTimeCounter/400)*pmultiplier;

clouds += generate3DNoise(pos * density, frameTimeCounter/320000)*multiplier; density *= 4.0; multiplier *= 0.05;
clouds += generate3DNoise(pos * density, frameTimeCounter/340000)*multiplier; density *= 2.1; multiplier *= 1.5;
clouds += generate3DNoise(pos * density, frameTimeCounter/360000)*multiplier; density *= 2.4; multiplier *= 0.5;
clouds += generate3DNoise(pos * density, frameTimeCounter/380000)*multiplier; density *= 2.9; multiplier *= 0.5;
clouds += generate3DNoise(pos * density, frameTimeCounter/400000)*multiplier; density *= 2.1; multiplier *= 0.5;
clouds += generate3DNoise(pos * density, frameTimeCounter/400000)*multiplier;

clouds = clamp(clouds, 0.0, 1.0);

return clouds;
}

float getDitherPattern(in float x, in float y) {

if (ditherPatternRes == 4)  {
int[16] ditherPattern = int[16](
0,12,3,15,
8,4,11,7,
2,14,1,13,
10,6,9,5);

float positionX = floor(mod((texCoord.s * x) * viewWidth/renderQuality, 4));
float positionY = floor(mod((texCoord.t * y) * viewHeight/renderQuality, 4));

int dither = ditherPattern[int(positionX) + int(positionY)*4];

return float(float(dither)/16);
}

if (ditherPatternRes == 8) {
int[64] ditherPattern = int[64](
0,42,12,60,3,51,15,63,
32,16,44,28,35,19,47,31,
8,56,4,52,11,59,7,55,
40,24,36,20,43,27,39,23,
2,50,14,62,1,49,13,61,
34,18,46,30,33,17,45,29,
10,58,6,54,9,57,5,53,
42,26,38,22,41,25,37,21); 

float positionX = floor(mod((texCoord.s * x) * viewWidth/renderQuality, 8));
float positionY = floor(mod((texCoord.t * y) * viewHeight/renderQuality, 8));

int dither = ditherPattern[int(positionX) + int(positionY)*8];

return float(float(dither)/64);
}
}

float ld(in float depth) {
	return (2.0 * near) / (far + near - depth * (far - near));
}

float getWaterDepth(in positionStruct Position, in vec3 normal) {
vec3 depth = vec3(getFragPosition(getCurrentPosition(texCoord,texture2D(depthtex0,texCoord).r)))-Position.fragPosition.xyz;
	return length3(depth)*abs(dot(normalize(depth),normal));
}

float getNdotL(in vec3 normal) {
	return clamp(dot(normal,lightVector*timeTransition),0,1);
}

float drawReflectedCircle(in positionStruct Position, in vec3 vector, in float roughness, in vec3 normal) {

vec3 viewDirection = normalize(Position.fragPosition.xyz);
vec3 halfAngle = normalize(vector - viewDirection);
float NdotH = dot(normal,halfAngle);

float alpha = roughness*roughness;
float alphaSqr = alpha*alpha;

float pi = 3.14159f;
float denom = NdotH * NdotH *(alphaSqr-1.0) + 1.0f;

return alphaSqr/(pi * denom * denom);
}

float drawCircle(in positionStruct Position, in vec3 vector, in float size) {
	return pow(max(dot(normalize(Position.fragPosition.xyz),vector),0.0),size);
}

float distanceX(in float dist) {
	return (((dist - near) * far) / ((far - near) * dist));
}

float getDepth(in float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

bool isMaterial(in float aux, in float value, in float value2) {
	return (aux < value2 && aux > value)? true:false;
}

void getModifiedWorldPosition(inout vec4 wPos, inout float compareDepth) {

wPos = shadowModelView * wPos;
compareDepth = abs(wPos.z);
wPos = shadowProjection * wPos;
wPos /= wPos.w;

wPos.st /= (1.0- shadowMapBias) + length2(wPos.st) * shadowMapBias;
wPos = wPos * 0.5 + 0.5;
}

void filterShadows(inout vec3 cShading, in positionStruct Position, in float compareDepth) {

float step;

if (shadowFilter1) {
step = shadowFilter1Strength;

cShading += shadow2D(shadowtex1,finalWorldPosition(vec4(Position.worldPosition.st+vec2(step,0),Position.worldPosition.z,1.0))).r;
cShading += shadow2D(shadowtex1,finalWorldPosition(vec4(Position.worldPosition.st+vec2(-step,0),Position.worldPosition.z,1.0))).r;
cShading += shadow2D(shadowtex1,finalWorldPosition(vec4(Position.worldPosition.st+vec2(0,step),Position.worldPosition.z,1.0))).r;
cShading += shadow2D(shadowtex1,finalWorldPosition(vec4(Position.worldPosition.st+vec2(0,-step),Position.worldPosition.z,1.0))).r;
cShading /= 4;
}

if (shadowFilter2) {

step = shadowFilter2Strength;

if (vps) {
float sample = compareDepth - (0.5 + (texture2DLod(shadowtex0, Position.worldPosition.st,6).z) * (256.0 - 0.5));

if (vpsHQ) {
sample = 0.0;
for (int i = 0; i < 60; ++i) sample += compareDepth - (0.5 + (texture2D(shadowtex0, Position.worldPosition.st+(offset2[i]*vec2(1.0,aspectRatio))*0.01).z) * (256.0 - 0.5));
sample /= 60;
}

float vps = (clamp(sample, 0, vpsPower)/vpsPower)*0.01;
step += vps*vpsStrength;
}

for (int i = 0; i < shadowFilter2Quality; i++) cShading += shadow2D(shadowtex1,finalWorldPosition(vec4(Position.worldPosition.st+(offset2[i]*vec2(1.0,aspectRatio))*step,Position.worldPosition.z,1.0))).x;
cShading /= shadowFilter2Quality+1;
}

}

void colorShadows(inout vec3 cShading, in positionStruct Position) {
vec3 coloredShading = shadow2D(shadowcolor,finalWorldPosition(Position.worldPosition)).rgb;
coloredShading *= shadow2D(shadowtex1,finalWorldPosition(Position.worldPosition)).r*1.5;

cShading = mix(cShading,coloredShading,coloredShading);
}

void getDirectSunlight(inout vec3 color, in materialStruct Material, in positionStruct Position, in float NdotL, inout bool wShading, in float shadowFade, in vec3 lightmaps) {

vec3 cShading = vec3(0.0);

float compareDepth = 0.0;
float wCompareDepth = 0.0;

getModifiedWorldPosition(Position.worldPosition,compareDepth);
getModifiedWorldPosition(Position.wWorldPosition,wCompareDepth);

wShading = (shadow2D(shadowtex1,finalWorldPosition(Position.wWorldPosition)).r > 0.1)? false:true;
cShading += shadow2D(shadowtex1,finalWorldPosition(Position.worldPosition)).r;

filterShadows(cShading,Position,compareDepth);
colorShadows(cShading,Position);

cShading *= !Material.translucentMaterials? NdotL:1.0;

cShading *= shadowFade;
cShading *= 1-(0.4*rainStrength);

color *= 1+0.6*(1-shadowFade);

if (Material.landMaterial) color *= cShading+(shadowTransparency+lightmaps*100)*(1+rainStrength), color /= 1+(shadowTransparency+lightmaps*100);
}

void getSSAO(inout float ao, inout vec3 color, in float pixelDepth, in vec3 normal, in positionStruct Position, in materialStruct Material) {

float projection = clamp(distance(CCStSS(Position.fragPosition.xyz).xy,texCoord),10.0*pw,10.0*pw);

for (int i = 1; i < ssaoQuality; i++) {

vec2 sampleCoord = texCoord + (offset4[i].st+offset4[i].yz * (i*ssaoSpread)) * (projection*ssaoSpread*50);

float sample = texture2D(depthtex1,sampleCoord).r;

float angle = pow(min(1.0-dot(normal,normalize(getFragPosition(getCurrentPosition(sampleCoord,sample)).xyz-Position.fragPosition.xyz)),1.0),2.0);
float dist = pow(min(abs(ld(sample)-ld(pixelDepth)),0.015)/0.015,2.0);

ao += min(dist+angle,1.0);

}

if (whiteWorld) color = vec3(1);
ao /= ssaoQuality-1;

ao = !Material.translucentMaterials? ao:1.0;
}

void getHexagonGrid(inout vec3 color, inout vec3 refCol) {
vec2 pos = gl_FragCoord.st/20.0; 
float  r = (1.0 -0.7)*0.5;	
	
pos.x *= 0.57735*2.0;
pos.y += mod(floor(pos.x), 2.0)*0.5;
pos = abs((mod(pos, 1.0) - 0.5));

color = vec3(smoothstep(0.0, r + 0.05, abs(max(pos.x*1.5 + pos.y, pos.y*2.0) - 1.0)));
refCol = color;
}

void getCelshading(inout vec3 color, in float pixelDepth) {
vec2 texOffset = vec2(1.0);

vec2 sampleCoord = texCoord+vec2(-pw,-ph)*texOffset;
vec2 sampleCoord2 = texCoord+vec2(pw,-ph)*texOffset;
vec2 sampleCoord3 = texCoord+vec2(-pw,0.0)*texOffset;
vec2 sampleCoord4 = texCoord+vec2(0.0,ph)*texOffset;
vec2 sampleCoord5 = texCoord+vec2(pw,ph)*texOffset;
vec2 sampleCoord6 = texCoord+vec2(-pw,ph)*texOffset;
vec2 sampleCoord7 = texCoord+vec2(pw,0.0)*texOffset;
vec2 sampleCoord8 = texCoord+vec2(0.0,-ph)*texOffset;

vec4 sample;
vec4 sample2;

sample.x = texture2D(depthtex1,sampleCoord).r;
sample.y = texture2D(depthtex1,sampleCoord2).r;
sample.z = texture2D(depthtex1,sampleCoord3).r;
sample.w = texture2D(depthtex1,sampleCoord4).r;
sample2.x = texture2D(depthtex1,sampleCoord5).r;
sample2.y = texture2D(depthtex1,sampleCoord6).r;
sample2.z = texture2D(depthtex1,sampleCoord7).r;
sample2.w = texture2D(depthtex1,sampleCoord8).r;

vec4 samples = abs((sample+sample2)-vec4(pixelDepth*2))-(1/(far/near)/100);
float celshading = clamp(dot(vec4(step(samples.x,0.0),step(samples.y,0.0),step(samples.z,0.0),step(samples.w,0.0)),vec4(0.25)),0.0,1.0);

color *= celshading;
//color *= 1+celshading;
}

void getVignette(inout vec3 color) {
float len =  length2(texCoord-vec2(0.5));

float xvect = (texCoord.x-0.5)*aspectRatio;
float yvect = (texCoord.y-0.5)*aspectRatio;

float len2 = sqrt(xvect*xvect + yvect*yvect);
float dc = mix(len,len2,0.3);

float t = clamp((dc - 0.95) / (0.15 - 0.95), 0.0, 1.0);

float vignette = t * t * (3.0 - 2.0 * t);
	
color = colorModifier(color,1.0,vec3(vignetteStrength),(1 - vignette),1.0,false);
}

void getGodrays(inout float color, in float ditherPattern, in positionStruct Position, in float sr, in bool wShading, in float vc) {

vec2 deltaPos = vec2(texCoord - Position.lightPos); 
deltaPos *= grRayDistance;

vec2 godraysTexCoord = texCoord - deltaPos * ditherPattern;

float godraysSample = texture2D(colortex4, godraysTexCoord).r;

godraysSample = isMaterial(texture2D(colortex4,godraysTexCoord).g,0.09,0.21)? 0.0:godraysSample;

float godrays = (step(godraysSample+(cloudRayBounce? vc:0.0),0.0)*drawCircle(Position,lightVector,1.2));

if (srGodrays) {
vec2 nLightPos = Position.lightPos;

Position.lightPos.y *= sunAngle;

vec2 refDeltaPos = vec2(texCoord - Position.lightPos);
refDeltaPos *= grRayDistance;

vec2 refGodraysTexCoord = texCoord - refDeltaPos * ditherPattern;

float refGodraysSample = texture2D(colortex4, refGodraysTexCoord).r;

refGodraysSample = isMaterial(texture2D(colortex4,refGodraysTexCoord).g,0.09,0.21)? 0.0:refGodraysSample;

godrays += (step(refGodraysSample,0.0)*drawCircle(Position,normalize(vec3(Position.lightPos,sunPosition.z)),8.0))*step(texture2D(colortex4,nLightPos).r,0.0);
}

godrays *= 0.4;
godrays *= 1+0.4*timeNoon*timeTransition;
godrays *= 1-(0.4*rainStrength);

color = godrays*1-(0.12*timeMidnight)*timeTransition;
color *= godraysStrength;
}

void getVolumetricLight(inout float color, in float ditherPattern, in positionStruct Position, in float pixelDepth) {
float vl = 0.0;

ditherPattern *= vlRayDistance;

float maxRayDist = 35.0;
float minRayDist = 0.01;
		
minRayDist += ditherPattern;

float weight = (maxRayDist / vlRayDistance);

for (minRayDist; minRayDist < maxRayDist;) {

if (getDepth(pixelDepth) < minRayDist) break;

vec4 worldPosition = getWorldPosition(getFragPosition(getCurrentPosition(texCoord,distanceX(minRayDist))));

float compareDepth = 0.0;

getModifiedWorldPosition(worldPosition,compareDepth);

vl += shadow2D(shadowtex1, finalWorldPosition(vec4(worldPosition.st,worldPosition.z+0.001,1.0))).r;

minRayDist += vlRayDistance;
}

vl /= weight;

if (!eyeIsInWater) {
color = mix(color,vl,clamp(vl*((eyeAdaptation*5*(1-timeMidnight*0.1)*timeTransition)+(0.01+(0.24*(timeSunrise+timeSunset)))),0.0,0.5));
color *= volumetricLightStrength;
}

}

void getVolumetricClouds(inout float vc, in float ditherPattern, in positionStruct Position, in materialStruct Material) {
const float strength = 1000.0;
const float lowerLimit = 105;

const vec3 dist = vec3(500,500,500);

vec3 worldPosition = Position.worldPosition.xyz+cameraPosition;

if (worldPosition.y > lowerLimit && !Material.landMaterial) {

float diff = 3.9;
diff *= 1-(0.5*rainStrength);

diff *= cloudLayerDepth;

float detail = 3.0;
detail *= 1+(0.5*rainStrength);

detail *= cloudDetail;

float rayIncrement = far / diff;
ditherPattern *= rayIncrement;

float rayDepth = far - diff;
rayDepth += ditherPattern;

float weight = rayDepth / rayIncrement;

while (rayDepth > 0.0) {

vec4 rayWorldPosition = twoDimensionalCloudPlane? normalize(getWorldPosition(getFragPosition(getCurrentPosition(texCoord,distanceX(rayDepth))))):(getWorldPosition(getFragPosition(getCurrentPosition(texCoord,distanceX(rayDepth)))));

vc += drawCloud(rayWorldPosition,dist,detail);
 
rayDepth -= rayIncrement;
}

vc /= weight;

vc *= strength;
vc -= strength*0.5;

vc = clamp(vc,0.0,1.0);

}

}

void getVolumetricWaterCaustics(inout vec3 color, inout float wc, inout float vw, in float lightVisibility, in float pixelDepth, in float ditherPattern, in positionStruct Position, in materialStruct Material) {

float frameTime = frameTimeCounter / 140;

if (volumetricWaterCaustics && eyeIsInWater) {

float rayDepth = 0.1+ditherPattern;

vec4 worldPosition = normalize(getWorldPosition(getFragPosition(getCurrentPosition(texCoord,distanceX(rayDepth)))));

vec2 waterCausticsCoord = ((worldPosition.xz+cameraPosition.xz)/30)-frameTime;

vw += texture2D(noisetex,waterCausticsCoord*2).r*0.1;
vw += texture2D(noisetex,waterCausticsCoord*8).r*0.05;
vw += texture2D(noisetex,waterCausticsCoord*16).r*0.025;
vw += texture2D(noisetex,waterCausticsCoord*32).r*0.0125;

vw *= volumetricCausticsStrength*45;
vw -= (volumetricCausticsStrength*10)*0.5;
vw = clamp(vw,0.0,0.25);
vw *= lightVisibility;
}

if (waterCaustics && Material.waterMaterial || waterCaustics && eyeIsInWater) {
vec2 waterCausticsCoord = ((Position.worldPosition.xz+cameraPosition.xz)/30)-frameTime;

wc += texture2D(noisetex,waterCausticsCoord*2).r*0.1;
wc += texture2D(noisetex,waterCausticsCoord*8).r*0.05;
wc += texture2D(noisetex,waterCausticsCoord*16).r*0.025;
wc += texture2D(noisetex,waterCausticsCoord*32).r*0.0125;

wc = (!eyeIsInWater)? wc*(2-rainStrength)*(1-0.5*(timeMidnight*timeTransition)*(1 - rainStrength)):wc;
wc *= lightVisibility;

vec3 waterCaustics = mix(color,vec3(wc)*20*waterCausticStrength,0.1);

color += pow(waterCaustics,vec3(2.2));
color /= 1+pow(waterCaustics,vec3(2.2));

}

}

void main() {

vec3 aux = texture2D(colortex4,texCoord).rgb;
vec3 color = texture2D(colortex0,texCoord).rgb;
vec3 normal = normalize(texture2D(colortex2,texCoord).rgb * 2.0 - 1.0);

Material.landMaterial = bool(aux.g);
Material.waterMaterial = isMaterial(aux.g,0.19,0.21);
Material.translucentMaterials = isMaterial(aux.g,0.09,0.11);
Material.handMaterial = isMaterial(aux.g,0.29,0.31);
Material.brightMaterials = isMaterial(aux.g,0.39,0.91);

float pixelDepth = Material.handMaterial? texture2D(depthtex0,texCoord).r:texture2D(depthtex1,texCoord).r;
if (lowEndGPUFix) pixelDepth = texture2D(depthtex1,texCoord).r;

float wPixelDepth = texture2D(depthtex0,texCoord).r;

Position.tPos = getTPos();
Position.lightPos = getLightPos(Position.tPos);
Position.currentPosition = getCurrentPosition(texCoord,pixelDepth);
Position.fragPosition = getFragPosition(Position.currentPosition);
Position.worldPosition = getWorldPosition(Position.fragPosition);
Position.wCurrentPosition = getCurrentPosition(texCoord,wPixelDepth);
Position.wFragPosition = getFragPosition(Position.wCurrentPosition);
Position.wWorldPosition = getWorldPosition(Position.wFragPosition);

bool wShading = false;

float sr = 0.0;
float vl = 0.0;
float gr = 0.0;
float vc = 0.0;
float ao = 0.0;
float vw = 0.0;
float wc = 0.0;

float NdotL = getNdotL(normal);
float ditherPattern = getDitherPattern(1,1);
float depth = length3(Position.fragPosition.xyz);
float waterDepth = getWaterDepth(Position,normal);

float lightVisibility = clamp(aux.r,0.0,1.0);
float shadowFade = clamp(1*(1-(depth/shadowDistance)),0.0,1.0);
float handLight = clamp(1*(1-(depth*0.2)),0.0,1.0);
float uwFog = clamp(exp(-depth*0.07),0.0,1.0);
float wFog = clamp(exp(1 - waterDepth*0.8),0.0,1.0);
float rFog = clamp(exp(-length3(Position.fragPosition.xyz)*0.005),0.0,1.0);

vec3 lightmaps = clamp(((aux.b+handLight*lightValue)*saturate(lightColor,1.8))*lightJitter*(1.0-aux.r),0.0,1.0);

vec3 brightObjects = contrast(saturate(((pow(Material.landMaterial? (Material.handMaterial? color*lightValue*1.1:color):vec3(0.0),vec3(lightSensitivity*2.6)) * (Material.brightMaterials? 2.5:1.0)) * (Material.brightMaterials? 1.0:0.1)),vibrantColors? colorVibrance:1.0),contrastedColors? colorContrast:1.0);

if (nightDesaturation) colorVibrance = float(colorModifier(vec3(colorVibrance),3.0,vec3(0.2),lightVisibility,timeMidnight,true));
if (lowlightDesaturation) colorVibrance = float(colorModifier(vec3(colorVibrance),3.0,vec3(1.0)*(1 - float(aux.r+lightmaps)),1.0,1.0,false));
if (rainDesaturation) colorVibrance = float(colorModifier(vec3(colorVibrance),3.0,vec3(0.2),rainStrength*(1 - timeMidnight),1.0,false));

if (colorFilter) color -= baseColor;
if (timedColors) color = colorModifier(color,3.0,timedColor,lightVisibility,1.0,false);
if (vibrantColors) color = saturate(color,colorVibrance);
if (contrastedColors) color = contrast(color,colorContrast);

brightObjects = colorModifier(brightObjects,1.0,vec3(0.75),Material.brightMaterials? 0.0:lightVisibility,1.0,false);

color = colorModifier(color,1.0,vec3(0.75),lightVisibility,1.0,false);

if (fakeShadows) color *= clamp((10000-(1-aux.r)*100000),1-fakeShadowDarkness,1);

if (Material.landMaterial) color = colorModifier(color,1.0,(1 - vec3(aux.r+lightmaps)),1.0,1.0,false);

if (dynamicExposure) color = colorModifier(color,1.0,1 - vec3(1 + clamp(eyeAdaptation,0.0,1.0)),1.0,1.0,false);

if (vignette) getVignette(color);
if (vignette) getVignette(brightObjects);

if (celshading) getCelshading(color,pixelDepth);
if (ssao) getSSAO(ao,color,pixelDepth,normal,Position,Material);
if (shadows) getDirectSunlight(color,Material,Position,NdotL,wShading,shadowFade,lightmaps);
getVolumetricWaterCaustics(color,wc,vw,lightVisibility,pixelDepth,ditherPattern,Position,Material);
if (Material.waterMaterial && waterFog) color = mix(vec3(0.0,0.5,0.6),color,wFog);
if (eyeIsInWater && underWaterFog) color = mix(vec3(0.0,0.5,0.6),color,uwFog);

if (Material.waterMaterial && waterFog) ao = 1;
if (eyeIsInWater && underWaterFog) ao = 1;

if (!wShading && sunReflection) sr = drawReflectedCircle(Position,normalize(lightVector),0.04,normal);

//if (!Material.landMaterial) color *= 0;

if (volumetricClouds) getVolumetricClouds(vc,ditherPattern,Position,Material);
if (volumetricLight) getVolumetricLight(vl,ditherPattern,Position,pixelDepth);
if (godrays) getGodrays(gr,ditherPattern,Position,sr,wShading,vc);

vec3 refCol = color;
//refCol += vc;

if (Material.landMaterial && fog) refCol = mix(vec3(0.8,0.7,0.9),refCol,rFog);
if (hexagonGrid) getHexagonGrid(color,refCol);

gl_FragData[0] = vec4(color,1.0);
gl_FragData[1] = vec4(vec3(vl+vw+gr,sr,ao),1.0);
gl_FragData[2] = vec4(brightObjects,1.0);
gl_FragData[3] = vec4(refCol,vc);
}