function [msh] = meshBuildFromNiftiClass(NiftiClassFile,hemisphere,inflateFlag,numGrayLayers)
% Builds and visualizes a mesh from a Nifti classification image from ITKGray
%  
%   [msh] = meshBuildFromNiftiClass(NiftiClassFile,hemisphere,[inflateFlag=0],[numGrayLayers=0])
%
% Builds a mesh from a nifti classification from itkGray.  You can add gray
% layers and you can inflate using mrmInflate if you set inflateFlag to 1.
%
% See also: meshBuildFromClass 
% 
% Example: 
%   fName=fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','t1_class.nii.gz');
%   msh = meshBuildFromNiftiClass(fName,'right')
%
% Author: Andreas Rauschecker June 19, 2008
%
% (c) Stanford VISTA Team, 2008

if notDefined('hemisphere'), hemisphere = 'left'; end
if notDefined('numGrayLayers'), numGrayLayers = 0; end
if notDefined('inflateFlag'), inflateFlag = 1; end

classNi = niftiRead(NiftiClassFile);
class   = readClassFile(classNi,0,0,hemisphere);
[nodes,edges,classData] = mrgGrowGray(class,numGrayLayers);

wm = uint8( (classData.data == classData.type.white) | (classData.data == classData.type.gray));

msh = meshBuildFromClass(wm,[1 1 1]);
msh = meshSmooth(msh);
msh = meshColor(msh);
if inflateFlag
    msh = mrmInflate(msh,400);
end

%mrmStart;
meshVisualize(msh);

return;


%% Extra for debugging

% To Save the mrGray class file
class.header.minor = 1;
writeClassFile(class,'right.Class');



NiftiClassFile='/biac2/wandell2/data/anatomy/dougherty/t1_class.nii.gz';
hemisphere='left'
classNi = niftiRead(NiftiClassFile);
class = readClassFile(classNi,0,0,hemisphere);
[nodes,edges,classData] = mrgGrowGray(class,3);
wm = uint8( (classData.data == classData.type.white) | (classData.data == classData.type.gray));
[msh.triangles,msh.vertices] = isosurface(wm, 0.5);
msh = mrmSet(msh,'origin',-mean(msh.vertices'));
msh = mrmInitMesh(msh)
meshVisualize(msh);

