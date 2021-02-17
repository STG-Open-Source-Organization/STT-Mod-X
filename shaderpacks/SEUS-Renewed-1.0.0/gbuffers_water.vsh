#version 120

//#define WAVING_WATER

uniform int worldTime;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 worldPosition;
varying vec4 vertexPos;

varying vec3 normal;
varying vec3 globalNormal;
varying vec3 tangent;
varying vec3 binormal;
varying vec3 viewVector;
varying vec3 viewVector2;
varying float distance;

attribute vec4 mc_Entity;

varying float iswater;
varying float isice;
varying float isStainedGlass;

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

#define TAA_ENABLED // Temporal Anti-Aliasing. Utilizes multiple rendered frames to reconstruct an anti-aliased image similar to supersampling. Can cause some artifacts.


void TemporalJitterProjPos(inout vec4 pos)
{
	#ifdef TAA_ENABLED
	const vec2 haltonSequenceOffsets[16] = vec2[16](vec2(-1, -1), vec2(0, -0.3333333), vec2(-0.5, 0.3333334), vec2(0.5, -0.7777778), vec2(-0.75, -0.1111111), vec2(0.25, 0.5555556), vec2(-0.25, -0.5555556), vec2(0.75, 0.1111112), vec2(-0.875, 0.7777778), vec2(0.125, -0.9259259), vec2(-0.375, -0.2592592), vec2(0.625, 0.4074074), vec2(-0.625, -0.7037037), vec2(0.375, -0.03703701), vec2(-0.125, 0.6296296), vec2(0.875, -0.4814815));
	const vec2 bayerSequenceOffsets[16] = vec2[16](vec2(0, 3) / 16.0, vec2(8, 11) / 16.0, vec2(2, 1) / 16.0, vec2(10, 9) / 16.0, vec2(12, 15) / 16.0, vec2(4, 7) / 16.0, vec2(14, 13) / 16.0, vec2(6, 5) / 16.0, vec2(3, 0) / 16.0, vec2(11, 8) / 16.0, vec2(1, 2) / 16.0, vec2(9, 10) / 16.0, vec2(15, 12) / 16.0, vec2(7, 4) / 16.0, vec2(13, 14) / 16.0, vec2(5, 6) / 16.0);
	const vec2 otherOffsets[16] = vec2[16](vec2(0.375, 0.4375), vec2(0.625, 0.0625), vec2(0.875, 0.1875), vec2(0.125, 0.0625),
vec2(0.375, 0.6875), vec2(0.875, 0.4375), vec2(0.625, 0.5625), vec2(0.375, 0.9375),
vec2(0.625, 0.3125), vec2(0.125, 0.5625), vec2(0.125, 0.8125), vec2(0.375, 0.1875),
vec2(0.875, 0.9375), vec2(0.875, 0.6875), vec2(0.125, 0.3125), vec2(0.625, 0.8125)
);
	pos.xy += ((bayerSequenceOffsets[int(mod(frameCounter, 12))] * 2.0 - 1.0) / vec2(viewWidth, viewHeight));
	//pos.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))).xy / vec2(viewWidth, viewHeight)) * 1.0;
	#else

	#endif
}

void main() {

	iswater = 0.0f;
	isice = 0.0f;
	isStainedGlass = 0.0f;

	if(mc_Entity.y == 1)
	{
		iswater = 1.0;
	}

	if (mc_Entity.x == 79) {
		isice = 1.0f;
		iswater = 0.0;
	}
	
		 vertexPos = gl_Vertex;

	// if (mc_Entity.x == 1971.0f)
	// {
	// 	iswater = 1.0f;
	// }
	
	// if (mc_Entity.x == 8 || mc_Entity.x == 9) {
	// 	iswater = 1.0f;
	// }

	if (mc_Entity.x == 95 || mc_Entity.x == 160)
	{
		isStainedGlass = 1.0f;
		iswater = 0.0;
	}


	
		
	vec4 viewPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec4 position = viewPos;

	worldPosition.xyz = viewPos.xyz + cameraPosition.xyz;

	vec4 localPosition = gl_ModelViewMatrix * gl_Vertex;

	distance = length(localPosition.xyz);

	gl_Position = gl_ProjectionMatrix * (gbufferModelView * position);



	//Temporal jitter
	gl_Position.xyz /= gl_Position.w;
	//gl_Position.xy += (rand(vec2(mod(float(frameCounter) / 16.0, 1.0))) / vec2(viewWidth, viewHeight)) * 2.0;
	//gl_Position.xy += (haltonSequenceOffsets[int(mod(frameCounter, 16))] / vec2(viewWidth, viewHeight)) * 1.0;
	TemporalJitterProjPos(gl_Position);
	gl_Position.xyz *= gl_Position.w;

	gl_Position.z -= 0.0001;

	
	color = gl_Color;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	


	gl_FogFragCoord = gl_Position.z;


	
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	globalNormal = normalize(gl_Normal);

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	} else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	} else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
                          tangent.y, binormal.y, normal.y,
                          tangent.z, binormal.z, normal.z);

	viewVector = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector2 = normalize(viewVector);
	viewVector = normalize(tbnMatrix * viewVector);


	
}