function view = makeOverlapMap(view,roiOption);
% view = makeOverlapMap(view,roiOption);
%
% A shell to call computeOverlapMap from mrLoadRet.
%
% Will create a parameter map that combines the currently viewed data (map,
% amp, ph, or co map on the current view) with another map, which is
% selected through a dialog. Saves it in the current view/dataSeries
% directory (e.g. /Inplane/Original) with the prefix overlap_, 
% keyed to the same scan as that which is currently viewed.
%
% In the output maps, the following values are used:
%
%   0: both maps are below their specified thresholds for this voxel
%   1: map1 but not map2 is above its specified threshold for this voxel
%   2: map2 but not map1 is above its specified threshold for this voxel
%   3: both maps are above their specified thresholds for this voxel
%   4: an ROI is here, superimposed over the map.
% 
% roiOption specifies which rois in the view to add to the map.
% options are: 0, add no ROIs; 1, add selected ROI; 2, add all ROIs.
%
% 12/03 ras.
% 06/04 ras: expanded to use corAnal fields as well as parameter maps, be
% more compatible with different views like flat.
if ~exist('view', 'var') | isempty(view), view = getCurView; end

if ~exist('roiOption','var')
    %     roiOption = menu('Add ROIs on top of map?','None','Selected','All') - 1;
    roiOption = 0; % default to adding no ROIs
end

% map 1
scan = getCurScan(view);
map1 = view.(view.ui.displayMode){scan};

% map 2
startdir = fullfile(pwd,view.subdir);
[map2Name,pth] = myUiGetFile(startdir,'*.mat','Select a second map');
% remember to add a provision for corAnal data later
% find which scan has the map
tmp = load(fullfile(pth,map2Name));


% check if map2 is a corAnal; if not
% assume it's a param map
if strncmp(map2Name,'corAnal',7);
    choice = menu('Use which field from corAnal?','amp','co','ph');
    fields = {'amp' 'co' 'ph'};
    field = fields{choice};
    for j = 1:length(tmp.(field));
        fieldAssigned(j) = ~isempty(tmp.(field){j});
    end
    whichScans = find(fieldAssigned);
    questn = sprintf('Use %s field from which scan?',field);
    for j = 1:length(whichScans)
        opts{j} = num2str(whichScans(j));
    end
    choice2 = menu(questn,opts);
    cnt = whichScans(choice2);
else
    field = 'map';
    cnt = 1; % maps generally only have 1 scan assigned
    while isempty(tmp.map{cnt})
        cnt = cnt + 1;
    end
end
map2 = tmp.(field){cnt};

% threshold 1
switch view.ui.displayMode
    case 'map',
        mapClip = getMapWindow(view);
        th1 = mapClip(1);
    case 'amp',
        % figure you wouldn't want to thresh by amp, but maybe I'm wrong.
        th1 = getCothresh(view); 
    case 'co',
        th1 = getCothresh(view);
    case 'ph',
        phClip = getPhWindow(view);
        th1 = [phClip(1) phClip(2)];
    otherwise,
        % exit gracefully
        fprintf('Sorry, you''re in an invalid view mode.\n');
        return
end

% threshold 2
th2 = input('Enter threshold for second map: ');

% data type
type = view.curDataType;

% output path
name = input('Enter name of saved overlap map: ','s');
outPath = fullfile(dataDir(view),['overlap_' name]);

% ROIs
switch roiOption
    case 0, ROIs = [];
    case 1, ROIs = view.selectedROI;
    case 2, ROIs = [1:length(view.ROIs)];
end

% crunch
map3 = computeOverlapMap(view,map1,map2,'th1',th1,'th2',th2,...
    'outPath',outPath,'ROIs',ROIs,...
    'whichScanNum',scan,'whichType',type);

% assign resulting map to current view, make nice color map
view.map{scan} = map3;
view.ui.mapMode = setColormap(view.ui.mapMode, 'overlapCmap');

view = setDisplayMode(view,'map');
view = refreshView(view);


return