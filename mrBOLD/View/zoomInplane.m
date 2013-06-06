function vw = zoomInplane(vw, resetFlag);
% view = zoomInplane(view, <resetFlag=0>);
%
% Zooms the 3-view. Allows the subject to click once (rect or center of
% zooming) on one of the views of the brain, gets the new extent of view,
% and sets the other axes to be consistent with the new zoom extent.
%
% resetFlag: if 1, will reset the zoom to be the whole view size and
% update the axis bounds of the image. If 0 <default>, will get the zoom
% from the user input.
%
% 05/04 ras, from zoom3view.
% 06/02 ras: now just updates zoom w/ AXIS command, rather than
% going through a full refresh. Also added resetFlag, so both
% zoom buttons have callbacks to this function (for Inplane/Flat views).
montageFlag = isequal(vw.viewType, 'Inplane'); % 1 for inplanes, 0 for other

% this should only work on Inplane or Flat views
if ~ismember(vw.viewType,{'Inplane' 'Flat'}),    return;      end

if exist('resetFlag', 'var') && resetFlag==1
    % reset the zoom
    dims = viewGet(vw,'Size');
    zoom = [1 dims(2) 1 dims(1)];
else
    %%%%%%%%%%%%%%%%%%%%
    % Get data from UI %
    %%%%%%%%%%%%%%%%%%%%
    [X, Y] = ginput(2);
    
    zoom = [X(1) X(2) Y(1) Y(2)];
    
    % montage views will need some fiddling:
    if isfield(vw.ui,'montageSize') || isfield(vw.ui,'numLevelEdit')
        montageFlag = 1;
        [zoom, rows, cols] = montage2Coords(vw, [Y X]', 1);
        
        % set to zoom format [xmin xmax ymin ymax], or [cols rows]
        zoom = [zoom(2,1) zoom(2,2) zoom(1,1) zoom(1,2)];
        
        % get current zoom size
        dims =viewGet(vw,'Size');
        
        % ensure the zoom values are increasing (if the pts were clipped,
        % this may not be the case)
        if zoom(1) > zoom(2), zoom(1:2) = zoom([2 1]); end
        if zoom(3) > zoom(4), zoom(3:4) = zoom([4 3]); end
        
    else
        montageFlag = 0;
    end
end

vw.ui.zoom = zoom;

axes(vw.ui.mainAxisHandle);
if montageFlag==1
    % we need to refresh the screen
    vw = refreshScreen(vw);
else
    % we can just use the zoom directly
    axis(zoom);
end


return



% zoom on
%
% waitForClick = ginput(1);
%
% zoom = round(axis);
