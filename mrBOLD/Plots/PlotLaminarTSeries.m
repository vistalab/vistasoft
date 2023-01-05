function t = PlotLaminarTSeries(depthRange, depthIncrement, maxDepth, t)

% t = PlotLaminarTSeries(depthRange, depthIncrement, maxDepth, t);
%
% Plot a montage of event-related time series plots taken from the
% MeanEvents in the current VOLUME view.
%
% Ress, 3/05

mrGlobals

SEMmult = 2;

if ~exist('t', 'var')
  ExtendLaminarROI(depthRange);
  if isempty(selectedVOLUME), return, end
  curROI = VOLUME{selectedVOLUME}.selectedROI;

  t = LaminateROI(depthIncrement);
else
  curROI = VOLUME{selectedVOLUME}.selectedROI;
end

if exist('maxDepth', 'var')
  t1 = t(t <= maxDepth); 
else
  t1 = t;
end

nLaminae = length(t1);
coords = cell(nLaminae, 1);
for iR=1:nLaminae, coords{iR} = VOLUME{selectedVOLUME}.ROIs(iR+curROI).coords; end
curScan = getCurScan(VOLUME{selectedVOLUME});
[ts, tsErr] = meanTSeries(VOLUME{selectedVOLUME}, curScan, coords);

% Build time base:
curType = VOLUME{selectedVOLUME}.curDataType;
params = dataTYPES(curType).scanParams(curScan);
tt = (0:params.nFrames-1) * params.framePeriod;

% Find scaling:
for ii=1:nLaminae
  ts1 = ts{ii};
  mxv(ii) = max(ts1+tsErr{ii}-ts1(1));
  mnv(ii) = min(ts1-tsErr{ii}-ts1(1));
end
maxVal = ceil(max(mxv));
minVal = floor(min(mnv));
minT = 0;
maxT = max(tt);
ax = [minT maxT minVal maxVal];

nP = ceil(sqrt(nLaminae));
figure;
for ii=1:nLaminae
  subplot(nP, nP, ii);
  ts1 = ts{ii};
  h = errorbar(tt, ts1-ts1(1), SEMmult*tsErr{ii});
  axis(ax);
  set(gca, 'FontSize', 7);
  xlabel('Time (s)', 'FontSize', 7);
  ylabel('BOLD signal (%)', 'FontSize', 7);
  d0 = round(t1(ii)*10) / 10;
  title(['Height: ', num2str(d0), ' mm; voxels: ', int2str(size(coords{ii}, 2))], 'FontSize', 9);
end