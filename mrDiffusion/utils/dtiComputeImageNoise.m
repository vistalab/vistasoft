function dtiComputeImageNoise(dwRaw,bvals, brainMask)


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
    % Pull out the data from the brain mask
    data = 
    
    
    
    % Find which volumes ar b=0
    b0inds = find(bvals ==  0);
    % Pull out the b=0 volumes
    dataB0 = squeeze(data(b0inds,1,:));
    % Calculate the median of the standard deviation. We do not think that
    % this needs to be rescaled. Henkelman et al. (1985) suggest that this
    % aproaches the true noise as the signal increases.
    sigma = median(std(dataB0,0,1));
end