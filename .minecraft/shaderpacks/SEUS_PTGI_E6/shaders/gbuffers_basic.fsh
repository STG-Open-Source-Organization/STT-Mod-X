#version 120


varying vec4 color;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

uniform int fogMode;

/* DRAWBUFFERS:012 */


void main() {
	
	vec4 albedo = color;
	albedo.a = 1.0;
	gl_FragData[0] = albedo;

	gl_FragData[1] = vec4(0.0f, 0.0f, 1.0f, 0.0f);
	
	gl_FragData[2] = vec4(0.0f, 0.0f, 0.0f, 0.0f);
}