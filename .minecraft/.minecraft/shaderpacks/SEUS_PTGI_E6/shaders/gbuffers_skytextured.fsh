#version 120

//sun and moon

uniform sampler2D texture;

varying vec4 color;
varying vec4 texcoord;


/* DRAWBUFFERS:01 */


void main() {

	vec4 tex = texture2D(texture, texcoord.st);

	//discard;


	gl_FragData[0] = tex * color;
	gl_FragData[1] = vec4(0.0f, 1.0f, 0.0f, 1.0f);
}