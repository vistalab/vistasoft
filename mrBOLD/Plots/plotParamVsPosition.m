function plotParamVsPosition(view, plotParam, scanList); 
%
%   plotParamVsPosition( view, plotParam, [scanList]); 
%   Example:  plotParamVsPosition( INPLANE{1}, 'co'); 
%   Normally set up from plotMenu callback
%
%Author: Wandell
%Purpose:
%   Plot the values of various parameters for data on a line ROI
%
%$date$


if ~strcmp(view.viewType,'Flat')
    error('plotParamVsPosition only applies to line ROIs in the Flat view');
end

switch plotParam
    case 'Phase',
        paramName = 'ph';
    case 'Amplitude',
        paramName = 'amp';
    case 'Co',
        paramName = 'co';
    case 'ProjAmp',
        error('Not yet implemented');
end

selectGraphWin
fontSize = 14;

ROIcoords = getCurROIcoords(view);

if(exist('scanList','var'))
    if isempty(scanList)
        scanList = selectScans(view,'Select Scans');
    else
        for ii=1:length(scanList)
            subdata(:,ii) = getCurDataROI(view, paramName, scanList(ii), ROIcoords)';
        end
    end
    
else
    scanNum = getCurScan(view);
    subdata = getCurDataROI(view, paramName, scanNum, ROIcoords);
end

plot(1:size(ROIcoords,2),subdata)

set(gca,'FontSize',fontSize)
xlabel('ROI pixel')
ylabel(plotParam)
ylim([0 2*pi])
set(gca,'UserData',subdata);
headerStr = sprintf('Parameter: %s. Line ROI ',plotParam);
set(gcf,'Name',headerStr);
grid on

return;

% Debug
view = FLAT{1};
plotParam = 'Amplitude';
plotParam = 'Co';
plotParam = 'Phase';
plotParam = 'ProjAmp';

scanList = [1 2];
plotParamVsPosition( view, plotParam, scanList); 

% How to commit this file.
baseDir = 'g:\VISTASOFT\mrLoadRet-3.0';
respositoryName = 'VISTASOFT';
fname = {'plotParamVsPosition.m'};
cvsAddNewFiles(baseDir,fname,respositoryName);