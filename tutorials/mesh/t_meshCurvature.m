%% t_meshCurvature
%
% Use tricurve_v01 to calculate curvature of a mesh
%
%

%% Load the class file.  A sphere is 1 and everything else 0
fName = fullfile(mrvDataRootPath,'anatomy','harmonic.nii.gz');
niClass = niftiRead(fName);
% showMontage(niClass.data)

%% Use Matlab to build the faces and edges
fv = isosurface(niClass.data,0.9);
smoothMode = 1; nIter = 5;
fv = smoothpatch(fv,smoothMode,nIter);
% This was suggested by Peyre.  It may work in the end.  But it takes time,
% as well, so I may as well stick with the tricurv_v01 for now.
%
% options.method = 'slow';
% fv.faces = perform_faces_reorientation(fv.vertices,fv.faces,options)';

%% One solution.  Slow, but this is the one used in meshFV2msh.m
% curvature1 = tricurv_v01(fv.faces,fv.vertices);

%% A second solution is much faster.  But it fails a lot.

% I will probably remove it from meshFV2msh.m  But there is an interesting
% exchange about it with Peyre.  See email and notes.
%
%   Umin is the direction of minimum curvature
%   Umax is the direction of maximum curvature
%   Cmin is the minimum curvature
%   Cmax is the maximum curvature
%   Cmean=(Cmin+Cmax)/2
%   Cgauss=Cmin*Cmax
%   Normal is the normal to the surface

% BUT, this routine fails a lot.  I wrote the authors.  I put a try/catch
% around it in meshFV2msh.m
% tic
% [Umin,Umax,Cmin,Cmax,Cmean,Cgauss,Normal] = ...
%     compute_curvature(fv.vertices,fv.faces);
% toc

%% Convert the fv mesh to a vistasoft mesh

msh = meshFV2msh(fv);
meshVisualize(msh);

%% End

