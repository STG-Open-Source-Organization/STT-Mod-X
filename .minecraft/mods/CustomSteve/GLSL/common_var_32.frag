uniform sampler2D mainTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D toonTexture;
uniform sampler2D spaTexture;
uniform vec2 lightmapCoord;
uniform vec3 lightDir;
uniform bool pureColor;
uniform bool enableLightmap;
uniform bool enableToon;
uniform int enableSpa;
uniform vec4 glColor;
in fData {
	vec3 normal;
	vec3 ecPos;
	vec2 vTexCoord;
	float edge;
}frag;