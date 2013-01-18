function view=segmentationMenu(view)
% view = segmentationMenu(view)
% 
% Set up the callbacks for the segmentation/unfold menu
% 
% djh, 2/14/2001
segmentationMenu = uimenu('Label','Segmentation','separator','on');

% Install new segmentation
%    installSegmentation;
callBackstr='installSegmentation;';
uimenu(segmentationMenu,'Label','(Re-)install segmentation','Separator','off',...
    'CallBack',callBackstr);

if strcmp(view.viewType,'Gray') || strcmp(view.viewType,'Volume')
    % Wrapper for mrFlatMesh
    %    flattenFromROI(view, ROI)
    callBackstr=['flattenFromROI(',view.name,');'];
    uimenu(segmentationMenu,'Label','Flatten (start from ROI)','Separator','on',...
        'CallBack',callBackstr);
end


% New flat callback:
%  newFlat;
callBackstr='newFlat;';
uimenu(segmentationMenu,'Label','Install New Unfold','Separator','off',...
    'CallBack',callBackstr);

% If flat view, pass arg to specify which flat to re-install
% Otherwise, user will be prompted to pick one of the flat subdirectories
if strcmp(view.viewType,'Flat')
    % Install new unfold
    %    installUnfold(view);
    callBackstr=['installUnfold(',view.name,'.subdir);'];
    uimenu(segmentationMenu,'Label','Reinstall unfold','Separator','off',...
        'CallBack',callBackstr);
else
    callBackstr='installUnfold;';
    uimenu(segmentationMenu,'Label','Reinstall unfold','Separator','off',...
        'CallBack',callBackstr);
end


if strcmp(view.viewType,'Volume') || strcmp(view.viewType,'Gray') || strcmp(view.viewType,'Flat')
    % Message box with segmentation information
    %    segInfo = segmentInfo(view)
    callBackstr=['segmentInfo(',view.name,');'];
    uimenu(segmentationMenu,'Label','Segmentation info','Separator','on',...
        'CallBack',callBackstr);
end

if strcmp(view.viewType,'Flat')
    % Xform Verify Gray-Flat correspondence callback:
    %    verifyGrayFlat(view);
    callBackstr=['checkCoordsNodes(',view.name,');'];
    uimenu(segmentationMenu,'Label','Verify Gray-Flat match','Separator','off',...
        'CallBack',callBackstr);
end

  
return

