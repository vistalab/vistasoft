function [msh,class] = meshBuildFromClass_mrMeshPy(voxels,mmPerVox,hemisphere)
% Build a VTK mesh from a class file
%  
%   [msh,class] = meshBuildFromClass_mrMeshPy(voxels,[mmPerVox],[hemisphere='left'])
%
% voxels: Either
%   - the file name of a white matter class file, or 
%   - the voxel classification data returned from readClassFile (see code)
%    If the file name (class file or nifti file) is entered, then the
%    classification data in the file can be returned. 
%
% mmPerVox:    defaults to [1 1 1] (mm)
% hemisphere:  'right' or 'left' or 'both'
%
% White matter values in the class or NIFTI file are the voxels with the
% value 16.
%
% See also: meshBuild, meshVisualize, 
% 
% Examples:
%   fName=fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
%   msh = meshBuildFromClass(fName);
%   msh = meshSmooth(msh);
%   msh = meshColor(msh);
%   meshVisualize(msh);
%
%   fName ='X:\anatomy\nakadomari\right\20050901_fixV1\right.Class';
%   mmPerVox = [1 1 1];
%   msh = meshBuildFromClass(fName, mmPerVox, 'right');
%   msh = meshSmooth(msh);
%   msh = meshColor(msh);
%   meshVisualize(msh);
%
% Guillaume Bertello (c) Stanford VISTA Team

% PROGRAMMING TODO:  
%   Perhaps we should replace this function with the Matlab isosurface
%   routine. See mrmBuildMeshMatlab.  In general, We would like to get rid
%   of the VTK dependent mex-files for smooth, build, and color.  These can
%   be replaced with matlab mesh functions. We want to reduce the mex file
%   stuff to only the mrMesh related calls to the window.
%
% We would like the mesh vertices to coregister with the vAnatomy or NIFTI
% T1 data.  We need to understand this better.
%

if ieNotDefined('mmPerVox'), mmPerVox = [1 1 1]; end
if ieNotDefined('hemisphere'), hemisphere = 'left'; end
if isempty(voxels) || ischar(voxels)
    switch hemisphere
        case 'both'
            fprintf('[%s]: Loading %s hemisphere white matter voxels...\n', mfilename),'right';
            headerOnly = 0; voiOnly = 0;
            class = readClassFile(voxels,headerOnly,voiOnly,'right');
            voxelsR = uint8(class.data == class.type.white);
            
            fprintf('[%s]: Loading %s hemisphere white matter voxels...\n', mfilename,'left');
            headerOnly = 0; voiOnly = 0;
            class = readClassFile(voxels,headerOnly,voiOnly,'left');
            voxelsL = uint8(class.data == class.type.white);
            
            voxels = voxelsL + voxelsR;
        case {'left','right'}
            fprintf('[%s]: Loading %s hemisphere white matter voxels...\n', mfilename,hemisphere);
            headerOnly = 0; voiOnly = 0;
            class = readClassFile(voxels,headerOnly,voiOnly,hemisphere);
            voxels = uint8(class.data == class.type.white);
        otherwise
            error('[%s]: Unknown hemisphere label', mfilename)
    end
elseif(isstruct(voxels))
    voxels = uint8(voxels.data == voxels.type.white);
end

%% AG EDIT -TODO
%assignin('base','voxels',voxels);

% build_mesh is a dll in VISTASRC.  It converts classification data into
% vertices and triangles.  It could be replaced by the Matlab isosurface
% routine.
fprintf('[%s]: Building a %s hemisphere mesh ...', mfilename, hemisphere)
%%% NEXT LINE REMOVED - now use mrMeshPy's pyMeshBuild instead
%%% msh = build_mesh(voxels,mmPerVox);   % Vertices (class) are in mm space
%%% 

%% new code
% get directory of matlab routine - same place as pyMeshBuild to call later
meshBuildPath = which(mfilename);
[meshBuildDir,~,~] = fileparts(meshBuildPath);

%reshape the voxel array 
voxels = permute(voxels,[3,2,1]);

% create a tmp file to write the data to
voxFileForMrMeshPy = [tempname,'.mat'];
mshFileFromMrMeshPy = [tempname,'.mat'];


%run the pyMeshBuild.py program to generate the meshes
if ismac
    % Mac - same as linux? #TODO
    % save the voxel data to a tmp file
    eval(['save ',voxFileForMrMeshPy,' voxels mmPerVox;']);
    %run the pyMeshBuild app
    cmdString = [meshBuildDir,'/launchMeshBuild.sh ',meshBuildDir,'/pyMeshBuild_mac.py ',voxFileForMrMeshPy,' ',mshFileFromMrMeshPy] %TODO set python path?
    system(cmdString);
    
elseif isunix
    % Linux
    % save the voxel data to a tmp file
    eval(['save ',voxFileForMrMeshPy,' voxels mmPerVox;']);
    %run the pyMeshBuild app
    cmdString = [meshBuildDir,'/launchMeshBuild.sh ',meshBuildDir,'/pyMeshBuild.py ',voxFileForMrMeshPy,' ',mshFileFromMrMeshPy]
    system(cmdString);

elseif ispc
    %  Windows 
    disp('Platform not supported')
    barf for now
else
    disp('Platform not supported')
    return
end

msh = load(mshFileFromMrMeshPy);

% AG EDIT -TODO
assignin('base','msh1',msh);

msh = meshFormat(msh);               % Converts old format to new.

% AG EDIT -TODO
assignin('base','msh2',msh);

% Set the mesh origin, by default, to the center of the object.
vertices = meshGet(msh,'vertices');
msh = meshSet(msh,'origin',-mean(vertices,2)');
msh = meshSet(msh,'mmPerVox',mmPerVox);
fprintf('[%s]: done. \n', mfilename);


assignin('base','msh3',msh);

return;
