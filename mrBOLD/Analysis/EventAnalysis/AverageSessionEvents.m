function [amps, ampErrs] = AverageSessionEvents(period, scanList, filterRange, typeName);

% [amps, ampErrs] = AverageSessionEvents(period, scanList, filterRange, typeName);
%
% Average together all inplane voxel time series in the current session for
% a specified regular-period event. Returns the reduced time-series as a 4D
% array, nTimeSamples x nX x nY x nSlices. Also returns the standard errors
% at each time point, the amplitude obtained by projecting each event
% time-series vector onto its mean, normalized by the length of that
% vector, and the sem of those amplitudes.
%
% Ress, 4/04

mrGlobals

if isempty(selectedINPLANE)
  Alert('Select an INPLANE!')
  return
end
view = INPLANE{selectedINPLANE};


if exist('scanList', 'var')
  nScans = length(scanList);
else
  nScans = length(mrSESSION.functionals);
  scanList = 1:nScans;
end
iS = scanList(1);

% Initialize some variables
tFrame = mrSESSION.functionals(iS).framePeriod;
fNyq = 0.5 / tFrame;
nEventFrames = period / tFrame;
nn = mrSESSION.functionals(iS).cropSize;
nSlices = mrSESSION.inplanes.nSlices;
nVoxels = prod(nn);
amps = zeros(nn(1), nn(2), nSlices);
ampErrs = amps;

% Create a new datatype to hold the results:
if (~exist('typeName', 'var') | isempty(typeName)), typeName = 'MeanEvents'; end
if ~existDataType(typeName), addDataType(typeName); end
hiddenView = initHiddenInplane;
hiddenView = selectDataType(hiddenView,existDataType(typeName));
% Get the tSeries directory for this dataType (make the directory if it doesn't already exist).
tseriesdir = tSeriesDir(hiddenView);
% Set dataTYPES.scanParams so that new meanEvents scan has the same params as
% the 1st scan on scanList.
ndataType = hiddenView.curDataType;
for scanNum = 1:2
  dataTYPES(ndataType).scanParams(scanNum) = dataTYPES(view.curDataType).scanParams(scanList(1));
  dataTYPES(ndataType).scanParams(scanNum).nFrames = nEventFrames;
  dataTYPES(ndataType).blockedAnalysisParams(scanNum) = dataTYPES(view.curDataType).blockedAnalysisParams(scanList(1));
  dataTYPES(ndataType).blockedAnalysisParams(scanNum).nCycles = 1;
  dataTYPES(ndataType).blockedAnalysisParams(scanNum).detrend = 0;
  dataTYPES(ndataType).blockedAnalysisParams(scanNum).inhomoCorrect = 0;
  dataTYPES(ndataType).eventAnalysisParams(scanNum) = dataTYPES(view.curDataType).eventAnalysisParams(scanList(1));
  % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
  scandir = fullfile(tseriesdir,['Scan',int2str(scanNum)]);
  if ~exist(scandir,'dir')
    mkdir(tseriesdir,['Scan', int2str(scanNum)]);
  end
end
dataTYPES(ndataType).scanParams(1).annotation = ['Mean events of ',getDataTypeName(view)];
dataTYPES(ndataType).scanParams(2).annotation = ['Std. errors of ',getDataTypeName(view)];
saveSession

% Find total events in all scans:
totalFrames = 0;
for iScan=1:nScans
  iS = scanList(iScan);
  totalFrames = totalFrames + mrSESSION.functionals(iS).nFrames;
end
tEvents = floor(totalFrames / nEventFrames);
sliceBlockTS = zeros(nEventFrames, tEvents, nn(1), nn(2));
ampsBlock = zeros(tEvents, nn(1), nn(2));

meanTSFull = [];
meanTSerrsFull = [];
for iSlice=1:nSlices
    % Stack the events for each slice
    iSl = find(iSlice == mrSESSION.functionals(iS).slices);
    if ~isempty(iSl)
        iEvent = 1;
        wH = mrvWaitbar(0, ['Stacking events for slice ', int2str(iSl)]);
        for iScan=1:nScans
            iS = scanList(iScan);
            ts = loadtSeries(view, iS, iSl);
            if exist('filterRange', 'var')
                ts = FilterF(filterRange/fNyq, ts);
            end %if
            nFrames = mrSESSION.functionals(iS).nFrames;
            nEvents = floor(nFrames / nEventFrames);
            ts = ts(1:nEvents*nEventFrames, :);
            ts = reshape(ts, nEventFrames, nEvents, nn(1), nn(2));
            sliceBlockTS(:, iEvent:(iEvent+nEvents-1), :, :) = ts;
            iEvent = iEvent + nEvents;
            mrvWaitbar(iScan/nScans, wH);
        end %for
        mrvWaitbar(1, wH, ['Processing events for slice ', int2str(iSl)]);
        numPoints = sum(isfinite(sliceBlockTS), 2);
        sliceBlockTS(~isfinite(sliceBlockTS)) = 0;
        sliceBlockTS = sliceBlockTS - repmat(sum(sliceBlockTS)/nEventFrames, [nEventFrames 1 1 1]);
        meanTS = squeeze(sum(sliceBlockTS, 2)./numPoints);
        meanTSFinal = reshape(meanTS, nEventFrames, nVoxels);
        dimNum = numel(size(meanTSFinal));
        meanTSFull = cat(dimNum + 1, meanTSFull, meanTSFinal);
        %savetSeries(reshape(meanTS, nEventFrames, nVoxels), hiddenView, 1, iSl);
        meanTSerrs = squeeze(std(sliceBlockTS, 0, 2)) / sqrt(tEvents);
        meanTSerrsFinal = reshape(meanTSerrs, nEventFrames, nVoxels);
        meanTSerrsFull = cat(dimNum + 1, meanTSFull, meanTSerrsFinal);
        %savetSeries(reshape(meanTSerrs, nEventFrames, nVoxels), hiddenView, 2, iSl);
        lengthTS = sqrt(squeeze(sum(meanTS.^2)));
        zeroLength = find(lengthTS == 0);
        for ii=1:tEvents
            ampsBlock1 = squeeze(sum(meanTS .* squeeze(sliceBlockTS(:, ii, :, :)))) ./ lengthTS;
            ampsBlock1(zeroLength) = NaN;
            ampsBlock(ii, :, :) = ampsBlock1;
        end
        amps(:, :, iSl) = squeeze(mean(ampsBlock));
        ampErrs(:, :, iSl) = squeeze(std(ampsBlock)) / sqrt(tEvents);
        close(wH);
    end
end %for

if dimNum == 3
    meanTSFull = reshape(meanTSFull,[1,2,4,3]);
    meanTSerrsFull = reshape(meanTSerrsFull,[1,2,4,3]);
end %if

savetSeries(meanTSFull,hiddenView,1);
savetSeries(meanTSerrsFull,hiddenView,2);


% Save the parameter maps:
hiddenView = setParameterMap(hiddenView, {amps, ampErrs}, 'EventAmplitudes');
fName = fullfile(dataDir(hiddenView), 'EventAmplitudes.mat');
saveParameterMap(hiddenView, fName, 1);
