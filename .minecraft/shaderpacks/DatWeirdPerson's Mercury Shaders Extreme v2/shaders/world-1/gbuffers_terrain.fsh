#version 120
#extension GL_ARB_shader_texture_lod : enable 
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4
/* DRAWBUFFERS:0246 */

const bool steepParallaxMapping	= false;
const bool bumpMapping				= false;

const float depth							= 0.1;
const float res								= 128.0;
const float distance						= 32.0;
const float mixDistance					= 32.0;
const float bmDepth						= 1.0;
const float minCoord 						= 1/4096.0;

const int maxPoints   							= 50;

/* Here, intervalMult might need to be tweaked per vTexCoord pack.  
The first two numbers determine how many samples are taken per fragment.
They should always be the equal to eachother.
The third number divided by one of the first two numbers is inversely proportional to the range of the height-map. */
const vec3 intervalMult = vec3(1.0, 1.0, 1.0/depth)/res * 1.0; 

varying vec4 color;
varying vec4 vTexCoord;
varying vec4 vTexCoordam;

varying vec3 normal;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 viewVector;

varying vec2 lightmapCoord;

varying float dist;
varying float material;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

uniform float wetness;

vec4 getTextureGradARB(in sampler2D ctex, in vec2 tex, in vec2 dcdx, in vec2 dcdy) {
	return texture2DGradARB(ctex, tex, dcdx, dcdy);
}

vec4 getNormals(in vec3 normal) {
	return vec4(normal*0.5+0.5, 1.0f);	
}

vec4 getLightmapCoordinates() {
	return vec4(lightmapCoord.t,material, lightmapCoord.s,1.0);
}

vec2 calculateAdjustedTexCoord() {
	return vTexCoord.st*vTexCoordam.pq+vTexCoordam.st;
}

mat3 getTBNMatrix() {
return mat3(
tangent.x, binormal.x, normal.x,
tangent.y, binormal.y, normal.y,
tangent.z, binormal.z, normal.z
);
}
								  
void getBumpMapping(inout vec4 normals, in vec3 bump) {

float bumpMultiplier = bmDepth*(1.0-wetness*lightmapCoord.t*0.9);
bump = bump * vec3(bumpMultiplier) + vec3(0.0f, 0.0f, 1.0f - bumpMultiplier);

normals = getNormals(normalize(bump * getTBNMatrix()));
}

void getSPM(inout vec2 adjustedTexCoord, inout vec2 dcdx, inout vec2 dcdy) {

if (dist < distance) {

if ( 
viewVector.z < 0.0 
&& getTextureGradARB(normals,fract(vTexCoord.st)*vTexCoordam.pq+vTexCoordam.st,dcdx,dcdy).a < 0.99 
&& getTextureGradARB(normals,fract(vTexCoord.st)*vTexCoordam.pq+vTexCoordam.st,dcdx,dcdy).a > 0.01
) {

vec3 interval = viewVector.xyz * intervalMult;
vec3 coord = vec3(vTexCoord.st, 1.0);
		
for (
int loopCount = 0; 
(loopCount < maxPoints) 
&& (getTextureGradARB(normals,fract(coord.st)*vTexCoordam.pq+vTexCoordam.st,dcdx,dcdy).a < coord.p);
++loopCount
) coord = coord+interval;

if (coord.t < minCoord) {
if (getTextureGradARB(texture,fract(vec2(coord.s,minCoord))*vTexCoordam.pq+vTexCoordam.st,dcdx,dcdy).a == 0.0) {
coord.t = minCoord;
discard;
}
}
float adjustedMixDistance = mixDistance-2;
adjustedTexCoord = mix(fract(coord.st)*vTexCoordam.pq+vTexCoordam.st , adjustedTexCoord , max(dist-adjustedMixDistance,0.0)/(distance-adjustedMixDistance));
}
}
}

void main() {

vec2 adjustedTexCoord = calculateAdjustedTexCoord();
vec2 dcdx = dFdx(vTexCoord.st*vTexCoordam.pq);
vec2 dcdy = dFdy(vTexCoord.st*vTexCoordam.pq);

vec4 normal = getNormals(normal);

if (steepParallaxMapping) getSPM(adjustedTexCoord,dcdx, dcdy);

vec3 bump = vec3(getTextureGradARB(normals, adjustedTexCoord, dcdx, dcdy)*2.0-1.0);

if (bumpMapping) getBumpMapping(normal,bump);

gl_FragData[0] = getTextureGradARB(texture, adjustedTexCoord, dcdx, dcdy)*color;
gl_FragData[1] = normal;
gl_FragData[2] = getLightmapCoordinates();
gl_FragData[3] = getTextureGradARB(specular, adjustedTexCoord, dcdx, dcdy);
}