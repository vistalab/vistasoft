function [sINP,curScan,nROI] = meshVOL2INP(handles)
%
%   [sINP,curScan,nROI] = meshVOL2INP(handles)
%
% Author: Wandell
% Purpose:
%     Using data from the open3dwindow handles either identify or create a
%     selected INPLANE view (sINP), determine the current scan (curScan)
%     of the currently selected VOLUME view, and set the INPLANE to that
%     scan and data type.  Then, create an ROI in the INPLANE view whose
%     position matches that of the cursor and disk size in the
%     open3dWindow.  This ROI is number nROI.
%
% Example:
%   

global INPLANE;
global selectedINPLANE;
global VOLUME;

if isempty(INPLANE), 
    INPLANE{1} = initHiddenInplane;
    INPLANE{1} = viewSet(INPLANE{1},'name','hidden');
    selectedINPLANE = 1;
end

% nROI is the number of the ROI in the INPLANE view. sINP and sVOL are the
% selected INPLANE and VOLUMEs.
[sINP,sVOL,nROI] = meshROIdiskInplane(handles);

% Plot the time series using the VOLUME scan number.  
curScan =     viewGet(VOLUME{sVOL},'currentscan');
curDataType = viewGet(VOLUME{sVOL},'datatypenumber');

% Make sure the data type in the INPLANE is the same as the one in the
% VOLUME
INPLANE{sINP} = viewSet(INPLANE{sINP},'datatypenumber',curDataType);
INPLANE{sINP} = viewSet(INPLANE{sINP},'currentscan',curScan);

end
