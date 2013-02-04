function sigma = dtiComputeImageNoise(dwRaw, bvals, brainMask, noiseCalcMethod)
% Compute image noise from a 4-d DWI image
%
% sigma = dtiComputeImageNoise(dwRaw, bvals, brainMask, [noiseCalcMethod])
%
% Takes in dwi data and returns sigma, the image noise
%
% dwRaw    - Nifti structure of the dwi data
% bvals    - A 1xN vector of bvalues for each volume in dwRaw
% brainMask- A 3-D matrix of binary values  denoting which voxels are
%            insided the brain. This is only necesary for noiseCalcMethod =
%            'b0'
% noiseCalcMethod- Whether to calculate the noise based on the corner of
%                  the image (default) or based on the standard deviation
%                  of the b=0 images ('b0').

if ~exist('noiseCalcMethod','var') || isempty(noiseCalcMethod)
    noiseCalcMethod = 'corner';
end

if strcmp('corner', noiseCalcMethod)
    
    % According to Henkelman (1985), the expected signal variance (sigma) can
    % be computed as 1.5267 * SD of the background (thermal) noise.
    sz = size(dwRaw.data);
    x  = 10;
    y  = 10;
    z  = round(sz(3)/2);
    
    [x,y,z,s] = ndgrid(x-5:x+5, y-5:y:5, z-5:z+5, 1:sz(4));
    noiseInds = sub2ind(sz, x(:), y(:), z(:), s(:));
    sigma     = 1.5267 * std(double(dwRaw.data(noiseInds)));
    
elseif strcmp('b0', noiseCalcMethod)
    
    % Number of volumes in the dw dataset
    numVols   = size(dwRaw.data,4);
    % Get brainmask indices
    brainInds = find(brainMask);
    % preallocate a 2d array (with a 2nd dimension that is a singleton). The
    % first dimension is the number of volumes and the 3rd is each voxel
    % (within the brain mask).
    data      = zeros(numVols,1,length(brainInds));  
    % Loop over the volumes and assign the voxels within the brain mask to data
    for ii=1:numVols
        tmp = double(dwRaw.data(:,:,:,ii));
        data(ii,1,:) = tmp(brainInds);
    end
    
    % Find which volumes ar b=0
    b0inds = find(bvals ==  0);
    n = length(b0inds);
    % Pull out the b=0 volumes
    dataB0 = squeeze(data(b0inds,1,:));
    % Calculate the median of the standard deviation. We do not think that
    % this needs to be rescaled. Henkelman et al. (1985) suggest that this
    % aproaches the true noise as the signal increases.
    sigma = median(std(dataB0,0,1));
    
    % std of a sample underestimates sigma (see http://nbviewer.ipython.org/4287207/)
    % This can be very big for small n (e.g., 20% for n=2)
    % We can compute the underestimation bias:
    bias = sigma * (1 - sqrt(2 / (n-1)) * (gamma(n / 2) / gamma((n-1) / 2)));
    
    % and correct for it:
    sigma = sigma + bias;
end