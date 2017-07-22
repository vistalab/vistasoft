function vw = refreshView(vw, recomputeFlag, redrawRois)
% 
% vw = refreshView(vw, [recomputeFlag=1], [redrawRois=1])
% 
% Author: Who Knows
% Purpose:
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
% image.  Otherwise, uses the image stored in vw.ui.image. (for
% values >1, bypasses the 'quick recompute' I implemented earlier;
% e.g., for changing orientations in a volume view, forget the previous
% zoom settings.)
% 
% djh, 1/97
% rmk, 1/15/99 added title bar updates for map views
% rfd, 3/31/99 added option for drawing ROIs as outlines
%              (a negative vw.ui.showROIs flags this).
% wap, 12/22/99
%	 Removed 'Refresh... view' print statement.  It was getting
%   annoying that information would wrap off the screen.
% bw, 12/29/00
%   added support for scan slider redisplay.
% djh, 2/22/2001 updated to version 3
% ras, 2007 (various points): created a separate 'displayImage' function,
% which updates a little quicker if the display axes have been created (and
% we're not switching orientations)

% TODO
% We ned to make sure that the VOLUME values (e.g., current roi) are
% properly set in the ui fields.  This is not currently enforced here (BW).
if ~exist('recomputeFlag','var'), recomputeFlag=1; end

if ~exist('redrawRois','var'), redrawRois=1; end


% Make this one the selectedInplane, selectedVolume, or selectedFlat
if iscell(vw), selectView(vw); end

% Set window title
% Check for sessionCode - this should have been set in openxxxxWindow but
% some other programs (like mrAlign) don't beshave properly.
if (~isfield(vw,'sessionCode'))
    vw.sessionCode=pwd;
end

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

if (recomputeFlag | isempty(vw.ui.image))
    vw = recomputeImage(vw,numGrays,numColors,clipMode);
end

% Select the window
set(0,'CurrentFigure',vw.ui.windowHandle);

% Update annotation string
vw=setAnnotation(vw,getCurScan(vw));

%% Display final image %%
% Change this to cope with different rotations in L and R flatmaps. For
% VOLUME, INPLANE views this does nothing.
rotateDeg=0;

if (strcmp(vw.viewType,'Flat'))
    [rotations,flipLR]=getFlatRotations(vw);
    thisRotation=getImageRotate(vw);

    
    if ((recomputeFlag==2)) % Only set when the hemisphere changes
        
        % Set the UI from the stored values
        
        % Set the corresponding value in degrees in FLAT.imageRotateDegrees
       setImageRotate(vw,rotations(viewGet(vw, 'Current Slice'))/(180/pi));
        thisRotation=getImageRotate(vw);
    end

    
    if (round(thisRotation*(180/pi))~=round(rotations(viewGet(vw, 'Current Slice'))))
        % The values in the VIEW structure and the GUI are out of sync.
        % Because we can get here from a GUI refresh, we should accept the
        % GUI values 
        rotations(viewGet(vw, 'Current Slice'))=thisRotation*(180/pi);
        
        vw=setFlatRotations(vw,rotations,flipLR);        
    end  
    
    rotateDeg=rotations(viewGet(vw, 'Current Slice'));
    flipFlag=flipLR(viewGet(vw, 'Current Slice'));
    
    if (rotateDeg | flipFlag) %If this has been set, then do a rotation        
        img=ind2rgb(vw.ui.image, cmap);              
        img=imrotate(img, -rotateDeg, 'bicubic', 'crop');           
        
        [img cmap] = rgb2ind(img, cmap);
        
        if (flipFlag), img=fliplr(img); end % if flipflag
    else
        img = vw.ui.image;
    end       
    
else    % non-flat view
    img = vw.ui.image;
    
end

vw = displayImage(vw, img, cmap, recomputeFlag);

%% Draw colorbar
if isempty(vw.ui.cbarRange)
    setColorBar(vw,'off',[numGrays+1,numGrays+numColors]);
else
    setColorBar(vw,'on',[numGrays+1,numGrays+numColors]);
end

%% Draw ROIs    (ras 01/07:we only need drawROIs now -- except it's SO
%% SLOW)
if redrawRois==1
    drawROIs(vw);
end

return;
% /----------------------------------------------------------------/ %




% /----------------------------------------------------------------/ %
function vw = displayImage(vw, img, cmap, recomputeFlag);
% ras 01/07: implemented a 'quick update' option, a la volume3View,
% which only updates the CData on an existing image if it can be found.
% This eliminates annoying, superfluous zoom changes when you use
% the zoom buttons (and is maybe a wee bit faster).
ui = vw.ui;
if recomputeFlag > 1  
    % for flag==2, we don't want a quick update; e.g., changing orientation
    ui.underlayHandle = -1;
end
    
if checkfields(ui, 'underlayHandle') && ishandle(ui.underlayHandle(1))
    % handles exist, update image CData only
    set(ui.underlayHandle(1), 'CData', img);
    colormap(cmap);
    quickUpdate = 1; % will bypass axes-related functions below
else
    % create image objects
    axes(ui.mainAxisHandle); cla;
    vw.ui.underlayHandle(1) = image(img); 
    colormap(cmap); axis image, axis off
    quickUpdate = 0; % will do zoom, text creation below
end

% zoom:
if isfield(vw.ui,'zoom') & quickUpdate==0
    if ismember(vw.viewType, {'Inplane' 'Flat' 'SS'}) 
        try, axis(vw.ui.zoom); end
    elseif ismember(vw.viewType, {'Volume' 'Gray'})
        % 3-D zoom bounds specified:
        z = vw.ui.zoom;
        switch getCurSliceOri(vw)
            case 1, axis([z(3,1) z(3,2) z(2,1) z(2,2)]); % axi
            case 2, axis([z(3,1) z(3,2) z(1,1) z(1,2)]); % cor
            case 3, axis([z(2,1) z(2,2) z(1,1) z(1,2)]); % sag
        end
    end
end

return

