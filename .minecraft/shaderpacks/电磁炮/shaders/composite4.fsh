#version 120

/* DRAWBUFFERS:2 */

const float LensFlareDelay = 1.85;
const float LensFlareNight = 0.425;
const float LensFlareSunRS = 0.325;
const float LensFlareDark  = 0.125;

const bool gaux2MipmapEnabled = true;

uniform sampler2D gnormal;
uniform sampler2D gaux2, gdepth, gcolor, gaux1;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

uniform vec3 sunPosition;
uniform int   isEyeInWater;

uniform mat4 gbufferProjection;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeMidnight;

varying vec4 texcoord;

float timeDay = 1.0 - timeMidnight;
float timeNoonNight = timeMidnight + timeNoon;
float timeSunRiseSet = 1.0 - timeNoonNight;

bool 	GetMaterialMask(in vec2 coord, in int ID, float matID) {
	matID = floor(matID * 255.0f);

	//Catch last part of sky
	if (matID > 254.0f) {
		matID = 0.0f;
	}

	if (matID == ID) {
		return true;
	} else {
		return false;
	}
}

float FlarePoint(in vec3 sP, in vec2 lPos, in float xP, in float yP, in float Scale, in float flarePow, in float flareFill, in float flareOffset, in float sunmask){	
	vec2 flareScale = vec2(xP * Scale, yP * Scale);
	vec2 flarePos = vec2(((1.0 - lPos.x) * (flareOffset + 1.0) - (flareOffset * 0.5)) * aspectRatio * flareScale.x,
                         ((1.0 - lPos.y) * (flareOffset + 1.0) - (flareOffset * 0.5))  				* flareScale.y);			
	float flare = distance(flarePos, vec2(texcoord.s * aspectRatio * flareScale.x, texcoord.t * flareScale.y));
		  flare = 0.5 - flare;
		  flare = clamp(flare * flareFill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
		  flare = sin(flare * 1.57075);
		  flare *= sunmask;
		  flare = pow(flare, 1.1);	  
		  flare *= flarePow;
					
	return flare;
}	

float FlarePointA(in vec3 sP, in vec2 lPos, in float xP, in float yP, in float Scale, in float flarePow, in float flareFill, in float flareOffset, in float sunmask){	
	vec2 flareScale = vec2(xP * Scale, yP * Scale);
	vec2 flarePos = vec2(((1.0 - lPos.x) * (flareOffset + 1.0) - (flareOffset * 0.5)) * aspectRatio * flareScale.x,
                         ((1.0 - lPos.y) * (flareOffset + 1.0) - (flareOffset * 0.5))  				* flareScale.y);			
	float flare = distance(flarePos, vec2(texcoord.s * aspectRatio * flareScale.x, texcoord.t * flareScale.y));
		  flare = 0.5 - flare;
		  flare = clamp(flare * flareFill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
		  flare = sin(flare * 10.0);
		  flare *= sunmask;
		  flare = pow(flare, 1.0);	  
		  flare *= flarePow;
					
	return flare;
}

float FlareRing(in vec3 sP, in vec2 lPos, in float xP, in float yP, in float Scale, in float flarePow, in float flareFill, in float flareOffset, in float sunmask){	
	vec2 flareScale = vec2(xP * Scale, yP * Scale);
	vec2 flarePos = vec2(((1.0 - lPos.x) * (flareOffset + 1.0) - (flareOffset * 0.5)) * aspectRatio * flareScale.x,
                         ((1.0 - lPos.y) * (flareOffset + 1.0) - (flareOffset * 0.5))  				* flareScale.y);			
	float flare = distance(flarePos, vec2(texcoord.s * aspectRatio * flareScale.x, texcoord.t * flareScale.y));
		  flare = 0.5 - flare;
		  flare = clamp(flare * flareFill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
		  flare = pow(flare, 1.9);
		  flare = sin(flare * 3.1415);
		  flare *= sunmask; 
		  flare *= flarePow;
					
	return flare;
}

float FlareHalf(in vec3 sP, in vec2 lPos, in float xP, in float yP, in float Scale, in float flarePow, in float flareFill, in float flareOffset, in float sunmask,
				in float xPHalf, in float yPHalf, in float flarePowHalf, in float flareFillHalf, in float flareOffsetHalf){	
	vec2 flareScale = vec2(xP * Scale, yP * Scale);
	vec2 flarePos = vec2(((1.0 - lPos.x) * (flareOffset + 1.0) - (flareOffset * 0.5)) * aspectRatio * flareScale.x,
                         ((1.0 - lPos.y) * (flareOffset + 1.0) - (flareOffset * 0.5))  				* flareScale.y);						 
	float flare = distance(flarePos, vec2(texcoord.s * aspectRatio * flareScale.x, texcoord.t * flareScale.y));
		  flare = 0.5 - flare;
		  flare = clamp(flare * flareFill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
		  flare = sin(flare * 1.57075);
		  flare *= sunmask;
		  flare = pow(flare, 1.1);	  
		  flare *= flarePow;

	vec2 flareScaleHalf = vec2(xPHalf * Scale, yPHalf * Scale);	  
	vec2 flarePosHalf = vec2(((1.0 - lPos.x) * (flareOffsetHalf + 1.0) - (flareOffsetHalf * 0.5)) * aspectRatio * flareScaleHalf.x,
                             ((1.0 - lPos.y) * (flareOffsetHalf + 1.0) - (flareOffsetHalf * 0.5))  				* flareScaleHalf.y);		  
	float flareHalf = distance(flarePosHalf, vec2(texcoord.s * aspectRatio * flareScaleHalf.x, texcoord.t * flareScaleHalf.y)); 
		  flareHalf = 0.5 - flareHalf;
		  flareHalf = clamp(flareHalf * flareFillHalf, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
		  flareHalf = sin(flareHalf * 1.57075);
		  flareHalf *= sunmask;
		  flareHalf = pow(flareHalf, 0.9);
		  flareHalf *= flarePowHalf;
		  
	float FinalFlare = clamp(flare - flareHalf, 0.0, 10.0);
		  
	return FinalFlare;
}	

void LensFlare(inout vec3 color){
    vec3 sP = sunPosition * timeDay;
	vec4 tpos = vec4(sP, 1.0) * gbufferProjection;
		 tpos = vec4(tpos.xyz / tpos.w, 1.0);	   
	vec2 lPos = tpos.xy / tpos.z;
		 lPos = (lPos + 1.0) / 2.0;
	vec2 PosD = tpos.xy / (tpos.z * LensFlareDelay);
		 PosD.y *= LensFlareDelay / 2.0;
		 PosD.x *= LensFlareDelay / 2.0;
		 PosD = (PosD + 1.0) / 2.0;
	float pw = 1.0 / viewWidth;
    float ph = 1.0 / viewHeight;	
	float distof = min(min(1.0 - lPos.x, lPos.x), min(1.0 - lPos.y, lPos.y));
	float fading = clamp(1.0 - step(distof, 0.5) + pow(distof * 10.0, 2.0), 0.0, 1.0);
    vec2 checkcoord = lPos + vec2(pw * 5.0, ph * 5.0); 
	
	float sunmask = 0.0;				
    float flarescale = 1.0;
	
	//光晕颜色
    float FlareR = 1.0;
    float FlareG = 1.0;
    float FlareB = 1.0;		
	
    if (isEyeInWater < 0.9) {
		if (checkcoord.x < 1.0f && checkcoord.x > 0.0f && checkcoord.y < 1.0f && checkcoord.y > 0.0f){          		   
			//sunmask = texture2D(gaux2, PosD).a;	
			//sunmask = texture2D(gaux2, lPos).a;	
			//sunmask *= float(GetMaterialMask(texcoord.st, 0, texture2D(gdepth, lPos).r));
			sunmask = float(GetMaterialMask(texcoord.st, 0, texture2D(gdepth, lPos).r));
			sunmask = clamp(sunmask, 0.0, 0.025);
		}
		sunmask *= fading;
		sunmask *= 1.0 - rainStrength;
		
		FlareR -= LensFlareNight * timeMidnight;
		FlareG -= LensFlareNight * timeMidnight;
		FlareB -= LensFlareNight * timeMidnight;	
		
		if (sunmask > 0.0) {
		    float centermask = 1.0 - clamp(distance(lPos.xy, vec2(0.5f, 0.5f))*2.0, 0.0, 1.0);
				  centermask = pow(centermask, 1.0f);
				  centermask *= sunmask;
				  centermask *= LensFlareDark;
			
			    flarescale *= (1.0 - centermask);
			
			color.rgb *= (1.0 - centermask);	
				
		/*-----------Half Flare-----------*/
			float Flare26 = FlareHalf(sP, lPos, 2.0, 2.0, flarescale, 0.7, 10.0, -0.5, sunmask, 1.4, 1.4, 1.0, 2.0, -0.65);
				color.r += Flare26 * (1.0 * timeSunRiseSet) * FlareR;
				color.g += Flare26 *  0.3                   * FlareG;	
				color.b += Flare26 * (1.0 * timeNoonNight ) * FlareB;				
			
			float Flare27 = FlareHalf(sP, lPos, 3.2, 3.2, flarescale, 1.4, 10.0, 0.0, sunmask, 2.1, 2.1, 2.7, 1.4, -0.05);
				color.r += Flare27 * (1.0 * timeSunRiseSet) * FlareR;
				color.g += Flare27 *  0.7 					* FlareG;	
				color.b += Flare27 * (1.0 * timeNoonNight ) * FlareB;				
			
			/*
			float Flare28 = FlareHalf(sP, lPos, 2.5, 2.5, flarescale, 0.4, 10.0, -3.35, sunmask, 1.95, 1.95, 1.2, 6.5, -2.95);
				color.r += Flare28 * (1.2 * timeSunRiseSet		) * FlareR;
				color.g += Flare28 * (0.4 - 0.1 * timeSunRiseSet) * FlareG;	
				color.b += Flare28 * (0.6 * timeNoonNight 		) * FlareB;			
			*/
			float Flare29 = FlareHalf(sP, lPos, 3.6, 3.6, flarescale, 1.4, 10.0, -2.95, sunmask, 2.3, 2.3, 2.7, 1.4, -2.85);
				color.r += Flare29 * (0.5 * timeSunRiseSet		 ) * FlareR;
				color.g += Flare29 * (0.7 - 0.35 * timeSunRiseSet) * FlareG;	
				color.b += Flare29 * (1.0 * timeNoonNight 		 ) * FlareB;				
		/*---------End Half Flare---------*/
			
        ///////////////////////////////////////////////////////////////////		

		/*---Close Blue/Red Flare Point---*/ 
			float Flare30 = FlarePoint(sP, lPos, 4.5, 4.5, flarescale, 0.3, 3.0, -0.1, sunmask);
				color.r += Flare30 * (0.8 * timeSunRiseSet) * FlareR;
				color.g += Flare30 * (0.2 * timeSunRiseSet) * FlareG;	
				color.b += Flare30 * (0.8 * timeNoonNight ) * FlareB;	
			
			float Flare31 = FlarePoint(sP, lPos, 7.5, 7.5, flarescale, 0.4, 2.0, 0.0, sunmask);
				color.r += Flare31 * (0.8 * timeSunRiseSet) * FlareR;
				color.b += Flare31 * (0.8 * timeNoonNight ) * FlareB;	
	
			float Flare32 = FlarePoint(sP, lPos, 37.5, 37.5, flarescale, 2.0, 2.0, -0.3, sunmask);
				color.r += Flare32 * (0.8 * timeSunRiseSet) * FlareR;
				color.g += Flare32 * 0.6					* FlareG;	
				color.b += Flare32 * (0.8 * timeNoonNight ) * FlareB;
			
			float Flare33 = FlarePoint(sP, lPos, 67.5, 67.5, flarescale, 1.0, 2.0, -0.35, sunmask);
				color.r += Flare33 * (0.4 * timeSunRiseSet) * FlareR;
				color.g += Flare33 * 0.2					* FlareG;	
				color.b += Flare33 * (0.8 * timeNoonNight ) * FlareB;			
			
			float Flare34 = FlarePoint(sP, lPos, 60.5, 60.5, flarescale, 1.0, 3.0, -0.3393, sunmask);
				color.r += Flare34 * (0.6 * timeSunRiseSet) * FlareR;
				color.g += Flare34 * 0.2					* FlareG;	
				color.b += Flare34 * (0.6 * timeNoonNight ) * FlareB;			
			
			float Flare35 = FlarePoint(sP, lPos, 20.5, 20.5, flarescale, 3.0, 3.0, -0.4713, sunmask);
				color.r += Flare35 * (0.1 * timeSunRiseSet) * FlareR;
				color.g += Flare35 * 0.1					* FlareG;	
				color.b += Flare35 * (0.1 * timeNoonNight ) * FlareB;			
		/*-End Close Blue/Red Flare Point-*/

		/*--------Close Half Flare--------*/
			float Flare36 = FlareHalf(sP, lPos, 6.0, 6.0, flarescale, 1.9, 1.1, -0.7, sunmask, 5.1, 5.1, 1.5, 1.0, -0.77);
				color.r += Flare36 * (0.4 * timeSunRiseSet) * FlareR;
				color.g += Flare36 * 0.2					* FlareG;	
				color.b += Flare36 * (0.1 * timeNoonNight ) * FlareB;
			
			float Flare37 = FlareHalf(sP, lPos, 6.0, 6.0, flarescale, 1.9, 1.1, -0.6, sunmask, 5.1, 5.1, 1.5, 1.0, -0.67);
				color.r += Flare37 * (0.9 * timeSunRiseSet) * FlareR;
				color.g += Flare37 * 0.2 					* FlareG;
				color.b += Flare37 * (0.9 * timeNoonNight ) * FlareB;
		/*------End Close Half Flare------*/		
			
        ///////////////////////////////////////////////////////////////////	
			
        }
    }
}

void main() {
	vec4 color = texture2D(gnormal, texcoord.xy);
		 color.a = 1.0;

	LensFlare(color.rgb);
	
	gl_FragData[0] = color;
}