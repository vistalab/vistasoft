function [amps, errs] = ProjectSessionEvents(meanAmps);

% [eventTS, eventErrs] = AverageSessionEvents(period, scanList, filterRange);
%
% Average together all inplane voxel time series in the current session for
% a specified regular-period event. Returns the reduced time-series as a 4D
% array, nTimeSamples x nX x nY x nSlices. Also returns the standard errors
% at each time point.
%
% Ress, 4/04

mrGlobals

if exist('INPLANE', 'var')
  view = INPLANE{selectedINPLANE};
else
  view = initHiddenInplane;
end

if exist('scanList', 'var')
  nScans = length(scanList);
else
  nScans = length(mrSESSION.functionals);
  scanList = 1:nScans;
end
iS = scanList(1);

% Initialize some variables
nSlices = mrSESSION.inplanes.nSlices;
tFrame = mrSESSION.functionals(iS).framePeriod;
fNyq = 0.5 / tFrame;
nEventFrames = period / tFrame;
nn = mrSESSION.functionals(iS).cropSize;
eventTS = zeros(nEventFrames, nn(1), nn(2), nSlices);
eventErrs = zeros(nEventFrames, nn(1), nn(2), nSlices);

% Find total events in all scans:
totalFrames = 0;
for iScan=1:nScans
  iS = scanList(iScan);
  totalFrames = totalFrames + mrSESSION.functionals(iS).nFrames;
end
tEvents = floor(totalFrames / nEventFrames);
sliceBlockTS = zeros(nEventFrames, tEvents, nn(1), nn(2));

for iSlice=1:nSlices
  iSl = find(iSlice == mrSESSION.functionals(iS).slices);
  if ~isempty(iSl)
    iEvent = 1;
    wH = mrvWaitbar(0, ['Stacking events for slice ', int2str(iSl)]);
    for iScan=1:nScans
      iS = scanList(iScan);
      ts = loadtSeries(view, iS, iSl);
      if exist('filterRange', 'var')
        ts = FilterF(filterRange/fNyq, ts);
      end
      nFrames = mrSESSION.functionals(iS).nFrames;
      nEvents = floor(nFrames / nEventFrames);
      ts = ts(1:nEvents*nEventFrames, :);
      ts = reshape(ts, nEventFrames, nEvents, nn(1), nn(2));
      sliceBlockTS(:, iEvent:(iEvent+nEvents-1), :, :) = ts;
      iEvent = iEvent + nEvents;
      mrvWaitbar(iScan/nScans, wH);
    end
  end
  mrvWaitbar(1, wH, ['Averaging events for slice ', int2str(iSl)]);
  sliceBlockTS = sliceBlockTS - repmat(mean(sliceBlockTS), [nEventFrames 1 1 1]);
  eventTS(:, :, :, iSl) = squeeze(mean(sliceBlockTS, 2));
  eventErrs(:, :, :, iSl) = squeeze(std(sliceBlockTS, 0, 2)) / sqrt(tEvents);
  close(wH);
end
