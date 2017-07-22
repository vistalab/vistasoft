function [img, h] = rfDensityPlot(pol, ecc, sigma, varargin);
%
% [img, plotHandle] = rfDensityPlot(pol, ecc, sigma, [options]);
%
% Plot the density of estimated population receptive fields
% in the visual field.
%
% ras, 10/2007.
if nargin < 2, error('Not enough input arguments.');    end
if notDefined('sigma'), sigma = ones(size(pol));        end

%% Params
xRng = -15:.1:15;  % sampling rate along X axis
yRng = -15:.1:15;  % sampling rate along Y axis
plotFlag = 1;    % flag to plot the image
polRadians = 0;  % flag: if 1, polar angle is in radians CCW from 3-o-clock
                 % (as per mathematical measures of angle); if 0,
                 % polar angle is degrees CW from 12-o-clock (as is
                 % convenient for describing retinotopy)

%% Parse options
for i = 1:2:length(varargin)
    eval( sprintf('%s = %s', varargin{i}, num2str(varargin{i+1})) );
end

%% Remove NaNs and Infs
ok = find( ~isnan(pol) & ~isinf(pol) & ~isnan(ecc) & ~isinf(ecc) );
pol = pol(ok);
ecc = ecc(ok);
sigma = sigma(:,ok);

%% Make the image
% Get sampling grid of visual field
[X Y] = meshgrid(xRng, yRng);

% initialize a blank image to match the sampling grid
img = zeros(size(X));

% convert polar angle and eccentricity into Cartesian coords
if polRadians==1
    [x0 y0] = pol2cart(pol, ecc);
else
    [x0 y0] = pol2cart( deg2rad(90-pol), ecc );
end

hwait = mrvWaitbar(0, 'Generating RF Density Plot...');

for v = 1:length(x0)
    % compute an RF for this voxel
    RF = rfGaussian2d(X(:), Y(:), sigma(v), sigma(v), 0, x0(v), y0(v));
    RF = reshape(RF, size(img));
    
    % rescale RF so that area = 1
    RF = RF ./ sum( RF(:) );  
    
    % positive Y should map to up instead of down (MATLAB convention):
    RF = flipud(RF);
    
    % add to density map
    img = img + RF;
	
	mrvWaitbar(v/length(x0), hwait);
end

close(hwait)

%% Show the image
if plotFlag==1
    mu = mean(img(:));
    sig = std(img(:));
    clim = [mu-sig mu+sig];
    h = imagesc(image, clim);  
    colormap gray;
else
    h = [];
end

return
