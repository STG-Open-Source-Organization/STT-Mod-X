#version 120

/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the LICENSE.txt contained in the root directory of this shaderpack!

*/



#include "Common.inc"


/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:2 */


const bool gaux3MipmapEnabled = true;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux3;
uniform sampler2D noisetex;

varying vec4 texcoord;
varying vec3 lightVector;

uniform int worldTime;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform sampler2D shadowcolor;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform int   isEyeInWater;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   fogMode;

varying float timeSunriseSunset;
varying float timeNoon;
varying float timeMidnight;

varying vec3 colorSunlight;
varying vec3 colorSkylight;

vec3 GetColor(vec2 coord)
{
	vec3 color = GammaToLinear(texture2D(gaux3, coord).rgb);
	//color = mix(color, vec3(dot(color, vec3(0.3333))), vec3(-0.5));

	return color;
}

vec2 ClampCoord(vec2 coord, vec2 texel)
{
	//return clamp(coord, texel, 1.0 - texel);
	return saturate(coord);
}

vec3 GrabBlurH(vec2 coord, const float octave, const vec2 offset)
{
	float scale = exp2(octave);

	coord += offset;
	coord *= scale;

	vec2 texel = scale / vec2(viewWidth, viewHeight);
	vec2 lowBound  = 0.0 - 10.0 * texel;
	vec2 highBound = 1.0 + 10.0 * texel;

	if (coord.x < lowBound.x || coord.x > highBound.x || coord.y < lowBound.y || coord.y > highBound.y)
	{
		return vec3(0.0);
	}

	//vec3 color = GetColor(coord);

	vec3 color = vec3(0.0);

/*
	float weights[3] = float[3](0.27343750, 0.32812500, 0.03515625);
	float offsets[3] = float[3](0.00000000, 1.33333333, 3.11111111);




	color += GetColor(ClampCoord(coord, texel)) * weights[0];

	for (int i = 1; i < 3; i++)
	{
		color += GetColor(ClampCoord(coord + vec2(offsets[i] * 1.0, 0.0) * texel, texel)) * weights[i];
		color += GetColor(ClampCoord(coord - vec2(offsets[i] * 1.0, 0.0) * texel, texel)) * weights[i];
	}
*/

	float weights[5] = float[5](0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625);
	float offsets[5] = float[5](0.00000000, 1.00000000, 2.00000000, 3.00000000, 4.00000000);

	color += GetColor(ClampCoord(coord, texel)) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		color += GetColor(ClampCoord(coord + vec2(offsets[i] * 1.0, 0.0) * texel, texel)) * weights[i];
		color += GetColor(ClampCoord(coord - vec2(offsets[i] * 1.0, 0.0) * texel, texel)) * weights[i];
	}

	return color;
}

vec2 CalcOffset(float octave)
{
    vec2 offset = vec2(0.0);
    
    vec2 padding = vec2(30.0) / vec2(viewWidth, viewHeight);
    
    offset.x = -min(1.0, floor(octave / 3.0)) * (0.25 + padding.x);
    
    offset.y = -(1.0 - (1.0 / exp2(octave))) - padding.y * octave;

	offset.y += min(1.0, floor(octave / 3.0)) * 0.35;
    
 	return offset;   
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	//vec3 color = GammaToLinear(texture2D(gaux3, texcoord.st).rgb);

	vec3 color = vec3(0.0);

	color += GrabBlurH(texcoord.st, 1.0, vec2(0.0, 0.0));
	color += GrabBlurH(texcoord.st, 2.0, CalcOffset(1.0));
	color += GrabBlurH(texcoord.st, 3.0, CalcOffset(2.0));
	color += GrabBlurH(texcoord.st, 4.0, CalcOffset(3.0));
	color += GrabBlurH(texcoord.st, 5.0, CalcOffset(4.0));
	color += GrabBlurH(texcoord.st, 6.0, CalcOffset(5.0));
	color += GrabBlurH(texcoord.st, 7.0, CalcOffset(6.0));
	color += GrabBlurH(texcoord.st, 8.0, CalcOffset(7.0));
	color += GrabBlurH(texcoord.st, 9.0, CalcOffset(8.0));


	//color += rand(texcoord.st) * (1.0 / 255.0);


	color = LinearToGamma(color);


	gl_FragData[0] = vec4(color.rgb, 1.0f);

}
