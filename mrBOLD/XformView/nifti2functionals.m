function vw = nifti2functionals(vw, mappth, t1pth)
%   Convert a 3D map from a nifti file into a mrVista format parameter map 
%
% vw = nifti2functionals([vw], [mappth], [t1pth])
%
% vw:       mrVista view structure (must be gray view) 
%               [default = current Gray view]               
% mappth:   path to nifti file with map to convert; 
%               [default = dialog]
% t1pth:    path to the t1-weighted anatomical image associated with the scan; 
%               [default = vANATOMYPATH]
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
if ~exist('vw', 'var') || isempty(vw), 
    vw = getSelectedGray; 
end

if ~exist('mappth', 'var') || ~exist(mappth, 'file') 
    mappth = getPathStrDialog(dataDir(vw),'Choose nifti parameter map','*.nii.gz');
end

if ~exist('t1pth', 'var')
    t1pth = vANATOMYPATH;  
    if ~exist(t1pth, 'file')
        t1pth = getPathStrDialog(dataDir(vw),'Select t1 anatomy file','*.nii.gz');
    end
end

% **********************
% Read in the map
% **********************
% Initialize the output variable
parameterMap = cell(1);

% fname for par map should be same as mappth except ".nii.gz" => ".mat"
[p fname] = fileparts(mappth); %#ok<ASGLU>
[p fname] = fileparts(fname); %#ok<ASGLU>

% read a nifti file with map to be converted
ni = readFileNifti(mappth);

% read the associated t1 nifti
t1  = readFileNifti(t1pth);


% **********************
% Xform coordinates
% **********************

% convert the 3D map to a vector with associated subscripts (x,y,z coords)
map.orig.vector     = ni.data(:)';

% i j k are the indices in the image space of the t1 we read in
[i j k]             = ind2sub(size(ni.data), 1:numel(map.orig.vector));
map.orig.ijk        = single([i; j; k]); clear i j k;

% convert the map coords to ACPC space (we need to do this in case the
% nifti file with the map has been cropped or rotated relative to the t1
% anatomy file)
xyz                 = mrAnatXformCoords(ni.qto_xyz, map.orig.ijk)';

% then convert the map to image space of the t1, which should be the same
% as image space of the mrVista session
map.acpc.ijk        = round(mrAnatXformCoords(t1.qto_ijk, xyz))';

% rebuild the vectorized map and subscripts into a 3d space so that we can
%  flip and permute it acc to our mrVista conventions
map.acpc.mat        = nan(size(t1.data));
map.acpc.inds       = sub2ind(size(map.acpc.mat), map.acpc.ijk(1,:), map.acpc.ijk(2,:), map.acpc.ijk(3,:));

map.acpc.mat(map.acpc.inds) = map.orig.vector;
map.vista.mat       = nifti2mrVistaAnat(map.acpc.mat);

[i j k]             = ind2sub(size(map.vista.mat), 1:numel(map.vista.mat));
map.vista.ijk       = [i; j; k]; clear i j k;
map.vista.vector    = map.vista.mat(:)';


% get the coords of the vista session
coords = viewGet(vw, 'grayCoords');

% Find the indexed values of the gray coordinates that correspond with the
% coords from the map. we round the map values because we know the gray
% coords are integers. if we do not round, then we might find no intersection.
% A more accurate method would be to use interp2 instead of round.
[~, map.vista.inds, grayIndices] = intersectCols(round(map.vista.ijk), coords);


% *****************************************
% Create and save the parameter map
% *****************************************

% initialize the map
parameterMap{1} = nan(1, length(map.vista.inds));

% set the values
parameterMap{1}(grayIndices) = map.vista.vector(map.vista.inds);

% add map to mrVista view
vw = setParameterMap(vw,parameterMap,fname);

% Save file
pathStr = fullfile(dataDir(vw), sprintf('%s.mat', fname)); 
saveParameterMap(vw, pathStr);

return