#version 120

uniform sampler2D mainTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D toonTexture;
uniform sampler2D spaTexture;
uniform vec2 lightmapCoord;
uniform vec3 lightDir;
uniform bool pureColor;
uniform bool enableLightmap;
uniform bool enableToon;
uniform bool enableSpa;
varying vec3 normal;
varying vec3 ecPos;


vec4 getFragColor(float stdLight, vec3 _lightDir)  
{  
	vec4 color = pureColor?gl_Color:texture2D(mainTexture,gl_TexCoord[0].st);
	if(enableToon)
	{
		float f = 0.5 * (1.0 - dot( _lightDir, normal ));
		vec2 toonCoord = vec2(0.0, f);
		color = color * texture2D(toonTexture,toonCoord);
	}
	if(enableLightmap)
	{	
		return stdLight * color * texture2D(lightmapTexture,lightmapCoord);
		//return stdLight * color;
	}
	else
	{
		return stdLight * color;
	}
}  