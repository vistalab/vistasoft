function FV2=smoothpatch(FV,mode,itt,lambda,sigma)
% This function PATCHSMOOTH smooths a triangulated Mesh, with accurate
% curvature flow smoothing, or laplacian smoothing with inverse vertice
% distance based umbrella weights.
%
% FV2=smoothpatch(FV,mode,itt,lambda,sigma);
%
% Inputs,
%   FV : A struct containing FV.faces with a facelist Nx3 and FV.vertices
%        with a Nx3 vertices list. Such a structure is created by Matlab
%        Patch function
%   mode : value 0 or 1 (default)
%          If zero uses inverse distance between vertices as weights. The
%          mesh becomes smoother but also edge distances more uniform
%          If one uses the normalized curvature operator as weights. The
%          mesh is mainly smoothed in the normal direction, thus the
%          orignal ratio in length between edges is preserved.
%   itt : Number of smoothing itterations (default 1)
%   lambda : Amount of smoothing [0....1] (default 1)
%   sigma : (If mode is 0), Influence of neighbour point is 
%             Weight = 1 / ( inverse distance + sigma)   (default sigma=1);
% Outputs,
%   FV2 : A struct containing the smoothed patch
%
% Literature:
% Mathieu Desbrun et al. "Implicit Faring of Irregular Meshes using
%     Diffusion and Curvature Flow"
% Alexander Belyaev. "Curvature Estimation"
%
% Example,
%   % Compile the c-code functions
%   mex smoothpatch_curvature_double.c -v
%   mex smoothpatch_inversedistance_double.c -v
%   mex vertex_neighbours_double.c -v
%
%   % Load a triangulated mesh of a sphere
%   load MRI;
%   D = squeeze(D);
%   FV = isosurface(D,1);
%
%   % Calculate the smoothed version
%   FV2=smoothpatch(FV,1,5);
%
%   % Show the mesh and smoothed mesh
%   figure, 
%    subplot(1,2,1), patch(FV,'FaceColor',[1 0 0],'EdgeAlpha',0);  view(3); camlight
%    subplot(1,2,2), patch(FV2,'FaceColor',[0 0 1],'EdgeAlpha',0); view(3); camlight
%
% Function is written by D.Kroon University of Twente (June 2009)
if(nargin<2), mode =1; end
if(nargin<3), itt=1; end
if(nargin<4), lambda=1; end
if(nargin<5), sigma=1; end

sizev=size(FV.vertices);
% Check size of vertice array
if((sizev(2)~=3)||(length(sizev)~=2))
    error('patchnormals:inputs','The vertice list is not a m x 3 array')
end

sizef=size(FV.faces);
% Check size of vertice array
if((sizef(2)~=3)||(length(sizef)~=2))
    error('patchnormals:inputs','The vertice list is not a m x 3 array')
end

% Check if vertice indices exist
if(max(FV.faces(:))>size(FV.vertices,1))
    error('patchnormals:inputs','The face list contains an undefined vertex index')
end

% Check if vertice indices exist
if(min(FV.faces(:))<1)
    error('patchnormals:inputs','The face list contains an vertex index smaller then 1')
end

FV.vertices=double(FV.vertices);
FV.faces=double(FV.faces);
if(mode==1)
    % Get the neighbour vertices of each vertice from the face list.
    Ne=vertex_neighbours(FV);
    % Do the curvature weighted smoothing
    [Vx,Vy,Vz]=smoothpatch_curvature_double(double(FV.faces(:,1)),double(FV.faces(:,2)),double(FV.faces(:,3)),double(FV.vertices(:,1)),double(FV.vertices(:,2)),double(FV.vertices(:,3)),ceil(double(itt)),[double(lambda) double(sigma)],Ne);
else
    % Do the umbrella inverse distance weighted smoothing
    [Vx,Vy,Vz]=smoothpatch_inversedistance_double(double(FV.faces(:,1)),double(FV.faces(:,2)),double(FV.faces(:,3)),double(FV.vertices(:,1)),double(FV.vertices(:,2)),double(FV.vertices(:,3)),ceil(double(itt)),[double(lambda) double(sigma)]);
end

FV2=FV;
FV2.vertices(:,1)=Vx;
FV2.vertices(:,2)=Vy;
FV2.vertices(:,3)=Vz;

