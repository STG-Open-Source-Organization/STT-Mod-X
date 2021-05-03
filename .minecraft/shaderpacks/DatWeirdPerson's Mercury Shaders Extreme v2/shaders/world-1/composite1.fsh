#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:035 */

const float ssaoDarkness					= 0.0;

const bool colortex5MipmapEnabled 	= true;

const bool cloudReflections 				= false;
const bool warmShaderTone 				= false;
const bool waterRefract						= false;
const bool fakeRays							= false;
const bool drawSun							= false;
const bool drawMoon							= false;
const bool stars 								= false;
const bool clouds 								= false;
const bool ssao									= true;
const bool fog									= true;

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
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D depthtex1;
uniform sampler2D depthtex0;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float far;
uniform float viewWidth;
uniform float aspectRatio;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform int isEyeInWater;

float pw = 1.0/viewWidth;
bool eyeIsInWater = bool(isEyeInWater);

struct positionStruct{

vec4 worldPosition;
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

vec4 getWorldPosition(in vec4 fragPosition) {
return gbufferModelViewInverse * fragPosition;
}

vec4 getCurrentPosition(in vec2 coordinates, in float pixelDepth) {	
	return vec4(coordinates.s * 2.0f - 1.0f, coordinates.t * 2.0f - 1.0f, 2.0f * pixelDepth - 1.0f, 1.0f);
}

vec3 getReflectedVector(in vec4 fragPosition, in vec3 normal) {
	return 1.0 * normalize(reflect(normalize(vec3(fragPosition)), normal));
}

vec3 saturate(in vec3 color, in float saturation) {
float luma = dot(color,vec3(0.299, 0.587, 0.114));
vec3 chroma = color - luma;

	return (chroma*saturation)+luma;
}

vec3 getSkyColor() {
vec3 skyColor = vec3(1);
skyColor *= 1+vec3(1.0,0.4,0.1);
skyColor *= 1-vec3(0.0,0.6,0.9);
return skyColor;
}

vec3 CCStSS(in vec3 cameraSpace) {
vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
vec3 screenSpace = 0.5 * NDCSpace + 0.5;

    return screenSpace;
}

vec2 getLightPos(in vec4 tPos, in float distance) {
vec2 lightPos = tPos.st/tPos.z*distance;
lightPos = (lightPos + 1.0f)/2.0f;	
	return lightPos;
}

float getEdgemask(in float lightPos) {
	return clamp(distance(lightPos, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
}

float getFresnel(in vec3 normal, in vec4 fragPosition) {
	return clamp(pow(1.0 + dot(normal, normalize(vec3(fragPosition))), 1.0),0.0,1.0);
}

float getWaterDepth(in positionStruct Position, in vec3 normal, in float pixelDepth) {
	return length3(vec3(Position.worldPosition.y))*abs(dot(normalize(vec3(Position.worldPosition.y)),normal));
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

void raytraceReflections(inout vec3 color, in vec3 normal, in float fresnel, in float sunRef, in vec3 reflectedVector, in positionStruct Position, in materialStruct Material, in vec3 skyColor, inout vec3 brightObjects, in vec3 aux) {

vec4 reflection = vec4(0.0);
vec4 clouds = vec4(0.0);
vec3 brightObjectsReflection = vec3(0.0);

bool reflectedLandMaterial = false;

vec3 oldpos = Position.fragPosition.xyz;
Position.fragPosition.xyz += reflectedVector;

int minf = 0;

for (int i = 0; i < 30; i++) {

vec3 pos = nvec3(gbufferProjection * Position.fragPosition) * 0.5 + 0.5;

if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
		
vec3 sPos = getFragPosition(getCurrentPosition(pos.st,texture2D(depthtex1,pos.st).r)).xyz;

float err = distance(Position.fragPosition.xyz,sPos);
if (err < pow(length3(reflectedVector)*1.85,1.15)) {

minf++;
Position.fragPosition.xyz = oldpos;
reflectedVector *= 0.12;

}

if (minf >= 5) {

reflection = texture2D(colortex5,pos.st);
brightObjectsReflection.rgb = texture2D(colortex3,pos.st).rgb;
clouds.a = texture2DLod(colortex5,pos.st,2).a;
reflectedLandMaterial = bool(texture2D(colortex4,pos.st).g);
reflection.a = 1.0 * clamp(1.0 - pow(max(abs(pos.s-0.5), abs(pos.t-0.5))*2.0, 5.0), 0.0, 1.0); 
break;

}
	
reflectedVector *= 1.6;
oldpos = Position.fragPosition.xyz;
Position.fragPosition.xyz += reflectedVector;

}

vec3 refCol = vec3(1);
refCol *= 1+(vec3(0.0,0.3,0.9)*timeMidnight*timeTransition);
refCol *= 1-(0.75*timeMidnight*timeTransition);
refCol *= 1+(vec3(1.0,0.4,0.1) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));
refCol *= 1-(vec3(0.0,0.6,0.9) * (warmShaderTone? (1 - timeMidnight)*timeTransition:(timeSunrise+timeSunset)*timeTransition));

vec3 cloudReflection = reflection.rgb;
vec3 cloudReflectionFinal = mix(reflection.rgb,vec3(clouds.a * 40),0.1)*refCol;

vec3 specular = texture2D(colortex6,texCoord).rgb;
float specularMap = (specular.r+specular.g)*0.4;
reflection.rgb = mix(skyColor, reflection.rgb,reflection.a);

vec3 specularReflection = !reflectedLandMaterial? vec3(0.0):reflection.rgb;

if (!reflectedLandMaterial) reflection.rgb += skyColor,reflection.rgb *= 0.5;
if (Material.waterMaterial && !reflectedLandMaterial && cloudReflections) {
reflection.rgb += pow(cloudReflectionFinal,vec3(2.2));
reflection.rgb /= 1+pow(cloudReflectionFinal,vec3(2.2));
}

if (Material.waterMaterial) color = fresnel*reflection.rgb+(1 - fresnel)*color+(sunRef*refCol*10);

if (Material.waterMaterial) brightObjects = fresnel*brightObjectsReflection+(1 - fresnel)*brightObjects+(sunRef*refCol);

color = specularMap*fresnel*reflection.rgb+(1 - fresnel*specularMap)*color+(sunRef*specularMap*0.5);
brightObjects = specularMap*fresnel*specularReflection+(1 - fresnel*specularMap)*brightObjects+(sunRef*specularMap*0.5);

if (Material.translucentMaterials) color = fresnel*reflection.rgb+(1 - fresnel)*color+(sunRef*refCol*10);
if (Material.translucentMaterials) brightObjects = fresnel*brightObjectsReflection+(1 - fresnel)*brightObjects+(sunRef*refCol);

}

void getFakeRays(inout vec3 color, in positionStruct Position, in float edges) {
vec2 lensMovement = vec2(0.0,fract(frameTimeCounter/7000));
lensMovement += Position.lightPos/75;

vec2 lensMovement2 = vec2(0.0,fract(frameTimeCounter/800));
lensMovement2 += Position.lightPos/65;

vec2 lensCoord = normalize(texCoord - Position.lightPos)/60;
vec2 lensCoord2 = normalize(texCoord - Position.lightPos)/50;

float aberrationMult = 0.0003;
float clampMult = 0.1;

vec2 redLensCoord = lensCoord+aberrationMult;
vec2 blueLensCoord = lensCoord-aberrationMult;

float lensRed = texture2D(noisetex,(redLensCoord+lensMovement)*15).x;
float lensGreen = texture2D(noisetex,(lensCoord+lensMovement)*15).x;
float lensBlue = texture2D(noisetex,(blueLensCoord+lensMovement)*15).x;

vec3 fakeRays = vec3(lensRed,lensGreen,lensBlue);
fakeRays = pow(fakeRays,vec3(22.2));
fakeRays *= 1+(599*(1 - timeMidnight))*timeTransition;

vec3 finalFakeRays = (fakeRays)*Position.truePos*step(texture2D(colortex4,Position.lightPos).r,0.0);
finalFakeRays = clamp(finalFakeRays,0.0,clampMult);
finalFakeRays *= 1-(0.8*rainStrength);
finalFakeRays *= 1-(0.3*timeMidnight*(1 - rainStrength))*timeTransition;

color = mix(color,vec3(1),finalFakeRays*(1 - drawCircle(Position,lightVector,1))*edges);
}

void blurAO(inout vec3 color, in materialStruct Material) {

vec3 blur = vec3(0.0);

float projection = clamp(distance(CCStSS(Position.fragPosition.xyz).xy,texCoord),10.0*pw,10.0*pw);

for (int i = 0; i < 30; ++i) blur += texture2D(colortex1,texCoord-(offset2[i]*vec2(1.0,aspectRatio))*projection*0.2).b;
blur /= 30;

if (Material.landMaterial && !Material.handMaterial) color = mix(color,vec3(-ssaoDarkness),1-blur);
}

void refractWater(inout vec3 color, in vec4 worldPosition, in float depth) {

const float pow = 2.0;
const float sReduction = 0.5;

float refPow = 0.0075*(pow+depth*256*0.05);
float abbPow = 0.015*(1+sin(frameTimeCounter)*15);
float offsetFix = refPow;

vec3 nCol = color;
vec3 refPos = (worldPosition.xyz+cameraPosition.xyz)/2.6;

float frameTime = isMaterial(texture2D(colortex4,texCoord).g,0.09,0.11)? 0.0:frameTimeCounter/150;

vec2 refCoord = (refPos.xz / 40.0) + frameTime;
float refPattern = texture2D(noisetex, refCoord).r*1.6;
refPattern *= 0.15;

refPattern += texture2D(noisetex, refCoord*2.5).r*0.1;
refPattern += texture2D(noisetex, refCoord*5).r*0.075;
refPattern += texture2D(noisetex, refCoord*10).r*0.05;
refPattern += texture2D(noisetex, refCoord*15).r*0.025;
refPattern += texture2D(noisetex, refCoord*20).r*0.015;
refPattern *= 3.75;

vec2 refCoord2 = (refPos.xz / 40.0) + frameTime;
float refPattern2 = texture2D(noisetex, refCoord2).x;

float uwRefPattern = sin((frameTimeCounter * 4.0) + texCoord.x*50.0 + texCoord.y*30.0);

refPattern2 = clamp(refPattern2,0.0,sReduction);

vec2 textureOffset = ((((refPattern)*vec2(refPow*50)))*vec2(refPow));

bool landMask = isMaterial(texture2D(colortex4,(texCoord+(textureOffset+refPattern2*refPow*abbPow))-vec2(offsetFix)).g,0.09,0.21);
bool landMask2 = isMaterial(texture2D(colortex4,(texCoord+textureOffset)-vec2(offsetFix)).g,0.09,0.21);
bool landMask3 = isMaterial(texture2D(colortex4,(texCoord+(textureOffset-refPattern2*refPow*abbPow))-vec2(offsetFix)).g,0.09,0.21);

float rCol = texture2D(colortex0,texCoord+(textureOffset+refPattern2*refPow*abbPow)-vec2(offsetFix)).r;
float gCol = texture2D(colortex0,texCoord+textureOffset-vec2(offsetFix)).g;
float bCol = texture2D(colortex0,texCoord+(textureOffset-refPattern2*refPow*abbPow)-vec2(offsetFix)).b;

rCol *= landMask? 1:0;
gCol *= landMask2? 1:0;
bCol *= landMask3? 1:0;

nCol.r *= landMask? 0:1;
nCol.g *= landMask2? 0:1;
nCol.b *= landMask3? 0:1;

vec3 oCol = vec3(rCol,gCol,bCol)+nCol;

float uwrCol = texture2D(colortex0,texCoord+uwRefPattern*vec2(refPow)*(0.25*1-abbPow)).r;
float uwgCol = texture2D(colortex0,texCoord+uwRefPattern*vec2(refPow)*0.25).g;
float uwbCol = texture2D(colortex0,texCoord+uwRefPattern*vec2(refPow)*(0.25*1+abbPow)).b;

vec3 uwoCol = vec3(uwrCol,uwgCol,uwbCol);

if (eyeIsInWater) color = uwoCol;
if (!eyeIsInWater && isMaterial(texture2D(colortex4,texCoord).g,0.09,0.21)) color = oCol; else color = color;
}

void main() {

vec3 aux = texture2D(colortex4,texCoord).rgb;
vec3 color = texture2D(colortex0,texCoord).rgb;
vec3 normal = normalize(normalize(texture2D(colortex2,texCoord).rgb * 2.0 - 1.0));
vec3 brightObjects = texture2D(colortex3,texCoord).rgb;

float sunRef = texture2D(colortex1,texCoord).g;
float pixelDepth = texture2D(depthtex0,texCoord).r;
float vc = texture2D(colortex5,texCoord).a;

Position.tPos = getTPos();
Position.lightPos = getLightPos(Position.tPos,1);
Position.truePos = getTruePos(Position.tPos);
Position.currentPosition = getCurrentPosition(texCoord,pixelDepth);
Position.fragPosition = getFragPosition(Position.currentPosition);
Position.worldPosition = getWorldPosition(Position.fragPosition);

vec3 skyColor = saturate(getSkyColor(),1.8);

float rFog = clamp(exp(-length3(Position.fragPosition.xyz)*0.005),0.0,1.0);
float depth = clamp(exp((1-getWaterDepth(Position,normal,pixelDepth))/5)*0.05,0,0.5);

Material.landMaterial = bool(aux.g);
Material.waterMaterial = isMaterial(aux.g,0.19,0.21);
Material.translucentMaterials = isMaterial(aux.g,0.09,0.11);
Material.handMaterial = isMaterial(aux.g,0.29,0.31);

float fresnel = getFresnel(normal,Position.fragPosition);
vec3 reflectedVector = getReflectedVector(Position.fragPosition,normal);

float edges = 1-(getEdgemask(Position.lightPos.x)+getEdgemask(Position.lightPos.y));

if (waterRefract) refractWater(color,Position.worldPosition,depth);
raytraceReflections(color,normal,fresnel,sunRef,reflectedVector,Position,Material,skyColor,brightObjects,aux);

if (ssao) blurAO(color,Material);

vec3 fogCol = vec3(1);
fogCol *= 1+vec3(1.0,0.4,0.1);
fogCol *= 1-vec3(0.0,0.6,0.9);

if (Material.landMaterial && fog) color = mix(fogCol,color,rFog);

if (!Material.landMaterial) color = skyColor;

if (stars) drawStars(color,Position.fragPosition,Material.landMaterial);
if (clouds) drawClouds(color,Position.fragPosition,Material.landMaterial);

if (fakeRays) getFakeRays(brightObjects,Position,edges);

vec3 sunCol = vec3(1);
sunCol *= 1+(vec3(1.0,0.4,0.1));
sunCol *= 1-(vec3(0.0,0.6,0.9));

vec3 moonCol = vec3(1);
moonCol *= 1+(vec3(0.0,0.3,0.9));
moonCol *= 1-(0.75);

float nFix = 1+(9*(timeSunrise+timeSunset)*timeTransition);

if (!Material.landMaterial && drawSun) color = mix(color,sunCol*10*nFix,drawCircle(Position,normalize(sunPosition),675.0*1-(0.5*rainStrength)));
if (!Material.landMaterial && drawMoon) color = mix(color,moonCol*10,drawCircle(Position,normalize(-sunPosition),775.0*1-(0.5*rainStrength)));

if (!Material.landMaterial && drawSun) brightObjects = mix(brightObjects,sunCol,drawCircle(Position,normalize(sunPosition),675.0*1-(0.5*rainStrength)));
if (!Material.landMaterial && drawMoon) brightObjects = mix(brightObjects,moonCol,drawCircle(Position,normalize(-sunPosition),775.0*1-(0.5*rainStrength)));

gl_FragData[0] = vec4(color,1.0);
gl_FragData[1] = vec4(brightObjects,1.0);
gl_FragData[2] = vec4(Material.handMaterial? vec3(0.0):brightObjects-0.35,vc);
}