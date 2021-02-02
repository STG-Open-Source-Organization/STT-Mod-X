#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:035 */

const float aberrationStrength 	= 0.01;
const float bloomSpread				= 1.0;
const float bloomStrength			= 6.0;

const vec2 bloomRes					= vec2(4096,2160);

const bool chromaticAberration 	= true;
const bool dynamicLensFlare	 	= true;
const bool bloom 						= true;
const bool rainDrops					= true;
const bool glare							= true;

varying vec2 texCoord;

varying float essentialsQuality;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform float aspectRatio;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

const vec2 circleOffsets[60] = vec2[60]  (
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

float length3(in vec3 v) {
	return sqrt(dot(v,v));
}

vec4 t2DPRB(in sampler2D channel, in vec2 coord, in vec2 resolution, in float blurPower) {
vec2 textureCoordinates = floor((coord+(vec2(0.5)/(resolution)))*resolution)/resolution;

vec4 blur = vec4(0.0);

for (int i = 0; i < essentialsQuality; ++i) blur += texture2D(channel,textureCoordinates-(circleOffsets[i]*vec2(1.0,aspectRatio))*blurPower);

	return blur/essentialsQuality;
}

const vec2 coords[9] = vec2[9](

vec2(0.3),
1-vec2(0.15),
1-vec2(0.05,0.5),

vec2(0.15),
vec2(0.05,0.75),
vec2(0.75,0.05),

1-vec2(0.75,0.05),
vec2(0.6,0.8),
1-vec2(0.3,0.8));

vec2 dropCoords[9] = vec2[9](
vec2(1.0,fract(frameTimeCounter/200.0)), 		  
vec2(1.0,fract(frameTimeCounter/80.0)), 		  
vec2(1.0,fract(frameTimeCounter/45.0)), 		
vec2(1.0,fract(frameTimeCounter/30.0)), 		  
vec2(1.0,fract(frameTimeCounter/20.0)), 		
vec2(1.0,fract(frameTimeCounter/130.0)), 		
vec2(1.0,fract(frameTimeCounter/175.0)), 		
vec2(1.0,fract(frameTimeCounter/60.0)), 		
vec2(1.0,fract(frameTimeCounter/230.0)));

float distanceRatio(in vec2 pos, in vec2 pos2) {
float xvect = pos.x*aspectRatio-pos2.x*aspectRatio;
float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}

float generateSolidCircularLens(in vec2 center, in float size) {
	return 1-pow(min(distanceRatio(texCoord,center),size)/size,3.0);
}

const float size[9] = float[9](
0.01,
0.016,
0.024,
0.037,
0.012,
0.029,
0.041,
0.027,
0.013);

bool isMaterial(in float aux, in float value, in float value2) {
	return (aux < value2 && aux > value)? true:false;
}

vec3 distort(in vec3 color, in float strength) {

vec2 conditions = vec2(0.0);
vec2 chromaticDistortionRed = vec2(0.0);
vec2 chromaticDistortionBlue = vec2(0.0);
vec2 refractedTexCoordRed = vec2(0.0);
vec2 refractedTexCoordBlue = vec2(0.0);

float isRainDrop = 0.0;

if (rainDrops) {

for (int i = 0; i < 9; ++i) {
vec2 dropCoord = coords[i]/dropCoords[i];

for (int a = 0; a < 9; ++a) {
dropCoord -= vec2(0.0,0.01+(a*0.001));
isRainDrop += generateSolidCircularLens(dropCoord,(size[i]*1.1));

}
}

isRainDrop *= 1.3;
isRainDrop *= rainStrength;
isRainDrop *= clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);

vec2 refractCoord = vec2(sin(frameTimeCounter*6.0 + texCoord.x*0.0 + texCoord.y*50.0),cos(frameTimeCounter*0.0 + texCoord.y*0.0 + texCoord.x*100.0));
vec2 finalRefractCoord = refractCoord * 0.01 * isRainDrop;

conditions += rainDrops? finalRefractCoord:vec2(0.0);
}

vec2 refractedTexCoord = texCoord + conditions;

refractedTexCoordRed += refractedTexCoord - vec2(rainDrops? (1*0.0027)*isRainDrop:0.0);
refractedTexCoordBlue += refractedTexCoord + vec2(rainDrops? (1*0.0027)*isRainDrop:0.0);

float focus = distance(texCoord, vec2(0.5));
focus = isMaterial(texture2D(colortex4,texCoord).g,0.29,0.31)? 0.0:pow(focus,2.0);

chromaticDistortionRed += chromaticAberration? vec2(1.0,0.0)*(focus/aspectRatio)*strength:vec2(0.0);
chromaticDistortionBlue += chromaticAberration? vec2(-1.0,0.0)*(focus/aspectRatio)*strength:vec2(0.0);

float distortedRed = texture2D(colortex0, refractedTexCoordRed + chromaticDistortionRed).r;
float distortedGreen = texture2D(colortex0, refractedTexCoord).g;
float distortedBlue = texture2D(colortex0, refractedTexCoordBlue + chromaticDistortionBlue).b;

vec3 distortedColor = vec3(distortedRed,distortedGreen,distortedBlue);
distortedColor -= texture2D(colortex0,texCoord).rgb*0.4;

return distortedColor+texture2D(colortex0,texCoord).rgb*(1*0.4);
}

void generateChromaHoop(inout vec3 lens, in float dispersal) {

vec3 chromaHoop = vec3(0.0);

vec2 lensCoord = -texCoord + vec2(1.0);
vec2 ghostVec = (vec2(0.5) - lensCoord);

vec2 coord1 = fract(lensCoord+(normalize(ghostVec) * dispersal)) + normalize(ghostVec) * -0.01;
vec2 coord2 = fract(lensCoord+(normalize(ghostVec) * dispersal));
vec2 coord3 = fract(lensCoord+(normalize(ghostVec) * dispersal)) + normalize(ghostVec) * 0.01;

chromaHoop.r += pow(texture2D(colortex5,coord1).r,(1.0/2.2));
chromaHoop.g += pow(texture2D(colortex5,coord2).g,(1.0/2.2));
chromaHoop.b += pow(texture2D(colortex5,coord3).b,(1.0/2.2));

chromaHoop = clamp(chromaHoop,0.0,0.3);

lens = mix(lens,vec3(1),chromaHoop);

}

void generateGhost(inout vec3 lens, in float size, in float dispersal) {
vec2 lensCoord = -texCoord + vec2(1.0);

vec2 lensVec = (vec2(0.5) - texCoord);
vec2 ghostVec = (vec2(0.5) - lensCoord) * dispersal;

float lensWeight = length(vec2(0.5) - fract(texCoord)) / length(vec2(0.5));
lensWeight = pow(1.0 - lensWeight, 5.0);

vec2 coord = fract(texCoord - ghostVec * size);

lens += pow(texture2D(colortex5,coord).rgb,vec3(1.0/2.2))*lensWeight;
}

void generateGlare(inout vec3 lens, in float offset) {

vec3 glare = vec3(0.0);

for (int i = 0; i < 60; ++i) {
glare += texture2D(colortex3,texCoord-vec2(0.0,offset*0.006*i)).rgb;
glare += texture2D(colortex3,texCoord+vec2(0.0,offset*0.006*i)).rgb;
}

glare = glare/120;

lens = mix(lens,vec3(1),glare);
}

void main() {

vec3 color = distort(texture2D(colortex0,texCoord).rgb,aberrationStrength);

float vc = texture2D(colortex5,texCoord).a;

vec3 lens = vec3(0.0);
vec3 blur = vec3(0.0);

if (bloom) blur += t2DPRB(colortex3,texCoord,bloomRes,0.05*bloomSpread).rgb*bloomStrength;
if (glare) generateGlare(color,0.5);

if (dynamicLensFlare) {
generateChromaHoop(lens,0.25);
generateChromaHoop(lens,0.45);

generateGhost(lens,1.0,0.2);
generateGhost(lens,2.0,0.2);
generateGhost(lens,3.0,0.2);
generateGhost(lens,2.0,0.8);
generateGhost(lens,3.0,0.8);
}

gl_FragData[0] = vec4(color,1.0);
gl_FragData[1] = vec4(lens,1.0);
gl_FragData[2] = vec4(blur,vc);
}