% kgsMesh.m
%
% This script will set the mrMesh paths specific for sechel or moach. It
% will remove the current path to mrMesh and set it to a path that has the
% mex files compiled for either sechel or moach. The hostname is used to
% identify the computer. 
%
% History:
% 2011-06-06 LMP wrote the thing

[meshPath b c] = fileparts(which('mrMesh'));

moachPath = '/biac2/kgs/dataTools/mrMesh_moach';
sechelPath = '/biac2/kgs/dataTools/mrMesh_sechel';

[d hostname] = unix('hostname');

if strfind(hostname,'moach') >0
    rmpath(genpath(meshPath));    
    addpath(genpath(moachPath));
    fprintf('Setting mrMesh path for Moach... \nmrMesh path set to %s\n',moachPath);
    
elseif strfind(hostname,'sechel') >0
    rmpath(genpath(meshPath));
    addpath(genpath(sechelPath));
    fprintf('Setting mrMesh path for Sechel... \nmrMesh path set to %s.\n',sechelPath);   
else
    fprintf('Not changing mrMesh path.\n');
end

clear meshPath b c d hostname moachPath sechelPath;

