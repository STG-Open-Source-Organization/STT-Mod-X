struct GBufferData
{
	vec4 albedo;
	float depth;
	vec3 normal;
	vec2 mcLightmap;
	float smoothness;
	float metalness;
	float materialID;
	float emissive;
	vec3 geoNormal;
	float totalTexGrad;
};

struct GBufferDataTransparent
{
	vec4 albedo;
	vec3 normal;
	vec3 geoNormal;
	float materialID;
	float smoothness;
	vec2 mcLightmap;
	float depth;
};





//Output helpers
void OutputGBufferDataSolid(in GBufferData data, out vec4 target0, out vec4 target1, out vec4 target2, out vec4 target3)
{
	//gcolor RGB8
	target0 = data.albedo;

	//gdepth RGBA16
	target1 = vec4(PackTwo8BitTo16Bit(data.mcLightmap.x, data.mcLightmap.y),
			   PackTwo8BitTo16Bit(data.smoothness, data.metalness),
			   PackTwo8BitTo16Bit(data.materialID, data.emissive),
			   PackTwo8BitTo16Bit(data.totalTexGrad, 1.0));

	//gnormal RGBA16
	target2 = vec4(EncodeNormal(data.normal.xyz), EncodeNormal(data.geoNormal.xyz));

	//composite RGB8
	target3 = vec4(0.0, 0.0, 0.0, 1.0);
}

void OutputGBufferDataTransparent(in GBufferDataTransparent data, out vec4 target0, out vec4 target1)
{
	//gdepth RGBA16
	target0 = vec4(PackTwo8BitTo16Bit(data.albedo.r, data.albedo.g),
				PackTwo8BitTo16Bit(data.albedo.b, data.albedo.a),
				EncodeNormal(data.normal));

	//gnormal RGBA16
	target1 = vec4(PackTwo8BitTo16Bit(data.mcLightmap.x, data.mcLightmap.y),
				PackTwo8BitTo16Bit(data.materialID, data.smoothness), 
				EncodeNormal(data.geoNormal.xyz));
}




float CurveBlockLightSky(float blockLight)
{
	//blockLight = pow(blockLight, 3.0);

	//blockLight = InverseSquareCurve(1.0 - blockLight, 0.2);
	blockLight = 1.0 - pow(1.0 - blockLight, 0.45);
	blockLight *= blockLight * blockLight;

	return blockLight;
}

#define TORCHLIGHT_FILL 1.0 // Amount of fill/ambient light to add to torchlight falloff. Higher values makes torchlight dim less intensely based on distance. [0.5 1.0 2.0 4.0 8.0]

float CurveBlockLightTorch(float blockLight)
{
	float decoded = pow(blockLight, 1.0 / 0.25);

	decoded = pow(decoded, 2.0) * 5.0;
	decoded += pow(decoded, 0.4) * 0.1 * TORCHLIGHT_FILL;

	return decoded;
}



GBufferData GetGBufferData()
{
	GBufferData data;

	vec4 tex0 = texture2DLod(gcolor, texcoord.st, 0);
	vec4 tex1 = texture2DLod(gdepth, texcoord.st, 0);
	vec4 tex2 = texture2DLod(gnormal, texcoord.st, 0);
	//vec4 tex3 = texture2D(composite, texcoord.st);

	float depthTex = texture2D(depthtex1, texcoord.st).x;

	vec2 unpacked1x = UnpackTwo8BitFrom16Bit(tex1.x);
	vec2 unpacked1y = UnpackTwo8BitFrom16Bit(tex1.y);
	vec2 unpacked1z = UnpackTwo8BitFrom16Bit(tex1.z);
	vec2 unpacked1w = UnpackTwo8BitFrom16Bit(tex1.w);



	data.albedo = vec4(GammaToLinear(tex0.rgb), 1.0);

	data.mcLightmap = unpacked1x;
	data.mcLightmap.g = CurveBlockLightSky(data.mcLightmap.g);
	data.mcLightmap.r = CurveBlockLightTorch(data.mcLightmap.r);

	data.normal = DecodeNormal(tex2.xy);
	data.geoNormal = DecodeNormal(tex2.zw);

	data.smoothness = unpacked1y.x;
	data.metalness = unpacked1y.y;
	data.emissive = unpacked1z.y;

	data.materialID = unpacked1z.x;

	data.totalTexGrad = unpacked1w.x;

	data.depth = depthTex;



	return data;
}

GBufferDataTransparent GetGBufferDataTransparent()
{
	GBufferDataTransparent data;

	vec4 tex1 = texture2DLod(gdepth, texcoord.st, 0);
	vec4 tex2 = texture2DLod(gnormal, texcoord.st, 0);

	vec2 unpacked1x = UnpackTwo8BitFrom16Bit(tex1.x);
	vec2 unpacked1y = UnpackTwo8BitFrom16Bit(tex1.y);

	vec2 unpacked2x = UnpackTwo8BitFrom16Bit(tex2.x);
	vec2 unpacked2y = UnpackTwo8BitFrom16Bit(tex2.y);

	float depthTex = texture2DLod(gdepthtex, texcoord.st, 0).x;



	data.albedo = vec4(unpacked1x, unpacked1y);
	data.albedo = vec4(GammaToLinear(data.albedo.rgb), data.albedo.a);
	data.normal = DecodeNormal(tex1.zw);
	data.geoNormal = DecodeNormal(tex2.zw);

	data.mcLightmap = unpacked2x;
	data.mcLightmap.x = CurveBlockLightTorch(data.mcLightmap.x);
	data.mcLightmap.y = CurveBlockLightSky(data.mcLightmap.y);

	data.materialID = unpacked2y.x;
	data.smoothness = unpacked2y.y;

	data.depth = depthTex;

	return data;
}