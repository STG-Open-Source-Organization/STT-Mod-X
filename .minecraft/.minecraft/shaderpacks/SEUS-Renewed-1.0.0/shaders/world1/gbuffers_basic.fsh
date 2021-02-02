#version 120


varying vec4 color;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

uniform int fogMode;

/* DRAWBUFFERS:0123 */


void main() {
	
	gl_FragData[0] = color;

	gl_FragData[1] = vec4(0.0f, 0.0f, 1.0f, 0.0f);
	
	gl_FragData[2] = vec4(0.0f, 0.0f, 0.0f, 0.0f);
	
	gl_FragData[3] = vec4(0.0f, 0.0f, 0.0f, 0.0f);
}