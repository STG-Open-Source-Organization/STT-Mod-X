#version 120
#include "compat.glsl"
#pragma optimize (on)

varying vec2 texcoord;

#include "GlslConfig"

//#define MOTION_BLUR
#define BLOOM

#include "CompositeUniform.glsl.frag"
#include "Utilities.glsl.frag"
#include "Effects.glsl.frag"

//#define SSEDAA
//#define BLACK_AND_WHITE

#define LF
#ifdef LF
// =========== LF ===========

uniform float aspectRatio;

varying float sunVisibility;
varying vec2 lf1Pos;
varying vec2 lf2Pos;
varying vec2 lf3Pos;
varying vec2 lf4Pos;

#define MANHATTAN_DISTANCE(DELTA) abs(DELTA.x)+abs(DELTA.y)

#define LENS_FLARE(COLOR, UV, LFPOS, LFSIZE, LFCOLOR) { \
				vec2 delta = UV - LFPOS; delta.x *= aspectRatio; \
				if(MANHATTAN_DISTANCE(delta) < LFSIZE * 2.0) { \
					float d = max(LFSIZE - sqrt(dot(delta, delta)), 0.0); \
					COLOR += LFCOLOR.rgb * LFCOLOR.a * smoothstep(0.0, LFSIZE * 0.25, d) * sunVisibility;\
				} }

#define LF1SIZE 0.026
#define LF2SIZE 0.03
#define LF3SIZE 0.05

const vec4 LF1COLOR = vec4(1.0, 1.0, 1.0, 0.05);
const vec4 LF2COLOR = vec4(1.0, 0.6, 0.4, 0.03);
const vec4 LF3COLOR = vec4(0.2, 0.6, 0.8, 0.05);

vec3 lensFlare(vec3 color, vec2 uv) {
	if(sunVisibility <= 0.0)
		return color;
	LENS_FLARE(color, uv, lf1Pos, LF1SIZE, (LF1COLOR * vec4(suncolor, 1.0)));
	LENS_FLARE(color, uv, lf2Pos, LF2SIZE, (LF2COLOR * vec4(suncolor, 1.0)));
	LENS_FLARE(color, uv, lf3Pos, LF3SIZE, (LF3COLOR * vec4(suncolor, 1.0)));
	return color;
}

#endif
// ==========================


void main() {
	#ifdef EIGHT_BIT
	vec3 color;
	bit8(color);
	#else
	#ifdef SSEDAA
	vec3 color = texture2D(composite, texcoord).rgb;
	float size = 1.0 / length(fetch_vpos(texcoord, depthtex0).xyz);
	vec3 edge = applyEffect(1.0, size,
		-1.0, -1.0, -1.0,
		-1.0,  8.0, -1.0,
		-1.0, -1.0, -1.0,
		composite, texcoord);
	vec3 blur = applyEffect(6.8, size,
		0.3, 1.0, 0.3,
		1.0, 1.6, 1.0,
		0.3, 1.0, 0.3,
		composite, texcoord);
	color = mix(color, blur, edge);
	#else
	vec3 color = texture2D(composite, texcoord).rgb;
	#endif
	#endif

	#ifdef MOTION_BLUR
	if (texture2D(gaux1, texcoord).a > 0.11) motion_blur(composite, color, texcoord, fetch_vpos(texcoord, depthtex0).xyz);
	#endif

	#ifdef DOF
	dof(color);
	#endif

	float exposure = get_exposure();

	#ifdef BLOOM
	color += max(vec3(0.0), bloom() * exposure);
	#endif
	
	#ifdef LF
	color = lensFlare(color, texcoord);
	#endif

	// This will turn it into gamma space
	#ifdef BLACK_AND_WHITE
	color = vec3(luma(color));
	#endif
	
	#ifdef NOISE_AND_GRAIN
	noise_and_grain(color);
	#endif
	
	#ifdef FILMIC_CINEMATIC
	filmic_cinematic(color);
	#endif
	
	tonemap(color, exposure);
	
	gl_FragColor = vec4(color, 1.0f);
}
