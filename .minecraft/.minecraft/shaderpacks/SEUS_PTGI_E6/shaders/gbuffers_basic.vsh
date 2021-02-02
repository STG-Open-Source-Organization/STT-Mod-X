#version 120

varying vec4 color;

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

#include "TAA.inc"


void main() {
	gl_Position = ftransform();

	//Temporal jitter
	gl_Position.xyz /= gl_Position.w;
	TemporalJitterProjPos(gl_Position);
	gl_Position.xyz *= gl_Position.w;
	
	color = gl_Color;

	gl_FogFragCoord = gl_Position.z;
}