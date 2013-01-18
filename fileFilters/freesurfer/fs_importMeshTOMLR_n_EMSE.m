function [view,EMSEfileName,mrmeshFilePath]=fs_importMeshToMLR_n_EMSE(view,fsMeshName,decimationFactor) %#ok<FNDEF>
% [view,EMSEfileName,mrmeshFilePath]=fs_importMeshToMLR_n_EMSE(view,fsMeshName,decimationFactor)
% Takes a single freesurfer mesh file as an input.
% Saves out two files:
% 1: An EMSE .wfr file ready for loading into EMSE /
% mrViewer
% 2: A mlr mesh file ready for loading into mrMesh
% Essentially this just concantenates two functions. But it is handy:
% Also it allows you to check imported meshes for defects in mrMesh
% The mrLoadRet gray view must be open when you call this.
% ARW 052405 : Wrote it.
%
mrGlobals;

if (ieNotDefined('decimationFactor'))
    disp('DecimationFactor is 0.1');
    decimationFactor=0.1;
end
if(ieNotDefined('fsMeshName'))
    fsMeshName=[];
end
if(ieNotDefined('view'))
    view=getSelectedGray;
    
end
if(ieNotDefined('decimationFactor'))
    decimationFactor=0.1;   
end
disp('Writing the EMSE .wfr file');
p=fs_writeEMSEMeshFromFreesurfer(fsMeshName,[],'cortex',decimationFactor);

disp('Now converting the mrMesh data');

% In theory we should be able to just write this out straight to disk as a
% .mat file since the p structure contains more or less all the important
% stuff. However, we go through mrMesh for the convenience - and also so
% that it can compute things like the surface normals for us.
EMSEfileName=p.mesh.fileName;

disp('Calling emseConvertEMSEMesh....');
disp(EMSEfileName);
  
[msh,lights,tenseMsh] =  emseConvertEMSEMesh(EMSEfileName,[],'localhost'); %#ok<NASGU> % Only use this on any subjects with a  1x1x1 voxel size
msh.surface='pial';

% Now write it out (prompting you for a filename)
[msh,mrmeshFilePath] = mrmWriteMeshFile(msh);

