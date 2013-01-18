function AX = normAxes(obj, AX, varargin);
% normAxes: set all axes within a figure to have the same axes.
% 
%	AX = normAxes(obj, AX, [options]);
%
% AX = normAxes(obj) sets all axes that are children of 
% the specified object to have the same, maximal axes. Returns
% AX, these maximal axes. obj defaults to gcf.
%
% If you only want to normalize some axes within the figure
% (E.g., for making figure papers), you can pass obj as a 
% vector of handles to those axes.
%
% You can also manually specify the axis bounds
% by specifying AX as a second argument. The format
% is [xmin xmax ymin ymax].
%
% Options include:
%
%	'xonly': will normalize each subplot only along the X axis, leaving the
%	Y axis range of each subplot as it was before. In this case, if you
%	don't pass in a value for the AX argument, it will default to the max
%	range across all axes; otherwise, it will only pay attention to the
%	first two elements of AX.
%
%	'yonly': will normalize each subplot only along the Y axis, leaving the
%	X axis range of each subplot as it was before. In this case, if you
%	don't pass in a value for the AX argument, it will default to the max
%	range across all axes; otherwise, it will only pay attention to the
%	third and fourth elements of AX.
%
%	'zoom': rather than setting the axis range AX based on the maximum
%	range across all subplots, the code will set the axis range based on
%	the minimum range across subplots. This will generally cause most
%	subplots to have data outside the plotted range, but will prevent any
%	subplot from have the data compressed in a small part of the axis
%	range.
%
%
% ras 06/05.
% ras 10/09: added optional inputs, made more sophisticated (for better or
% worse :).
if ~exist('obj', 'var') | isempty(obj), obj = get(gca, 'Parent'); end

if length(obj)==1
    haxes = findobj('Type','axes','Parent',obj);
else
    haxes = obj;
end

if isempty(haxes), AX = []; return; end

%% flags for optional behaviors
maxRange = 1; % default axis range is the max across subplots
xOnly = 0;
yOnly = 0; 

% parse the options
for ii = 1:length(varargin)
	switch lower(varargin{ii})
		case 'zoom', maxRange = 0;
		case 'xonly', xOnly = 1;
		case 'yonly', yOnly = 1;
		otherwise, warning('Unrecognized option: %s', varargin{ii});
	end
end

if ~exist('AX','var') | isempty(AX)
	% get a default axis range across subplots
    for i = 1:length(haxes)
        axes(haxes(i));
        a(i,:) = axis;
	end
	
	if maxRange==1
	    % take the maximum axis range across all subplots
		AX = [min(a(:,1)) max(a(:,2)) min(a(:,3)) max(a(:,4))];
	else
		% take the minimum axis range across all subplots.
	    AX = [max(a(:,1)) min(a(:,2)) max(a(:,3)) min(a(:,4))];
	end
end

for i = 1:length(haxes)
    axes(haxes(i));
	
	if xOnly==1
		% set x range only
		tmpAX = axis;
		tmpAX(1:2) = AX(1:2);
	elseif yOnly==1
		% set y range only
		tmpAX = axis;
		tmpAX(3:4) = AX(3:4);
	else 
		tmpAX = AX;
	end
	
	axis(tmpAX);	
end

return
