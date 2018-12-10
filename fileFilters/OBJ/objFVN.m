function OBJ = objFVN(FV, N)
%Convert Matlab faces/vertices/normals to a wavefront OBJ format
%
%  This appears to work for a cortical mesh.
%  We have also made it work for a fiber produced by AFQ.
%
% Example
%  OBJ = objFVN(FV,N);
%  objWrite(OBJ,fname);
%
% LMP/BW Vistasoft Team, 2015

%% Check FV and Normals

%% Figure out the general things to do here

% Need to understand more about the OBJ file format to make this work
% better. 

% Make material structures.  
% Ka is the ambient illuminant
% Kd is the diffuse reflectance
% Ks is the specular reflectance
% I don't know what the values in illum (presumably illuminant) and Ns (not
% sure what that is) refer to.
material(1).type='newmtl';
material(1).data='skin';
material(2).type='Ka';
material(2).data=[0.8 0.4 0.4];
material(3).type='Kd';
material(3).data=[0.8 0.4 0.4];
material(4).type='Ks';
material(4).data=[1 1 1];
material(5).type='illum';
material(5).data = 2;
material(6).type = 'Ns';
material(6).data = 27;

%% Make alias wavefront object structure

% This is the OBJ data structure that will be written out by the routine
% objWrite 
clear OBJ
OBJ.material = material;

% Vertices and normals
OBJ.vertices = FV.vertices;
OBJ.vertices_normal = N;

% No idea what these control.  They don't seem aligned with the materials
% above.  Maybe they should be and then something good would happen.
OBJ.objects(1).type='g';
OBJ.objects(1).data='skin';

OBJ.objects(2).type='usemtl';
OBJ.objects(2).data='skin';

OBJ.objects(3).type='f';
OBJ.objects(3).data.vertices=  FV.faces;
OBJ.objects(3).data.normal  =  FV.faces;

end

