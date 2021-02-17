#version 120

/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////ADJUSTABLE VARIABLES//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define SKY_DESATURATION 0.0f

#define NIGHT_LIGHT 0.3			// increase for brighter nights 0.00015 is default, best is 0.15 for brighter night

/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////


varying vec4 texcoord;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float rainStrength;

uniform int worldTime;

varying vec3 lightVector;
varying vec3 upVector;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
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


void main() {
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;

	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}

	upVector = normalize(upPosition);
	
	
	float timePow = 2.0f;
	float timefract = worldTime;
	
	timeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));  
	timeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
	timeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);  
	timeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
	timeSkyDark = ((clamp(timefract, 12000.0, 16000.0) - 12000.0) / 4000.0) - ((clamp(timefract, 22000.0, 24000.0) - 22000.0) / 2000.0);
	timeSkyDark = pow(timeSkyDark, 3.0f);
	
	timeSunrise  = pow(timeSunrise, 1.0f);
	timeNoon     = pow(timeNoon, 1.0f/timePow);
	timeSunset   = pow(timeSunset, 1.0f);
	timeMidnight = pow(timeMidnight, 1.0f/timePow);
	
	const float rayleigh = 0.1f;


	colorWaterMurk = vec3(0.2f, 1.0f, 0.95f);
	colorWaterBlue = vec3(0.2f, 1.0f, 0.95f);
	colorWaterBlue = mix(colorWaterBlue, vec3(1.0f), vec3(0.5f));

//colors for shadows/sunlight and sky
	
	vec3 sunrise_sun;
	 sunrise_sun.r = 1.00 * timeSunrise;
	 sunrise_sun.g = 0.56 * timeSunrise;
	 sunrise_sun.b = 0.00 * timeSunrise;
	 sunrise_sun *= 0.45f;
	
	vec3 sunrise_amb;
	 sunrise_amb.r = 0.85 * timeSunrise;
	 sunrise_amb.g = 0.40 * timeSunrise;
	 sunrise_amb.b = 0.95 * timeSunrise;	
	 sunrise_amb = mix(sunrise_amb, vec3(1.0f), 0.2f);
	 
	
	vec3 noon_sun;
	 noon_sun.r = mix(1.00, 1.00, rayleigh) * timeNoon;
	 noon_sun.g = mix(1.00, 0.48, rayleigh) * timeNoon;
	 noon_sun.b = mix(1.00, 0.00, rayleigh) * timeNoon;	 
	
	vec3 noon_amb;
	 noon_amb.r = 0.00 * timeNoon * 1.0;
	 noon_amb.g = 0.23 * timeNoon * 1.0;
	 noon_amb.b = 0.999 * timeNoon * 1.0;
	
	vec3 sunset_sun;
	 sunset_sun.r = 1.0 * timeSunset;
	 sunset_sun.g = 0.48 * timeSunset;
	 sunset_sun.b = 0.0 * timeSunset;
	 sunset_sun *= 0.55f;
	
	vec3 sunset_amb;
	 sunset_amb.r = 0.752 * timeSunset;
	 sunset_amb.g = 0.427 * timeSunset;
	 sunset_amb.b = 0.700 * timeSunset;
	
	vec3 midnight_sun;
	 midnight_sun.r = 0.45 * timeMidnight;
	 midnight_sun.g = 0.6 * timeMidnight;
	 midnight_sun.b = 0.8 * timeMidnight;
	 midnight_sun *= 0.07f;
	
	vec3 midnight_amb;
	 midnight_amb.r = 0.0 * timeMidnight;
	 midnight_amb.g = 0.23 * timeMidnight;
	 midnight_amb.b = 0.99 * timeMidnight;
	 midnight_amb *= 0.04f;


	colorSunlight;
	 colorSunlight.r = sunrise_sun.r + noon_sun.r + sunset_sun.r + midnight_sun.r;
	 colorSunlight.g = sunrise_sun.g + noon_sun.g + sunset_sun.g + midnight_sun.g;
	 colorSunlight.b = sunrise_sun.b + noon_sun.b + sunset_sun.b + midnight_sun.b;
	
	colorSkylight;
	 colorSkylight.r = sunrise_amb.r + noon_amb.r + sunset_amb.r + midnight_amb.r;
	 colorSkylight.g = sunrise_amb.g + noon_amb.g + sunset_amb.g + midnight_amb.g;
	 colorSkylight.b = sunrise_amb.b + noon_amb.b + sunset_amb.b + midnight_amb.b;
	 
	 
	vec3 colorSunglow_sunrise;
	 colorSunglow_sunrise.r = 1.00f * timeSunrise;
	 colorSunglow_sunrise.g = 0.46f * timeSunrise;
	 colorSunglow_sunrise.b = 0.00f * timeSunrise;
	 
	vec3 colorSunglow_noon;
	 colorSunglow_noon.r = 1.0f * timeNoon;
	 colorSunglow_noon.g = 1.0f * timeNoon;
	 colorSunglow_noon.b = 1.0f * timeNoon;
	 
	vec3 colorSunglow_sunset;
	 colorSunglow_sunset.r = 1.00f * timeSunset;
	 colorSunglow_sunset.g = 0.38f * timeSunset;
	 colorSunglow_sunset.b = 0.00f * timeSunset;
	 
	vec3 colorSunglow_midnight;
	 colorSunglow_midnight.r = 0.05f * 0.8f * 0.0055f * timeMidnight;
	 colorSunglow_midnight.g = 0.20f * 0.8f * 0.0055f * timeMidnight;
	 colorSunglow_midnight.b = 0.90f * 0.8f * 0.0055f * timeMidnight;
	
	 colorSunglow = colorSunglow_sunrise + colorSunglow_noon + colorSunglow_sunset + colorSunglow_midnight;
	 
	 
	 
	
	 //colorBouncedSunlight = mix(vec3(0.64f, 0.73f, 0.34f), colorBouncedSunlight, 0.5f);
	 //colorBouncedSunlight = colorSunlight;
	 
	colorSkylight.g *= 0.95f;
	 
	 colorSkylight = mix(colorSkylight, vec3(dot(colorSkylight, vec3(1.0))), SKY_DESATURATION);
	 
	 float sun_fill = 0.01f;
	
	 colorSkylight = mix(colorSkylight, colorSunlight, sun_fill);
	 vec3 colorSkylight_rain = vec3(2.0, 2.0, 2.38) * 0.35f * (1.0f - timeMidnight * 0.009995f); //rain
	 colorSkylight = mix(colorSkylight, colorSkylight_rain, rainStrength); //rain
	

				
	//Saturate sunlight colors
	colorSunlight = pow(colorSunlight, vec3(2.0f));
	
	
	 colorBouncedSunlight = mix(colorSunlight, colorSkylight, 0.15f);
	 
	 colorScatteredSunlight = mix(colorSunlight, colorSkylight, 0.15f);

	 colorSunglow = pow(colorSunglow, vec3(2.5f));
	 
	//colorSunlight = vec3(1.0f, 0.5f, 0.0f);
	
	//Make ambient light darker when not day time
	colorSkylight = mix(colorSkylight, colorSkylight * 0.5f, timeSunrise);
	colorSkylight = mix(colorSkylight, colorSkylight * 1.0f, timeNoon);
	colorSkylight = mix(colorSkylight, colorSkylight * 1.5f, timeSunset);
	colorSkylight = mix(colorSkylight, colorSkylight * 0.0010f, timeMidnight);

	// colorSkylight = vec3(0.0f, 0.0f, 1.0f);
	// colorSunlight = vec3(1.0f, 1.0f, 0.0f); //fuf
	
	//Make sunlight darker when not day time
	colorSunlight = mix(colorSunlight, colorSunlight * 1.0f, timeSunrise);
	colorSunlight = mix(colorSunlight, colorSunlight * 1.0f, timeNoon);
	colorSunlight = mix(colorSunlight, colorSunlight * 2.0f, timeSunset);
	colorSunlight = mix(colorSunlight, colorSunlight * NIGHT_LIGHT, timeMidnight);
	
	//Make reflected light darker when not day time
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.5f, timeSunrise);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 1.0f, timeNoon);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.5f, timeSunset);
	colorBouncedSunlight = mix(colorBouncedSunlight, colorBouncedSunlight * 0.00015f, timeMidnight);
	
	//Make scattered light darker when not day time
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.5f, timeSunrise);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 1.0f, timeNoon);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.5f, timeSunset);
	colorScatteredSunlight = mix(colorScatteredSunlight, colorScatteredSunlight * 0.00015f, timeMidnight);
	


	float colorSunlightLum = colorSunlight.r + colorSunlight.g + colorSunlight.b;
		  colorSunlightLum /= 3.0f;

	colorSunlight = mix(colorSunlight, vec3(colorSunlightLum), vec3(rainStrength));
	
	//Torchlight color
	float torchWhiteBalance = 0.02f;
	colorTorchlight = vec3(1.00f, 0.22f, 0.00f);
	colorTorchlight = mix(colorTorchlight, vec3(1.0f), vec3(torchWhiteBalance));

	colorTorchlight = pow(colorTorchlight, vec3(0.99f));
	
}
