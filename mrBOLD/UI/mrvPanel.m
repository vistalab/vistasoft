function h = mrvPanel(loc, sz, par, units, varargin);
%
% h = mrvPanel([loc], [sz], [par], [units], [other properties]);
%
% UI tool for mrVista 2.0:
% Add a uipanel (for a group of related controls
% or axes) to a parent figure/other object in the
% specified position,  while maintaining the size of
% the other objects in the figure. Returns a handle
% to the panel.
%
% loc: string specifying where to add the panel. Can be 
% 'top', 'bottom', 'left', 'right'. [Default 'right'] The
% panel will cover the entire width (for 'top' or 'bottom')
% or height (for 'left' or 'right') of the object,  and will
% make the figure larger.
%
% sz: number specifying the width or height of the panel,  in the
% panel's units (see below). [Default 0.1,  normalized]
%
% par: parent object. Usually a figure,  but could theoretically
% be another uipanel (nesting panels within panels). [Default gcf]
%
% units: units to specify for the panel. [Default 'normal',  normalized
% to par object] But could be e.g. 'char' for characters
% or 'pixels' for pixels relative to corner of par object.
%
% NOTE: if 'normalized' units are specified,  this is taken
% to mean 'normalized with respect to parent object',  
% rather than 'normalized w.r.t. screen': e.g.,  if sz=0.25, 
% this means the panel size will be a quarter the size of
% the figure,  not make the figure take up a quarter more
% of the screen.
%
%
% OPTIONAL PROPERTIES:
% There are many other properties of uipanels which may 
% be useful to GET/SET; see HELP UIPANEL or DOC UIPANEL
% for more info. You may set these properties when you call
% mrvPanel by specifying them in the optional arguments, in pairs
% of 'PropertyName', [Value], ... See the example below.
%
% EXAMPLES:
%
% h = mrvPanel('below', 2, gcf, 'char');
%
% adds a panel 2 characters high beneatch the current
% figure,  colored white and with a frame titled 'My Panel'.
%
% h2 = mrvPanel('right', .3, gcf, 'char', 'BackgroundColor', 'w', ...
%              'Title', 'My Panel');
%  
% adds a panel to the right side of the current figure, at 30% its length,
% colored white and with a frame titled 'My Panel'.
%
% SEE ALSO:
% uipanel,  uicontrol,  uibuttongroup,  mrvShowPanel.
%
% ras,  07/05/05.
% ras,  09/25/06: allows panel properties to be set at creation.

% default arguments
if ~exist('loc', 'var') | isempty(loc),  loc = 'right';               end
if ~exist('sz', 'var') | isempty(sz),  sz = 0.1;                      end
if ~exist('par', 'var') | isempty(par),  par = gcf;                   end
if ~exist('units', 'var') | isempty(units),  units = 'normalized';    end

% check that the location arg makes sense
if ~ismember(lower(loc), {'above' 'below' 'left' 'right'})
    help(mfilename);
    error('Unrecognized location argument.');
end

% get the dimension along which the figure will be
% added (index into position vector):
switch lower(loc)
    case {'above', 'below'},  dim = 4;
    case {'left', 'right'},  dim = 3;
end
corner = dim-2; % index into position vector of corner

% get size of parent object in same units as panel:
exUnits = get(par,  'Units'); % existing units
set(par,  'Units',  units);
exPos = get(par,  'Position'); % existing position in same units as panel
exSize = exPos(dim); % size in same units as panel

% parse 'normalized' units to be w.r.t. figure;
% also,  set it so that the specified size is the
% fraction the figure takes after resizing:
% E.g.,  if sz is 1/2,  make the figure twice as big, 
% one half of which is the new panel; NOT make it
% one-and-a-half times as big,  with one third being the
% new panel:
if strncmp(lower(units),  'norm',  4)
    sz = 1 / (1/sz - 1); % makes the specified sz proportion of final size
    sz = sz * exSize;
end

% figure out how much bigger the par will need to be
% to accommodate the new panel
newSize = exSize + sz; % fig size after adding panel

% meanwhile,  the 'panelSize' variable will describe the
% panel's size in normalized units relative to the parent.
% Also set this such that the 
panelSize = sz/newSize; % if units were 'norm',  this should = the original
                        % value of sz

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% resize the parent object %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get new size -- make larger
newPos = exPos;
newPos(dim) = newSize;

% for panels in the below or left locations,  move the corner  back,  
% so existing objects% stay in the same place on the screen
if ismember(lower(loc), {'left' 'below'})
    newPos(corner) = exPos(corner) - exPos(dim)/(1/panelSize+1);
end 

% set the new parent position
set(par, 'Position', newPos);

% check that the new size doesn't push the figure off the
% screen edge -- if so,  move back:
figOffscreenCheck(gcf);

% get all existing child objects of the par object, 
% so we can adjust their relative sizes
objs = findobj('Parent',  par,  'Type',  'uicontrol');
objs = [objs; findobj('Parent',  par,  'Type',  'axes')];
objs = [objs; findobj('Parent',  par,  'Type',  'uipanel')];

% existing objects in the parent will need to be shrunk
% along the relevant dimension by an amount corresponding
% to the growth of the par:
for i = 1:length(objs)
    objUnits = get(objs(i),  'Units');
    set(objs(i),  'Units',  'normalized'); % deal in normalized units for now
    objPos = get(objs(i),  'Position');   % pre-shrinking position
    objPos(dim) = objPos(dim) * (1-panelSize);

    % to keep existing panels flush with one another, 
    % even after shrinking,  we need to nudge panels back:
    if objPos(corner) > 0
        objPos(corner) = objPos(corner) * (1-panelSize);
    end

    % for these locations,  need to move the corners
    % of existing objects forward as well:
    if ismember(lower(loc),  {'left' 'below'})
        objPos(corner) = objPos(corner) + panelSize;
    end
    
    set(objs(i),  'Position',  objPos);
    set(objs(i),  'Units',  objUnits); % restore previous unit convention
end

% figure out the position of the new panel
set(par, 'Units', 'normalized');
switch lower(loc)
    case 'above',  pos = [0 exSize/newSize 1 panelSize];
    case 'below',  pos = [0 0 1 panelSize];
    case 'left',  pos = [0 0 panelSize 1];
    case 'right',  pos = [exSize/newSize 0 panelSize 1];
end
set(par, 'Units', exUnits); % restore previous unit convention

% finally,  add the new panel
h = uipanel('Units', 'Normalized', 'Position', pos, ...
            'UserData', lower(loc), 'FontSize', 14, ...
			'BackgroundColor', get(gcf, 'Color'), ...
            'BorderType', 'none', 'Parent', par);
set(h, 'Units', units);

% set properties according to any optional arguments
for i = 1:2:length(varargin)
    set(h, varargin{i}, varargin{i+1});
end

return
