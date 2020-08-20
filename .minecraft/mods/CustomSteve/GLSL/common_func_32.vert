mat4 unpackMatrix(float id)
{
	vec4 a1,a2,a3,a4;
	a1 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 3.5/4.0 )).rgba;
	a2 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 2.5/4.0 )).rgba;
	a3 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 1.5/4.0 )).rgba;
	a4 = texture2D(BoneMatrixArray,vec2( (id+0.5)/BoneNumberM4 , 0.5/4.0 )).rgba;
	return mat4(a1,a2,a3,a4);
}

//mat4 unpackMatrix(int id)
//{
	//vec4 a,b,c,d;
	//int pos = id * 3;
	//a = texelFetchBuffer(tBoneTBO, pos+0).rgba;
	//b = vec4(0.0,1.0,0.0,0.0);
	//c = vec4(0.0,0.0,1.0,0.0);
	//d = vec4(0.0,0.0,0.0,1.0);
	//b = texelFetchBuffer(tBoneTBO, pos+1).abgr;
	//c = texelFetchBuffer(tBoneTBO, pos+2).abgr;
	//d = texelFetch(tBoneTBO, pos+3).abgr;
	//return mat4(a,b,c,d);
//}

vec4 getPosition()
{
	mat4 my_BoneMatrix0,my_BoneMatrix1;
	mat4 tempMatrix;

	my_Vertex = vec4(vPosition+vFace,1.0);
	vertex.normal = vNormal;
	vertex.vTexCoord = vUV;
	if(fBone0Weight>0.99){
		my_BoneMatrix0=unpackMatrix(iBone0);
		vertex.ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		vertex.normal = normalize(gl_NormalMatrix * mat3(my_BoneMatrix0) * vertex.normal);
		//normal = -normal;
		//vertex.normal.z = -vertex.normal.z;
		return gl_ModelViewMatrix*my_BoneMatrix0*my_Vertex;
    }
    else if(fBone0Weight<0.01){
		my_BoneMatrix1=unpackMatrix(iBone1);
		vertex.ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		vertex.normal = normalize(gl_NormalMatrix * mat3(my_BoneMatrix1) * vertex.normal);
		//normal = -normal;
		//vertex.normal.z = -vertex.normal.z;
		return gl_ModelViewMatrix*my_BoneMatrix1*my_Vertex;
    }
    else{
		my_BoneMatrix0=unpackMatrix(iBone0);
		my_BoneMatrix1=unpackMatrix(iBone1);
		tempMatrix = (
            my_BoneMatrix0*fBone0Weight+
            my_BoneMatrix1*(1.0-fBone0Weight)
            );
		vertex.ecPos = normalize(vec3(gl_ModelViewMatrix * my_Vertex));
		vertex.normal = normalize(gl_NormalMatrix * mat3(tempMatrix) * vertex.normal);
		//normal = -normal;
		//vertex.normal.z = -vertex.normal.z;
		return gl_ModelViewMatrix * tempMatrix * my_Vertex;
    }
}