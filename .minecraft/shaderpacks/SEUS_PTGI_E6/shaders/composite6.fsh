#version 130

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


const bool gnormalMipmapEnabled = false;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

in vec4 texcoord;
in vec3 lightVector;

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
uniform int frameCounter;

in float timeSunriseSunset;
in float timeNoon;
in float timeMidnight;

in vec3 colorSunlight;
in vec3 colorSkylight;

uniform float frameTime;

vec3 GetColor(vec2 coord)
{
	return GammaToLinear(texture2D(gnormal, coord).rgb);
}

vec3 BlurV(vec2 coord)
{

	vec3 color = vec3(0.0);

	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);


/*
	float weights[3] = float[3](0.27343750, 0.32812500, 0.03515625);
	float offsets[3] = float[3](0.00000000, 1.33333333, 3.11111111);




	color += GetColor(coord) * weights[0];

	for (int i = 1; i < 3; i++)
	{
		color += GetColor(coord + vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
		color += GetColor(coord - vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
	}
*/

	float weights[5] = float[5](0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625);
	float offsets[5] = float[5](0.00000000, 1.00000000, 2.00000000, 3.00000000, 4.00000000);
	
	color += GetColor(coord) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		color += GetColor(coord + vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
		color += GetColor(coord - vec2(0.0, offsets[i] * 1.0) * texel) * weights[i];
	}

	return color;

	//return GetColor(coord);
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

vec2 GetNearFragment(vec2 coord, float depth, out float minDepth)
{
	
	
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	vec4 depthSamples;
	depthSamples.x = texture2D(gdepthtex, coord + texel * vec2(1.0, 1.0)).x;
	depthSamples.y = texture2D(gdepthtex, coord + texel * vec2(1.0, -1.0)).x;
	depthSamples.z = texture2D(gdepthtex, coord + texel * vec2(-1.0, 1.0)).x;
	depthSamples.w = texture2D(gdepthtex, coord + texel * vec2(-1.0, -1.0)).x;

	vec2 targetFragment = vec2(0.0, 0.0);

	if (depthSamples.x < depth)
		targetFragment = vec2(1.0, 1.0);
	if (depthSamples.y < depth)
		targetFragment = vec2(1.0, -1.0);
	if (depthSamples.z < depth)
		targetFragment = vec2(-1.0, 1.0);
	if (depthSamples.w < depth)
		targetFragment = vec2(-1.0, -1.0);


	minDepth = min(min(min(depthSamples.x, depthSamples.y), depthSamples.z), depthSamples.w);

	return coord + texel * targetFragment;
}

vec3 RGBToYUV(vec3 color)
{
	mat3 mat = 		mat3( 0.2126,  0.7152,  0.0722,
				 	-0.09991, -0.33609,  0.436,
				 	 0.615, -0.55861, -0.05639);
				 	
	return color * mat;
}

vec3 YUVToRGB(vec3 color)
{
	mat3 mat = 		mat3(1.000,  0.000,  1.28033,
				 	1.000, -0.21482, -0.38059,
				 	1.000,  2.12798,  0.000);
				 	
	return color * mat;
}

vec3 ClipAABB(vec3 aabbMin, vec3 aabbMax, vec3 p, vec3 q)
{
	vec3 pClip = 0.5 * (aabbMax + aabbMin);
	vec3 eClip = 0.5 * (aabbMax - aabbMin);

	vec3 vClip = q - pClip;
	vec3 vUnit = vClip / eClip;
	vec3 aUnit = abs(vUnit);
	float maxUnit = max(aUnit.x, max(aUnit.y, aUnit.z));

	if (maxUnit > 1.0)
	{
		return pClip + vClip / maxUnit;
	}
	else
	{
		return q;
	}
}

#define COLORPOW 1.0


// From "Filmic SMAA Sharp Morphological and Temporal Antialiasing" by Jorge Jimenez
// http://www.klayge.org/material/4_11/Filmic%20SMAA%20v7.pdf

vec4 GetPrevColor(vec2 uv)
{
	vec2 res = vec2(viewWidth, viewHeight);
    vec2 rcpres = 1.0 / res;

    vec2 position = uv * res;
    vec2 centerPosition = floor(position - 0.5) + 0.5;
    vec2 f = position - centerPosition;
    vec2 f2 = f * f;
    vec2 f3 = f * f2;

    float c = 0.5; // Reprojection sharpness
    vec2 w0 =           -c  * f3 +  2.0 * c             * f2 - c * f;
    vec2 w1 =     (2.0 - c) * f3 - (3.0 - c)            * f2         + 1.0;
    vec2 w2 =    -(2.0 - c) * f3 + (3.0 - 2.0 * c)      * f2 + c * f;
    vec2 w3 =            c  * f3 -                    c * f2;

    vec2 w12 = w1 + w2;
    vec2 tc12 = rcpres * (centerPosition + w2 / w12);
    vec4 centerColor = texture2DLod(gaux4, vec2(tc12.x, tc12.y), 0);

    vec2 tc0 = rcpres * (centerPosition - 1.0);
    vec2 tc3 = rcpres * (centerPosition + 2.0);
    vec4 color = vec4(texture2DLod(gaux4, vec2(tc12.x, tc0.y ), 0).rgb, 1.0) * (w12.x * w0.y ) +
                 vec4(texture2DLod(gaux4, vec2(tc0.x,  tc12.y), 0).rgb, 1.0) * (w0.x  * w12.y) +
                 vec4(centerColor.rgb                                 , 1.0) * (w12.x * w12.y) +
                 vec4(texture2DLod(gaux4, vec2(tc3.x,  tc12.y), 0).rgb, 1.0) * (w3.x  * w12.y) +
                 vec4(texture2DLod(gaux4, vec2(tc12.x, tc3.y ), 0).rgb, 1.0) * (w12.x * w3.y );

    return vec4(max(vec3(0.0), color.rgb * (1.0 / color.a)), centerColor.a);
}

#include "TAA.inc"
 
float AverageExposure()
{
	float avglod = int(log2(min(viewWidth, viewHeight)));
	return pow(Luminance(texture2DLod(composite, vec2(0.65, 0.65), avglod).rgb), 2.0);
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	//vec3 color = GammaToLinear(texture2D(gaux3, texcoord.st).rgb);

	vec3 bloomColor = vec3(0.0);

	bloomColor = BlurV(texcoord.st);

	bloomColor = LinearToGamma(bloomColor);

	float depth = texture2D(gdepthtex, texcoord.st).x;

	//color += rand(texcoord.st) * (1.0 / 255.0);



	//Combine TAA here...
	vec2 unjitteredCoord = texcoord.st;
	if (depth > 0.7)
	{
		// TemporalJitterProjPos01(unjitteredCoord);
	}

	vec4 compositeData = texture2DLod(composite, unjitteredCoord, 0);
	float smoothness = compositeData.a;

	vec3 color = pow(compositeData.rgb, vec3(COLORPOW));	//Sample color texture
	vec3 origColor = color;



/*
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;
*/

	float minDepth;

	vec2 nearFragment = GetNearFragment(texcoord.st, depth, minDepth);

	float nearDepth = texture2D(gdepthtex, nearFragment).x;

	vec4 projPos = vec4(texcoord.st * 2.0 - 1.0, nearDepth * 2.0 - 1.0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * projPos;
	viewPos.xyz /= viewPos.w;

	vec4 worldPos = gbufferModelViewInverse * vec4(viewPos.xyz, 1.0);
	//worldPos.xyz += cameraPosition;

	vec4 worldPosPrev = worldPos;
	//worldPosPrev.xyz -= previousCameraPosition;
	worldPosPrev.xyz += (cameraPosition - previousCameraPosition);

	vec4 viewPosPrev = gbufferPreviousModelView * vec4(worldPosPrev.xyz, 1.0);
	vec4 projPosPrev = gbufferPreviousProjection * vec4(viewPosPrev.xyz, 1.0);
	projPosPrev.xyz /= projPosPrev.w;

	vec2 motionVector = (projPos.xy - projPosPrev.xy);

	float motionVectorMagnitude = length(motionVector) * 10.0;
	float pixelMotionFactor = clamp(motionVectorMagnitude * 500.0, 0.0, 1.0);

	vec2 reprojCoord = texcoord.st - motionVector.xy * 0.5;
	reprojCoord = depth < 0.7 ? texcoord.st : reprojCoord; 		//Don't reproject hand

	vec2 pixelError = cos((fract(abs(texcoord.st - reprojCoord.xy) * vec2(viewWidth, viewHeight)) * 2.0 - 1.0) * 3.14159) * 0.5 + 0.5;
	vec2 pixelErrorFactor = pow(pixelError, vec2(0.5));

// * frameTime * 0.5

	// vec4 prevColor = pow(texture2D(gaux4, reprojCoord.st), vec4(COLORPOW, COLORPOW, COLORPOW, 1.0));
	vec4 prevColor = pow(GetPrevColor(reprojCoord.st), vec4(COLORPOW, COLORPOW, COLORPOW, 1.0));
	float prevMinDepth = prevColor.a;

	float motionVectorDiff = (abs(motionVectorMagnitude - prevColor.a));


	vec3 minColor = vec3(1000000.0,1000000.0,1000000.0);
	vec3 maxColor = vec3(0.0,0.0,0.0);
	vec3 avgColor = vec3(0.0,0.0,0.0);
	vec3 avgX = vec3(0.0);
	vec3 avgY = vec3(0.0);

	int c = 0;

	vec3 m1 = vec3(0.0);
	vec3 m2 = vec3(0.0);

	///*
	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 offs = (vec2(float(i), float(j)) / vec2(viewWidth, viewHeight)) * 1.0;
			vec3 samp = pow(texture2D(composite, unjitteredCoord.xy + offs).rgb, vec3(COLORPOW));
			minColor = min(minColor, samp);
			maxColor = max(maxColor, samp);
			avgColor += samp;

			if (j == 0)
			{
				avgX += samp;
			}

			if (i == 0)
			{
				avgY += samp;
			}

			samp = (RGBToYUV(samp));

			m1 += samp;
			m2 += samp * samp;
			c++;
		}
	}
	avgColor /= c;

	avgX /= 3.0;
	avgY /= 3.0;


	float colorWindow = 1.5;

	// Modulate color window by smoothness
	colorWindow += (saturate(smoothness * 10.0) * saturate(10.0 - smoothness * 10.0)) * 0.5;
	colorWindow -= 0.5 * saturate(smoothness * 10.0 - 9.0);

	vec3 blendWeight = vec3(0.05);


	if (abs(ExpToLinearDepth(minDepth) - ExpToLinearDepth(prevMinDepth)) > 1.0)
	{
		blendWeight = vec3(0.1);
		colorWindow = 1.0;
		// prevColor.rgb = vec3(1.0, 0.0, 0.0);
		// color.rgb = vec3(1.0, 0.0, 0.0);
	}

	if (   reprojCoord.x < 0.0 / viewWidth 
		|| reprojCoord.x > 1.0 - 0.0 / viewWidth 
		|| reprojCoord.y < 0.0 / viewHeight 
		|| reprojCoord.y > 1.0 - 0.0 / viewHeight)
	{
		blendWeight = vec3(1.0);
		// prevColor.rgb = vec3(1.0, 0.0, 0.0);
		// color.rgb = vec3(1.0, 0.0, 0.0);
	}

	if (depth < 0.7)
	{
		blendWeight = vec3(0.1);
		colorWindow = 0.5;
	}

	// blendWeight = vec3(1.0);



	vec3 mu = m1 / c;
	vec3 sigma = sqrt(max(vec3(0.0), m2 / c - mu * mu));
	vec3 minc = mu - (colorWindow) * sigma;
	vec3 maxc = mu + (colorWindow) * sigma;



	//adaptive blur
	//color = mix(color, avgColor, vec3(0.25 - pixelErrorFactor * 0.25));



	//if (abs(ExpToLinearDepth(minDepth) - ExpToLinearDepth(prevMinDepth)) > 1.0 && abs(ExpToLinearDepth(depth) - ExpToLinearDepth(prevMinDepth)) > 1.0)
	//{
		//blendWeight = vec3(1.0);
	//}


	//adaptive sharpen
	vec3 sharpen = (vec3(1.0) - exp(-(color - avgColor) * 15.0)) * 0.06;
	vec3 sharpenX = (vec3(1.0) - exp(-(color - avgX) * 15.0)) * 0.06;
	vec3 sharpenY = (vec3(1.0) - exp(-(color - avgY) * 15.0)) * 0.06;
	color += sharpenX * (0.1 / blendWeight) * pixelErrorFactor.x;
	color += sharpenY * (0.1 / blendWeight) * pixelErrorFactor.y;


	// color += sharpen * 1.5;



	//color = mix(color, avgColor, vec3(0.5));
	//prevColor.rgb = vec3(0.01, 0.0, 0.0);

	prevColor.rgb = YUVToRGB(ClipAABB(minc, maxc, color.rgb, RGBToYUV(prevColor.rgb)));

	/*
	prevColor.rgb = clamp(prevColor.rgb, minColor, maxColor);


	if (prevColor.r < minColor.r || prevColor.r > maxColor.r ||
		prevColor.g < minColor.g || prevColor.g > maxColor.g ||
		prevColor.b < minColor.b || prevColor.b > maxColor.b )
	{
		//blendWeight = 1.0;
		vec3 difference = clamp((minColor - prevColor.rgb), vec3(0.0), vec3(10000.0));
			 difference += clamp((prevColor.rgb - maxColor), vec3(0.0), vec3(10000.0));

		//blendWeight += difference * 6000.0;
	}
	*/






	//blendWeight = mix(blendWeight, 1.0, clamp(motionVectorDiff * 40.0, 0.0, 1.0));

	blendWeight = clamp(blendWeight, vec3(0.0), vec3(1.0));

	if (depth < 0.7)
	{
		// blendWeight = vec3(1.0);
		// color = origColor;
	}


	vec3 taa = mix(prevColor.rgb, color, blendWeight);


	//taa.xy += pixelError * 0.01;


	//if (abs(ExpToLinearDepth(minDepth) - ExpToLinearDepth(prevMinDepth)) > 1.0 && abs(ExpToLinearDepth(depth) - ExpToLinearDepth(prevMinDepth)) > 1.0)
	//{
		//taa.r += 0.01;
	//}

	//taa.r += motionVectorDiff * 0.01;
	//taa.r += motionVectorDiff * 0.01;

	//taa = color;


	taa = pow(taa, vec3(1.0 / COLORPOW));




	// Average exposure exponential moving average
	vec2 pixelCoord = texcoord.st * vec2(viewWidth, viewHeight);
	if (distance(pixelCoord, vec2(0.0, 0.0)) < 1.0)
	{
		float avgExposure = AverageExposure() * 500.0;
		float prevAvgExposure = texture2DLod(gaux4, texcoord.st, 0).a;
		avgExposure = mix(prevAvgExposure, avgExposure, avgExposure > prevAvgExposure ? 0.025 : 0.1);
		// avgExposure = mix(prevAvgExposure, avgExposure, 0.0125);

		minDepth = avgExposure;
	}





	gl_FragData[0] = vec4(bloomColor.rgb, 1.0f);
	gl_FragData[1] = vec4(taa, minDepth);
	gl_FragData[2] = vec4(vec3(0.0), 1.0f);

}

/* DRAWBUFFERS:237 */
