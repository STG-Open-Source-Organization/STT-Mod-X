#version 120
#include "compat.glsl"
#pragma optimize (on)

varying vec2 texcoord;

#include "GlslConfig"

//#define SPACE

#include "CompositeUniform.glsl.frag"
#include "Utilities.glsl.frag"
#include "Material.glsl.frag"
#include "Lighting.glsl.frag"
#include "Atomosphere.glsl.frag"
#include "Water.glsl.frag"

vec4 mclight = texture2D(gaux2, texcoord);

LightSource torch;
LightSource amb;
LightSourcePBR sun;
Material land;

Mask mask;

#ifdef WISDOM_AMBIENT_OCCLUSION
#ifdef HQ_AO
//=========== BLUR AO =============
float blurAO (vec2 uv, vec3 N) {
	float z  = texture2D(composite, uv).r;
	float x  = z * 0.2941176f;
	vec3  y  = texture2D(composite, uv + vec2(0.0, -pixel.y * 1.333333)).rgb;
	      x += mix(z, y.x, max(0.0, dot(normalDecode(y.yz), N))) * 0.352941176f;
	      y  = texture2D(composite, uv + vec2(0.0,  pixel.y * 1.333333)).rgb;
	      x += mix(z, y.x, max(0.0, dot(normalDecode(y.yz), N))) * 0.352941176f;
	return x;
}
//=================================
#endif
#endif

//#define PRIME_RENDER
//#define MODERN

void main() {
	// rebuild hybrid flag
	vec4 speculardata = texture2D(gaux1, texcoord);
	float flag = speculardata.a;

	// build up mask
	init_mask(mask, flag);

	vec3 color = vec3(0.0f);

	// build up materials & light sources
	if (!mask.is_sky) {
		#ifdef MODERN
		const vec3 torch_color = vec3(0.01f);
		#else
		const vec3 torch_color = vec3(0.2435f, 0.0921f, 0.01053f) * 0.1f;
		#endif
		torch.color = torch_color;
		torch.attenuation = light_mclightmap_attenuation(mclight.x);

		material_sample(land, texcoord);
		#ifdef PRIME_RENDER
		land.albedo = vec3(0.7);
		#endif

		#ifndef SPACE
		sun.light.color = suncolor;
		float thickness;
		float shadow = 0.0;

		shadow = light_fetch_shadow(shadowtex1, light_shadow_autobias(land.cdepthN), wpos2shadowpos(land.wpos), thickness);
		if (isEyeInWater) {
			shadow = max(shadow, 1.0 - mclight.y);
		}

		sun.light.attenuation = 1.0 - max(extShadow, shadow);
		#ifdef WATER_CAUSTICS
		if ((mask.is_water || (isEyeInWater && !mask.is_water)) && shadow < 0.95) {
			sun.light.attenuation *= 1.3 - get_caustic(land.wpos + cameraPosition);
		}
		#endif
		sun.L = lightPosition;
		#endif

		amb.color = ambient;
		amb.attenuation = light_mclightmap_simulated_GI(mclight.y, sun.L, land.N);
		#ifdef WISDOM_AMBIENT_OCCLUSION
		#ifdef HQ_AO
		float ao = blurAO(texcoord, land.N);
		#else
		float ao = texture2D(composite, texcoord).r;
		#endif
		amb.attenuation *= ao;
		torch.attenuation *= ao;
		#endif
		
		// Force ground wetness
		float wetness2 = wetness * pow(mclight.y, 5.0) * float(!mask.is_plant);
		if (wetness2 > 0.1 && !(mask.is_water || mask.is_hand || mask.is_entity)) {
			float wet = noise((land.wpos + cameraPosition).xz * 0.15);
			wet += noise((land.wpos + cameraPosition).xz * 0.3) * 0.5;
			wet = clamp(smoothstep(0.1, 0.3, wetness2) * wet, 0.0, 1.0);
			
			land.roughness = mix(land.roughness, 0.05, wet);
			land.metalic = mix(land.metalic, 0.15, wet);
			vec3 flat_normal = normalDecode(mclight.zw);
			land.N = mix(land.N, flat_normal, wet);
			
			land.albedo *= 1.0 - rainStrength * 0.3;
		}

		// Light composite
		#ifdef SPACE
		color += light_calc_diffuse(torch, land) + light_calc_diffuse(amb, land);
		#else
		color += light_calc_PBR(sun, land, mask.is_plant ? thickness : 1.0) + light_calc_diffuse(torch, land) + light_calc_diffuse(amb, land);
		#endif
		
		// Emmisive
		if (!mask.is_trans) color = mix(color, land.albedo * 2.0, land.emmisive);
	} else {
		vec4 viewPosition = fetch_vpos(texcoord, depthtex1);
		vec4 worldPosition = normalize(gbufferModelViewInverse * viewPosition) * 512.0;
		worldPosition.y += cameraPosition.y;
		// Sky
		#ifdef SPACE
		color = vec3(0.0);
		#else
		color = calc_sky_with_sun(worldPosition.xyz, normalize(viewPosition.xyz));
		#endif
		//color = vec3(get_thickness(normalize(worldPosition.xyz)));
	}

/* DRAWBUFFERS:3 */
	gl_FragData[0] = vec4(max(vec3(0.0), color), 1.0f);
}
