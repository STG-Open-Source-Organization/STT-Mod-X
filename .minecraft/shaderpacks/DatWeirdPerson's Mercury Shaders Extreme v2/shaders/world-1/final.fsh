#version 120
// This is property of DatWeirdPerson's Mercury Shaders. Derived from CyboxShaders v4 Preview1. Go and try them here http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/2364704-cyboxshaders-v4-100k-downloads-pc-mac-intel-1-6-4

const bool motionBlur				= true;
const bool motionFocusBlur		= true;

const float focusStrength			= 6.0;
const float motionBlurStrength	= 1.0;

varying vec2 texCoord;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex1;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;

uniform int isEyeInWater;

struct positionStruct{

vec4 currentPosition;
vec4 fragPosition;
vec4 previousPosition;

}Position;

vec4 getPreviousPosition(in vec4 fragPosition) {

fragPosition = gbufferModelViewInverse * fragPosition;
fragPosition /= fragPosition.w;

fragPosition.xyz += cameraPosition;
fragPosition.xyz -= previousCameraPosition;

fragPosition = gbufferPreviousModelView * fragPosition;
fragPosition = gbufferPreviousProjection * fragPosition;
fragPosition /= fragPosition.w;

return fragPosition;
}

vec4 getFragPosition(in vec4 currentPosition) {
vec4 fragPosition = gbufferProjectionInverse * currentPosition;
fragPosition /= fragPosition.w;

	return fragPosition;
}

vec4 getCurrentPosition(in vec2 coordinates, in float pixelDepth) {
	return vec4(coordinates.s * 2.0f - 1.0f, coordinates.t * 2.0f - 1.0f, 2.0f * pixelDepth - 1.0f, 1.0f);
}

bool isMaterial(in float aux, in float value, in float value2) {
	return (aux < value2 && aux > value)? true:false;
}

float length2(in vec2 v) {
	return sqrt(dot(v,v));
}

void getMotionBlur(inout vec3 color, in positionStruct Position) {

float len =  length2(texCoord-vec2(0.5));

float xvect = (texCoord.x-0.5)*aspectRatio;
float yvect = (texCoord.y-0.5)*aspectRatio;

float len2 = sqrt(xvect*xvect + yvect*yvect);
float dc = mix(len,len2,0.3);

float t = clamp((dc - 0.95) / (0.15 - 0.95), 0.0, 1.0);

vec2 velocity = vec2(Position.currentPosition - Position.previousPosition) * 0.01;
velocity = clamp(velocity, -0.001, 0.001);

bool staticHandMask = isMaterial(texture2D(colortex4,texCoord).g,0.29,0.31);
velocity *= staticHandMask? 0:(1*motionBlurStrength)+(motionFocusBlur? (1-(t * t * (3.0 - 2.0 * t)))*focusStrength:0.0);

int samples = 1;

vec2 texelSize = 1.0 / vec2(viewWidth,viewHeight);

float speed = length2(velocity / texelSize);
float variableSamples = clamp(int(speed*15), float(2), float(25));

for (int i = 0;i < variableSamples;++i) {

vec2 dualDirectionCoord = texCoord - velocity * 50 * (i / (variableSamples - 1) - 0.5);

if (dualDirectionCoord.s > 1.0 || dualDirectionCoord.t > 1.0 || dualDirectionCoord.s < 0.0 || dualDirectionCoord.t < 0.0) dualDirectionCoord = texCoord;
vec3 motionBlur = texture2D(colortex0,dualDirectionCoord).rgb;

bool handMask = !isMaterial(texture2D(colortex4,dualDirectionCoord).g,0.29,0.31);

motionBlur *= handMask? 1:0;

color += motionBlur+(color/samples*(handMask? 0:1));

samples += 1;
}

color /= samples;

color += texture2D(colortex0,texCoord).rgb*0.4; color /= 1+0.4;

}

void main() {

vec3 color = texture2D(colortex0,texCoord).rgb;

float pixelDepth = texture2D(depthtex1,texCoord).r;

Position.currentPosition = getCurrentPosition(texCoord,pixelDepth);
Position.fragPosition = getFragPosition(Position.currentPosition);
Position.previousPosition = getPreviousPosition(Position.fragPosition);

if (motionBlur) getMotionBlur(color,Position);

gl_FragColor = vec4(color,1.0);
}