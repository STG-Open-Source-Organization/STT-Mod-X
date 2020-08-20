for(int i=0; i<3; i++)
{
	frag.normal = vertex[i].normal;
	frag.ecPos = vertex[i].ecPos;
	frag.vTexCoord = vertex[i].vTexCoord;
	frag.edge = 0.0;
	gl_Position = gl_ProjectionMatrix * gl_in[i].gl_Position;
	EmitVertex();
}
EndPrimitive();

vec4 distance;
float dis2 = 1.0;

float scale;
if(gl_ProjectionMatrix[3].w == 0)
{
	scale = edgeInPerspective * edgeScale;
	distance = vec4(gl_ProjectionMatrix[0].w, gl_ProjectionMatrix[1].w, gl_ProjectionMatrix[2].w, 0.0) - gl_in[0].gl_Position;
	dis2 = distance.x * distance.x + 
				distance.y * distance.y +
				distance.z * distance.z;
	dis2 = max(1.0 ,dis2);
	dis2 = min(4.0,dis2);
}
else
{
	scale = edgeInOrthogonal * edgeScale;
}

for(int i=0; i<3; i++)
{
	frag.normal = vertex[i].normal;
	frag.ecPos = vertex[i].ecPos;
	frag.vTexCoord = vertex[i].vTexCoord;
	frag.edge = 1.0;
	//gl_Position = gl_in[i].gl_Position + vec4(frag.normal, 0.0) * scale;
	//gl_Position = gl_ProjectionMatrix * gl_Position;
	//gl_Position.z = gl_Position.z + edgeOffset;
	
	gl_Position = gl_ProjectionMatrix * gl_in[i].gl_Position;
	gl_Position = gl_Position + normalize(gl_ProjectionMatrix * vec4(frag.normal , 0.0)) * scale * dis2;
	gl_Position.z = gl_Position.z + edgeOffset;
	EmitVertex();
}
EndPrimitive();