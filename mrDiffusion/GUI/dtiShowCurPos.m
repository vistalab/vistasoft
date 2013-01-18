function dtiShowCurPos(handles,markSize,markStyle)
%
%   dtiShowCurPos(handles, [markSize=6], [markStyle='rx']])
%
%Author: Dougherty, Wandell
%Purpose:
%    Plot the current position on the Matlab Figure window 3 axes
%

if(~exist('handles','var')|isempty(handles)), error('dtiFiberUI handles required.'); end
if(~exist('markSize','var')|isempty(markSize)), markSize = 6; end
if(~exist('markStyle','var')|isempty(markStyle)), markStyle = 'rx'; end

curPosition  = str2num(get(handles.editPosition, 'String'));

axes(handles.z_cut); hold on;
h = plot(curPosition(1), curPosition(2), markStyle);
set(h,'MarkerSize',markSize*2,'HitTest','off'); hold off;

axes(handles.y_cut); hold on;
h = plot(curPosition(1), curPosition(3), markStyle);
set(h,'MarkerSize',markSize*2,'HitTest','off'); hold off;

% Final flip, curPosition(2) = BigVal - curPosition(2);
axes(handles.x_cut); hold on;
h = plot(curPosition(2), curPosition(3), markStyle);
set(h,'MarkerSize',markSize*2,'HitTest','off'); hold off;

return;
