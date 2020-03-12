#version 120

#define TORCHLIGHT_COLOR_TEMPERATURE 2300 // Color temperature of torch light in Kelvin. [2000 2300 2500 3000]


#include "Common.inc"


varying vec4 texcoord;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float rainStrength;
uniform vec3 skyColor;
uniform float sunAngle;

uniform int worldTime;

varying vec3 lightVector;
varying vec3 upVector;
varying vec3 sunVector;

varying float timeSunriseSunset;
varying float timeNoon;
varying float timeMidnight;
varying float timeSkyDark;

varying vec3 colorSunlight;
varying vec3 colorSkylight;
varying vec3 colorSunglow;
varying vec3 colorBouncedSunlight;
varying vec3 colorScatteredSunlight;
varying vec3 colorTorchlight;
varying vec3 colorWaterMurk;
varying vec3 colorWaterBlue;
varying vec3 colorSkyTint;

varying vec4 skySHR;
varying vec4 skySHG;
varying vec4 skySHB;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

varying vec3 worldLightVector;
varying vec3 worldSunVector;

uniform mat4 shadowModelViewInverse;

varying float nightDarkness;

varying float contextualFogFactor;

uniform float frameTimeCounter;

uniform sampler2D noisetex;


varying float heldLightBlacklist;

uniform int heldItemId;    

float CubicSmooth(in float x)
{
	return x * x * (3.0f - 2.0f * x);
}

float clamp01(float x)
{
	return clamp(x, 0.0, 1.0);
}

void ContextualFog(inout vec3 color, in vec3 viewPos, in vec3 viewDir, in vec3 lightDir, in vec3 skyLightColor, in vec3 sunLightColor, float density)
{
	float dist = length(viewPos);

	float fogDensity = density * 0.019;
		  fogDensity *= 1.0 -  saturate(viewDir.y * 0.5 + 0.5) * 0.72;
	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 2.0);
		  //fogFactor = 1.0 -  saturate(viewDir.y * 0.5 + 0.5);




	vec3 fogColor = pow(gl_Fog.color.rgb, vec3(2.2));


	float VdotL = dot(viewDir, lightDir);

	float g = 0.72;
				//float g = 0.9;
	float g2 = g * g;
	float theta = VdotL * 0.5 + 0.5;
	float anisoFactor = 1.5 * ((1.0 - g2) / (2.0 + g2)) * ((1.0 + theta * theta) / (1.0 + g2 - 2.0 * g * theta)) + g * theta;


	float skyFactor = pow(saturate(viewDir.y * 0.5 + 0.5), 1.5);
		  //skyFactor = skyFactor * (3.0 - 2.0 * skyFactor);

	fogColor = sunLightColor * anisoFactor * 1.0 + skyFactor * skyLightColor * 1.0;

	fogColor *= exp(-density * 1.5) * 2.0;

	color = mix(color, fogColor, fogFactor);

}

void DoNightEye(inout vec3 color)
{
	float luminance = Luminance(color);

	color = mix(color, luminance * vec3(0.2, 0.4, 0.9), vec3(0.8));
}

void main() 
{
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;


	heldLightBlacklist = 1.0;

	//Calculate ambient light from atmospheric scattering
	//worldSunVector = normalize((gbufferModelViewInverse * vec4(sunVector, 0.0)).xyz);
	//worldLightVector = normalize((gbufferModelViewInverse * vec4(lightVector, 0.0)).xyz);
	worldSunVector = normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
	worldLightVector = worldSunVector;

	sunVector = normalize((gbufferModelView * vec4(worldSunVector.xyz, 0.0)).xyz);
	lightVector = sunVector;

	if (sunAngle < 0.5f) 
	{
		//lightVector = normalize(sunPosition);
	} 
	else 
	{
		//lightVector = normalize(moonPosition);
		//lightVector *= -1.0;
		//worldLightVector *= -1.0;
		worldSunVector *= -1.0;
		sunVector *= -1.0;
	}

	//sunVector = normalize(sunPosition);

	//upVector = normalize(upPosition);

	upVector = normalize((gbufferModelView * vec4(0.0, 1.0, 0.0, 0.0)).xyz);


	if (
		heldItemId == 344
		|| heldItemId == 423
		|| heldItemId == 413
		|| heldItemId == 411
		)
	{
		heldLightBlacklist = 0.0;
	}



	
	nightDarkness = 0.003;


	float timePow = 6.0f;

	float LdotUp = dot(upVector, sunVector);
	float LdotDown = dot(-upVector, sunVector);

	timeNoon = 1.0 - pow(1.0 - clamp01(LdotUp), timePow);
	timeSunriseSunset = 1.0 - timeNoon;
	timeMidnight = CubicSmooth(CubicSmooth(clamp01(LdotDown * 20.0f + 0.4)));
	timeMidnight = 1.0 - pow(1.0 - timeMidnight, 2.0);
	timeSunriseSunset *= 1.0 - timeMidnight;
	timeNoon *= 1.0 - timeMidnight;

	// timeSkyDark = clamp01(LdotDown);
	// timeSkyDark = pow(timeSkyDark, 3.0f);
	timeSkyDark = 0.0f;


	float horizonTime = CubicSmooth(clamp01((1.0 - abs(LdotUp)) * 7.0f - 6.0f));
	
	const float rayleigh = 0.02f;


	colorWaterMurk = vec3(0.2f, 0.5f, 0.95f);
	colorWaterBlue = vec3(0.2f, 0.5f, 0.95f);
	colorWaterBlue = mix(colorWaterBlue, vec3(1.0f), vec3(0.5f));

/*
	
	const int numRays = 32;

	const float phi = 1.618033988;
	const float gAngle = phi * 3.14159265 * 1.0003;

	vec4 shR = vec4(0.0);
	vec4 shG = vec4(0.0);
	vec4 shB = vec4(0.0);

	for (int i = 0; i < numRays; i++)
	{
		float fi = float(i);
		float fiN = fi / float(numRays);
		float lon = gAngle * fi * 6.0;
		float lat = asin(fiN * 2.0 - 1.0);

		vec3 kernel;
		kernel.x = cos(lat) * cos(lon);
		kernel.z = cos(lat) * sin(lon);
		kernel.y = sin(lat);

		kernel = normalize(kernel + vec3(0.0, 1.00, 0.0));

		//kernel = vec3(0.0, 1.0, 0.0);

		vec3 biasedKernel = vec3(kernel.x, kernel.y, kernel.z);

		vec3 skyCol = AtmosphericScattering(biasedKernel, worldSunVector, 0.0);
		skyCol = pow(skyCol, vec3(1.0));

		float contribution = saturate(kernel.y);

		//skyCol *= contribution;

		//skyCol = vec3(1.0, 1.0, 1.0);

		skyCol *= 0.5;

		shR += ToSH(skyCol.r, kernel);
		shG += ToSH(skyCol.g, kernel);
		shB += ToSH(skyCol.b, kernel);

		shR += ToSH(skyCol.r, kernel * vec3(-1.0, 1.0, -1.0));
		shG += ToSH(skyCol.g, kernel * vec3(-1.0, 1.0, -1.0));
		shB += ToSH(skyCol.b, kernel * vec3(-1.0, 1.0, -1.0));
	}
	
	shR /= numRays;
	shG /= numRays;
	shB /= numRays;

	skySHR = shR;
	skySHG = shG;
	skySHB = shB;
*/


	vec3 skyTint = vec3(1.0);
	float skyTintAmount = abs(skyColor.r - (116.0 / 255.0)) + abs(skyColor.g - (172.0 / 255.0)) + abs(skyColor.b - (255.0 / 255.0));
	//skyTint = mix(vec3(1.0), skyColor, saturate(skyTintAmount));
	contextualFogFactor = clamp(skyTintAmount * 3.0, 0.0, 1.0) * 0.5;
	contextualFogFactor = 0.0;

	//float randomFog = texture2D(noisetex, vec2(frameTimeCounter * 0.01, 0.0)).x;
	//randomFog = saturate(randomFog * 1.5 - 0.5);
	//randomFog = pow(randomFog, 1.0);
	//contextualFogFactor += randomFog;

	//contextualFogFactor = (sin(frameTimeCounter * 0.8) * 0.5 + 0.5) * 1.0;

	//contextualFogFactor *= 10.0;




	colorSunlight = AtmosphericScatteringSingle(worldSunVector, worldSunVector, 1.0) * 0.2;
	colorSunlight = normalize(colorSunlight + 0.001);

	colorSunlight *= pow(saturate(worldSunVector.y), 0.9);
	
	colorSunlight *= 1.0f - horizonTime;



	vec3 moonlight = AtmosphericScattering(-worldSunVector, -worldSunVector, 1.0);
	moonlight = normalize(moonlight + 0.0001);
	moonlight *= pow(saturate(-worldSunVector.y), 0.9);
	moonlight *= nightDarkness * 0.5;



	colorSkylight = vec3(0.0);

///*
	const int latSamples = 5;
	const int lonSamples = 5;

	vec4 shR = vec4(0.0);
	vec4 shG = vec4(0.0);
	vec4 shB = vec4(0.0);

	for (int i = 0; i < latSamples; i++)
	{
		float latitude = (float(i) / float(latSamples)) * 3.14159265;
			  latitude = latitude;
		for (int j = 0; j < lonSamples; j++)
		{
			float longitude = (float(j) / float(lonSamples)) * 3.14159265 * 2.0;
			//longitude = longitude * 0.5 + 0.5;

			vec3 kernel;
			kernel.x = cos(latitude) * cos(longitude);
			kernel.z = cos(latitude) * sin(longitude);
			kernel.y = sin(latitude);

			vec3 skyCol = AtmosphericScattering(kernel, worldSunVector, 0.1);


//void ContextualFog(inout vec3 color, in vec3 viewPos, in vec3 viewDir, in vec3 lightDir, in vec3 skyLightColor, in vec3 sunLightColor, float density)
			ContextualFog(skyCol, kernel * 1670.0, kernel, worldSunVector, skyCol, colorSunlight * 1.0, contextualFogFactor);

			//skyCol = vec3(1.0, 1.0, 1.0);
			//skyCol *= skyTint;

			vec3 moonAtmosphere = AtmosphericScattering(kernel, -worldSunVector, 1.0);
			DoNightEye(moonAtmosphere);

			skyCol += moonAtmosphere * nightDarkness;

			colorSkylight += skyCol;

			//skyCol *= 0.5;

			shR += ToSH(skyCol.r, kernel);
			shG += ToSH(skyCol.g, kernel);
			shB += ToSH(skyCol.b, kernel);

			//shR += ToSH(skyCol.r, kernel * vec3(-1.0, 1.0, -1.0));
			//shG += ToSH(skyCol.g, kernel * vec3(-1.0, 1.0, -1.0));
			//shB += ToSH(skyCol.b, kernel * vec3(-1.0, 1.0, -1.0));


		}
	}

	colorSkylight /= latSamples * lonSamples;

	DoNightEye(moonlight);

	colorSunlight += moonlight;


	shR /= latSamples * lonSamples;
	shG /= latSamples * lonSamples;
	shB /= latSamples * lonSamples;

	//float ambientMie = 0.01;
	//shR += ToSH(colorSunlight.r * ambientMie, worldSunVector);
	//shG += ToSH(colorSunlight.g * ambientMie, worldSunVector);
	//shB += ToSH(colorSunlight.b * ambientMie, worldSunVector);

	skySHR = shR;
	skySHG = shG;
	skySHB = shB;
//*/


	



//colors for shadows/sunlight and sky
	
	/*


	vec3 sunrise_sun;
	 sunrise_sun.r = 1.00;
	 sunrise_sun.g = 0.58;
	 sunrise_sun.b = 0.00;
	 sunrise_sun *= 0.65f;
	
	vec3 sunrise_amb;
	 sunrise_amb.r = 0.30 ;
	 sunrise_amb.g = 0.595;
	 sunrise_amb.b = 0.70 ;	
	 sunrise_amb *= 1.0f;
	 
	
	vec3 noon_sun;
	 noon_sun.r = mix(1.00, 1.00, rayleigh);
	 noon_sun.g = mix(1.00, 0.75, rayleigh);
	 noon_sun.b = mix(1.00, 0.00, rayleigh);	 
	
	vec3 noon_amb;
	 noon_amb.r = 0.00 ;
	 noon_amb.g = 0.3  ;
	 noon_amb.b = 0.999;
	
	// vec3 sunset_sun;
	//  sunset_sun.r = 1.0 ;
	//  sunset_sun.g = 0.58;
	//  sunset_sun.b = 0.0 ;
	//  sunset_sun *= 0.65f;
	
	// vec3 sunset_amb;
	//  sunset_amb.r = 1.0;
	//  sunset_amb.g = 0.0;
	//  sunset_amb.b = 0.0;	
	//  sunset_amb *= 1.0f;
	
	vec3 midnight_sun;
	 midnight_sun.r = 1.0;
	 midnight_sun.g = 1.0;
	 midnight_sun.b = 1.0;
	
	vec3 midnight_amb;
	 midnight_amb.r = 0.0 ;
	 midnight_amb.g = 0.23;
	 midnight_amb.b = 0.99;


	colorSunlight = sunrise_sun * timeSunriseSunset  +  noon_sun * timeNoon  +  midnight_sun * timeMidnight;



	sunrise_amb = vec3(0.19f, 0.35f, 0.7f) * 0.15f;
	noon_amb    = vec3(0.15f, 0.29f, 0.99f);
	midnight_amb = vec3(0.005f, 0.01f, 0.02f) * 0.025f;
	
	colorSkylight = sunrise_amb * timeSunriseSunset  +  noon_amb * timeNoon  +  midnight_amb * timeMidnight;

	vec3 colorSunglow_sunrise;
	 colorSunglow_sunrise.r = 1.00f * timeSunriseSunset;
	 colorSunglow_sunrise.g = 0.46f * timeSunriseSunset;
	 colorSunglow_sunrise.b = 0.00f * timeSunriseSunset;
	 
	vec3 colorSunglow_noon;
	 colorSunglow_noon.r = 1.0f * timeNoon;
	 colorSunglow_noon.g = 1.0f * timeNoon;
	 colorSunglow_noon.b = 1.0f * timeNoon;
	 
	vec3 colorSunglow_midnight;
	 colorSunglow_midnight.r = 0.05f * 0.8f * 0.0055f * timeMidnight;
	 colorSunglow_midnight.g = 0.20f * 0.8f * 0.0055f * timeMidnight;
	 colorSunglow_midnight.b = 0.90f * 0.8f * 0.0055f * timeMidnight;
	
	 colorSunglow = colorSunglow_sunrise + colorSunglow_noon + colorSunglow_midnight;
	 
	 
	 
	
	 //colorBouncedSunlight = mix(vec3(0.64f, 0.73f, 0.34f), colorBouncedSunlight, 0.5f);
	 //colorBouncedSunlight = colorSunlight;
	 
	//colorSkylight.g *= 0.95f;
	 
	 //colorSkylight = mix(colorSkylight, vec3(dot(colorSkylight, vec3(1.0))), SKY_DESATURATION);
	 
	 float sun_fill = 0.0;
	
	 //colorSkylight = mix(colorSkylight, colorSunlight, sun_fill);
	 vec3 colorSkylight_rain = vec3(2.0, 2.0, 2.38) * 0.25f * (1.0f - timeMidnight * 0.9995f); //rain
	 colorSkylight = mix(colorSkylight, colorSkylight_rain, rainStrength); //rain
	

				
	//Saturate sunlight colors
	colorSunlight = pow(colorSunlight, vec3(2.2f));
	
	colorSunlight *= 1.0f - horizonTime;
	
	
	 colorBouncedSunlight = mix(colorSunlight, colorSkylight, 0.15f);
	 
	 colorScatteredSunlight = mix(colorSunlight, colorSkylight, 0.15f);

	 colorSunglow = pow(colorSunglow, vec3(2.5f));
	 
	//colorSunlight = vec3(1.0f, 0.5f, 0.0f);

	//Make ambient light darker when not day time
	// colorSkylight = mix(colorSkylight, colorSkylight * 0.03f, timeSunrise);
	// colorSkylight = mix(colorSkylight, colorSkylight * 1.0f, timeNoon);
	// colorSkylight = mix(colorSkylight, colorSkylight * 0.3f, timeSunset);
	// colorSkylight = mix(colorSkylight, colorSkylight * 0.0080f, timeMidnight);
	// colorSkylight *= mix(1.0f, 0.001f, timeMidnightLin);
	// colorSkylight *= mix(1.0f, 0.001f, timeSunriseLin);
	//colorSkylight = vec3(0.3f) * vec3(0.17f, 0.37f, 0.8f);

	// colorSkylight = vec3(0.0f, 0.0f, 1.0f);
	// colorSunlight = vec3(1.0f, 1.0f, 0.0f); //fuf
	
	//Make sunlight darker when not day time
	colorSunlight = mix(colorSunlight, colorSunlight * 0.5f, timeSunriseSunset);
	colorSunlight = mix(colorSunlight, colorSunlight * 1.0f, timeNoon);
	colorSunlight = mix(colorSunlight, colorSunlight * 0.00020f, timeMidnight);
	
	//Make reflected light darker when not day time
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.5f, timeSunriseSunset);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 1.0f, timeNoon);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.000015f, timeMidnight);
	
	//Make scattered light darker when not day time
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.5f, timeSunriseSunset);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 1.0f, timeNoon);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.000015f, timeMidnight);

	//Make scattered light darker when not day time
	// colorSkyTint = mix(colorSkyTint, colorSkyTint * 0.5f, timeSunrise);
	// colorSkyTint = mix(colorSkyTint, colorSkyTint * 1.0f, timeNoon);
	// colorSkyTint = mix(colorSkyTint, colorSkyTint * 0.5f, timeSunset);
	// colorSkyTint = mix(colorSkyTint, colorSkyTint * 0.0045f, timeMidnight);
	


	float colorSunlightLum = colorSunlight.r + colorSunlight.g + colorSunlight.b;
		  colorSunlightLum /= 3.0f;

	colorSunlight = mix(colorSunlight, vec3(colorSunlightLum), vec3(rainStrength));



*/





	
	//Torchlight color
	//colorTorchlight = vec3(1.00f, 0.30f, 0.00f);
	//colorTorchlight = vec3(1.0f, 0.5, 0.1);

	if (TORCHLIGHT_COLOR_TEMPERATURE == 2000)
		//2000k
		colorTorchlight = pow(vec3(255, 141, 11) / 255.0, vec3(2.2));
	else if (TORCHLIGHT_COLOR_TEMPERATURE == 2300)
		//2300k
		colorTorchlight = pow(vec3(255, 152, 54) / 255.0, vec3(2.2));
	else if (TORCHLIGHT_COLOR_TEMPERATURE == 2500)
		//2500k
		colorTorchlight = pow(vec3(255, 166, 69) / 255.0, vec3(2.2));
	else
		//3000k
		colorTorchlight = pow(vec3(255, 180, 107) / 255.0, vec3(2.2));


	// colorTorchlight = vec3(1.0);
	// colorTorchlight = vec3(0.5, 0.01, 1.0) * 0.7 + 0.1;

	//2000k
	//colorTorchlight = pow(vec3(255, 141, 11) / 255.0, vec3(2.2));

	//2200k
	//colorTorchlight = pow(vec3(255, 147, 44) / 255.0, vec3(2.2));

	//2500k
	//colorTorchlight = pow(vec3(255, 166, 69) / 255.0, vec3(2.2));

	//3000k
	//colorTorchlight = pow(vec3(255, 180, 107) / 255.0, vec3(2.2));




	//colorSkylight = vec3(0.1f);
	
}
