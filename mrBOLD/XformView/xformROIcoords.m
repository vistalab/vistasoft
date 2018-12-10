function [newROIcoords,tmpNewROIcoords] = xformROIcoords(ROIcoords,Xform,inputVoxSize,outputVoxSize,sampRate)
%
% newROIcoords = xformROIcoords(ROIcoords,Xform,inputVoxSize,outputVoxSize,[sampRate])
%
% Transforms ROI coords using Xform, supersampling in each
% dimension to accumulate partial volumes, then keeping only
% those voxels with partial volumes above thresh.
% 
% ROIcoords: 3xN matrix of coordinates (y,x,z).
% Xform: 4x4 homogeneous transform
% inputVoxSize: 3-vector, size of voxels (mm) in ROIcoords
% outputVoxSize: 3-vector, size of voxels (mm) in newROIcoords
% sampRate: 3-vector, supersampling rate for each dimension
%           default is odd number >= 4x ratio of inputVoxSize/outputVoxSize
%
% newROIcoords: 3xN matrix of (y,x,z) 
%
% djh, 8/98.  Modified from ROIcoords/transformROI.m in mrLoadRet-1
% 7/19/02 djh, modified to maintain equal volumes
% 11/02/05 ARW now returns the 'raw' transformed coordinates - useful for
% various applications including interfacing with SPM
if ~isa(ROIcoords, 'double'), ROIcoords = double(ROIcoords); end

if ~exist('sampRate','var')
	sampRate = ceil(inputVoxSize ./ outputVoxSize) .* [4,4,4];
	sampRate = 2*floor(sampRate/2) + 1;
end

% Convert ROI coords to homogenous coordinates, by adding a fourth
% row of 1's, and transform.
%
tmpNewROIcoords = ones(4,size(ROIcoords,2));
tmpNewROIcoords(1:3,:) = ROIcoords;
tmpNewROIcoords = Xform * tmpNewROIcoords;

% Find bounding (min and max) volume.
%
minPos = [min(tmpNewROIcoords(1,:));min(tmpNewROIcoords(2,:));min(tmpNewROIcoords(3,:));1];
maxPos = [max(tmpNewROIcoords(1,:));max(tmpNewROIcoords(2,:));max(tmpNewROIcoords(3,:));1];
minPos = floor(minPos)-[2,2,2,0]';
maxPos = ceil(maxPos)+[2,2,2,0]';
dims = maxPos(1:3)-minPos(1:3)+ones(3,1);

% Initialize accumulator for partial volume calculation, a vector
% of length appropriate to index the bounding volume.
%
accum = zeros(1,prod(dims));

% Calculate offsets that will be added within the loop to do the
% partial voluming.
%
xoffsets=[-.5+1/(2*sampRate(1)):1/sampRate(1):.5-1/(2*sampRate(1))];
yoffsets=[-.5+1/(2*sampRate(2)):1/sampRate(2):.5-1/(2*sampRate(2))];
zoffsets=[-.5+1/(2*sampRate(3)):1/sampRate(3):.5-1/(2*sampRate(3))];
% xoffsets=[0:1/sampRate(1):1-1/sampRate(1)];
% yoffsets=[0:1/sampRate(2):1-1/sampRate(2)];
% zoffsets=[0:1/sampRate(3):1-1/sampRate(3)];

% Divide alpha by prod(sampRate) to get partial volume for the
% supersampled voxels.
%
alpha = repmat(1/prod(sampRate),[1 size(ROIcoords,2)]);

% Set up a mrvWaitbar if needed.
verbose = prefsVerboseCheck;
if verbose > 1
	waitHandle = mrvWaitbar(0,'Transforming ROI coordinates.  Please wait...');
end


% Loop through supersamples, transform them, and accumulate
% partial volume.
%
ROIcoords = double(ROIcoords);
for ioff=1:length(xoffsets)
	xoff=xoffsets(ioff);
	
	if verbose>1, mrvWaitbar(ioff/length(xoffsets)); end
	
	for yoff=yoffsets
		for zoff=zoffsets
			% Add offset
			tmpNewROIcoords(1:3,:) = ROIcoords + ...
				repmat([xoff;yoff;zoff],[1,size(ROIcoords,2)]);
            
			% Transform
			tmpNewROIcoords = Xform * tmpNewROIcoords;
            
			% Round and subtract minPos
			coords = round(tmpNewROIcoords(1:3,:)) - ...
				repmat(minPos(1:3),[1,size(tmpNewROIcoords,2)]);
            
			% Convert to indices and remove duplicates
			indices = coords2Indices(coords,dims);
            
			% Accumulate partial volume.  Need to do it in a loop
			% instead of:
			%    accum(indices) = accum(indices) + alpha;
			% because an index can appear twice in indices and we want
			% to accumulate them both.
			for jj=1:length(indices)
				accum(indices(jj)) = accum(indices(jj)) + alpha(jj);
			end
		end
	end
end

if verbose>1, close(waitHandle); end

% Build newROIcoords
%
[sortedAccum,indices] = sort(accum);
nonZeroSize = length(find(accum > 0));
newROIsize = round(prod(inputVoxSize)*size(ROIcoords,2) / prod(outputVoxSize));
newROIsize = max(1,newROIsize); % we don't want an ROI size of 0. This will cause an error.
newROIsize = min(nonZeroSize,newROIsize);
indices = indices(length(indices)-newROIsize+1:length(indices));
if ~isempty(indices)
  newROIcoords = indices2Coords(indices,dims);
  newROIcoords = newROIcoords + repmat(minPos(1:3),[1,length(indices)]);
else
  newROIcoords = [];
end

return;

%%%%%%%%%%%%%%
% Debug/test %
%%%%%%%%%%%%%%

ROIcoords = [0; 0; 0];
ROIcoords = [1 2 3 4;
	         1 1 1 1;
	         1 1 1 1];
Xform = [1 0 0 0;
	     0 1 0 0;
	     0 0 1 0.5;
	     0 0 0 1];
inputVoxSize = [1,1,1];
outputVoxSize = [1,1,1/2];
xformROIcoords(ROIcoords,Xform,inputVoxSize,outputVoxSize)
