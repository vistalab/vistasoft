function mr2 = mrXform(mr, xform, interpMethod, varargin);
% Transform and reslice an mr file.
% 
%  mr2 = mrXform(mr, xform, [interpMethod='linear'], [options]);
%
% **** DOES NOT YET WORK *****
% (This is a sketch, but the xforms are not being correctly applied.)
%
% Will apply the transform specified in xform to MR data,
% and return a resampled mr struct. If the input data is 4D, each 3D
% subvolume will have the xform applied to it separately.
%
% Possible interp methods are:
%	'nearest': Use nearest-neighbor interpolation.
%	'linear': Linear interpolation using mrVista's myCinterp3 function.
%	'cubic': Cubic interpolation using MATLAB interp3.
%	'spline': Spline interpolation using MATLAB interp3.
%	'spm': B-spline interpolation using SPM's spm_bsplinc function.
%	Requires spm2 or later.
%
% Options include: 
%	'boundingbox', [minY minX minZ; maxY maxX maxZ]: set the bounding box
%	for the resampled volume. Defaults to a size that will capture the
%	whole transformed image, padding the corners with zeros if it is
%	rotated.
%
%	'showprogress', [1 or 0]: show a progress bar. If omitted, gets from
%	the VISTA 'verbose' preference.
%
% ras, 03/02/07. Started.
if nargin<2, error('Need an mr struct and xform'); end

if notDefined('mr'),			mr = mrLoad;				end
if notDefined('interpMethod'),	interpMethod = 'linear';	end

%% defaults
verbose = prefsVerboseCheck;
bb = [-mr.dims(1:3)./2; mr.dims(1:3)./2];

%% parse options here (N.Y.I.)
opts = unNestCell(varargin);

%% initialize the output mr
mr2 = mr;

%% If we have a 4D volume, recursivel xform each 3D subvolume.
if ndims(mr.data) > 3
	mr2.data = [];
	for t = 1:mr.dims(4)
		tmp = mr; tmp.data = mr.data(:,:,:,t);
		tmp = mrXform(tmp, xform, interpMethod, varargin);
		mr2.data(:,:,:,t) = tmp.data;
	end
	return
end

%% get coordinates of mr data; transform to new coordinates
coords = mrGet(mr2, 'coords');
C = coordsXform(xform, coords)'; % new coords

%% main switchyard: interpolate according to the method
switch lower(interpMethod)
	case 'nearest'	
		% using myCinterp3 on rounded coords is faster than indexing...
		mr2.data = myCinterp3(mr.data, [mr.dims(1) mr.dims(2)], mr.dims(3), ...
								round(C([2 1 3],:)'), 0.0);
	case 'linear'
		mr2.data = myCinterp3(mr.data, [mr.dims(1) mr.dims(2)], mr.dims(3), ...
								C([2 1 3],:)', 0.0);		
	case 'cubic'
		mr2.data = interp3(vol, C(2,:), C(1,:), C(3,:), 'cubic');
			
	case 'spline'
		mr2.data = interp3(vol, C(2,:), C(1,:), C(3,:), 'spline');
			
	case 'spm'
		mr2.data = mrAnatResliceSpm(mr.data, xform, bb, mr.voxelSize(1:3), ...
									[], verbose);
								
	otherwise
		error('Invalid interpolation method.')
								
end

%% ensure size and dimensions are correct
switch lower(interpMethod)
	case {'nearest' 'linear' 'cubic' 'spline'}
		% data are in a vector; reshape
		mr2.dims = diff(bb, 1, 1);
		mr2.data = reshape(mr2.data, mr2.dims);
		
	case {'spm'}
		% data are in a matrix: record size
		mr2.dims = size(mr2.data);
end

% figure out new voxel size: this may be tricky
[trans rot scale skew] = affineDecompose(xform);
mr2.voxelSize(1:3) = mr.voxelSize(1:3) .* scale;
mr2.extent(1:3) = mr2.voxelSize(1:3) .* mr2.dims(1:3);

return
