function [MSE,mn,sd] = motionCompMSE(tSeriesAllSlices,ROI,refImage,plotMSE,plotMSEmean)

%    [MSE,mn,sd] = motionCompMSE(tSeriesAllSlices, [ROI], [refImage], [plotMSE], [plotMSEmean])
%
% gb 01/18/05
%
% Computes the Mean Squared Error between the time series and a reference
% image. 'plotMSE' and 'plotMSE' should be the value '1' if the user wants to
% plot the MSE error and its mean. The variable ROI is a region of the
% image where the error has to be computed.
%   Default : refImage = 0
%             plotMSE = 0
%             plotMSEmean = 0
        
% Initializes arguments and variables
if ieNotDefined('plotMSE')
    plotMSE = 0;
end
if ieNotDefined('plotMSEmean')
    plotMSEmean = 0;
end

% The default shape for a time series is a 4D array :
% [frames sliceDimX sliceDimY slices]
if ndims(tSeriesAllSlices) < 4
    tSeriesAllSlices = shiftdim(tSeriesAllSlices,ndims(tSeriesAllSlices) - 4);
end

nFrames  = size(tSeriesAllSlices,1);
nVoxelsX = size(tSeriesAllSlices,2);
nVoxelsY = size(tSeriesAllSlices,3);
nSlices  = size(tSeriesAllSlices,4);
nVoxels = nVoxelsX * nVoxelsY;

if ieNotDefined('ROI')
    ROI = ones(1,nVoxelsX,nVoxelsY,nSlices);
end

if ieNotDefined('refImage')
    refImage = zeros(1,nVoxelsX,nVoxelsY,nSlices);
end

% Synchronizing the dimensions of the time series and the reference image
if ~isequal(size(refImage),size(tSeriesAllSlices(1,:,:,:)))
    try
        refImage = reshape(refImage,size(tSeriesAllSlices(1,:,:,:)));
    catch
        error('The Reference Image does not have the correct size');
    end
end

% Symchronizing the dimensions of the time series and the region of
% interest
if ~isequal(size(ROI),size(tSeriesAllSlices(1,:,:,:)))
    try
        ROI = reshape(ROI,size(tSeriesAllSlices(1,:,:,:)));
    catch
        error('The Region of interest does not have the correct size');
    end
end

% Computes the difference between the time series and the reference image
MSE = tSeriesAllSlices - repmat(refImage,[nFrames 1 1 1]);

% Applies weights to focus the error on a special region
MSE = MSE.*repmat(ROI, [nFrames 1 1 1]);

% Computes the mean square error
MSE = 1/nVoxels*sqrt(sum(sum(sum(MSE.^2,4),3),2));

% Computes the mean and the standard deviation of the MSE
mn = mean(MSE);
sd = std(MSE);

% Plots the curves
if plotMSE > 0
    if gcf == 1
        figure;
    end
    hold off
    plot(MSE);
end

if plotMSEmean > 0 
    if gcf == 1
        figure;
    end
    hold on
    plot([1 nFrames],[mn + 2*sd,mn + 2*sd]);
    hold off
end
