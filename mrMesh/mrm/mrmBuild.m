function [msh, unsmoothedMsh] = mrmBuild(wm,mmPerVox,smoothFlag,visualizeFlag,varargin)
%Build a smoothed and unsmooth mesh from a white matter voxels
%
%  [msh, lights, unsmoothedMsh] = mrmBuild(wm,mmPerVox,smoothFlag,visualizeFlag,varargin)
%
% If you do not want the smoothed mesh, set smoothFlag = 0
%
% This routine will replace mrmBuildMesh shortly.
% 

if ieNotDefined('wm'), error('White matter voxels required.'); end
if ieNotDefined('mmPerVox'),      mmPerVox = [1 1 1]; end
if ieNotDefined('smoothFlag'),    smoothFlag = 1; end
if ieNotDefined('visualizeFlag'), visualizeFlag = 1; end
lights = [];

nVar = length(varargin);
if mod(nVar,2), error('Parameters must be (name,value)'); end

% Build the one that is only marching cubes
unsmoothedMsh = meshBuildFromClass(wm,mmPerVox);

% We should think about moving the proper format of msh into buildMesh (the
% mex file).  This requires recompilation, we think, so for now we are
% handling this issue outside of the mex files, in Matlab.
unsmoothedMsh = meshFormat(unsmoothedMsh);
% meshVisualize(unsmoothedMsh); 

msh = unsmoothedMsh;

% Let VTK smooth the mesh
if smoothFlag,
    for ii=1:2:nVar
        msh = meshSet(msh,varargin{ii},str2num(varargin{ii+1}));
    end
    msh = meshSmooth(unsmoothedMsh);
    msh = meshColor(msh);
end

% Return the user the lights
if visualizeFlag, [msh,lights] = meshVisualize(msh); end

return;

