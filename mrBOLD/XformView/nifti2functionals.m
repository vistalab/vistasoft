function vw = nifti2functionals(vw, mappth)
%   Convert a 3D map from a nifti file into a mrVista format parameter map 
%
% vw = nifti2functionals([vw], [mappth])
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
%   4) Save as a parameter map
%
% Example: nifti2functionals(vw, mappth)
%
%   JW, 4/27/2009
%

mrGlobals;

% **********************
% Variable check
% **********************
if notDefined('vw'), vw = getSelectedGray; end

if ~exist('mappth', 'var') || ~exist(mappth, 'file') 
    mappth = getPathStrDialog(dataDir(vw),'Choose nifti parameter map','*.nii.gz');
end

% **********************
% Read in the map
% **********************
% Initialize the output variable
parameterMap = cell(1);

% fname for par map should be same as mappth except ".nii.gz" => ".mat"
[~, fname] = fileparts(mappth); 
[~, fname] = fileparts(fname); 

% read a nifti file with map to be converted
ni = niftiRead(mappth);

% apply our canonical transform to ensure orientation is matched to t1;
ni   = niftiApplyCannonicalXform(ni);
data = niftiGet(ni, 'data');
data = nifti2mrVistaAnat(data);

coords = viewGet(vw, 'coords');

indices = coords2Indices(coords, size(data));


% *****************************************
% Create and save the parameter map
% *****************************************

% initialize the map
parameterMap{1} = double(data(indices));

% add map to mrVista view
vw = setParameterMap(vw,parameterMap,fname);

return
