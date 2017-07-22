function [roi, C] = roiXformCoords(roi, xform, outputVoxSize, sampRate)
% Please document - used a little in mrBOLD land.  ROI coord transforms
% need to be regularized.
%
%   roi = roiXformCoords(roi, xform, [outputVoxSize = 1 1 1], [sampRate])
%
% Transforms ROI coordinates using xform, supersampling in each dimension
% to accumulate partial volumes, then keeping only those voxels with
% partial volumes above thresh.
%
% roi.coords: 3xN matrix of coordinates (y,x,z).
% xform:      4x4 homogeneous transform
% roi.voxelSize(1:3): 3-vector, size of voxels (mm) in roi.coords
% outputVoxSize: 3-vector, size of voxels (mm) in roi.coords
% sampRate: 3-vector, supersampling rate for each dimension
%           default is odd number >= 4x ratio of roi.voxelSize(1:3)/outputVoxSize
%
% roi.coords: 3xN matrix of (y,x,z)
%
% djh, 8/98.  Modified from roi.coords/transformROI.m in mrLoadRet-1
% 7/19/02 djh, modified to maintain equal volumes
% 11/02/05 ARW now returns the 'raw' transformed coordinates - useful for
% various applications including interfacing with SPM
% ras, 02/20/2007 -- imported into mrVista2 from 'xformROIcooords' in
% the VISTASOFT repository.
if nargin < 2, error('Not enough input arguments'); end

if ~exist('outputVoxSize', 'var') || isempty(outputVoxSize)
	outputVoxSize = [1 1 1];
end

if length(roi) > 1	% recursively check many ROIs
	% (sampRate may not be specified -- as a kludge, just use the default 
	% for each ROI)
	for i = 1:length(roi)
		if iscell(roi), roi{i} = roiXformCoords(roi{i}, xform, outputVoxSize);
        else			roi(i) = roiXformCoords(roi(i), xform, outputVoxSize);
		end
	end
	return
end

if isempty(roi.coords), return; end

if ~isa(roi.coords, 'double'), roi.coords = double(roi.coords); end

if ~exist('sampRate','var')
	sampRate = ceil(roi.voxelSize(1:3) ./ outputVoxSize) .* [4,4,4];
	sampRate = 2*floor(sampRate/2) + 1;
end

% Convert ROI coords to homogenous coordinates, by adding a fourth
% row of 1's, and transform. The variable C is an intermediate set
% of coordinates before upsampling (?).
C = ones(4, size(roi.coords,2));
C(1:3,:) = roi.coords;
C = xform * C;

% Find bounding (min and max) volume.
minPos = [min(C(1,:)); min(C(2,:)); min(C(3,:)); 1];
maxPos = [max(C(1,:)); max(C(2,:)); max(C(3,:)); 1];
minPos = floor(minPos) - [2 2 2 0]';
maxPos = ceil(maxPos) + [2 2 2 0]';
dims = maxPos(1:3) - minPos(1:3) + ones(3, 1);

% Initialize accumulator for partial volume calculation, a vector
% of length appropriate to index the bounding volume.
accum = zeros(1, prod(dims));

% Calculate offsets that will be added within the loop to do the
% partial voluming.
xoffsets = [-.5 + 1/(2*sampRate(1)): 1/sampRate(1) : .5 - 1/(2*sampRate(1))];
yoffsets = [-.5 + 1/(2*sampRate(2)): 1/sampRate(2) : .5 - 1/(2*sampRate(2))];
zoffsets = [-.5 + 1/(2*sampRate(3)): 1/sampRate(3) : .5 - 1/(2*sampRate(3))];

% Divide alpha by prod(sampRate) to get partial volume for the
% supersampled voxels.
alpha = repmat(1/prod(sampRate), [1 size(roi.coords,2)]);

verbose = prefsVerboseCheck;
if verbose > 1, waitHandle = mrvWaitbar(0, 'Transforming ROI coordinates...'); end

for ioff = 1:length(xoffsets)
	xoff = xoffsets(ioff);

	if verbose > 1, mrvWaitbar(ioff/length(xoffsets), waitHandle); end

	for yoff = yoffsets
		for zoff = zoffsets
			% Add offset
			offset = repmat([xoff; yoff; zoff], [1 size(roi.coords, 2)]);
			C(1:3,:) = roi.coords + offset;

			% Transform
			C = xform * C;

			% Round and subtract minPos
			coords = round(C(1:3,:)) - repmat(minPos(1:3), [1 size(C, 2)]);

			% Convert to I and remove duplicates
			I = coords2Indices(coords, dims);

			% Accumulate partial volume.  Need to do it in a loop
			% instead of:
			%    accum(I) = accum(I) + alpha;
			% because an index can appear twice in I and we want
			% to accumulate them both.
			for jj = 1:length(I)
				accum(I(jj)) = accum(I(jj)) + alpha(jj);
			end
		end
	end
end

if verbose > 1, close(waitHandle); end

% Build new ROI coordinates
[sortedAccum I] = sort(accum);
nonZeroSize = length(find(accum > 0));
newSize = round(prod(roi.voxelSize(1:3)) * size(roi.coords,2) / prod(outputVoxSize));
newSize = min(nonZeroSize, newSize);
I = I(length(I)-newSize+1:length(I));
if ~isempty(I)
	roi.coords = indices2Coords(I, dims);
	roi.coords = roi.coords + repmat(minPos(1:3), [1 length(I)]);
else
	roi.coords = [];
end

roi.modified = datestr(now);


return;

