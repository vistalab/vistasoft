function [vw,im] = recompute3ViewImage(vw,sliceNum,sliceOri);
%
% [vw,im] = recompute3ViewImage(vw,sliceNum,sliceOri);
%
% Recomputes the image for a volume 3 vw. The main difference from
% recomputeImage is that the slice # and slice orientation can be input as
% arguments, rather than using the vals set for the vw (curSlice(vw) for a
% 3-vw is somewhat nonsensical).
%
% djh, sometime in '98
% djh, 2/2001. version 3.0
% ras, hacked off of recomupteImage, 03/06/03
% Ress mentioned an improvement in recomputeImage since this branched off,
% which allows, for amplitude modes, the amp clip to be set using the
% mapMin/mapMax sliders. This is a good idea; I need to merge that feature
% in here. -ras, 03/04
if ~exist('sliceNum','var') sliceNum = 1;   end
if ~exist('sliceOri','var') sliceOri = 1;   end

% Initialize image
anatIm=[];


% Get colormap, numGrays, numColors and clipMode
modeStr=['vw.ui.',vw.ui.displayMode,'Mode'];
mode = eval(modeStr);
numGrays = mode.numGrays;
numColors = mode.numColors;
clipMode = mode.clipMode;

% Get cothresh, phWindow, and mapWindow from sliders
cothresh     = viewGet(vw, 'cothresh');      
phWindow     = viewGet(vw, 'phaseWindow');   
mapWindow    = viewGet(vw, 'mapWindow');    

% error check on slice number
if isnan(sliceNum) || sliceNum<1, sliceNum = 1; end
if sliceNum > size(vw.anat, sliceOri)
    sliceNum = size(vw.anat, sliceOri);
end

%TODO: Replace with viewGets once the anat file is no longer written out
% Get anatomy image
%This seems to suggest that we are in SAR format. So, the vw.anat data
%matrix was stored in SAR format, with X being dim2, Y being dim3
switch sliceOri
    case 1, % axial
        anatIm = squeeze(vw.anat(sliceNum,:,:));
    case 2, % coronal
        anatIm = squeeze(vw.anat(:,sliceNum,:)); 
    case 3, % sagittal
        anatIm = vw.anat(:,:,sliceNum);
end

% Get overlay
overlay = [];
if ~strcmp(vw.ui.displayMode,'anat')
    overlay = cropCurSlice(vw, vw.ui.displayMode, sliceNum, sliceOri);
end

% Select pixels that satisfy cothresh, phWindow, and mapWindow
pts = [];
if ~isempty(overlay)
    pts = ones(size(overlay));
    curCo=cropCurSlice(vw,'co',sliceNum,sliceOri);
    curPh=cropCurSlice(vw,'ph',sliceNum,sliceOri);
    curMap=cropCurSlice(vw,'map',sliceNum,sliceOri);
    if ~isempty(curCo) & cothresh>0
        ptsCo = curCo > cothresh;
        pts = pts & ptsCo;
    end
    if ~isempty(curPh)
        if diff(phWindow) > 0
            ptsPh = (curPh>=phWindow(1) & curPh<=phWindow(2));
        else
            ptsPh = (curPh>=phWindow(1) | curPh<=phWindow(2));
        end
        pts = pts & ptsPh;
    end
    if ~isempty(curMap)
        % If mapWindow(2) > mapWindow(1), we use AND operator (select
        % values between min and max). If mapWindow(2) < mapWindow(1) we
        % use OR operator (select values greater than mapWindow(1) OR less
        % than mapWindow(2). We do the same already for phase window.
        if diff(mapWindow) > 0
            ptsMap = (curMap>=mapWindow(1) & curMap<=mapWindow(2));
        else
            ptsMap = (curMap>=mapWindow(1) | curMap<=mapWindow(2));
        end
        pts = pts & ptsMap;
    end
end

%% adjust image brightness/contrast based on the GUI settings
brightness = get(vw.ui.brightness.sliderHandle,'Value');
contrast = get(vw.ui.contrast.sliderHandle,'Value');

% unlike the normal way contrast/brightness work,
% I've found it's better to have 'contrast'
% just change the upper bound of the anatClip,
% and 'brightness' just shift the median value
% up and down a bit:
minVal = double(min(anatIm(:)));
maxVal = (1-contrast)*double(max(anatIm(:)));
% removed lines that turned off/on warnings...
anatIm = (rescale2(double(anatIm),[minVal maxVal],[1 numGrays])); 

% brighten
brightDelta = brightness - 0.5;
if brightDelta ~= 0 % slowwww....
	anatIm = brighten(anatIm, brightDelta);
	anatIm = rescale2(anatIm, [], [1 numGrays]);
end

% Rescale overlay to [numGrays:numGrays+numColors-1]
if ~isempty(overlay)
    if strcmp(clipMode,'auto') || isempty(clipMode)
        if ~isempty(find(pts, 1));
            overClipMin = min(overlay(pts));
            overClipMax = max(overlay(pts));
        else
            overClipMin = min(overlay(:));
            overClipMax = max(overlay(:));
        end
    else
        overClipMin = min(clipMode);
        overClipMax = max(clipMode);
    end
    overlay=rescale2(overlay,[overClipMin,overClipMax],...
        [numGrays+1,numGrays+numColors]);
end

% Combine overlay with anatomy image
if ~isempty(overlay)
    % Combine them in the usual way
    im = anatIm;
    indices = find(pts);
    im(indices) = overlay(indices);

elseif ~strcmp(vw.ui.displayMode,'anat')
    % Perhaps data not loaded
    im = anatIm;


else
    % No overlay.  Just show anatomy image.
    im = anatIm;

end

% 2003.01.10 RFD: the following is no longer necessary- the uint8 data
% can't have any NaNs! Also, it caused problems in matlab versions <6.5.
% 2003.01.23 ARW: But without it, Matlab 6.5 fills in the Nans in the flat map as white.
% Do a version check for now and replace NaNs if >=R13
if (version('-release')>=13)
    indices = isnan(im);
    im(indices) = 1;
end

% Finally, set the vw.ui.image field
%vw.ui.image = uint8(double(im)-1);

vw.ui.image = im;

if isempty(overlay)
    vw.ui.cbarRange = [];
else
    vw.ui.cbarRange = [overClipMin overClipMax];
end

return;

