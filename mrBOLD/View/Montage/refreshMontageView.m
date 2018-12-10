function vw = refreshMontageView(vw,recomputeFlag,drawRois)
% 
% vw = refreshMontageView(vw,recomputeFlag,drawRois)
% 
% For inplane montage views:
% Refresh the screen given the current state of the ui
% parameters.  This is a key script.  It is used to put up all
% the different viewTypes of images under the View menu.
%
% vw.ui.displayMode must be a string (either 'anat', 'co',
% 'amp', 'ph, or 'map') corresponding to the available
% displayModes (anatMode, coMode, ampMode, phMode, and mapMode).
% Each displays a different overlay on the anatomy, with a
% different colormap.
%
% Each displayMode has a cmap field (e.g., vw.ui.anatMode.cmap).
%
% Each displayMode also has a clipMode field (e.g.,
% vw.ui.anaMode.clipMode) that determines clipping of the
% overlay image values to fill the range of available colors.  The
% clipMode can be either 'auto' or [clipMin clipMax].  If 'auto',
% uses overlayClip sliders to determine clipping.  If [clipMin
% clipMax], uses those values instead.  For some of the
% displayModes ('ph') fixed clipping usually makes sense because
% we want certain values (e.g., 0 phase) to always correspond to
% the same color (e.g., red) regardless of the cothresh and
% phWindow.
%
% recomputeFlag: if nonzero (the default), recomputes the uint8
% image.  Otherwise, uses the image stored in vw.ui.image.
% 
% ras 09/04: broken off refreshView.
if ~exist('vw', 'var'),             vw = getSelectedInplane;    end
if ~exist('recomputeFlag','var'),   recomputeFlag=1;            end
if ~exist('drawRois','var') || isempty(drawRois), drawRois = 1; end

% Get colormap, numGrays, numColors and clipMode
modeName = viewGet(vw,'displayMode');
str = [modeName 'Mode'];

% Make sure the phMode, or ampMode structure exists.  If not, then set them
% to the default values.
if ~checkfields(vw,'ui',str), vw=resetDisplayModes(vw); end

% Here is the mode, get the relevant parameters.
modeStr=['vw.ui.',str];
mode = eval(modeStr);
numGrays = mode.numGrays;
numColors = mode.numColors;

if (recomputeFlag || isempty(vw.ui.image))
    delete(findobj('Parent', vw.ui.mainAxisHandle)); %Deletes the previous graph
    firstSlice =  viewGet(vw, 'curSlice');
    nSlices = get(vw.ui.montageSize.sliderHandle,'Value');
    slices = firstSlice:firstSlice+nSlices-1;
    slices = slices(slices <= viewGet(vw, 'numSlices'));
    zoom = viewGet(vw, 'zoom');
    [img, vw] = inplaneMontage(vw,slices,modeName,zoom); %#ok<ASGLU>

end

% Select the window
set(0,'CurrentFigure',vw.ui.windowHandle);

% Update annotation string
dt = viewGet(vw, 'dt struct'); curscan = viewGet(vw, 'curScan');
set(vw.ui.annotationHandle,'string',dtGet(dt, 'annotation', curscan));

% Draw colorbar
if isempty(vw.ui.cbarRange)
    setColorBar(vw,'off',[numGrays+1,numGrays+numColors]);
else
    setColorBar(vw,'on',[numGrays+1,numGrays+numColors]);
end

%% Draw ROIs    
% (ras 01/07 -- we only need drawROIs now)
% (ras 02/07 -- except it's REALLY SLOW. going back to the the old approach
% for now)
if drawRois==1
    delete(findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line'))
    if vw.ui.showROIs ~= 0
        switch lower(vw.ui.roiDrawMethod)
            case 'perimeter',   vw = drawROIsPerimMontage(vw, .5);
            case 'boxes',       vw = drawROIsMontage(vw);
            otherwise,          vw = drawROIs(vw);
        end
    end
end


return