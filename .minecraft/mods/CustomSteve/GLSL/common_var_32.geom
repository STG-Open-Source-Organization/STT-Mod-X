uniform float edgeScale;
const float edgeInOrthogonal = 0.005;
const float edgeInPerspective = 0.0025;
const float edgeOffset = 0.005;

layout (triangles) in;
layout (triangle_strip, max_vertices=6) out;

in vData {
	vec3 normal;
	vec3 ecPos;
	vec2 vTexCoord;
}vertex[];

out fData {
	vec3 normal;
	vec3 ecPos;
	vec2 vTexCoord;
	float edge;
}frag;