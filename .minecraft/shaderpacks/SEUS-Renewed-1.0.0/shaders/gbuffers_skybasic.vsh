#version 120

varying vec4 color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	
	color = gl_Color;



	//Translate vertices by local offset so sky behaves as if it's very very far away
	vec4 worldPosition = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	vec3 localOffset = (gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// worldPosition.xyz *= 4.0;

	worldPosition.xyz += localOffset.xyz;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * worldPosition;



	gl_FogFragCoord = gl_Position.z;
}