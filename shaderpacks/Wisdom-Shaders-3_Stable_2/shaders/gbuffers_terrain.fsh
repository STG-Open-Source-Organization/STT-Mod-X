/*
 * Copyright 2017 Cheng Cao
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// =============================================================================
//  PLEASE FOLLOW THE LICENSE AND PLEASE DO NOT REMOVE THE LICENSE HEADER
// =============================================================================
//  ANY USE OF THE SHADER ONLINE OR OFFLINE IS CONSIDERED AS INCLUDING THE CODE
//  IF YOU DOWNLOAD THE SHADER, IT MEANS YOU AGREE AND OBSERVE THIS LICENSE
// =============================================================================

#version 120
#extension GL_ARB_shader_texture_lod : require

#pragma optimize(on)

#define SMOOTH_TEXTURE

#define NORMALS

uniform sampler2D texture;
uniform sampler2D specular;
#ifdef NORMALS
uniform sampler2D normals;
#endif

varying  vec4 color;
varying  vec3 normal;
varying  vec4 coords;
varying  vec4 wdata;

#define wpos wdata.xyz
#define flag wdata.w

#define texcoord coords.rg
#define lmcoord coords.ba

#ifdef NORMALS
varying vec3 tangent;
varying vec3 binormal;
#endif

vec2 dcdx = dFdx(texcoord);
vec2 dcdy = dFdy(texcoord);

#ifdef SMOOTH_TEXTURE
#define texF(a,b) texSmooth(a,b)
uniform ivec2 atlasSize;

vec4 texSmooth(in sampler2D s, in vec2 texc) {
	vec2 pix_size = vec2(1.0) / (vec2(atlasSize) * 24.0);

	vec4 texel0 = texture2DGradARB(s, texc + pix_size * vec2(0.1, 0.5), dcdx, dcdy);
	vec4 texel1 = texture2DGradARB(s, texc + pix_size * vec2(0.5, -0.1), dcdx, dcdy);
	vec4 texel2 = texture2DGradARB(s, texc + pix_size * vec2(-0.1, -0.5), dcdx, dcdy);
	vec4 texel3 = texture2DGradARB(s, texc + pix_size * vec2(0.5, 0.1), dcdx, dcdy);

	return (texel0 + texel1 + texel2 + texel3) * 0.25;
}
#else
#define texF(a,b) texture2DGradARB(a, b, dcdx, dcdy)
#endif


vec2 normalEncode(vec3 n) {return sqrt(-n.z*0.125+0.125) * normalize(n.xy) + 0.5;}

/* DRAWBUFFERS:01245 */
void main() {
	vec2 texcoord_adj = texcoord;

	vec4 texture = texF(texture, texcoord_adj);

	gl_FragData[0] = texture * color;
	gl_FragData[1] = vec4(wpos, 1.0);
	#ifdef NORMALS
		if (length(wpos) < 96.0) {
			vec3 normal2 = texF(normals, texcoord_adj).xyz * 2.0 - 1.0;
			const float bumpmult = 0.35;
			normal2 = normal2 * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
			mat3 tbnMatrix = mat3(
				tangent.x, binormal.x, normal.x,
				tangent.y, binormal.y, normal.y,
				tangent.z, binormal.z, normal.z);
			gl_FragData[2] = vec4(normalEncode(normal2 * tbnMatrix), flag, 1.0);
		} else {
			gl_FragData[2] = vec4(normalEncode(normal), flag, 1.0);
		}
	#else
		gl_FragData[2] = vec4(normalEncode(normal), flag, 1.0);
	#endif
	gl_FragData[3] = texF(specular, texcoord_adj);
	gl_FragData[4] = vec4(lmcoord, 1.0, 1.0);
}
