mat4 unpackMatrix(float id)
{
	vec4 a1,a2,a3,a4;
	a1 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 3.5/4.0 )).rgba;
	a2 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 2.5/4.0 )).rgba;
	a3 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 1.5/4.0 )).rgba;
	a4 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 0.5/4.0 )).rgba;
	return mat4(a1,a2,a3,a4);
}

mat4 unpackVertex(float x,float y)
{
	vec4 a1,a2,a3,a4;
	a1 = texture2D(VertexMatrixArray,vec2( (x+0.5)/VertexMaxX , (y+0.5)/VertexMaxY )).rgba;
	a2 = texture2D(VertexMatrixArray,vec2( (x+0.5)/VertexMaxX , (y+1.5)/VertexMaxY )).rgba;
	a3 = texture2D(VertexMatrixArray,vec2( (x+0.5)/VertexMaxX , (y+2.5)/VertexMaxY )).rgba;
	a4 = texture2D(VertexMatrixArray,vec2( (x+0.5)/VertexMaxX , (y+3.5)/VertexMaxY )).rgba;
	return mat4(a1,a2,a3,a4);
}

vec4 getPosition()
{
	float my_Bone0Id,my_Bone1Id,my_BoneWeight0;
	mat4 my_BoneMatrix0,my_BoneMatrix1,vertexData;
	mat4 tempMatrix;
	
	vertexData = unpackVertex(my_VertexIDX,my_VertexIDY);
	my_Vertex = vertexData[0];
	if(my_Vertex.w==1.0)
	{
		my_Vertex.x+=faceVector.x;
		my_Vertex.y+=faceVector.y;
		my_Vertex.z+=faceVector.z;
	}
	my_Vertex.w = 1.0;
	gl_TexCoord[0]=vec4(vertexData[2].s,vertexData[2].t,0.0,0.0);
    gl_FrontColor=vertexData[3];
	my_Bone0Id=vertexData[2].z;
	my_Bone1Id=vertexData[2].w;
	my_BoneWeight0=vertexData[1].w;
	
    if(my_BoneWeight0>0.99){
		my_BoneMatrix0=unpackMatrix(my_Bone0Id);
		ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		normal = normalize(gl_NormalMatrix * vec3(vertexData[1]));
		//normal = -normal;
		normal.z = -normal.z;
		return gl_ModelViewProjectionMatrix*my_BoneMatrix0*my_Vertex;
    }
    else if(my_BoneWeight0<0.01){
		my_BoneMatrix1=unpackMatrix(my_Bone1Id);
		ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		normal = normalize(gl_NormalMatrix * vec3(vertexData[1]));
		//normal = -normal;
		normal.z = -normal.z;
		return gl_ModelViewProjectionMatrix*my_BoneMatrix1*my_Vertex;
    }
    else{
		my_BoneMatrix0=unpackMatrix(my_Bone0Id);
		my_BoneMatrix1=unpackMatrix(my_Bone1Id);
		tempMatrix = (
            my_BoneMatrix0*my_BoneWeight0+
            my_BoneMatrix1*(1.0-my_BoneWeight0)
            );
		ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		normal = normalize(gl_NormalMatrix * vec3(vertexData[1]));
		//normal = -normal;
		normal.z = -normal.z;
		return gl_ModelViewProjectionMatrix * tempMatrix * my_Vertex;
    }
}