function MI = motionCompMI(tSeriesAllSlices,ROI,refImage,plotMI,plotMImean)
% 
%     MI = motionCompMI(tSeriesAllSlices, [ROI], [refImage], [plotMI], [plotMImean])
%     
% gb 01/31/05
%     
% Computes the mutual information of consecutive frames for a whole volume.
% The volume may be loaded with the function motionCompLoadImages. The
% Region Of Interest (ROI) is the region where the mutual information has
% to be computed.

% Initializes arguments and variables

global dataTYPES mrSESSION
try
    mmPerVox = mrSESSION.functionals(1).voxelSize;
catch
    mmPerVox = 1;
end

if ieNotDefined('plotMI')
    plotMI = 0;
end
if ieNotDefined('plotMImean')
    plotMImean = 0;
end
if ndims(tSeriesAllSlices) == 3
    tSeriesAllSlices = shiftdim(tSeriesAllSlices,-1);
end

nFrames = size(tSeriesAllSlices,1);
nVoxelsA = size(tSeriesAllSlices,2);
nVoxelsB = size(tSeriesAllSlices,3);
nSlices = size(tSeriesAllSlices,4);

if ieNotDefined('ROI')
    ROI = ones(nVoxelsA,nVoxelsB,nSlices);
end

if ~isequal(size(ROI),size(squeeze(tSeriesAllSlices(1,:,:,:))))
    try
        ROI = reshape(ROI,size(squeeze(tSeriesAllSlices(1,:,:,:))));
    catch
        % The ROI is frequently set to the wrong size. Still can't figure
        % out where this happens -- the first time this is called, it's ok.
        % So, for now, don't crash the whole motion comp procedure if this
        % fails. -ras, 02/06
        warning('The Region of interest does not have the correct size. Aborting...');
        MI = zeros(nFrames-1, 1);
        return
    end
end
ROI = ROI/max(ROI(:));
ROI = uint8(255*ROI);
    
N = 256;

MI = zeros(nFrames - 1,1);

normalize = 1;
acc = 0.0232;

if ~ieNotDefined('refImage')
    if ndims(refImage) == 3
        refImage = shiftdim(refImage,-1);
    end
    mx = max(refImage(:));
    mn = min(refImage(:));
else
    mx = 0;
    mn = 0;
end

rand('state',100);
r = rand(size(tSeriesAllSlices(1,:,:,:)))*acc;
mn = min(min(tSeriesAllSlices(:)),mn);
mx = max(max(tSeriesAllSlices(:)),mx) + acc;
tSeriesAllSlices = uint8(round((tSeriesAllSlices + repmat(r,[nFrames 1 1 1]) - mn)*(N - 1)/(mx - mn)));

if ~ieNotDefined('refImage')
    refImage = uint8(round((refImage + r - mn)*(N - 1)/(mx - mn)));
    endFrame = 0;
else 
    endFrame = 1;
end

for i = 1:(nFrames - endFrame)
    
    if ieNotDefined('refImage')
        uint8a = squeeze(tSeriesAllSlices(i + 1,:,:,:));
    else
        uint8a = squeeze(refImage);
    end
    uint8b = squeeze(tSeriesAllSlices(i,:,:,:));
    
    % Computes the joint histogram
    H = spm_hist2_weighted_MI(uint8a,uint8b, eye(4), [1 1 1], ROI);
      
    % Computes the mutual information
    MI(i) = motionCompComputeMI(H,normalize);
end

if plotMI > 0
    if gcf == 1
        figure;
    end
    hold off
    plot(MI);
end

if plotMImean > 0 
    if gcf == 1
        figure;
    end
    mn = mean(MI);
    sd = std(MI);

    hold on
    plot([1 nFrames],[mn + 2*sd,mn + 2*sd]);
    hold off
end