function view = roiLoadHdf5(view, select, clr)
% got rid of absPathFlag,defaultPathFlag
%
% view = roiLoadHdf5(view,  [select], [color])

%% Analagous to old getROIfilename.m

global MRFILES;

pathStr=['/', view.subdir, '/ROIs'];
MRFILES = mrFilesSet(MRFILES, 'path', pathStr);

groups = mrFilesGet(MRFILES, 'groups');
% there should be no datasets here
datasets = mrFilesGet(MRFILES, 'datasets');

if ~isempty(datasets)
    error('mrFiles:roiLoadHdf5:Malformed', ...
              ['found dataset under' pathStr]);
end

if isempty(groups)
  myErrorDlg('No ROIs found')
end

roi_offset = length(pathStr)+2;
group_names = {};
for i = 1:length(groups)
    group_names = {group_names{:}, groups{i}(roi_offset:end)};
end

% right now we just return the max / most recent ROI from each group.  we
% should offer a full range!
[sel,ok] = listdlg('PromptString','Select an ROI',...
       'SelectionMode','multiple',...
       'ListString',group_names);

if ok
    groups = groups(sel);
    group_names = group_names(sel);
else
    groups = {};
    group_names = {};
end



%% Analagous to loadROI.m
if ~exist('select', 'var'),            select=1;           end 
 
for i=1:length(groups)
    % This is a little inefficient, but not so bad
    MRFILES = mrFilesSet(MRFILES, 'path', groups{i});
    
    MRFILES = mrfPos(MRFILES, 'max');
    
    disp(['loading ', groups{i}]);
    thisROI = mrfLoadHdf5(MRFILES, 'coords');
    
    thisROI.name = group_names{i};

    % SHOULD THIS BE DONE?
    % this is guaranteed by the fact that we're using view.subdir
    % using view.subdir directly might even be better, but I'm guessing
    % these things are separate for a reason...
    thisROI.viewType = view.viewType;
    
    % Check color is set well
    if exist('clr','var') % from the function call
        thisROI.ROI.color=clr;
    end
    if ~isfield(thisROI,'color')
        thisROI.color='b';
    end

    view = addROI(view,thisROI,select);
end

disp('Done loading');
