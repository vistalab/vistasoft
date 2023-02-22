function view = refreshSSView(view,recomputeFlag)
% 
% view = refreshSSView(view,recomputeFlag)
% 
% rmk 9/17/98 based on refreshView
% ras 12/04: added brighten GUI callback

if ~exist('recomputeFlag','var')
  recomputeFlag=1;
end

% Get colormap, numGrays, numColors and clipMode
modeStr=['view.ui.',view.ui.displayMode,'Mode'];
mode = eval(modeStr);
cmap = mode.cmap;
numGrays = mode.numGrays;
numColors = mode.numColors;
clipMode = mode.clipMode;

if (recomputeFlag | isempty(view.ui.image))
  view = recomputeSSImage(view,numGrays,numColors,clipMode);
end


% Select the window
set(0,'CurrentFigure',view.ui.windowHandle)

% Display final image
    image(view.ui.image);
    colormap(cmap);
    axis image;
    axis off;
%imshow(view.ui.image,cmap);

% add a fancy GUI callback
htmp = get(gca,'Children');
set(htmp,'ButtonDownFcn',sprintf('%s = adjustMRImage(%s);',view.name,view.name));


return