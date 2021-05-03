#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

const float aberrationStrength 			= 0.01;

const bool colortex1MipmapEnabled 	= true;

const bool warmShaderTone 				= false;
const bool godrays							= true;
const bool srGodrays							= false;
const bool volumetricClouds				= true;
const bool volumetricWaterCaustics	= true;
const bool volumetricLight					= true;
const bool raytrace 							= true;
const bool drawSun							= true;
const bool drawMoon							= true;
const bool stars 								= true;
const bool clouds 								= true;
const bool chromaticAberration 			= true;

varying vec3 lightVector;

varying vec2 texCoord;

varying float timeMidnight;
varying float timeSunrise;
varying float timeSunset;
varying float timeNoon;
varying float timeTransition;

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex6;
uniform sampler2D depthtex1;
uniform sampler2D depthtex0;

uniform vec3 sunPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float far;
uniform float rainStrength;
uniform float aspectRatio;
uniform float frameTimeCounter;

uniform int isEyeInWater;

bool eyeIsInWater = bool(isEyeInWater);

struct positionStruct{

vec4 fragPosition;
vec4 currentPosition;
vec4 tPos;

vec2 lightPos;

float truePos;

}Position;

struct materialStruct{

bool landMaterial;
bool waterMaterial;
bool translucentMaterials;
bool handMaterial;

}Material;

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

vec4 getTPos() {
vec4 tPos = vec4(sunPosition,1.0)*gbufferProjection;
tPos = vec4(nvec3(tPos),1.0);

	return tPos;
}

vec4 getCurrentPosition(in vec2 coordinates, in float pixelDepth) {	
	return vec4(coordinates.s * 2.0f - 1.0f, coordinates.t * 2.0f - 1.0f, 2.0f * pixelDepth - 1.0f, 1.0f);
}

vec3 getReflectedVector(in vec4 fragPosition, in vec3 normal) {
	return 50.0 * normalize(reflect(normalize(vec3(fragPosition)), normalize(normal)));
}

vec3 saturate(in vec3 color, in float saturation) {
float luma = dot(color,vec3(0.299, 0.587, 0.114));
vec3 chroma = color - luma;

	return (chroma*saturation)+luma;
}

vec3 distort(in vec3 color, in float strength, in materialStruct Material) {

float focus = distance(texCoord, vec2(0.5));
focus = Material.handMaterial? 0.0:pow(focus,2.0);

float distortedRed = texture2D(colortex0, texCoord + vec2(1.0,0.0)*(focus/aspectRatio)*strength).r;
float distortedGreen = texture2D(colortex0, texCoord).g;
float distortedBlue = texture2D(colortex0, texCoord - vec2(1.0,0.0)*(focus/aspectRatio)*strength).b;

vec3 distortedColor = vec3(distortedRed,distortedGreen,distortedBlue);
distortedColor -= texture2D(colortex0,texCoord).rgb*0.4;

return distortedColor+texture2D(colortex0,texCoord).rgb*(1*0.4);
}

vec3 getSkyColor() {
vec3 noonSky = vec3(0.53,0.74,1.0)*timeNoon;
vec3 sunriseSky = vec3(0.95,0.63,0.5)*timeSunrise;
vec3 sunsetSky = vec3(0.95,0.63,0.5)*timeSunset;
vec3 nightSky = vec3(0.0,0.2,0.25)*timeMidnight;
vec3 rainSky = vec3(0.7,0.7,0.7)*rainStrength;

vec3 skyColor = (((noonSky+sunsetSky+sunriseSky+nightSky)*(1 - rainStrength)+rainSky)*timeTransition);

return skyColor;
}

vec2 getLightPos(in vec4 tPos, in float distance) {
vec2 lightPos = tPos.st/tPos.z*distance;
lightPos = (lightPos + 1.0f)/2.0f;	
	return lightPos;
}

float getFresnel(in vec3 normal, in vec4 fragPosition) {
	return clamp(pow(1.0 + dot(normal, normalize(vec3(fragPosition))), 1.0),0.0,1.0);
}

float drawCircle(in positionStruct Position, in vec3 vector, in float size) {
	return pow(max(dot(normalize(Position.fragPosition.xyz),vector),0.0),size);
}

float getTruePos(in vec4 tPos) {
	return pow(clamp(dot(-lightVector*timeTransition,tPos.xyz)/length3(tPos.xyz),0.0,1.0),0.25);	
}

bool isMaterial(in float aux, in float value, in float value2) {
	return (aux < value2 && aux > value)? true:false;
}

void drawStars(inout vec3 color, in vec4 fPosition, in bool landMaterial) {
vec4 worldPos = (gbufferModelViewInverse * fPosition)  / far * 128;

float y = 10.12;

float frameTime = frameTimeCounter*15;  

vec2 wind = vec2(1+frameTime, 8+frameTime)/(y*10.0);
vec2 camPos = (worldPos.xz/worldPos.y);
vec2 pos = -1+0.01*(camPos + wind/y);
pos /= 0.8/10.12;
pos *= 15;

float rawStars = texture2D(noisetex,fract(pos/2)).x;
rawStars += texture2D(noisetex,fract(pos.xy)).x/2.0;
rawStars += texture2D(noisetex,fract(pos.xy)).x/2.0;

float starsStrength = max(rawStars-1.7,0.0);
vec3 stars = vec3(1 - (pow(0.01,starsStrength)));

if (!landMaterial) color = mix(color,vec3(1),stars*timeMidnight*timeTransition);
}

void drawClouds(inout vec3 color, in vec4 fPosition, in bool landMaterial) {

float x = 0.8;
float y = 10.12;
float z = 0.1;

vec4 worldPos = (gbufferModelViewInverse * fPosition)  / far * 128;

float cloudNormal = (worldPos.y + length1(worldPos.y))/100;
float frameTime = frameTimeCounter;  
float cloudTex = 0.2;
float density = 1.0;
float multiplier = 0.7*(1.0-rainStrength*-0.9);

vec2 wind = vec2(1+frameTime, 8+frameTime)/(y*10.0);
vec2 camPos = (worldPos.xz*z/worldPos.y);
vec2 pos = -1+0.01*(camPos + wind/y);

pos /= x/y;

float clouds = 0.0;

clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/320000).x*multiplier; density *= 4.0; multiplier *= 0.05;
clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/340000).x*multiplier; density *= 2.1; multiplier *= 1.5;
clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/360000).x*multiplier; density *= 2.4; multiplier *= 0.5;
clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/380000).x*multiplier; density *= 2.9; multiplier *= 0.5;
clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/400000).x*multiplier;density *= 2.1; multiplier *= 0.5;
clouds += texture2D(noisetex, vec2(pos.s,pos.t)*density - frameTimeCounter/400000).x*multiplier;
clouds *= 5.9;

float b = 0.9;
float c = clouds - (b+0.175);
if(c <= 0) c = 0; 

clouds = ((1.0 - pow(b, c))*cloudNormal);
clouds = clamp(clouds,0.0,1.0);

vec3 noon = vec3(1.0);
vec3 sunrise = vec3(0.95,0.63,0.5)*timeSunrise;
vec3 sunset = vec3(0.95,0.63,0.5)*timeSunset;
vec3 night = vec3(0.0,0.2,0.25)*timeMidnight;
vec3 rain = vec3(0.7,0.7,0.7)*rainStrength;

vec3 colors = ((noon+sunset+sunrise+night)*(1-rainStrength)+rain*rainStrength);

vec3 cloudColor = colors*(clouds/(3.0+(3.0*(1 - timeNoon))))*timeTransition;

if (!landMaterial) color = mix(color,vec3(1),cloudColor);
}

void raytraceReflections(inout vec3 color, in vec3 normal, in float fresnel, in float sunRef, in vec3 reflectedVector, in positionStruct Position, in materialStruct Material, in vec3 skyColor, in vec3 aux) {

vec4 reflection = vec4(0.0);

bool isReflectedLand = false;

vec3 oldpos = Position.fragPosition.xyz;
Position.fragPosition.xyz += reflectedVector;

int minf = 0;

for (int i = 0; i < 5; i++) {

vec3 pos = nvec3(gbufferProjection * Position.fragPosition) * 0.5 + 0.5;

if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
		
vec3 sPos = getFragPosition(getCurrentPosition(pos.st,texture2D(depthtex1,pos.st).r)).xyz;

float err = distance(Position.fragPosition.xyz,sPos);
if (err < pow(length3(reflectedVector)*1.85,1.15)) {
	
minf++;
Position.fragPosition.xyz = oldpos;
reflectedVector *= 0.12;

}

if (minf >= 1) {

reflection = texture2D(colortex0, pos.st);
reflection.a = 1.0 * clamp(1.0 - pow(max(abs(pos.s-0.5), abs(pos.t-0.5))*2.0, 5.0), 0.0, 1.0); 
isReflectedLand = bool(texture2D(colortex4,pos.st).g);
break;

}
	
reflectedVector *= 1.6;
oldpos = Position.fragPosition.xyz;
Position.fragPosition.xyz += reflectedVector;

}

vec3 specular = texture2D(colortex6,texCoord).rgb;
float specularMap = (specular.r+specular.g)*clamp((rainStrength+0.01),0.0,1.0);

reflection.rgb = mix(skyColor, reflection.rgb,reflection.a);

if (!isReflectedLand) reflection.rgb += skyColor,reflection.rgb *= 0.5;

vec3 refCol = vec3(10);
refCol *= 1+(vec3(0.0,0.3,0.9)*timeMidnight*timeTransition);
refCol *= 1-(0.75*timeMidnight*timeTransition);
refCol *= 1+(vec3(1.0,0.4,0.1) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));
refCol *= 1-(vec3(0.0,0.6,0.9) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));

if (Material.waterMaterial) color = fresnel*reflection.rgb+(1 - fresnel)*color+(sunRef*refCol);

color = specularMap*fresnel*reflection.rgb+(1 - fresnel*specularMap)*color+(sunRef*specularMap*0.5);

if (Material.translucentMaterials) color = fresnel*reflection.rgb+(1 - fresnel)*color+(sunRef*refCol);

}

void essentials(inout vec3 color) {

const float offset = 0.0025;

vec3 blur = vec3(0.0);

blur += texture2DLod(colortex1,texCoord+vec2(0.0,offset),3).r;
blur += texture2DLod(colortex1,texCoord-vec2(0.0,offset),3).r;

blur += texture2DLod(colortex1,texCoord+vec2(offset,0.0),3).r;
blur += texture2DLod(colortex1,texCoord-vec2(offset,0.0),3).r;

blur /= 4;

blur *= 1+(vec3(1.0,0.4,0.1) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));
blur *= 1-(vec3(0.0,0.6,0.9) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));

blur *= 1+(vec3(0.0,0.3,0.9)*timeMidnight*timeTransition);
blur *= 1-(0.75*timeMidnight*timeTransition);

vec3 blurFinal = mix(color,blur*40,0.1);

color += pow(blurFinal,vec3(2.2));
color /= 1+pow(blurFinal,vec3(2.2));

}

void main() {

vec3 aux = texture2D(colortex4,texCoord).rgb;
vec3 color = texture2D(colortex0,texCoord).rgb;
vec3 normal = texture2D(colortex2,texCoord).rgb * 2.0 - 1.0;

float pixelDepth = texture2D(depthtex0,texCoord).r;
float sunRef = texture2D(colortex1,texCoord).g;

Position.tPos = getTPos();
Position.lightPos = getLightPos(Position.tPos,1);
Position.truePos = getTruePos(Position.tPos);
Position.currentPosition = getCurrentPosition(texCoord,pixelDepth);
Position.fragPosition = getFragPosition(Position.currentPosition);

vec3 skyColor = saturate(getSkyColor(),1.8);

Material.landMaterial = bool(aux.g);
Material.waterMaterial = isMaterial(aux.g,0.19,0.21);
Material.translucentMaterials = isMaterial(aux.g,0.09,0.11);
Material.handMaterial = isMaterial(aux.g,0.29,0.31);

float fresnel = getFresnel(normal,Position.fragPosition);
vec3 reflectedVector = getReflectedVector(Position.fragPosition,normal);

color = chromaticAberration? distort(color,aberrationStrength,Material):color;

if (raytrace) raytraceReflections(color,normal,fresnel,sunRef,reflectedVector,Position,Material,skyColor,aux);

if (!Material.landMaterial) color += skyColor,color *= 0.5;

if (stars) drawStars(color,Position.fragPosition,Material.landMaterial);
if (clouds) drawClouds(color,Position.fragPosition,Material.landMaterial);

vec3 sunCol = vec3(1);
sunCol *= 1+(vec3(1.0,0.4,0.1));
sunCol *= 1-(vec3(0.0,0.6,0.9));

vec3 moonCol = vec3(1);
moonCol *= 1+(vec3(0.0,0.3,0.9));
moonCol *= 1-(0.75);

float nFix = 1+(9*(timeSunrise+timeSunset)*timeTransition);

if (!Material.landMaterial && drawSun) color = mix(color,sunCol*10*nFix,drawCircle(Position,normalize(sunPosition),675.0*1-(0.5*rainStrength)));
if (!Material.landMaterial && drawMoon) color = mix(color,moonCol*10,drawCircle(Position,normalize(-sunPosition),775.0*1-(0.5*rainStrength)));

if (godrays || volumetricLight || srGodrays || volumetricClouds || volumetricWaterCaustics) essentials(color);

gl_FragColor = vec4(color,1.0);
}