function tSeries = meanTSeriesForPlotting(vw, selectedROIs, getRawData)
% Return the mean t-series for one or more ROIs. Start by checking for data
% in Inplane. If this fails, try the gray view.
%
%   tSeries = meanTSeriesForPlotting(vw, selectedROIs)
%
%   Example:
%
%       tSeries = meanTSeriesForPlotting(vw);
%
%   See: plotMultipleSingleCycleErr.m
%
%   JW, 8/2009: Split off from various plotting functions that each
%   duplicated this code
%   JW, 9/2010: Added flag 'getRawData' in case you want to plot without
%               converting to % signal change, replaced GLOBAL INPLANE with
%               ip
mrGlobals;

viewType = viewGet(vw, 'viewType');

if ~exist('selectedROIs', 'var') || isempty(selectedROIs),
    selectedROIs = roiGetList(vw);
end

if ~exist('getRawData', 'var') || isempty(getRawData),
    getRawData  = false;
end

nROIs = length(selectedROIs);
scan  = viewGet(vw,'currentScan');

switch viewType
    case {'Volume' 'Gray'}   %%%For ROIs in Gray view - xform to inplane
        
        selectedVOLUME = viewSelected('volume');
        
        %initiate hiddenINPLANE
        ip = initHiddenInplane;
        ip = viewSet(ip,'name','hidden');
        
        % Set the Inplane scan number and datatype to match the Volume view.
        curDataType = viewGet(vw,'datatypenumber');
        
        
        ip = viewSet(ip,'datatypenumber',curDataType);
        ip = viewSet(ip,'currentscan',scan);
        
        %Transfer current VOLUME ROI to INPLANE
        for ii = 1:nROIs
            vw = viewSet(vw,'selectedROI', selectedROIs(ii));
            ip = vol2ipCurROI(vw,ip);
            selectedInplaneROIs(ii) = viewGet(ip, 'curroi');
        end
        
        
    case {'Flat'} %%%For ROIs in Flat view - xform to inplane
                
        %initiate and / or select VOLUME and INPLANE windows
        if isempty(VOLUME),
            VOLUME{1} = initHiddenGray;
            VOLUME{1} = viewSet(VOLUME{1},'name','hidden');
        else
            selectedVOLUME = viewSelected('volume');
        end
        
        ip = initHiddenInplane;
        ip = viewSet(ip,'name','hidden');
        
        % Set the Inplane scan number and datatype to match the Flat view.
        %         curScan =     viewGet(FLAT{selectedFLAT},'currentscan');
        curDataType = viewGet(vw,'datatypenumber');
        ip = viewSet(ip,'datatypenumber',curDataType);
        ip = viewSet(ip,'currentscan',scan);
        
        %Transfer current FLAT ROI to INPLANE
        for ii = 1: nROIs
            vw = viewSet(vw,'selectedROI', selectedROIs(ii));
            ip = flat2ipCurROI(vw,ip,VOLUME{selectedVOLUME});
            selectedInplaneROIs(ii) = viewGet(ip, 'curroi');
        end
        
    case {'Inplane'}   %%%For ROIs in INPLANE view - select inplane
        selectedInplaneROIs = selectedROIs;
        ip = vw;
end

% Compute meanTSeries for each ROI
ROIcoords = cell(1,nROIs);
try
    for r=1:nROIs
        ROIcoords{r}=ip.ROIs(selectedInplaneROIs(r)).coords;
    end
    tSeries = meanTSeries(ip,scan,ROIcoords, getRawData);
catch ME
    warning(ME.identifier, ME.message)
    for r=1:nROIs
        ROIcoords{r}=VOLUME{selectedVOLUME}.ROIs(selectedROIs(r)).coords;
    end
    tSeries = meanTSeries(VOLUME{selectedVOLUME},scan,ROIcoords, getRawData);
end

if ~iscell(tSeries)
    tmp{1}=tSeries;
    tSeries=tmp;
end

return
