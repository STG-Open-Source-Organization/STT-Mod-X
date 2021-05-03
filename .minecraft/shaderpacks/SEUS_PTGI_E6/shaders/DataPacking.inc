
//Packing functions
float PackTwo4BitTo8Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 15.0 / 16.0);
	b = clamp(b, 0.0, 15.0 / 16.0);

	a *= 15.0;
	b *= 15.0;

	a = floor(a);
	b = floor(b);

	data = a * exp2(4.0);
	data += b;

	data /= exp2(8.0) - 1;

	return data;
}

vec2 UnpackTwo4BitFrom8Bit(float value)
{
	vec2 data;

	value *= exp2(8.0) - 1;

	data.x = floor(value / exp2(4.0));
	data.y = mod(value, exp2(4.0));

	data.x /= 15.0;
	data.y /= 15.0;

	return data;
}





float PackTwo8BitTo16Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 255.0 / 256.0);
	b = clamp(b, 0.0, 255.0 / 256.0);

	a *= 255.0;
	b *= 255.0;
	
	a = floor(a);
	b = floor(b);

	data = a * exp2(8.0);
	data += b;



	data /= exp2(16.0) - 1;

	return data;

	// vec2 d = vec2(a, b);
	// d = clamp(d, vec2(0.0), vec2(255.0 / 256.0));
	// d *= 256.0;

	// float data = dot(d, vec2(1.0 / exp2(8.0), 1.0 / exp2(16.0)));

	// return data;
}

vec2 UnpackTwo8BitFrom16Bit(float value)
{
	vec2 data;

	value *= exp2(16.0) - 1;

	data.x = floor(value / exp2(8.0));
	data.y = mod(value, exp2(8.0));

	data.x /= 255.0;
	data.y /= 255.0;

	return data;
}




// float PackTwo16BitTo32Bit(float a, float b)
// {
// 	a = clamp(a, 0.0, 1.0);
// 	b = clamp(b, 0.0, 1.0);

// 	a *= 65536.0;
// 	b *= 65536.0;

// 	int ai = int(a);
// 	int bi = int(b);

// 	int data = ai << 16;
// 	data += bi & 0x0000FFFF;

// 	float dataf = float(data) / 0xFFFFFFFF;

// 	return dataf;
// }

// vec2 UnpackTwo16BitFrom32Bit(float value)
// {
// 	int data = int(value * 0xFFFFFFFF);

// 	int ai = data >> 16;
// 	int bi = data & 0x0000FFFF;

// 	float a = float(ai) / 65536.0;
// 	float b = float(bi) / 65536.0;

// 	return vec2(a, b);
// }

#if 0

float PackTwo16BitTo32Bit(float a, float b)
{
	float data;

	a = clamp(a, 0.0, 255.0 / 256.0);
	b = clamp(b, 0.0, 255.0 / 256.0);

	a *= 65535.0;
	b *= 65535.0;

	a = floor(a);
	b = floor(b);

	data = a * exp2(16.0);
	data += b;

	data /= exp2(32.0) - 1;

	return data;


	// float data;

	// a = clamp(a, 0.01, 2047.0 / 2048.0);
	// b = clamp(b, 0.01, 2047.0 / 2048.0);

	// a *= 2047.0;
	// b *= 2047.0;

	// a = floor(a);
	// b = floor(b);

	// data = a * exp2(11.0);
	// data += b;

	// data /= exp2(22.0) - 1;
	// data += 1.0;

	// return data;
}

vec2 UnpackTwo16BitFrom32Bit(float value)
{
	vec2 data;

	value *= exp2(32.0) - 1;

	data.x = floor(value / exp2(16.0));
	data.y = mod(value, exp2(16.0));

	data.x /= 65535.0;
	data.y /= 65535.0;

	return data;


	// vec2 data;

	// value -= 1.0;
	// value *= exp2(22.0) - 1;

	// data.x = floor(value / exp2(11.0));
	// data.y = mod(value, exp2(11.0));

	// data.x /= 2047.0;
	// data.y /= 2047.0;

	// return data;
}


#else


float PackTwo16BitTo32Bit(float a, float b) {
	vec2 v = vec2(a, b);
	// v = clamp(v, vec2(0.0), vec2(1.0));
    return dot(floor(v*8191.9999),vec2(1./8192.,1.));
}
vec2 UnpackTwo16BitFrom32Bit(float v) {
    return vec2(fract(v)*(8192./8191.),floor(v)/8191.);
}

#endif


vec4 PackFloatRGBA(float v)
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc = fract(enc);
	enc -= enc.yzww * vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
	return enc;
}

float UnpackFloatRGBA(vec4 rgba)
{
	return dot(rgba, vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0));
}


