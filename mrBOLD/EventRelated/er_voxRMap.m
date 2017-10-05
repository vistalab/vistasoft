function view = er_voxRMap(view, roi, scans, dt, conditions, subsets);
%
% view = er_voxRMap(<view=cur view>,  <roi=selected>, <scans=scan group>, ...
%                          <dt=cur dt>, <conditions=all>, <subsets=even odd>);
%
% Export a map of "voxel reliability": for each voxel, the correlation
% coefficient R between response amplitudes across conditions for two
% subsets. By default, these subsets are even and odd runs in the scan
% group.
% 
% If 'gray' is provided as the ROI, will step through gray matter computing
% the map in a memory-efficient manner.
%
% subsets: 2x1 cell, e.g. {[1 3 5 7] [2 4 6 8]}, showing which subsets of
% runs to compare. By default, will compare even and odd runs across the
% selected scans.
%
% ras, 05/01/06.
if notDefined('view'), view = getCurView;               end
if notDefined('roi'),  roi = view.selectedROI;          end
if notDefined('scans'), scans = er_getScanGroup(view);  end
if notDefined('dt'), dt = view.curDataType;              end
if notDefined('conditions'), 
    trials = er_concatParfiles(view);
    conditions = trials.condNums(trials.condNums>0);
end
if notDefined('subsets'), % {odd even}
    subsets = {scans(1:2:end) scans(2:2:end)};
end

if ~isequal(roi, 'gray')
    % for an ROI: call mv_exportMap
    mv = mv_init(view, roi, scans, dt);
    mv_exportMap(mv, 'voxel reliability', 1);
    return
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If we got here, we're doing a memory-efficient gray matter computation %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi = getGrayRoi(view);
roi.coords = roiSubCoords(view, roi.coords); % remove redundant voxels
nVoxels = size(roi.coords, 2);

hwait = mrvWaitbar(0, 'Computing Voxel Reliability Across Gray Matter...');
set(hwait, 'Position', get(hwait,'Position')+[0 100 0 0]);
for a = 1:2000:nVoxels
    b = min(nVoxels, a+1999);
    subRoi = roi;
    subRoi.coords = roi.coords(:,a:b);
    subRoi.name = 'ROI1'; % will prevent lengthy caching of each sub-ROI

    mv = mv_init(view, subRoi);
    
    mv.params.selConds = conditions;
    mv = mv_reliability(mv, 'plotFlag', 0);
    
    voxR(a:b) = mv.wta.voxR;
    
    mrvWaitbar(b/nVoxels, hwait);
end
close(hwait);


% plug in the values to the map volume:
mapdims = viewGet(view,'dataSize');
nScans = viewGet(view,'numScans');
mapvol = zeros(mapdims);
scan = scans(1);
ind = roiIndices(view, roi.coords);
mapvol(ind) = voxR;

%%%%%set in view
map = cell(1,nScans);
mapName = sprintf('VoxR_%s', roi.name);
map{scan} = mapvol; 
view = setParameterMap(view, map, mapName);
saveParameterMap(view, [], 1);
disp('Finished computing gray matter voxel reliability map.')

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function roi = getGrayRoi(view);
% roi = getGrayRoi(view);
% find, load, or make a gray ROI for the view.

% try finding a loaded ROI
if ~isempty(view.ROIs)
    existingRois = {view.ROIs.name};
    N = cellfind(existingRois, 'gray');
    if ~isempty(N), roi = view.ROIs(N); return; end
end

% try loading a saved ROI
w = what(roiDir(view));
savedRois = w.mat';
if ~isempty(savedRois)
    N = cellfind(savedRois, 'gray.mat');
    if ~isempty(N)
        load(fullfile(roiDir(view), 'gray.mat'), 'ROI');
        roi = ROI; 
        return
    end
end

% got here: need to make it
try 
    view = makeGrayROI(view);
    roi = view.ROIs(end);
    saveROI(view, roi);
catch
    disp('Couldn''t make a gray ROI. Segmentation installed?')
    roi = [];
end

return
