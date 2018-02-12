function blurTimeSeries(view,scanList,cutoffFreq)
%
% blurTimeSeries(view,[scanList],[cutoffFreq])
%
% Temporal lowpass filter.
% Creates dataType 'Lowpass' if it doesn't already exist.
% Output is a new set of tSeries files in a new Scan subdirectory
% under the Lowpass directory.
% Uses the current dataType of the view to determine which tSeries
% to filter.
%
% scanList: default is to bring up check-box dialog
% cutoffFreq: not yet implemented
%
% djh, 7/19/2002
% Modified from averageTSeries.m
%
% Bugs: dont currently use cuffofFreq, just blur by a fixed amount.
% Will need to add this feature later.

mrGlobals

if ~exist('scanList','var')
    scanList = selectScans(view);
end

if ~existDataType('Lowpass')
    addDataType('Lowpass');
end

% *** change this according to cutoffFreq
filt = namedFilter('binom5');

% Open a hidden view and set its dataType to 'Lowpass'
switch view.viewType
case 'Inplane'
    hiddenView = initHiddenInplane;
case 'Volume'
    hiddenView = initHiddenVolume;
case 'Gray'
    hiddenView = initHiddenGray;
case 'Flat'
    hiddenView = initHiddenFlat(viewDir(view));
end
hiddenView = selectDataType(hiddenView,existDataType('Lowpass'));

% Get the tSeries directory for this dataType 
% (make the directory if it doesn't already exist).
tseriesdir = tSeriesDir(hiddenView);

% Loop through scans in scanList
waitHandle = mrvWaitbar(0,'Lowpass filtering tSeries.  Please wait...');
nScans = length(scanList);
for newScanNum = 1:nScans
	origScanNum = scanList(newScanNum);
	
	% Make the Scan subdirectory for the new tSeries (if it doesn't exist)
	scandir = fullfile(tseriesdir,['Scan',num2str(newScanNum)]);
	if ~exist(scandir,'dir')
		mkdir(tseriesdir,['Scan',num2str(newScanNum)]);
	end
	
	% Loop through slices
	nSlices = length(sliceList(view,origScanNum));
    dimNum = 0;
	for iSlice = sliceList(view,scanList(1));
		tSeries = loadtSeries(view,origScanNum,iSlice);
        dimNum = numel(size(tSeries));
		tmp = corrDn(tSeries,filt,'circular',[2 1]);
		result = upConv(tmp,filt,'circular',[2 1]);
		resultFull = cat(dimNum + 1, resultFull, result);
    end
    
    if dimNum == 3
        resultFull = reshape(resultFull,[1,2,4,3]);
    end %if
    
    savetSeries(resultFull,hiddenView,newScanNum);
	
	% update dataTYPES.scanParams so that new scan has the same params as
	% the orig scan.
	ndataType = hiddenView.curDataType;
	dataTYPES(ndataType).scanParams(newScanNum) = ...
		dataTYPES(view.curDataType).scanParams(origScanNum);
	dataTYPES(ndataType).blockedAnalysisParams(newScanNum) = ...
		dataTYPES(view.curDataType).blockedAnalysisParams(origScanNum);
	dataTYPES(ndataType).eventAnalysisParams(newScanNum) = ...
		dataTYPES(view.curDataType).eventAnalysisParams(origScanNum);
	dataTYPES(ndataType).scanParams(newScanNum).annotation = ...
		['Lowpass of ',getDataTypeName(view),', scan: ',num2str(origScanNum)];
	saveSession
	
	mrvWaitbar(newScanNum/nScans);
end
close(waitHandle);

return

% Debug/test
blurTimeSeries(INPLANE{1});

