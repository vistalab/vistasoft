function ui = mrViewZoom(ui,zoom);
%
%  ui = mrViewZoom([ui],[zoom]);
%
% Set the zoom state of a mrViewer UI.
%
% If zoom is omitted, prompts user to zoom with 
% the mouse.
%
% If zoom is entered as 'reset', resets to maximum
% possible zoom.
%
% ras, 07/05/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end

figure(ui.fig);

if ~exist('zoom','var') | isempty(zoom)
    %%%%%%%%%%%%%%%%%%
    % get user input %
    %%%%%%%%%%%%%%%%%%
    tmp1 = get(ui.panels.display,'BackgroundColor');
    tmp2 = get(ui.fig,'Name');
    set(ui.panels.display,'BackgroundColor','y');
    newName = 'Click Zoom Bounds (Right click for symmetric axes)';
    set(ui.fig,'Name',newName);
    
    [X Y button] = ginput(2);
    
    set(ui.panels.display,'BackgroundColor',tmp1);    
    set(ui.fig,'Name',tmp2);

    % use the identity of the last button press
    % to determine if the axes should be isometric
    if button(end)==3
        isoAxes = 1;
    else
        isoAxes = 0;
    end

    zoom = ui.settings.zoom;
    
    % get orientation of axes
    ori = ui.settings.ori;
    if ui.settings.displayFormat==2
        % multi view: get from view axes
        tmp = get(gca,'Tag');
        ori = str2num(tmp(end));
    end
    switch ori
        case 1, % axial view was zoomed in on
            zoom(2,:) = [Y(1) Y(2)];
            zoom(3,:) = [X(1) X(2)];
        case 2, % coronal view was zoomed in on
            zoom(1,:) = [Y(1) Y(2)];
            zoom(3,:) = [X(1) X(2)];
        case 3, % sagittal view was zoomed in on
            zoom(1,:) = [Y(1) Y(2)];
            zoom(2,:) = [X(1) X(2)];
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
            case 1, fov = [fov; 0];
            case 2, fov = [fov(2); 0; fov(1)];
            case 3, fov = [0; fov];
        end

        [maxFov, whichAxis] = max(fov);

        for ori = 1:3
            centerPt = mean(ui.settings.zoom(ori,:));
            zoom(ori,1) = centerPt - maxFov/2;
            zoom(ori,2) = centerPt + maxFov/2;
        end
    end
elseif isequal(zoom,'reset')
    zoom = ui.settings.bounds;
end

ui.settings.zoom = zoom;

mrViewRefresh(ui);

return
