#include "DataPacking.inc"


// #define PHYSICALLY_BASED_MAX_ROUGHNESS // If disabled, materials that are 100% rough will have zero specular highlights (legacy SEUS behavior). If enabled, even 100% rough materials still show some subtle specular highlights. This can cause slowdown if "Full Raytrace Reflections" is on!
#define SUNLIGHT_LEAK_FIX // Fixes light leaking in caves. May cause issues with large outdoor overhanging structures!


float saturate(float x)
{
	return clamp(x, 0.0, 1.0);
}

vec3 saturate(vec3 x)
{
	return clamp(x, vec3(0.0), vec3(1.0));
}

vec2 saturate(vec2 x)
{
	return clamp(x, vec2(0.0), vec2(1.0));
}

vec3 nozero(vec3 x)
{
	if (abs(x.x) < 0.001)
		x.x = 0.001;

	if (abs(x.y) < 0.001)
		x.y = 0.001;

	if (abs(x.z) < 0.001)
		x.z = 0.001;

	return x;
}

vec2 EncodeNormal(vec3 normal)
{
	float p = sqrt(normal.z * 8.0 + 8.0);
	return vec2(normal.xy / p + 0.5);
}

vec3 DecodeNormal(vec2 enc)
{
	vec2 fenc = enc * 4.0 - 2.0;
	float f = dot(fenc, fenc);
	float g = sqrt(1.0 - f / 4.0);
	vec3 normal;
	normal.xy = fenc * g;
	normal.z = 1.0 - f / 2.0;
	return normal;
}





vec4 SampleLinear(sampler2D tex, vec2 coord)
{
	return pow(texture2D(tex, coord), vec4(2.2));
}

vec3 LinearToGamma(vec3 c)
{
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c)
{
	return pow(c, vec3(2.2));
}

float curve(float x)
{
	return x * x * (3.0 - 2.0 * x);
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

vec3 rand(vec2 coord)
{
	float noiseX = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223))) * 43758.5453));
	float noiseY = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*2.0)) * 43758.5453));
	float noiseZ = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*3.0)) * 43758.5453));

	return vec3(noiseX, noiseY, noiseZ);
}


vec4 ToSH(float value, vec3 dir)
{
	const float PI = 3.14159265359;
	const float N1 = sqrt(4 * PI / 3);
	const float transferl1 = (sqrt(PI) / 3.0) * N1;
	const float transferl0 = PI;

	const float sqrt1OverPI = sqrt(1.0 / PI);
	const float sqrt3OverPI = sqrt(3.0 / PI);

	vec4 coeffs;

	coeffs.x = 0.5 * sqrt1OverPI * value * transferl0;
	coeffs.y = -0.5 * sqrt3OverPI * dir.y * value * transferl1;
	coeffs.z = 0.5 * sqrt3OverPI * dir.z * value * transferl1;
	coeffs.w = -0.5 * sqrt3OverPI * dir.x * value * transferl1; //TODO: Vectorize the math so it's faster

	return coeffs;
}


vec3 FromSH(vec4 cR, vec4 cG, vec4 cB, vec3 lightDir)
{
	const float PI = 3.14159265;

	const float N1 = sqrt(4 * PI / 3);
	const float transferl1 = (sqrt(PI) / 3.0) * N1;
	const float transferl0 = PI;

	const float sqrt1OverPI = sqrt(1.0 / PI);
	const float sqrt3OverPI = sqrt(3.0 / PI);

	vec4 sh;

	sh.x = 0.5 * sqrt1OverPI;
	sh.y = -0.5 * sqrt3OverPI * lightDir.y;
	sh.z = 0.5 * sqrt3OverPI * lightDir.z;
	sh.w = -0.5 * sqrt3OverPI * lightDir.x;

	vec3 result;
	result.r = sh.x * cR.x;
	result.r += sh.y * cR.y;
	result.r += sh.z * cR.z;
	result.r += sh.w * cR.w;

	result.g = sh.x * cG.x;
	result.g += sh.y * cG.y;
	result.g += sh.z * cG.z;
	result.g += sh.w * cG.w;

	result.b = sh.x * cB.x;
	result.b += sh.y * cB.y;
	result.b += sh.z * cB.z;
	result.b += sh.w * cB.w;

	return result.rgb;
}



vec3 DoNightEyeAtNight(in vec3 color, float timeFactor)
{
	float luminance = Luminance(color);

	float rodFactor = 1.0f / (luminance * 1000.0 + 1.0);

	color = mix(color, luminance * vec3(0.2, 0.4, 0.9) * 1.5, vec3(0.6 * rodFactor * timeFactor));

	return color;
}















//x is distance to outer surface, y is distance to inner surface
vec2 RaySphereIntersection( vec3 p, vec3 dir, float r ) 
{
	float b = dot( p, dir );
	float c = dot( p, p ) - r * r;
	
	float d = b * b - c;
	if ( d < 0.0 ) 
	{
		return vec2( 10000.0, -10000.0 );
	}

	d = sqrt( d );
	
	return vec2( -b - d, -b + d );
}


#define R_INNER 0.985

// Mie
// g : ( -0.75, -0.999 )
//      3 * ( 1 - g^2 )               1 + c^2
// F = ----------------- * -------------------------------
//      2 * ( 2 + g^2 )     ( 1 + g^2 - 2 * g * c )^(3/2)
float phase_mie( float g, float c, float cc ) {
	float gg = g * g;
	
	float a = ( 1.0 - gg ) * ( 1.0 + cc );

	float b = 1.0 + gg - 2.0 * g * c;
	b *= sqrt( b );
	b *= 2.0 + gg;	
	
	return 1.5 * a / b;
}

// Reyleigh
// g : 0
// F = 3/4 * ( 1 + c^2 )
float phase_reyleigh( float cc ) 
{
	return 0.75 * ( 1.0 + cc );
}

float density( vec3 p )
{
	const float R = 1.0;
	const float SCALE_H = 4.0 / ( R - R_INNER );
	const float SCALE_L = 1.0 / ( R - R_INNER );

	return exp( -( length( p ) - R_INNER ) * SCALE_H ) * 2.0;
}

float optic( vec3 p, vec3 q ) 
{
	const int numOutscatter = 1;

	const float R = 1.0;
	const float SCALE_L = 1.0 / (R - R_INNER);

	vec3 step = ( q - p ) / float(numOutscatter);
	step *= 0.3;
	vec3 v = p + step * 0.5;
	
	float sum = 0.0;
	for ( int i = 0; i < numOutscatter; i++ ) 
	{
		sum += density( v );
		v += step;
	}
	sum *= length( step ) * SCALE_L;


	return sum;
}

vec3 in_scatter(vec3 rayOrigin, vec3 rayDir, vec2 originToSkyIntersection, vec3 lightVector, float mieAmount, float rayleighAmount) 
{
	const float numInscatter = 3;
	
	const float PI = 3.14159265359;

	const float R = 1.0;
	const float SCALE_L = 1.0 / (R - R_INNER);

	float K_R = 0.186 * rayleighAmount;
	float K_M = 0.025 * mieAmount;
	const float E = 27.0;
	const vec3 C_R = vec3(0.4, 0.6, 1.0);	//Rayleigh scattering coefficients
	const float G_M = -0.75;


	float rayStepSize = (originToSkyIntersection.y * (1.0)) / float(numInscatter);
	vec3 step = rayDir * rayStepSize;
	step *= 2.0;

	//float boosty = 1.0 - abs(l.y);
	

	vec3 skyRayPos = rayOrigin + rayDir * ( rayStepSize * (0.5) );



	vec3 sum = vec3( 0.0 );
	for ( int i = 0; i < numInscatter; i++ ) 
	{
		vec2 atmosphereIntersection = RaySphereIntersection( skyRayPos, lightVector, R );
		vec3 outerAtmospherePos = skyRayPos + lightVector * atmosphereIntersection.y;
		
		float n = ( optic( rayOrigin, skyRayPos ) + optic( skyRayPos, outerAtmospherePos ) ) * ( PI * 4.0 );
		
		sum += density( skyRayPos ) * exp( -n * ( K_R * C_R ) );

		skyRayPos += step;
	}
	sum *= rayStepSize * SCALE_L;
	
	float c  = dot( rayDir, -lightVector );
	float cc = c * c;
	
	return sum * ( K_R * C_R * phase_reyleigh( cc ) + K_M * phase_mie( G_M, c, cc ) ) * E;
}



vec3 AtmosphericScattering(vec3 rayDir, vec3 lightVector, float mieAmount)
{
	const float R = 1.0;

	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	vec3 originalRayDir = rayDir;

	if (rayDir.y < 0.0)
	{
		//rayDir.y = abs(rayDir.y);
		//rayDir.y *= rayDir.y;
		rayDir.y = 0.0;
		// rayDir.y *= -0.5;
	}
	rayDir.y = mix(rayDir.y, 1.0, 0.03);

	vec2 e = RaySphereIntersection(eye, rayDir, R);


	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount, 1.0);

	// float secondaryLightFactor = lightVector.y < 0.0 ? lightVector.y * 1.5 : lightVector.y;
	float secondaryLightFactor = lightVector.y;
	float secondary = pow(clamp(secondaryLightFactor, -1.0, 0.3) * 0.5 + 0.5, 8.0);
	// secondary *= 20.0 / (rayDir.y * 3.0 + 1.2);
	secondary *= 10.0;
	vec3 ambient = vec3(0.3, 0.5, 1.0);
	atmosphere += secondary * ambient;


	atmosphere *= vec3(0.5, 0.75, 1.0);
	// atmosphere *= vec3(0.6, 0.75, 1.0);

	// atmosphere *= exp(-0.5 * vec3(0.2, 0.45, 1.0));

	return atmosphere;
}

vec3 ModulateSkyForRain(vec3 skyColor, vec3 colorSkylight, float rainStrength)
{
	skyColor = mix(skyColor, vec3(1.0) * Luminance(colorSkylight), vec3(rainStrength * 0.95));

	return skyColor;
}

vec3 AtmosphericScattering(vec3 rayDir, vec3 lightVector, float mieAmount, float depth)
{
	const float R = 1.0;

	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	vec3 originalRayDir = rayDir;

	if (rayDir.y < 0.0)
	{
		//rayDir.y = abs(rayDir.y);
		//rayDir.y *= rayDir.y;
		rayDir.y = 0.0;
	}

	vec3 up = vec3(0.0, 1.0, 0.0);

	vec2 e = RaySphereIntersection(eye, rayDir, R);
	e.y = depth;


	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount, 1.0);

	// float secondaryLightFactor = lightVector.y < 0.0 ? lightVector.y * 1.5 : lightVector.y;
	float secondaryLightFactor = lightVector.y;
	float secondary = pow(clamp(secondaryLightFactor, -1.0, 0.3) * 0.5 + 0.5, 8.0) * depth;
	secondary *= 10.0 / (rayDir.y * 3.0 + 1.2);
	vec3 ambient = vec3(0.3, 0.5, 1.0);
	atmosphere += secondary * ambient;


	atmosphere *= vec3(0.5, 0.75, 1.0);
	// atmosphere *= vec3(0.6, 0.75, 1.0);

	// atmosphere *= exp(-0.5 * vec3(0.2, 0.45, 1.0));






	return atmosphere;
}

vec3 AtmosphericScatteringSingle(vec3 rayDir, vec3 lightVector, float mieAmount)
{
	const float PI = 3.14159265359;
	const float DEG_TO_RAD = PI / 180.0;

	//Scatter constants
	const float K_R = 0.166;
	const float K_M = 0.0025;
	const float E = 14.3;
	const vec3 C_R = vec3(0.3, 0.7, 1.0);	//Rayleigh scattering coefficients
	const float G_M = -0.85;

	const float R = 1.0;
	const float SCALE_H = 4.0 / (R - R_INNER);
	const float SCALE_L = 1.0 / (R - R_INNER);

	const int NUM_OUT_SCATTER = 10;
	const float FNUM_OUT_SCATTER = 10.0;

	const int NUM_IN_SCATTER = 10;
	const float FNUM_IN_SCATTER = 10.0;

	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	vec3 originalRayDir = rayDir;

	if (rayDir.y < 0.0)
	{
		//rayDir.y = abs(rayDir.y);
		//rayDir.y *= rayDir.y;
		rayDir.y = 0.0;
	}

	vec3 up = vec3(0.0, 1.0, 0.0);

	vec2 e = RaySphereIntersection(eye, rayDir, R);
	vec2 eup = RaySphereIntersection(eye, up, R);


	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount, 0.7);


	atmosphere = pow(atmosphere, vec3(1.3));

	//if (originalRayDir.y < 0.0)
	//{
		//atmosphere *= curve(saturate(originalRayDir.y + 1.0));
	//}


	return atmosphere;
}









vec3 ClipCheck(vec3 color)
{
	color.r = color.r > 1.0 ? 0.0 : color.r;
	color.g = color.g > 1.0 ? 0.0 : color.g;
	color.b = color.b > 1.0 ? 0.0 : color.b;

	return color;
}