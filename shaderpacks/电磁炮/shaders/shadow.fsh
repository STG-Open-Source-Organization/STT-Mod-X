#version 120

uniform sampler2D tex;

varying vec4 texcoord;
varying vec4 color;
varying vec3 normal;
varying vec3 rawNormal;

varying float materialIDs;

void main() {

	vec4 tex = texture2D(tex, texcoord.st, 0) * color;

	//tex.rgb = vec3(1.1f);

	//tex.rgb = pow(tex.rgb, vec3(1.1f));


	float NdotL = pow(max(0.0f, mix(dot(normal.rgb, vec3(0.0f, 0.0f, 1.0f)), 1.0f, 0.0f)), 1.0f / 2.2f);


	vec3 toLight = normal.xyz;

	vec3 shadowNormal = normal.xyz;

	bool isTranslucent = abs(materialIDs - 3.0f) < 0.1f
					  //|| abs(materialIDs - 2.0f) < 0.1f
					  || abs(materialIDs - 4.0f) < 0.1f
					  //|| abs(materialIDs - 11.0f) < 0.1f
					  ;

	if (isTranslucent)
	{
		shadowNormal = vec3(0.0f, 0.0f, 0.0f);
		NdotL = 1.0f;
	}

	gl_FragData[0] = vec4(tex.rgb * NdotL, tex.a);
	gl_FragData[1] = vec4(shadowNormal.xyz * 0.5 + 0.5, 1.0f);
}