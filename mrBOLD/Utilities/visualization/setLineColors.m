function setLineColors(col,h);
% setLineColors(col,[h]): set the color order used
% when plotting lines in an axis.
% 
% Problem: When you plot a bunch of lines in MATLAB,
% it cycles through a default color set -- blue, red,
% green, cyan, etc. But sometimes you want different
% colors, and don't want to manually loop through,
% plotting each one separately.
%
% Solution: use this. col can be a matrix of 
% nColors x 3, or a cell whose entries are either
% a string specifying a color ('w' for white, 'r' for
% red -- type HELP PLOT for more options) or an 
% [R G B] 1 x 3 matrix. h is the handle for the
% axes to which to apply the colors. It defaults 
% to the current axes. 
%
% Note this can be done after the fact as well -- 
% you can plot first, then set the colors later.
% However, it sets the 'NextPlot' property of 
% the axes to 'ReplaceChildren', and the specified
% color order as the default -- meaning future plots
% plotted on the axes will cycle through the new
% color order specified in col.
%
% ras 01/05.
if nargin < 2
    h = gca;
end

% the new color order should be an N x 3 matrix:
if iscell(col)
    nColors = length(col);
    tmp = zeros(nColors,3);
    for c = 1:nColors
        if ischar(col{c})
            tmp(c,:) = colorLookup(col{c});
        elseif isnumeric(col{c}) & isequal(size(col{c}),[1 3])
            tmp(c,:) = col{c};
        else
            error('Entries in col must be either a letter or a 1 x 3 matrix');
        end
    end
    col = tmp;
end

% recursive if h specifies many axes
if length(h) > 1
    for i = 1:length(h)
        setLineColors(col,h(i));
    end
    return
end

% try to change any existing lines in the axis
oldco = get(h,'ColorOrder');
exlns = findobj('Parent',h,'Type','line');
for l = 1:length(exlns)
    % findobj will return the lines in reverse
    % order to how they were created, meaning
    % that you have to work backwards down the
    % list of existing lines:
    colorInd = length(exlns)-l+1;
    colorInd = mod(colorInd-1,size(col,1)) + 1; % cycle around colors
    set(exlns(l),'Color',col(colorInd,:));
end

% also retroactively change any patches (bar plots)
expatches = findobj('Parent',h,'Type','hggroup');
for l = 1:length(expatches)
    % findobj will return the lines in reverse
    % order to how they were created, meaning
    % that you have to work backwards down the
    % list of existing lines:
    colorInd = length(expatches)-l+1;
    colorInd = mod(colorInd-1,size(col,1)) + 1; % cycle around colors
    
    if isprop(get(expatches(l), 'Children'), 'FaceColor')
        set(get(expatches(l), 'Children'), 'FaceColor', col(colorInd,:));
        
    elseif isprop(get(expatches(l), 'Children'), 'Color')
        set(get(expatches(l), 'Children'), 'Color', col(colorInd,:));
        
    end
end


% also set axis properties for future plots
set(h,'NextPlot','ReplaceChildren','ColorOrder',col);
    
return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function vec = colorLookup(str);
% looks up the character in string and returns
% an appropriate 1 x 3 RGB vector.
switch lower(str(1))
    case 'r', vec = [1 0 0]; % red
    case 'g', vec = [0 1 0]; % green
    case 'b', vec = [0 0 1]; % blue
    case 'w', vec = [1 1 1]; % white
    case 'k', vec = [0 0 0]; % black
    case 'c', vec = [0 .75 .75]; % cyan
    case 'y', vec = [.75 .75 0]; % yellow
    case 'm', vec = [.75 0 .75]; % magenta
    case 'e', vec = [.25 .25 .25]; % gray
    otherwise, 
        msg = sprintf('color lookup: strange color specified? -- %s\n',str);
        msg = sprintf('%s defaulting to black...\n',msg);
        warning(msg);
        vec = [0 0 0];
end
return
   