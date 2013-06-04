function vw = zoom3view(vw, resetFlag);
% Zooms the 3D view
%
% view = zoom3view(view, <resetFlag=0>);
%
% Allows the subject to click twice (corners of a rect) on one of
% the views of the brain, gets the new extent of view,  and sets the other
% axes to be consistent with the new zoom extent.
%
% Since you can only select a rectangular zoom range in one orientation
% (axial, coronal, sagittal), leaving the third dimension unconstrained,
% there are two options for how to update the zoom range. If you use the
% left mouse button when selecting the zoom range, the zoom will affect the
% third dimension, causing an isometric zoom range (equal size in each of
% three dimensions). E.g., if you zoom in on an axial slice, the
% superior <-> inferior range will be affected in addition to a <-> p and
% l <-> r directions. If you right or middle click when selecting the range,
% the zoom range will not be isometric (in the example above, the s <-> i
% range will be unchanged; also, a very narrow rectangle will make the
% other directions uneven, while left-clicking will force each direction to
% match the wider edge of the rectangle). It is only the second mouse click 
% that determines whether the zoom is isometric or not.
%
% resetFlag: if 1, will reset the zoom to be the whole view size and 
% update the axis bounds of the image. If 0 <default>, will get the zoom
% from the user input.
%
%
% 01/04 ras.
% 08/04 ras. Now makes the zoom range cubic by default (equal FOV
% in all directions) if the left mouse button is used, but uses
% an asymmetric zoom (each sub-view may be rectangular) if another
% button is used.
% 06/02 ras: now just updates zoom w/ AXIS command, rather than
% going through a full refresh. Also added resetFlag, so both 
% zoom buttons have callbacks to this function (for Volume/Gray views).
    
dims = viewGet(vw,'Size');

if exist('resetFlag', 'var') & resetFlag==1
    %%%%%reset the zoom
    zoom = [1 dims(1); 1 dims(2); 1 dims(3)];
else
    %%%%%Get from UI
    [X, Y, button] = ginput(2);
    AX = [X(1) X(2) Y(1) Y(2)];

    % use the identity of the last button press
    % to determine if the axes should be isometric
    if button(end)==1
        isoAxes = 1;
    else
        isoAxes = 0;
    end

    % could use getCurSliceOri to get orientation, 
    % but this would mean we'd have to allow zooming
    % only on the selected view axes (which is fairly
    % unimportant on a 3-view) -- so figure it out manually
    if isequal(vw.refreshFn, 'volume3View')
        if vw.ui.axiAxesHandle==gca,       ori = 1;
        elseif vw.ui.corAxesHandle==gca,   ori = 2;
        else                                 ori = 3;
        end
    else
        ori = getCurSliceOri(vw);
    end
    
    % update the zoom for those dimensions the user restricted
    zoom = vw.ui.zoom;    
    switch ori
        case 1, % axial view was zoomed in on
            zoom(2,:) = [AX(3) AX(4)];
            zoom(3,:) = [AX(1) AX(2)];
        case 2, % coronal view was zoomed in on
            zoom(1,:) = [AX(3) AX(4)];
            zoom(3,:) = [AX(1) AX(2)];
        case 3, % sagittal view was zoomed in on
            zoom(1,:) = [AX(3) AX(4)];
            zoom(2,:) = [AX(1) AX(2)];
    end

    % make axes isometric, if selected
    if isoAxes==1
        % this is a bit tricky since we want the widest
        % field-of-view from the two selected directions,
        % but ignore the fov-size for the dimension
        % orthogonal to the orientation (e.g., if selected on
        % an axi slice, ignore the axial zoom range):
        fov = diff([X'; Y'],1,2);
        switch ori
            case 1, fov = [0; fov];
            case 2, fov = [fov(1); 0; fov(2)];
            case 3, fov = [fov; 0];
        end

        [maxFov, whichAxis] = max(fov);

        for ori = 1:3
            centerPt = mean(zoom(ori,:));
            zoom(ori,1) = centerPt - maxFov/2;
            zoom(ori,2) = centerPt + maxFov/2;
        end
    end
end

% bounds check
zoom(zoom<1) = 1;
upperBound = min(zoom(:,2), dims(:));
zoom(:,2) = upperBound;

% set the zoom
vw.ui.zoom = zoom;

% update the axes
if isequal(vw.refreshFn, 'volume3View')
    % 3-view
    axis(vw.ui.axiAxesHandle, [zoom(3,:) zoom(2,:)]);
    axis(vw.ui.corAxesHandle, [zoom(3,:) zoom(1,:)]);
    axis(vw.ui.sagAxesHandle, [zoom(2,:) zoom(1,:)]);
else
    % regular gray/volume view
    switch getCurSliceOri(vw)
        case 1, axis(vw.ui.mainAxisHandle, [zoom(3,:) zoom(2,:)]);
        case 2, axis(vw.ui.mainAxisHandle, [zoom(3,:) zoom(1,:)]);
        case 3, axis(vw.ui.mainAxisHandle, [zoom(2,:) zoom(1,:)]);
    end
end

return


