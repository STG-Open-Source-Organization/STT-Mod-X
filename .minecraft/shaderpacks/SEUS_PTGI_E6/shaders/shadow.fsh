#version 330 compatibility
#extension GL_ARB_shading_language_packing : enable
#extension GL_ARB_shader_bit_encoding : enable

uniform sampler2D tex;

in vec4 texcoord;
in vec4 color;
in vec3 normal;
in vec3 rawNormal;
in vec4 viewPos;

in float materialIDs;

in vec4 lmcoord;

in float invalid;
in float isVoxelized;
in float fragDepth;
in float iswater;

in vec2 midTexcoord;

void main() {

	if (invalid > 0.5 || iswater > 0.5)
	{
		discard;
	}


	vec4 tex = texture2D(tex, texcoord.st, 0);
	// tex.rgb = pow(length(tex.rgb), 0.75) * normalize(tex.rgb + 0.000001);
	vec3 albedo = tex.rgb * color.rgb;

	float alphaSwitch = 1.0;

	if (isVoxelized < 0.5)
	{
		alphaSwitch = min(tex.a * 10.0, 1.0);
		gl_FragDepth = gl_FragCoord.z;
	}
	else
	{
		gl_FragDepth = fragDepth;
	}


	//tex.rgb = vec3(1.1f);

	//tex.rgb = pow(tex.rgb, vec3(1.1f));

	//Fix wrong normals on some entities


	// float NdotL = 1.0;

	//tex.rgb = normalize(tex.rgb) * pow(length(tex.rgb), 0.5);

	// float skylight = clamp((lmcoord.t * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);



	vec3 shadowNormal = normal.xyz;

	// if (materialIDs > 1.8 && materialIDs < 2.2)
	// {
	// 	shadowNormal = 
	// }

	// bool isTranslucent = abs(materialIDs - 3.0f) < 0.1f
	// 				  //|| abs(materialIDs - 2.0f) < 0.1f
	// 				  || abs(materialIDs - 4.0f) < 0.1f
	// 				  //|| abs(materialIDs - 11.0f) < 0.1f
	// 				  ;

	// if (isTranslucent)
	// {
	// 	shadowNormal = vec3(0.0f, 0.0f, 0.0f);
	// 	NdotL = 1.0f;
	// }

	//tex.rgb *= pow(skylight, 10.0);

	// float na = skylight * 0.8 + 0.2;

	// if (isStainedGlass > 0.5)
	// {
	// 	na = 0.1;
	// }

	// if (normal.z < 0.0)
	// {
	// 	tex.rgb = vec3(0.0);
	// }
	// albedo *= normalize(albedo + 0.0001);
	albedo *= albedo;

	// albedo = normalize(albedo + 0.0001) * pow(length(albedo), 0.5);

	float colorized = clamp((abs(color.r - color.g) + abs(color.r - color.b) + abs(color.g - color.b)) * 500.0, 0.0, 1.0);

	//gl_FragData[0] = vec4(albedo.rgb * 0.5, ((materialIDs + 0.5) / 255.0) * alphaSwitch);
	gl_FragData[0] = vec4(albedo.rgb * 1.0, ((materialIDs + 0.1) / 255.0) * alphaSwitch);
	gl_FragData[1] = vec4(midTexcoord.xy, colorized, dot(tex.rgb, vec3(0.33333)));
}
