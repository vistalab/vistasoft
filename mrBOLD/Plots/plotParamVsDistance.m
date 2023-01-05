function ROIdata = plotParamVsDistance(view, plotParam, scanNum, ROIdata, binSize, plotFlag); 
%
%  ROIdata = plotParamsVsDistance(view, [plotParam], [scanNum], [ROIdata], [binSize], [plotFlag]);
%
% plots co or ph vs. cortical distance for a flat line ROI
% 
% HISTORY:
%   2003.01.05 AAB wrote it based on plotparamvsposition and cortmag code
%   from Dougherty
%   2008.5.28 KA made this function work not only with 'ph' and 'co' but with
%   'amp' and 'map'.

%%Check and set up views
mrGlobals;

switch(view.viewType)
    case {'Inplane','Volume','Gray'}
        error([mfilename,' doesn''t work for ',view.viewType,'.']);
    case 'Flat'
        % Get a gray structure because we need the gray nodes.
        grayView = getSelectedGray;
        if isempty(grayView)
            grayView = initHiddenGray;
        end
    otherwise
        error([view.viewType,' is unknown!']);
end
flatView = view;

if ~flatView.selectedROI
  myErrorDlg('Must have a selected ROI in the Flat window before parameters can be plotted.');
end

%% Set up variables and ROIdata structure
if ieNotDefined('scanNum'), scanNum = getCurScan(view); end
if ieNotDefined('plotFlag'), plotFlag = 1; end
if ~exist('ROIdata','var'), ROIdata = {}; end
if ~isfield(ROIdata,'name') | isempty('ROIdata.name'); ROIdata.name = flatView.ROIs(flatView.selectedROI).name; end
if ~isfield(ROIdata,'coords') | isempty('ROIdata.coords'); ROIdata.coords=flatView.ROIs(flatView.selectedROI).coords; end
if ~isfield(ROIdata,'mmPerPix') | isempty('ROIdata.mmPerPix'); 
    vANATOMYPATH = getvAnatomyPath(mrSESSION.subject);
    ROIdata.mmPerPix = readVolAnatHeader(vANATOMYPATH); 
end 
ROIdata.ph = getCurDataROI(view, 'ph', scanNum, ROIdata.coords);
ROIdata.co = getCurDataROI(view, 'co', scanNum, ROIdata.coords);
ROIdata.map = getCurDataROI(view, 'map', scanNum, ROIdata.coords);
ROIdata.amp = getCurDataROI(view, 'amp', scanNum, ROIdata.coords);

if ieNotDefined('plotParam') | ieNotDefined('binSize')
    prompt = {'Enter Parameter to plot: co, amp, ph, map','Bin distance'};            
    def = {'map','2'};
    answer = inputdlg(prompt,'Parameter',1,def,'on'); 
    if ~isempty(answer)
        plotParam = answer{1};
        ROIdata.binDist = str2num(answer{2});
    else 
        error('No parameter selected.')
    end 
else 
    ROIdata.binDist = binSize;
end

%% Find gray nodes for each flat ROI coordinate
ROIdata = ROIBuildNodes(ROIdata, flatView, grayView);

%% Assign ROI nodes into bins and find corresponding distances
ROIdata = ROIBuildBins(ROIdata, flatView, grayView);

%% Plot ROI parameter vs. distance
switch plotParam
    case 'ph',
        for binNum=1:length(ROIdata.bins)
            dist(binNum) = ROIdata.bins(binNum).distToPrev;
%             meanParam(binNum) = mean(unwrap(ROIdata.bins(binNum).allPh));
            meanParam(binNum) = mean(unwrapPhases(ROIdata.bins(binNum).allPh));
        end
        
    case 'co',
        for binNum=1:length(ROIdata.bins)
            dist(binNum) = ROIdata.bins(binNum).distToPrev;
            meanParam(binNum) = mean(ROIdata.bins(binNum).allCo);
        end
        
    case 'amp',
        for binNum=1:length(ROIdata.bins)
            dist(binNum) = ROIdata.bins(binNum).distToPrev;
            meanParam(binNum) = mean(ROIdata.bins(binNum).allAmp);
        end
        
    case 'map',
        for binNum=1:length(ROIdata.bins)
            dist(binNum) = ROIdata.bins(binNum).distToPrev;
            meanParam(binNum) = mean(ROIdata.bins(binNum).allMap);
        end
end

if(plotFlag)
    figure;
    plot(cumsum(dist), meanParam);
    set(gca,'FontSize',14)
    xlabel('Cortical Distance (mm)')
    ylabel(plotParam)
    set(gca,'UserData',ROIdata);
    headerStr = sprintf('Parameter: %s. vs. dist;  ROI: %s',plotParam,ROIdata.name);
    set(gcf,'Name',headerStr);
    grid on
end

return;
