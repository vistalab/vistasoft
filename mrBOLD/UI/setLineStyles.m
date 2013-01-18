function setLineStyles(styles, h);
% setLineStyles(styles, [h=gca]): set the line style and width used
% when plotting lines in an axis.
% 
% Problem: When you plot a matrix of lines in MATLAB, 
% each column in the matrix is plotted with the same symbol, 
% line style and width. It's often desirable to distinguish them
% by these traits,  but always writing FOR loops can be a pain.
%
% Solution: use this. styles should be a cell array with string
% entries for each distinct style. Allowed strings in styles are:
%	Line Styles: '-',  ':',  '--',  '.-',  'none'
%   Symbol types: 'o',  'x',  's',  'd',  '*',  '+'
%	Line Widths: a string with the width: '2.5',  '1',  ...
% see HELP PLOT for more options.
% 
% If you specify fewer line styles than lines in the plot, the styles will
% loop around, being applied in turn. The line styled are applied according
% to order of creation, so if you used HOLD ON and plot many lines, the
% earlier entries will apply to the earlier lines.
%
% EXAMPLE:
%	figure,  plot(rand(10,  4));
%	setLineStyles({'-1' '--1.5' '-.2' ':3'});
%
% ras 03/07.
if nargin < 2
    h = gca;
end

if ~iscell(styles)
	error('styles should be a cell array of strings.');
end

% be recursive if h specifies many axes
if length(h) > 1
    for i = 1:length(h)
        setLineColors(styles, h(i));
    end
    return
end

% find existing lines in the parent object
exlns = findobj('Parent', h, 'Type', 'line');
exlns = [exlns findobj('Parent', h, 'Type', 'hggroup')]; % errorbar objs

% loop through each, setting line styles
% (NOTE: this is a pretty inefficient method -- guess time doesn't much
% matter)
lineStyles = {'--' ':' '-.' '-' 'none' '(none)'};
symbols = {'o' 'x' '+' '*' 's' 'd' 'v' '^' '<' '>' 'p' 'h'};
for l = 1:length(exlns)
    % findobj will return the lines in reverse
    % order to how they were created,  meaning
    % that you have to work backwards down the
    % list of existing lines:
    I = length(exlns) - l + 1;
    I = mod(I-1, length(styles)) + 1; % cycle around entries
	
	str = styles{I};  % style string for this line
	
	% check if this string specifies the line style
	j = 1;
	while 1
		if strfind(str, lineStyles{j})
			set(exlns(l), 'LineStyle', lineStyles{j});
			break
		elseif j==length(lineStyles), 
			break
		end
		j = j + 1;
	end
	
	% check if this string specifies a symbol
	j = 1;
	while 1
		if strfind(str, symbols{j})
			set(exlns(l), 'Marker', symbols{j});
			break
		elseif j==length(symbols), 
			break
		end
		j = j + 1;
	end	
	
	% check if this string specifies a line width
	if any(ismember(int16(str), 48:57))  % has a number string 
		% find numeric string indices
		ii = find(ismember(str, char('.0123456789')));
		set(exlns(l), 'LineWidth', str2num(str(ii)));
	end
end
    
return
