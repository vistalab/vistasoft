function [d, m, s, curMap] = plotParamVsDistToRoi(distances, binSize, ROI, view,  plotParam, scanNum, plotFlag)
%plotParamVsShorestDistanceToRoi - 
%%  
%   Purpose: Plot a map as a function of input distances. The intention is 
%               to be able to plot data in one ROI as a function of the
%               distance to the closest voxel in a second ROI, such as an
%               isoeccentricity line. The function RoiToRoiDist can be used
%               to get the distances to the second ROI. 
%
%
% [d, m, s, curMap] = plotParamVsDistToRoi(distances, binSize, ROI, view,
% plotParam, scanNum, plotFlag)
%
% Arguments:
%
%  distances:   a vector of distances equal in length to ROI.coords
%  binSize:     size in mm of distances to bin [default = 1]
%  ROI:         mrVista ROI struct or integer indexing a mrVista ROI struct
%  view:        mrVista view struct 
%  plotParam:   data to plot (can be 'ph','co', 'amp', 'map') 
%  scanNum:     number of the scan to obtain data from 
%  plotFlag:    plot the data [default=true] 
%  
%
% Outputs:
%  d : binned distances from each voxel in target ROI to nearest voxel in line ROI
%  m : mean of plotParam at each binned distance 
%  s : sem of plotParam at each binned distance 
%  curMap : unbinned values of plotParam
%
%   HISTORY:
%       2008.02.23: JW adapted it from SOD's plotLineROI and AAB's
%       plotParamVsDistance
%     

% Set up variables and ROIdata structure
if ieNotDefined('view'), view = getCurView; end
if ieNotDefined('ROI') 
    if isempty(view.ROIs(view.selectedROI)), error ('Must have a target ROI selected'); 
    else ROI = view.ROIs(view.selectedROI); end
end
if isnumeric(ROI), ROI = view.ROIs(ROI); end
if ieNotDefined('plotParam'), plotParam = view.ui.displayMode; end
if ieNotDefined('scanNum'), scanNum = getCurScan(view); end
if ieNotDefined('binSize'), binSize = 1; end
if ieNotDefined('plotFlag'), plotFlag = true; end
if length(distances) ~= length(ROI.coords), 
    error(['The number of distances and the number of ROI coords are not the same!'...
    ' Try using RoiToRoiDist to get input distances.']);
end
% Get the map data
curMap = getCurDataROI(view, plotParam, scanNum, ROI);

% Bin the data by distance
binnedDistances = round(distances/ binSize) * binSize;
[m,s] = grpstats([binnedDistances; curMap]', binnedDistances, {'mean', 'sem'});

%if parameter to plot is ph, convert to rectangular coords before averaging
if strcmp(plotParam,'ph'),
    cohMap = getCurDataROI(view, 'co', scanNum, ROI);
    z = cohMap.*exp(i*curMap);
    mReal = grpstats([binnedDistances; real(z);]', binnedDistances, 'mean');
    [mImag,n] = grpstats([binnedDistances; imag(z);]', binnedDistances, {'mean','numel'});
    m(:,2) = angle([mReal(:,2) + mImag(:,2)*i]);
    m(:,2) = mod(m(:,2) + 2*pi, 2*pi);
    
    s = (1 - abs([mReal(:,2) + mImag(:,2)*i])).*(2*pi);
    Sem = sqrt(s)./sqrt(n(:,2));
    s = ones(length(Sem),1);
    s =[s Sem];    

%     z = exp(i*curMap);
%     [mReal,s] = grpstats([binnedDistances; real(z);]', binnedDistances, {'mean', 'sem'});
%     [mImag,s] = grpstats([binnedDistances; imag(z);]', binnedDistances, {'mean', 'sem'});
%     m(:,2) = angle([mReal(:,2) + mImag(:,2)*i]);
%     m(:,2) = mod(m(:,2) + 2*pi, 2*pi);
end



d = m(:,1); %binned distances
m = m(:,2); %mean of data to be plotted at each distance bin
s = s(:,2); %sem of data to be plotted at each distance bin

%Plot the data
if(plotFlag)
    %plot means
    figure; errorbar(d, m, s , 'ko-'); hold on;
    %plot raw
    plot(distances, curMap, '.y');
    %label axes
    xlabel(['distance from each voxel in ' ROI.name ' to nearest voxel in target (mm)']);
    ylabel([plotParam ' +/- sem']);
    title([plotParam ' as a function of distance']);
    %set y limits
    if strcmp(plotParam,'ph'), ylim([0 2*pi]); end
    if strcmp(plotParam,'coh'), ylim([0 1]); end
end