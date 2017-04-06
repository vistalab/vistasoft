function vw = nifti2ROI(vw, mappth)
%   Convert a nifti label file into a mrVista format ROI 
%
% vw = nifti2ROI([vw], [mappth])
%
% vw:       mrVista view structure (must be gray view) 
%               [default = current Gray view]               
% mappth:   path to nifti file with map to convert; 
%               [default = dialog]
%
% Notes: the nifti format map is a 3D matrix. The mrVista parameter map is
% a vector, indexed to the gray coords. The main steps of the routine are:
%   1) Convert the nifti format 3D map to a vector and 3xN coordinate
%           matrix
%   2) Transform the coordinates to the space of the t1-weighted anatomy
%       (using header information in the two files)       
%   3) Transform the coordinates to mrAnat conventions
%
% Example:  Convert a class file into ROIs
% vw = nifti2ROI(vw, viewGet(vw, 'class file', 'right'))
%
%   JW, 4/27/2015
%

mrGlobals;

% Variable check
if notDefined('vw'), vw = getSelectedGray; end

if ~exist('mappth', 'var') || ~exist(mappth, 'file') 
    mappth = getPathStrDialog(dataDir(vw),'Choose nifti parameter map','*.nii.gz');
end

% read a nifti file with map to be converted to ROIs
ni = niftiRead(mappth);

% apply our canonical transform to ensure orientation is matched to t1;
ni   = niftiApplyCannonicalXform(ni);

% This is the map data
data = niftiGet(ni, 'data');
data = nifti2mrVistaAnat(data);
data = round(data);
% ensure data are integers
assert(isequal(data, round(data)));

% define ROIs
labels = setdiff(unique(data(:)),0);

fprintf('[%s]: Creating %d ROIs from file %s\n', mfilename, length(labels), mappth);

for ii = 1:length(labels)
   [x, y, z] = ind2sub(size(data), find(data == labels(ii)));
   coords = [x y z]';
   comments = sprintf('ROI defined by label %d in map %s', labels(ii), mappth);
   name = sprintf('ROI_%03d', labels(ii));
   fprintf('.');drawnow();
   vw = newROI(vw,name,1,'k',coords, comments);
end

return
