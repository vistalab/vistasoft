function [mesh params] = mfmReadMesh(params);
% READ IN THE ORIGNAL MRGRAY MESH OR BUILD A MESH FROM A CLASS FILE
%
%  [mesh params] = mfmReadMesh(params);
%
%Author:  Winawer
%
%   Purpose: Read in the original mrGray mesh or build a mesh from a class file
%     
%   Sub-routine derived from Alex's unfoldMeshFromGUI code.
%
% See Also:  unfoldMeshFromGUI
%

global vANATOMYPATH;

% Get all the variables we may need
meshFileName     = params.meshFileName;
grayFileName     = params.grayFileName;
flatFileName     = params.flatFileName;
startCoords      = params.startCoords;
scaleFactor      = params.scaleFactor;
perimDist        = params.perimDist;
statusHandle     = params.statusHandle;
busyHandle       = params.busyHandle;
spacingMethod    = params.spacingMethod;
adjustSpacing    = params.adjustSpacing;
gridSpacing      = params.gridSpacing;
showFigures      = params.showFigures;
saveExtra        = params.saveExtra;
truePerimDist    = params.truePerimDist;
hemi             = params.hemi;
nperims          = params.NPERIMS;
saveIntermeidate = params.SAVE_INTERMEDIATE;
numberOfSteps    = params.NUMBEROFSTEPS;


% parse the file name
[p,f,e] = fileparts(meshFileName);

% update the status window
statusStringAdd(statusHandle,['Loading: ',meshFileName]);

% IF it's a class file...
if(strcmpi(e,'.class')||strcmpi(e,'.gz')||strcmpi(e,'.nii'))
    % read in the mesh and mesh resolution
    mmPerPix = readVolAnatHeader(vANATOMYPATH);
    mesh = meshBuildFromClass(meshFileName, mmPerPix, hemi);
    scaleFactorFromMesh = mmPerPix;
    
    % smooth it
    mesh = meshSet(mesh,'smooth_iterations',10);
    smoothMesh = meshSmooth(mesh);
    tmp = curvature(smoothMesh);
    smoothMesh.colors = tmp.colors;
    smoothMesh.curvature = tmp.curvature;
    mesh.rgba = smoothMesh.colors;
    
    % Convert new mrMesh format to old mrGray mrm-file format. 
    %   Perhaps we should leave it alone do the opposite conversion?
    %   *** FIX ME: change field names to avoid duplication
    mesh.faceIndexList = mesh.triangles'+1;
    mesh.vertices = mesh.vertices';
    mesh.normal = mesh.normals';
    mesh.rgba = mesh.rgba';

% IF it's an old MrM file...
else

    [mesh, scaleFactorFromMesh] = mrReadMrM(meshFileName, 0);
    % Check to see if a file called [meshFilename,'_smooth'] exists. If it
    % does, read this in as well and use the RGB values rather than the ones
    % from the unsmoothed mesh.  Use the unsmoothed mesh for everything else..
    [origPath, origName, origExt, origVern] = fileparts(meshFileName);
    smoothFileName = fullfile(origPath, [origName,'_smooth',origExt]);

    if (exist(smoothFileName,'file'))
        [smMesh, dummy] = mrReadMrM(smoothFileName,0);
        if (length(smMesh.rgba)~=length(mesh.rgba))
            error('A smooth mesh file was found but it was not the same size as the original one.');
        else
            str = sprintf('Using rgb values from smooth map.\n');
            statusStringAdd(statusHandle,str);
            mesh.rgba=smMesh.rgba;
        end
    end
end

% mrReadMrM scales everything to voxel coords. So mrGray writes out a mesh
% in real world coordinates (say 0.5,0.5,0.5) and saves the voxel size( say
% 0.5^3) with the mesh. Then mrReadMrM returns the coordinate as [1 1 1]
% and tells you the voxel size it used. 
% scaleFactorFromMesh is in mm/voxel
if notDefined('scaleFactorFromMesh')
    errordlg('No mesh scale factor. You must create a new (modern) mesh.'); 
end
str = sprintf('Scale factor %.03f,%.03f,%.03f\n',scaleFactorFromMesh);
statusStringAdd(statusHandle,str);
scaleFactor=scaleFactorFromMesh; % mm per voxel

params.scaleFactor = scaleFactor;

return