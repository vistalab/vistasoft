function tSeries = roiMeanTSeries(scans, getRawData)
% Try to get the mean t-series for an ROI from INPLANE view. If this fails,
% try VOLUME view. Many functions duplicate this code. 

% tSeries = roiMeanTSeries(scans, [getRawData])

mrGlobals;
if ~exist('getRawData', 'var'), getRawData  = false;  end

nScans = length(scans);

tSeries = cell(1, length(scans));
try
    ROIcoords=viewGet( INPLANE{selectedINPLANE}, 'roicoords');
    for s=1:nScans
        tSeries{s} = meanTSeries(INPLANE{selectedINPLANE},scans(s),ROIcoords, getRawData);
    end

catch ME
    warning(ME.identifier, ME.message)
    try
        ROIcoords=viewGet(VOLUME{selectedVOLUME}, 'roicoords');
        for s=1:nScans
            tSeries{s} = meanTSeries(VOLUME{selectedVOLUME},scans(s),ROIcoords, getRawData);
        end
    catch ME
        error(ME.identifier, ME.message)
    end;
end;

return