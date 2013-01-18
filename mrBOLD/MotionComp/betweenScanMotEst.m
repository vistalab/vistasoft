function betweenScanMotEst(view, baseScan, targetScans)
%
% betweenScanMotEst(view, baseScan, targetScans)
%
% Robust 3D rigid body motion estimation between MEAN MAPS of different scans
%
% 04/05 Ress, rewritten from betweenScanMotComp.m

if ~exist('baseScan', 'var'), baseScan = selectScans(view, 'Select base scan'); end
if isempty(baseScan), return, end
baseScan = baseScan(1);
if ~exist('targetScans', 'var'), targetScans = selectScans(view, 'Select target scans'); end
% removes the base scan, if present
targetScans = targetScans(find(targetScans~=baseScan));
if isempty(targetScans), return, end

% Get or compute Mean Maps.
view = loadMeanMap(view);
meanMap = view.map;

% if the number of slices is too small, repeat the first and last slice
% to avoid running out of data (the derivative computation discards the
% borders in z, tipically 2 slices at the begining and 2 more at the end)
if size(meanMap,3)<=8
  meanMap = cat(3, meanMap(:,:,1,:), meanMap(:,:,1,:), meanMap,...
    meanMap(:,:,end,:), meanMap(:,:,end,:));
end

% get base mean map
baseMeanMap = meanMap{baseScan};

% Do motion estimation for each scan.
corrected = 0 * targetScans;
for iScan=1:length(targetScans)
  scan = targetScans(iScan);
  nSlices = length(sliceList(view,scan));
  dims = sliceDims(view,scan);
 
  % estimate motion between mean maps
  M = estMotionIter3(baseMeanMap,meanMap{scan},3,eye(4),1,1); % rigid body, ROBUST
  midX = [dims/2 nSlices/2]';
  midXp = M(1:3, 1:3) * midX; % Rotational motion
  rotMot = sqrt(sum((midXp - midX).^2));
  transMot = sqrt(sum(M(1:3, 4).^2)); % Translational motion
  totalMot = sqrt(rotMot^2 + transMot^2);
  disp(['Scan ', int2str(scan), ' - motion (voxels): rot = ', num2str(rotMot), '; trans = ', num2str(transMot), ...
      ' total = ', num2str(totalMot)])
  
end % scan LOOP

return
