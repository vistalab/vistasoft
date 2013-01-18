function groupName = groupScans(view, scanList, groupName, notes)
%
% dataTypeName = groupScans(view, [scanList], [dataTypeName], [annotation])
% 
% Author: Wandell
% Purpose:
%    Select scans from the Original series and make a new dataType
%    containing a subset (unaveraged).  For example, if a scan contains
%    retinotopies and color, you might want them grouped into two different
%    sets.  This occupies more space, but it could make life more
%    efficient for loading and thinking.
%
%    Generally follows the logic in averageTSeries
%
% scanList: scans to be grouped into the new type. Default: prompt user.
% dataTypeName: If omitted, the user is prompted for the name of the group.
% 
% ras 01/05: added option to enter data type name as an input arg.
% ras 10/05: appends scans to specified group if it already exists.
% ras 09/08: added optional annotation for the scans.
mrGlobals;

if (~exist('scanList','var') | isempty(scanList)), scanList = er_selectScans(view); end
if isempty(scanList), return; end
% if ~strcmp(view.viewType,'Inplane'), error('Grouping is only applied in the Inplane view'); end
if notDefined('groupName')
    % Select a name for the group
	groupName = mrSelectName({dataTYPES.name}, view.curDataType);
end

% Add the name to the dataTYPES
if isempty(groupName)
    return;
elseif existDataType(groupName)
    % just append, below
else
    addDataType(groupName); 
end

switch lower(view.viewType),
  case 'inplane',
    hiddenView = initHiddenInplane;
  case 'gray',
    hiddenView = initHiddenGray;
  case 'volume',
    hiddenView = initHiddenVolume;
  case 'flat',
    hiddenView = initHiddenFlat;
end;

srcDt = view.curDataType;
tgtDt = existDataType(groupName);
hiddenView = selectDataType(hiddenView, tgtDt);

% Set dataTYPES.scanParams so that new group scan has the same params as
% the 1st scan on scanList.
newScanNum = length(scanList);
if existDataType(groupName)
    firstNewScan = length(dataTYPES(tgtDt).scanParams)+1;
else
    firstNewScan = 1;
end

newScanRange = firstNewScan:firstNewScan+newScanNum-1;
for ii = 1:length(newScanRange)
    tgt = newScanRange(ii);
    initScan(view, groupName, tgt, {view.curDataType view.curScan});
	
	dataTYPES(tgtDt).scanParams(tgt) = ...
		dataTYPES(view.curDataType).scanParams(scanList(ii));
    dataTYPES(tgtDt).blockedAnalysisParams(tgt) = dataTYPES(view.curDataType).blockedAnalysisParams(scanList(ii));
    
	if notDefined('notes')
		dataTYPES(tgtDt).scanParams(tgt).annotation = ...
			dataTYPES(srcDt).scanParams(scanList(ii)).annotation;
	else
		dataTYPES(tgtDt).scanParams(tgt).annotation = notes;
	end
end
saveSession;

% Get the tSeries directory for this dataType 
% (make the directory if it doesn't already exist).
tseriesdir = tSeriesDir(hiddenView);

% Make the Scan subdirectory for the new tSeries (if it doesn't exist)
scandir = fullfile(tseriesdir, ['Scan',num2str(newScanNum)]);
if ~exist(scandir,'dir')
    mkdir(tseriesdir, ['Scan',num2str(newScanNum)]);
end

% Double loop through slices and scans in scanList
nSlices = length(sliceList(view,scanList(1)));
wbar = waitbar(0,'Copying tseries...');
nTseries = newScanNum*nSlices;
for  iScan = 1:length(newScanRange)
    % For each scan... copy the tseries.
    for iSlice = 1:nSlices
        % For each slice...
        tgt = newScanRange(iScan);
        tSeries = loadtSeries(view, scanList(iScan), iSlice);
        savetSeries(tSeries,hiddenView,tgt,iSlice);
        waitbar((nSlices*(iScan-1) + iSlice)/nTseries,wbar)
    end
end
close(wbar);

% for event-related scans, group the scans
try
    er_groupScans(view, newScanRange, 2, existDataType(groupName));
catch
    % don't worry about it...
end

% Loop through the open views, switch their curDataType appropriately, 
% and update the dataType popups
INPLANE = resetDataTypes(INPLANE,tgtDt);
VOLUME  = resetDataTypes(VOLUME,tgtDt);
FLAT    = resetDataTypes(FLAT,tgtDt);

return;


%---------------------------------------------
function newName = mrSelectName(curNames, defaultVal)
%
% Select a new name for some object.  Show the user the current names,
% generally to be avoided.
%
dlg(1).fieldName = 'existingDt';
dlg(1).style = 'popup';
dlg(1).string = 'Target Data Type for imported scans?';
dlg(1).list = [curNames {'New Data Type (named below)'}];
dlg(1).value = defaultVal;

dlg(2).fieldName = 'newDtName';
dlg(2).style = 'edit';
dlg(2).string = 'Name of new data type (if making a new one)?';
dlg(2).value = '';

[resp, ok] = generalDialog(dlg, 'Group Scans');
if ~ok, return; end

if ismember(resp.existingDt, curNames)
    newName = resp.existingDt;
else
    newName = resp.newDtName;
end

return;
