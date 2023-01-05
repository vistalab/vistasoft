% When you have a light and object described by a mesh, you want to know
% the shadow of the object.
% This function calculates a mesh named "shadowvolume" (see wikipedia) from
% a triangulated object mesh and a light.
%
% [SVvertices,SVfaces]=patchshadowvolume(OBJvertices,OBJfaces,L);
%
% Inputs,
%    OBJvertices, OBJfaces : The triangulated patch vertices and faces
%                       of the object causing a shadow
%    L: The light must be a 1x4 array with x,y,z,d, 
%		 with d=0 for parallel light, then x,y,z is the light direction
%		 and d=1 for point light, then x,y,z is the light position
%
% Outputs,
%    SVvertices, SVfaces : The triangulated shadow volume
%
% Function is written by D.Kroon University of Twente (March 2010)

