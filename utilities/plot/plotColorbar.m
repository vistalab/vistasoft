function plotColorbar(view)
%
% plotColorbar(view)
% Displays the current colorbar in a separate window- good for presentations.
%
% HISTORY:
%   2002.07.18 RFD (bob@white.stanford.edu) Wrote it.
%

selectGraphWin;
global GRAPHWIN;

% Get colormap, numGrays, numColors and clipMode
modeStr = ['view.ui.',view.ui.displayMode,'Mode'];
mode = eval(modeStr);
numGrays = mode.numGrays;
numColors = mode.numColors;
cmap = mode.cmap;

tmp = inputdlg('Adjust cbar range:','Adjust Range',1,{num2str(view.ui.cbarRange)});
cbarRange = str2num(tmp{1});

if(strmatch(view.ui.displayMode,'co'))
    blankIndex = numGrays+1:numGrays+round(numColors*getCothresh(view));
    cmap(blankIndex,:) = zeros(size(cmap(blankIndex,:)));
end

% Draw colorbar
if (length(cbarRange)>1)
    figure(GRAPHWIN);
    image([cbarRange(1) cbarRange(2)], [], [numGrays+1:numGrays+numColors]);
    set(gca,'YTick',[]);
    set(gca,'fontSize',10);
    colormap(cmap);
end


return;