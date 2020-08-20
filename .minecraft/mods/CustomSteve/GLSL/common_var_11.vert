attribute float my_VertexIDX;
attribute float my_VertexIDY;
attribute vec3 faceVector;
uniform sampler2D VertexMatrixArray;
uniform float VertexMaxX;
uniform float VertexMaxY;
uniform sampler2D BoneMatrixArray;
uniform float BoneNumberM4;
varying vec3 normal;
varying vec3 ecPos;

vec4 my_Vertex;