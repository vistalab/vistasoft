function vw = refreshFlatLevelView(vw,recomputeFlag)
% 
% vw = refreshFlatLevelView(vw,recomputeFlag);
% 
% This is a version of refreshView that works on the
% Flat Across-Gray-Levels View. There are 2 main reasons
% I'm breaking it off into a separate function:
%
%   1) It allows for working off a mosaic of several layers
%      at once, which may be useful for things like inplane
%      views but would also make the refreshView code confusing;
%
%   2) It's still being tested out, so it's structure is likely
%      to change.
%
% But basically, it refreshes the flat multi view interface
% based off the settings in the UI controls.
% 
% ras, 08/04, off refreshView

if ~exist('recomputeFlag','var'), recomputeFlag=1; end

% Make this one the selectedInplane, selectedVolume, or selectedFlat
if iscell(vw), selectView(vw); end

% Set window title
% Check for sessionCode - this should have been set in openxxxxWindow but
% some other programs (like mrAlign) don't beshave properly.
if (~isfield(vw,'sessionCode'))
    vw.sessionCode=pwd;
end

ui = viewGet(vw,'ui');

% Get colormap, numGrays, numColors and clipMode
str = [vw.ui.displayMode,'Mode'];

% Make sure the phMode, or ampMode structure exists.  If not, then set them
% to the default values.
if ~checkfields(vw,'ui',str), vw=resetDisplayModes(vw); end

% Here is the mode, get the relevant parameters.
modeStr=['vw.ui.',str];
mode = eval(modeStr);
cmap = mode.cmap;
numGrays = mode.numGrays;
numColors = mode.numColors;
clipMode = mode.clipMode;

% get/set flat rotations
[rotations,flipLR] = getFlatRotations(vw);  

if (~(recomputeFlag==2)) % Only set when the hemisphere changes
    % Retreive the imageRotation from the UI
    thisRotation = getImageRotate(vw);
        
    % Set the corresponding value in degrees in FLAT.imageRotateDegrees
    rotations(viewGet(vw, 'Current Slice')) = thisRotation*(180/pi);
end

vw = setFlatRotations(vw,rotations,flipLR);

% recompute the image if selected
if (recomputeFlag | isempty(vw.ui.image))
    vw = recomputeFlatLevelImage(vw);
end

% Select the window
set(0,'CurrentFigure',vw.ui.windowHandle);

% Update annotation string
set(vw.ui.annotationHandle,'string',annotation(vw,getCurScan(vw)));

% Display final image
dispMode = sprintf('%sMode',viewGet(vw,'displayMode'));
cmap = vw.ui.(dispMode).cmap;
imshow(vw.ui.image);
colormap(cmap);

% Draw colorbar
if isempty(vw.ui.cbarRange)
    setColorBar(vw,'off',[numGrays+1,numGrays+numColors]);
else
    setColorBar(vw,'on',[numGrays+1,numGrays+numColors]);
end

% Draw ROIs
if vw.ui.showROIs > 0,     drawROIsMontage(vw);
elseif vw.ui.showROIs < 0, drawROIsPerimMontage(vw);
end

return
