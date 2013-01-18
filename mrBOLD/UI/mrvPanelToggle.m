function newState = mrvPanelToggle(panel, state);
%
% newState = mrvPanelToggle(panel, [state]);
%
% Toggles the visibility of an mrvPanel, rescaling the parent
% figure and other objects in the figure, such that the other
% objects remain the same size and the figure grows/shrinks.
%
% panel is a handle to the mrvPanel.
%
% state can be:
%   handle to a uimenu: toggle the 'checked' status of the
%       uimenu and, depending on whether the menu has become
%       checked or unchecked, set the panel visibility
%       appropriately.
%   'on' or 'off': force the respective visibility state.
%   omitted: toggles based on the 'visible' property of the
%       panel.
%
% Returns the new visibility state (1 for on, 0 for off) of
% the panel.
%
% ras, 07/06/05.
% ras, 07/15/05. Now deals w/ panels that reside in their
% own figures.
if nargin<1, help(mfilename); error('Not enough args.'); end

% parse the state argument; figure out new state
if ~exist('state','var') | isempty(state)
    % get from panel's visibility property
    currState = get(panel,'Visible');
    if isequal(currState,'on'),
        state = 'off';
    else
        state = 'on';
    end
    newState = (isequal(state,'on'));
    
elseif ischar(state)
    if ~ismember(lower(state),{'on' 'off'})
        help(mfilename);
        error('Invalid state argument.')
    end
    state = lower(state);
    newState = (isequal(state,'on'));
    
elseif ishandle(state)
    % shuffle the variables such that
    % state is a string 'on' or 'off',
    % and hmenu points to the handle
    hmenu = state;
    newState = umtoggle(hmenu);
    if newState==1, state = 'on'; else, state = 'off'; end
    
else
    error('Invalid state argument.')
    
end

% first, if the panel resides in its own figure,
% just hide/show the figure
if isequal(get(panel, 'Position'), [0 0 1 1])
    set( get(panel, 'Parent'), 'Visible', state );
    return
end

% if the panel is already in the specified state, return quietly
if isequal( get(panel, 'Visible'), state )
    return
end

% show/hide panel
set(panel,'Visible',state);

% the location of the panel w.r.t. other objects is
% kept as the panel's user data
loc = lower(get(panel,'UserData'));

% get the parent object
parent = get(panel,'Parent');

% get all existing child objects of the parent object,
% so we can adjust their relative sizes
objs = findobj('Parent', parent, 'Type', 'uicontrol');
objs = [objs; findobj('Parent', parent, 'Type', 'axes')];
objs = [objs; findobj('Parent', parent, 'Type', 'uipanel')];
objs = setdiff(objs, panel); % don't alter panel any further

% get the dimension along which things will be scaled
switch loc
    case {'above', 'below'}, dim = 4;
    case {'left', 'right'}, dim = 3;
end
corner = dim-2;

%%%%%figure out scaling sizes
figUnits = get(parent, 'Units');
panelUnits = get(panel, 'Units');
set(parent,'Units', 'normalized'); % note these norm units are diff't --
set(panel,'Units', 'normalized');  % parent is rel to screen, panel is
figPos = get(parent, 'Position');   % rel to parent. Need to be careful
figSize = figPos(dim);              % about math.
panelPos = get(panel, 'Position');
panelSize = panelPos(dim);

%%%%%if showing panel, re-initialize its position
if isequal(state, 'on')
    switch loc
        case 'above', pos = [0 1-panelSize 1 panelSize];
        case 'below', pos = [0 0 1 panelSize];
        case 'left', pos = [0 0 panelSize 1];
        case 'right', pos = [1-panelSize 0 panelSize 1];
    end
    set(panel,'Position',pos);
end

if isequal(state, 'on')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % show panel: make figure larger, shrink other objs %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % extent to grow figure such that the panel size 
    % is the right proportion:
    growFactor = 1 / (1/panelSize - 1); 
    
    % resize the parent object -- make larger
    newSize = figSize * (1+growFactor); % new figure size
    newPos = figPos;
    newPos(dim) = newSize;
    if ismember(loc,{'below' 'left'})
        % move the corner of the parent back to accommodate panel
        newPos(corner) = figPos(corner) - (newSize - figPos(dim)); % figPos(dim)*(1-growFactor);
    end
    set(parent,'Position',newPos);

    % existing objects in the parent will need to be shrunk
    % along the relevant dimension by an amount corresponding
    % to the growth of the parent (e.g., they'll stay the same
    % absolute size, but be a smaller proportion of the parent):
    for i = 1:length(objs)
        exUnits = get(objs(i), 'Units');
        set(objs(i), 'Units', 'normalized');
        objPos = get(objs(i), 'Position');
        
        % shrink object along relevant dim
        objPos(dim) = objPos(dim) * (1-panelSize);
        objPos(dim) = min(1,objPos(dim)); % off-figure check

        % to keep existing panels flush with one another,
        % even after shrinking, we need to nudge panels back:
        if objPos(corner) > 0
            objPos(corner) = objPos(corner) * (1-panelSize);
        end

        % for these locations, need to move the corners
        % of existing objects forward as well:
        if ismember(lower(loc), {'left' 'below'})
            objPos(corner) = objPos(corner) + panelSize;
        end

        objPos(corner) = max(0,objPos(corner)); % off-figure check
        set(objs(i), 'Position', objPos);
        set(objs(i), 'Units', exUnits); % restore previous unit convention
    end

else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % hide panel: make figure smaller, grow other objs  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % existing objects in the parent will need to be grown
    % along the relevant dimension by an amount corresponding
    % to the size decrease of the parent:
    for i = 1:length(objs)
        exUnits = get(objs(i),'Units');
        set(objs(i),'Units','normalized');
        objPos = get(objs(i),'Position');
        
        % grow object along relevant dim
        objPos(dim) = objPos(dim) / (1-panelSize);
        objPos(dim) = min(1,objPos(dim)); % off-figure check
        
        % for these locations, need to move the corners
        % of existing objects backward as well
        if objPos(corner) > panelPos(corner)
            objPos(corner) = (objPos(corner)-panelSize);
        end
        
        % to keep existing panels flush with one another,
        % even after growing, we need to nudge panels forward:
        if objPos(corner) > 0
            objPos(corner) = objPos(corner) / (1-panelSize);
        end
        
        objPos(corner) = max(0,objPos(corner)); % off-figure check
        set(objs(i),'Position',objPos);
        set(objs(i),'Units',exUnits); % restore previous unit convention
    end

    % resize the parent object -- make smaller
    newSize = figSize * (1-panelSize);
    newPos = figPos;
    newPos(dim) = newSize;
    if ismember(loc,{'below' 'left'})
        newPos(corner) = newPos(corner) + figSize*panelSize;
    end
    set(parent,'Position',newPos);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A quick fix for a complicated problem:
% if many panels are added in many locations, (e.g. some above,
% some to the right), and they are toggled in a random order,
% some panels may be made too large. To help correct for this,
% correct panels which are larger than the parent object.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(objs)
    exUnits = get(objs(i),'Units');
    set(objs(i),'Units','normalized');
    objPos = get(objs(i),'Position');
    if objPos(3)+objPos(1) > 1
        objPos(3) = 1-objPos(1);
        set(objs(i),'Position',objPos);
    end
    if objPos(4)+objPos(2) > 1
        objPos(4) = 1-objPos(2);
        set(objs(i),'Position',objPos);
    end
    set(objs(i),'Units',exUnits); % restore previous unit convention
end

% restore previous units
set(parent,'Units',figUnits);
set(panel,'Units',panelUnits);

figOffscreenCheck(parent);

return

