function view = initHiddenFlat(subdir)
%
%  hiddenFlat = initHiddenFlat([subdir])
%
% subdir: string specifying the flat subdirectory
% 
% ras, 2004: made it
% ras, 04/05, set name to 'hidden'
% ras, 05/05, added curScan field
disp('Initializing HIDDEN Flat view')
% Set viewType
view.name='hidden';
view.viewType='Flat';
% Prompt user for flat subdirectory
if ~exist('subdir','var')
    subdir = getFlatSubdir;
end
view.subdir = subdir;
% Initialize slots for co, amp, and ph
view.co = [];
view.amp = [];
view.ph = [];
view.map = [];
view.mapName = '';
view.mapUnits = '';
% Initialize slots for tSeries
view.tSeries = [];
view.tSeriesScan = NaN;
view.tSeriesSlice = NaN;
% Initialize ROIs
view.ROIs = [];
view.selectedROI = 0;
% Initialize curDataType
view.curDataType = 1;
% Initialize curScan
view.curScan = 1;
% Compute/load coords
view = getFlatLevelCoords(view);
return;
