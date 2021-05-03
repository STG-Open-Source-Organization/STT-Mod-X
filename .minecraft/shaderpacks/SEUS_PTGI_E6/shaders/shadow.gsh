#version 330 compatibility

layout(triangles) in;
layout(triangle_strip, max_vertices = 6) out;

in vec4 vcolor[];
in vec4 vtexcoord[];
in vec3 vnormal[];
in vec3 vrawNormal[];
in vec4 vviewPos[];
in float vmaterialIDs[];
in vec4 volumeScreenPos[];
in vec4 shadowScreenPos[];
in float vInvalidForVolume[];
in vec2 vMidTexcoord[];
in float vFragDepth[];
in float viswater[];

out vec4 color;
out vec4 texcoord;
out vec3 normal;
out vec3 rawNormal;
out vec4 viewPos;
out float materialIDs;
out float isVoxelized;
out vec2 midTexcoord;
out float fragDepth;
out float iswater;

 void main()
 {
   int d;
   vec4 v;
   for(d=0;d<3;d++)
     v=gl_in[1].gl_Position,v=shadowScreenPos[d],gl_Position=v,color=vcolor[d],texcoord=vtexcoord[d],normal=vnormal[d],rawNormal=vrawNormal[d],viewPos=vviewPos[d],materialIDs=vmaterialIDs[d],midTexcoord=vMidTexcoord[d],fragDepth=vFragDepth[d],iswater=viswater[d],isVoxelized=0.,EmitVertex();
   EndPrimitive();
   bool r=true;
   if(vInvalidForVolume[0]>.5||vInvalidForVolume[1]>.5||vInvalidForVolume[2]>.5)
     r=false;
   if(r)
     {
       if(distance(volumeScreenPos[0].xy,volumeScreenPos[1].xy)>1./1024.||distance(volumeScreenPos[0].xy,volumeScreenPos[2].xy)>1./1024.||distance(volumeScreenPos[1].xy,volumeScreenPos[2].xy)>1./1024.)
         ;
       else
         {
           for(d=0;d<3;d++)
             v=gl_in[1].gl_Position,v=volumeScreenPos[d],gl_Position=v,color=vcolor[d],texcoord=vtexcoord[d],normal=vnormal[d],rawNormal=vrawNormal[d],viewPos=vviewPos[d],materialIDs=vmaterialIDs[d],midTexcoord=vMidTexcoord[d],fragDepth=vFragDepth[d],iswater=viswater[d],isVoxelized=1.,EmitVertex();
           EndPrimitive();
         }
     }
 };