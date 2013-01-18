function ui = mrViewSetSpace(ui,space);
% ui = mrViewSetSpace(ui,space);
% Set the selected coordinate space for mrViewer.
% space can be an integer into the UI's set of
% spaces (see mrViewSpaceMenu), or the name of the
% space.
% If it exists, will select the menu choice for
% that space and deselect the others.
% ras 07/05.
if ischar(space)
    names = {ui.spaces.name};
    space = cellfind(names,space);
end

% set new space, record old space
oldSpace = ui.settings.space;
ui.settings.space = space;

% figure out extent of new coords
if isfield(ui.spaces(space),'bounds') & ~isempty(ui.spaces(space).bounds)
    bounds = ui.spaces(space).bounds;
else
    if ~isempty(ui.spaces(space).xform)
        [X Y Z] = meshgrid([1 ui.mr.dims(2)], ...
            [1 ui.mr.dims(1)], ...
            [1 ui.mr.dims(3)]);
        corners = [Y(:) X(:) Z(:)]'; clear X Y Z
        nVoxels = size(corners,2);
        newCorners = ui.spaces(space).xform * [corners; ones(1,nVoxels)];
        C = newCorners(1:3,:);
        bounds = round([min(C,[],2) max(C,[],2)]);
        % bounds = bounds([2 1 3],:);
    elseif ~isempty(ui.spaces(space).coords)
        C = ui.mr.spaces(space).coords;
        bounds = round([min(C,[],2) max(C,[],2)]);
    else
        error('Space doesn''t specify an xform or coords.')
    end
end
ui.settings.bounds = bounds;

% also figure out new cursor location in this space
loc = ui.settings.cursorLoc;
if ~isempty(ui.spaces(space).xform)
    loc = inv(ui.spaces(oldSpace).xform) * [loc 1]';
    loc = ui.spaces(space).xform * loc;
elseif ~isempty(ui.spaces(space).coords)
    ind = sub2ind(ui.mr.dims(1:3),loc(1),loc(2),loc(3));
    if ismember(ind,ui.spaces(space).indices)
        ii = find(ui.spaces(space).indices==ind);
        loc = ui.spaces(space).coords(:,ii);
    else
        loc = [0 0 0];
    end
end
if space==1, loc = round(loc); end; % pixel space uses integer indices

% check that cursor is located within bounds of new space
loc = loc(1:3)';
b = ui.settings.bounds';
loc(loc<b(1,:)) = b(1,find(loc<b(1,:)));
loc(loc>b(2,:)) = b(2,find(loc>b(2,:)));
ui = mrViewSet(ui, 'cursorLoc', loc);

% check the appropriate menu item, if it exists
if isfield(ui.spaces(1),'menuHandle') & ishandle(ui.spaces(1).menuHandle)
    handles = [ui.spaces.menuHandle];
    set(handles,'Checked','off');
    set(handles(space),'Checked','on');
end

% label the directions appropriately
if isfield(ui.controls,'ori') & ishandle(ui.controls.ori(1))
    for i = 1:3
        set(ui.controls.ori(i), 'String', ui.spaces(space).sliceLabels{i});
    end
end

% reset zoom
ui.settings.zoom = ui.settings.bounds;

% If we're in the pixel space, ensure the slice slider
% is an integer. Otherwise, allow non-integer values,
% since we're interpolating anyway.
ori = findSelectedButton(ui.controls.ori);
rng = bounds(ori,:); % slice range
if space==1
    mrvSliderSet(ui.slice,'IntFlag',1,'Range',rng);
else
    mrvSliderSet(ui.slice,'IntFlag',1,'Range',rng,'FlexFlag',1);
end
ui = mrViewSet(ui, 'slice', loc(ui.settings.ori));

return