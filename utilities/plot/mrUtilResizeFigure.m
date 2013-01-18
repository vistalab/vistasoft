function mrUtilResizeFigure(figNum, width, height, reposition);
% Resizes the figure without changing it's poisition.
% mrUtilResizeFigure(figNum, width, height, [reposition=false]);
%
% HISTORY:
% 2006.05.04 RFD: wrote it.

if(exist('reposition','var') & ~isempty(reposition) & reposition)
    ss = get(0,'ScreenSize');
    p = [ss(2) ss(3)];
else
    p = get(figNum,'Position');
end

set(figNum, 'Position', [p(1), p(2), width, height]);

return;