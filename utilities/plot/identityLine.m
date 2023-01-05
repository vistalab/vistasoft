function p = identityLine(ax,varargin)
%Draw an identity line on the current axis
%
%   p = identityLine(ax,varargin)
%
% Example:
%   plot(1:10,randn(1,10),'o')
%   identityLine(gca);
%   identityLine(gca,'linecolor',[1 0 0],'linestyle',':');
%
% (c) Stanford VISTA Team

%% if notDefined('ax'), ax = gca; end
p = inputParser;

% First optional argument
p.addRequired('ax',@isgraphics);

% Line color and style
vFunc = @(x) isnumeric(x) && logical(length(x) == 3);
p.addParameter('linecolor',[.5 .5 .5],vFunc);
p.addParameter('linestyle','--',@ischar);

% Parse inputs
p.parse(ax,varargin{:});
ax = p.Results.ax;
linecolor = p.Results.linecolor;
linestyle = p.Results.linestyle;

%% Set up axes
% Minimum and maximum of axes
xlim = get(ax,'xlim');
ylim = get(ax,'ylim');
mn = min(xlim(1),ylim(1));
mx = max(xlim(2),ylim(2));

% Here's the line
p = line([mn mx],[mn mx],'color',linecolor,'linestyle',linestyle);

% Set line properties.  These probably want to come in as an argument
set(p,'linewidth',2);
grid on

return