in vec3 vPosition;
in vec3 vNormal;
in vec2 vUV;
in float iBone0;
in float iBone1;
in float fBone0Weight;
in vec3 vFace;
uniform sampler2D BoneMatrixArray;
uniform float BoneNumberM4;
out vData {
	vec3 normal;
	vec3 ecPos;
	vec2 vTexCoord;
}vertex;

vec4 my_Vertex;