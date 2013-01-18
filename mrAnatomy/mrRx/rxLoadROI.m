function rx = rxLoadROI(rx, roiPath, type)
%
% rx = rxLoadROI([rx], [roiPath=prompt]);
%
% Load a mrVista ROI into mrRx. If the ROI path is omitted, will put up a
% dialog.
%
% Can load Volume/Gray or Inplane ROIs. For the inplane ROIs, will apply
% the currently-set xform to get the ROI coordinates into the volume space.
%
% If a cell of many paths is specified, will load each in turn.
%
% ras, 08/06.
if notDefined('rx'), rx = get(findobj('Tag','rxControlFig'),'UserData');  end
if notDefined('type'), type = 'Volume'; end

if notDefined('roiPath')
    [f p] = uigetfile('*.mat', 'Select an ROI file...', 'MultiSelect', 'on');

    if iscell(f)    % load many ROIs
        for i = 1:length(f)
            roiPath{i} = fullfile(p, f{i});
        end
        rx = rxLoadROI(rx, roiPath);
        return
    end

    % if we get here, only one file to load:
    roiPath = fullfile(p, f);
end

if iscell(roiPath)
    for i = 1:length(roiPath)
        rx = rxLoadROI(rx, roiPath{i}, type);
    end
end

if ~exist(roiPath, 'file'), % let's look for it
    
    % Try the local Gray/ROIs directory
    pth = fullfile('Gray', 'ROIs', roiPath);    
    
    if exist([pth '.mat'], 'file'), 
        roiPath = pth;     
    else % if not there try Volume/ROIs
        pth = fullfile('Volume', 'ROIs', roiPath);
        if exist([pth '.mat'], 'file'), roiPath = pth; end        
    end
    
end

load(roiPath, 'ROI');
ROI.coords = double(ROI.coords); %#ok<NODEF>
N = length(rx.rois) + 1;

switch lower(ROI.viewType)
    case 'inplane'
        ip2vol = rx.xform;      % account for diff't xform order
        ip2vol([1 2],:) = ip2vol([2 1],:);
        ip2vol(:,[1 2]) = ip2vol(:,[2 1]);

        volCoords = ip2vol * [ROI.coords; ones(1, size(ROI.coords, 2))];
        rx.rois(N).volCoords = volCoords(1:3,:);

    case {'volume' 'gray'}
        rx.rois(N).volCoords = ROI.coords;
        
    otherwise
        error('Unsupported ROI type.')
end

rx.rois(N).name = ROI.name;
rx.rois(N).color = ROI.color;

% rxRefresh(rx);

% let's go ahead center the views on the new ROI
rxCenterOnROI(rx);


return

