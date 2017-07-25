function mapVals = rmOverlapMap(model, mask, X, Y);
% Produce a single pRF / stimulus overlap mapVals given some low-level inputs.
%
%  mapVals = rmOverlapMap(model, mask, X, Y);
%
% model should be a pRF / RM Model struct (or a path to an RM file).
%
% mask should be a single, 2D, binary stimulus mask, sampled at the
% retinotopic points represented in X and Y.
%
% X and Y can either be the range of x and y points at which the mask was
% sampled, or matrices (e.g. produced my MESHGRID) matching the size of
% mask. Direction conventions: +x is right, -x is left; +y is up, -y is
% down.
%
% Returns a vector of mapVals values representing the proportion of each
% voxel's pRF which is contained within the mask.
%
% Currently implemented only for Volume/Gray views models.
%
% SEE ALSO: rmComputeOverlapMaps.
%
% ras, 11/2007.
if nargin < 4, error('Need all 4 input arguments.');	end
if iscell(model),	model = model{1};		end

if ~isequal( size(mask), size(X) ) | ~isequal( size(mask), size(X) )
	% assume x and y ranges were input
	xRange = unique(X);
	yRange = unique(Y);
	[X Y] = meshgrid(xRange, yRange);
end

% get indices in the mask
I = find(mask);

%% main loop, create pRF for each voxel, convolve w/ mask
% Doing this one voxel at a time takes a LONG time (hours).
% But trying to make all the pRFs at once may cause an
% out-of-memory error. So, we split the difference: do it
% in batches of size n (chosen to work on my ~2005 Windows box;
% adjust as needed).
n = 50;  % compute n pRFs at once
nVoxels = length(model.x0);
verbose = prefsVerboseCheck;
if verbose
	hwait = mrvWaitbar(0, 'Computing pRF Overlap Map...');
end

% go
for v = 1:n:nVoxels
	rng = [0:n-1] + v;  % take this bunch of voxels first
	rng = rng( rng < nVoxels );  % out-of-range check
	
	% grab params for this batch
	x0 = model.x0(rng);
	y0 = model.y0(rng);
	sigma = model.sigma.major(rng);
	
	% make pRFs for this batch
	pRFs = rfGaussian2D(X, Y, sigma, sigma, 0, x0, y0);
	
	% loop across pRFs, convolving each with the mask
	for ii = 1:length(rng)
		mapVals(rng(ii)) = sum(pRFs(I,ii)) ./ sum(pRFs(:,ii));
	end
	
	if verbose, mrvWaitbar(v/nVoxels, hwait); end
end

if verbose,	close(hwait); end

return
