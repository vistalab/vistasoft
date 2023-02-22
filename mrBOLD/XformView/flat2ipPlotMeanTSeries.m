function data = flat2ipPlotMeanTSeries(view, scan, plotType);
% Xform an ROI from a FLAT view to an INPLANE view, then plot one of the
% standard measures (e.g., mean time series).
%
%  flat2ipPlotMeanTSeries(view, scan, <plotType='meanTSeries'>);
%
% ras, 08/2008.
if notDefined('plotType'), plotType = 'meanTSeries';		end

global FLAT
global selectedFlat
global VOLUME
global selectedVOLUME
global INPLANE
global selectedINPLANE

selectedFLAT = viewSelected('flat');

%initiate and / or select VOLUME and INPLANE windows
if isempty(VOLUME),
    VOLUME{1} = initHiddenGray;
    VOLUME{1} = viewSet(VOLUME{1},'name','hidden');
    selectedVOlUME = 1;
else
    selectedVOLUME = viewSelected('volume');
end

if isempty(INPLANE),
    INPLANE{1} = initHiddenInplane;
    INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
    selectedINPLANE = 1;
else
    selectedINPLANE = viewSelected('inplane');
end

% Set the Inplane scan number and datatype to match the Flat view.
curDataType = viewGet(FLAT{selectedFLAT},'datatypenumber');
INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'datatypenumber',curDataType);
INPLANE{selectedINPLANE} = viewSet(INPLANE{selectedINPLANE},'currentscan',scan);

% Transfer current FLAT ROI to INPLANE
INPLANE{selectedINPLANE} = flat2ipCurROI(view,INPLANE{selectedINPLANE},VOLUME{selectedVOLUME});

% try to plot from INPLANE
try
    switch lower(plotType)
        case 'meantseries', data = plotMeanTSeries(INPLANE{selectedINPLANE}, scan);
        case 'meanfft', data = plotMeanFFTSeries(INPLANE{selectedINPLANE}, scan);
    end
    fprintf('[%s]: plotting data from inplanes\n', mfilename);


catch
    % if INPLANE fails plot from VOLUME (and if this fails we give up)
    VOLUME{selectedVOLUME}  = flat2volCurROI(view,VOLUME{selectedVOLUME});
    VOLUME{selectedVOLUME}  = viewSet(VOLUME{selectedVOLUME} ,'datatypenumber',curDataType);
    VOLUME{selectedVOLUME}  = viewSet(VOLUME{selectedVOLUME},'currentscan',scan);
    switch lower(plotType)
        % Transfer current FLAT ROI to VOLUME
        case 'meantseries', data = plotMeanTSeries(VOLUME{selectedVOLUME}, scan);
        case 'meanfft', data = plotMeanFFTSeries(VOLUME{selectedVOLUME}, scan);
    end
    fprintf('[%s]: plotting data from VOLUME\n', mfilename);
end

return
