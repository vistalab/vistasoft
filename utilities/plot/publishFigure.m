function [vw, img] = publishFigure(vw, varargin)
% [vw, img] = publishFigure(vw, varargin)
%
% Produces a publication-quality figure from the current view.
% Currently, it only works properly with the FLAT view.
%
% Note that if an ROI named 'mask' is found, it will be treated differently
% from all other ROIs. It willnot be rendered, but instead will be used as
% a mask so that only data within the ROI will be shown. Just the anatomy
% underlay will be shown in the region outside the 'mask' ROI.
%
% Here's a summary of what it does:
%
%  * everything (anatomy, data overlay, ROI overlay) is upsampled
%    with 2 iterations of 'upsample', which quadruples nrows and ncols.
%    Each iteration applies a 4-tap filter that does minimal blurring
%    and preserves spatial location.
%
%  * A background mask is extracted from the anatomy image (which is
%    from vw.anat).  Basically, everything that is a nan in vw.anat
%    becomes background.  This mask is blurred to shit and then thresholded
%    in order to get a smoothed version of the anatomy outline.
%
%  * The anatomy image is upsampled blurred once, and then scaled to a
%    specified mean and contrast (currently .5 and .1).  Then, it is
%    thresholded by its median to produce a Tootell-esque curvature
%    image.  Finally, it is run through another iteration of blurring
%    and loaded into an RGB array transformed by a grayscale colormap.
%
%  * The data are loaded from the current slice and scan.  The desired
%    data overlay (co, ph, amp or map) is then upsampled.  Then, an
%    overlay mask is created based on the current coThresh, ph window
%    and map window.  This mask is upsampled and blurred, and is then
%    thresholded.  As with the background mask, the blurring here
%    creates a mask with smooth outlines without having to blur the
%    actual data.  The data are not blurred any more than is necessary
%    for upsampling.  The data are finally merged into the anatomy RGB
%    using the relevant colormap (from vw.ui...) and the overlay mask.
%
%  * A slight blur is applied at this point to each of the color channels
%    in order to blend the data overlay into the anatomy.  However, the
%    overlay is overlayed again _after_ this blurring, so that the actual
%    data are not blurred, just their edges.  This effect is subtle, but it
%    helps the data overlay to look like it's on the anatomy, not floating
%    above it.
%
%  * The ROIs are loaded and their contours smoothed by a blur-then-threshold
%    procedure similar to the background and overlay masks.  Then, they are
%    convolved with a kernel that enlarges them.  The original ROIs are
%    subtracted from the enlarged ROIs, thus leaving a thickened border
%    around them.  This border is also merged with the anatomy RGB using the
%    colors from vw.ROIs.
%
%  * Finally, the background mask is applied to make the background the
%    desired color (currently black), and a scale bar is added.  The scale
%    bar is 40 pixels long, which will correspond to 1 cm, if the vw.anat
%    pixels are 1 mm (which they should be for a Flat map).
%
% Options:
%    'noROIs'
%	 'newFig'
%    'paramPrompt': prompt the user to set publishing params using a
%			dialog.
%    'cbarFlag': will attach the figure's colorbar in a side panel.
%    'labelRois': will attach a legend with ROI colors and names in a side
%    panel.
%
%
% TODO:
% * Allow options
%
% 99.10.13 RFD wrote it.
% 99.10.14 RFD Got ROI overlays working.
% 99.10.15 fixed 1-pixel roi placement error, added 1 cm scale bar,
%          and a description.
% 02.12.18 RFD: fixed some issues with Matlab 6.5 (mostly with logical data
% types). I also changed correlation thresholding so that with cothresh of
% 0, no thresholding is performed. Also added data masking.
% 03.01.14 RFD: added option to prompt for some parameters.
% 03.09.20 arw : Added filledPerimeter and rotateImageDegrees options
% 07.01.09 ras: added cbarFlag and labelRois options. Set default fig color
% to white.
global PREFS;
global GRAPHWIN;
binaryAnatFlag = 1;
anatBlurIter = 1;
anatBlurIterPre = 1;
backRGB = [1 1 1];
roiLineWidth = 2;
overlayBlurIter = 0;
upSampIter = 2;
clipMode = [];
cbarFlag = 0; % ~isequal( viewGet(vw, 'displayMode'), 'anat' );
labelRois = 0;

% should we plot the results? And if so, in a new figure?
plotFlag = ~(nargout > 1);
if(strmatch('plot', lower(varargin))),	plotFlag = true; end
if(strmatch('newfig', lower(varargin))) 
	newFigFlag = 1; 
else
	newFigFlag = 0; 
end
clipPtsThresh = 0.5;
upFilt = [0 .25 .75 .75 .25]';
anatMean = .5;
anatCont = .1;

fprintf('Publishing Flat Figure.... ');

ii = strmatch('anatbluriterpre', lower(varargin));
if (~isempty(ii)), anatBlurIterPre = str2num(varargin{ii+1}); end
ii = strmatch('roilinewidth', lower(varargin));

if (~isempty(ii)), roiLineWidth = str2num(varargin{ii+1}); end

ii = strmatch('upsampiter', lower(varargin));
if (~isempty(ii)), upSampIter = str2num(varargin{ii+1}); end

% get PREFS from a prompt, if requested
if any(strmatch('paramprompt', lower(varargin)))
	[PREFS ok] = publishFigureParams(vw, PREFS);
	if ~ok
		disp('User aborted.')
		img = [];
		return
	end	
end

binaryAnatFlag = PREFS.plots.publishFigure.binaryAnatFlag;
anatBlurIter = PREFS.plots.publishFigure.anatBlurIter;
anatBlurIterPre = PREFS.plots.publishFigure.anatBlurIterPre;
backRGB = PREFS.plots.publishFigure.backRGB;
roiLineWidth = PREFS.plots.publishFigure.roiLineWidth;
overlayBlurIter = PREFS.plots.publishFigure.overlayBlurIter;
upSampIter = PREFS.plots.publishFigure.upSampIter;
clipMode = PREFS.plots.publishFigure.clipMode;
cbarFlag = PREFS.plots.publishFigure.cbarFlag;
labelRois = PREFS.plots.publishFigure.labelRois;

curSlice = viewGet(vw, 'Current Slice');
%antiAliasFilt = [.25 .5 .25];
antiAliasFilt = [.0625 .2500 .3750 .2500 .0625];
antiAliasFilt = antiAliasFilt'*antiAliasFilt;
anatIm = vw.anat(:,:,curSlice);
imSize = size(anatIm).*(2^upSampIter);
% imSize = size(anatIm)*upSampIter;
anatRGB = zeros([imSize 3]);
img = zeros([imSize 3]);
scaleBar.len = 10*(2^upSampIter);
scaleBar.thick = max(1, 1*(2^upSampIter));
sbOffset = 10*(upSampIter);
scaleBar.x = [imSize(2)-sbOffset-scaleBar.len, imSize(2)-sbOffset];
scaleBar.y = [imSize(1)-sbOffset-scaleBar.thick, imSize(1)-sbOffset-scaleBar.thick];
if(all(backRGB==[0.5 0.5 0.5]))
    scaleBar.color = [1 1 1];
else
    scaleBar.color = 1-backRGB;
end



% Extract the background mask
%
% (ones where the background is, zeros everywhere else)
% We create it by first finding the nans (which represent the
% pixels outside of the unfold area).  Then, we upsample to
% the desired size.  One problem is that the unfold regions
% have jagged, pixely edges.  So, we blur the shit out of the
% background mask and then threshold it to get zeros and ones
% again.  This smooths the outline nicely.  The only complication
% is that there are noticeable edge effects from the blur, so
% we put a padding of ones in before blurring, and then clip
% back to the original size.
backMask = (isnan(anatIm) | anatIm == 0);
backMask = double(backMask);
backMask = mrUpSample(backMask, upSampIter, upFilt);
onesPad = 20;
temp = ones(size(backMask)+2*onesPad);
temp((onesPad+1):(end-onesPad),(onesPad+1):(end-onesPad)) = backMask;
temp = blur(temp,3);
backMask = temp((onesPad+1):(end-onesPad),(onesPad+1):(end-onesPad))>.5;


% Extract the anatomy image
%
% replace the nans with the mean, upsample, and then normalize.
anatIm(isnan(anatIm)) = mean(anatIm(~isnan(anatIm(:))));
curvIm = blur(mrUpSample(anatIm,upSampIter,upFilt), anatBlurIterPre);
curvIm = curvIm - min(curvIm(:));
curvIm = curvIm./max(curvIm(:));
curvIm = curvIm.*anatCont + anatMean-anatCont/2;

% Turn the anatomy into a tootelleske binary curvature map, if desired
if binaryAnatFlag
    anatMedian = median(curvIm(~backMask(:)));
    curvIm = (curvIm>anatMedian).*anatCont + anatMean-anatCont/2;
end

% Set each of the 3 color channels, adding a little more
% blur, if desired.
anatRGB(:,:,1) = blur(curvIm, anatBlurIter);
anatRGB(:,:,2) = blur(curvIm, anatBlurIter);
anatRGB(:,:,3) = blur(curvIm, anatBlurIter);
clear curvIm  anatIm;



% Create data overlay
%
% We extract the whole set of data and a mask which
% indicates which subset we should show, based on the current
% cothresh, phase window and map window settings.
%
cothresh = getCothresh(vw);
phWindow = getPhWindow(vw);
mapWindow = getMapWindow(vw);

% Extract the overlay data
overlay = [];
overlayMask = [];

% initialize overlay RGB array
if ~strcmp(vw.ui.displayMode,'anat')
    overlay = cropCurSlice(vw,vw.ui.displayMode);
end
if ~isempty(overlay)
    overlayMask = ones(size(overlay));
    overlayRGB = zeros([imSize 3]);
    curCo = cropCurSlice(vw,'co');
    curPh = cropCurSlice(vw,'ph');
    curMap = cropCurSlice(vw,'map');
    if ~isempty(curCo) & cothresh>0
        overlayMask = overlayMask & (curCo > cothresh);
    end
    if ~isempty(curPh)
        if diff(phWindow) > 0
            overlayMask = overlayMask & ((curPh>=phWindow(1) & curPh<=phWindow(2)));
        else
            overlayMask = overlayMask & ((curPh>=phWindow(1) | curPh<=phWindow(2)));
        end
    end
    if ~isempty(curMap)
        if diff(mapWindow) >0
            overlayMask = overlayMask & (curMap>=mapWindow(1) & curMap<=mapWindow(2));
        else
            overlayMask = overlayMask & (curMap>=mapWindow(1) | curMap<=mapWindow(2));
        end

    end

    % Extract the appropriate overlay colormap and set the clipMode.
    eval(['mode = vw.ui.',vw.ui.displayMode,'Mode;']);
    if(isempty(clipMode))
        clipMode = mode.clipMode;
    end
    cmap = mode.cmap(mode.numGrays+1:end,:);

    % Rescale the overlay to 1-ncolors
    if strcmpi(clipMode,'auto')
        if ~isempty(find(overlayMask, 1));
            overClipMin = min(overlay(overlayMask));
            overClipMax = max(overlay(overlayMask));
        else
            overClipMin = min(overlay(:));
            overClipMax = max(overlay(:));
        end
    else
        overClipMin = min(clipMode);
        overClipMax = max(clipMode);
    end

    overlay = rescale2(overlay,[overClipMin,overClipMax],[1,size(cmap,1)]);
    overlay = round(overlay);

    % add a black entry to the colormap to deal with nans
    cmap = [[0 0 0];cmap];
    % adjust the overlay values to reflect the extra color
    overlay = overlay+1;

    % deal with nans by filling them with 1's, which index black
    % in our colormap.
    notNans = find(~isnan(overlay));
    overlay(isnan(overlay)) = 1;

    % upsample and blur each color channel
    overlayRGB(:,:,1) = blur(mrUpSample(reshape(cmap(overlay,1),size(overlay)), ...
        upSampIter,upFilt),overlayBlurIter);
    overlayRGB(:,:,2) = blur(mrUpSample(reshape(cmap(overlay,2),size(overlay)), ...
        upSampIter,upFilt),overlayBlurIter);
    overlayRGB(:,:,3) = blur(mrUpSample(reshape(cmap(overlay,3),size(overlay)), ...
        upSampIter,upFilt),overlayBlurIter);

    %
    % Process overlay mask
    %
    % upsample and blur the existing mask, then repmat it to
    % rows x cols x 3 color channels.
    overlayMask = blur(mrUpSample(double(overlayMask), upSampIter,upFilt),overlayBlurIter);
    overlayMask = repmat(overlayMask>=clipPtsThresh,[1 1 3]);

    %
    % Create merged RGB data
    %
    img = anatRGB.*(~overlayMask) + overlayRGB.*overlayMask;
    clear overlay notNans;

    % Anti-alias overlay edges
    %
    % blur a bit more to smear the edges
    img(:,:,1) = conv2(img(:,:,1), antiAliasFilt, 'same');
    img(:,:,2) = conv2(img(:,:,2), antiAliasFilt, 'same');
    img(:,:,3) = conv2(img(:,:,3), antiAliasFilt, 'same');

    % re-apply the functional overlay, so that they aren't blured
    % by the anti-alias filter
    % (to anti-alias, we only want to blur the edges)
    %overlayMask = overlayMask.*(~backMask);
    img = img.*(~overlayMask) + overlayRGB.*overlayMask;

else % if ~isempty(overlay)
    img = anatRGB;
end

% Draw ROI - This code is buggy.  If there is no ROI, the code breaks.  THe
% current work around is to simply not show any ROIs.
if (~any(strmatch('norois', lower(varargin))) && vw.ui.showROIs~=0)
    [roiRGB,roiMask,dataMask] = makeROIPerimeterRGB(vw, 2^upSampIter, imSize, roiLineWidth);
    %    [roiRGB,roiMask] = makeROIPerimeterRGB(vw, upSampIter, imSize, roiLineWidth);
    roiMask = repmat(roiMask, [1 1 3]);
    img = img.*(~roiMask) + roiRGB.*roiMask;
    if(~isempty(dataMask))
        % data mask is created in makeROIPerimeterRGB and it tells us to
        % show data only in the specified (non-zero) region. So, we replace
        % the data with the anatomy image.
        dataMask = repmat(dataMask, [1 1 3]);
        img = img.*dataMask + anatRGB.*(~dataMask);
        % *** WE SHOULD DO SOME ANTI-ALIASING HERE
    end
end

% Do a rotation if necessary
rotateDeg=0;
if (strcmp(vw.viewType,'Flat'))
    [rotations,flipLR]=getFlatRotations(vw);
    rotateDeg=rotations(viewGet(vw, 'Current Slice'));
    flipFlag=flipLR(viewGet(vw, 'Current Slice'));
end

% Do rotation if required
if (rotateDeg)
    img=imrotate(img,-rotateDeg,'bicubic','crop');
end

% Check for flip
if (flipFlag)
    img(:,:,1)=fliplr(img(:,:,1));
    img(:,:,2)=fliplr(img(:,:,2));
    img(:,:,3)=fliplr(img(:,:,3));
end


% Apply background mask
backMask = repmat(backMask, [1 1 3]);
backRGB = repmat(reshape(backRGB,[1 1 3]),[imSize 1]);
img = img.*(~backMask) + backRGB.*backMask;

% clip, incase the filtering created some out-of-range values
temp = find(img>1);
img(temp) = 1;
temp = find(img<0);
img(temp) = 0;

% draw scale bar
if scaleBar.thick>0
    for(ii=0:scaleBar.thick-1)
        for(c=1:3)
            img(scaleBar.y(1)+ii,scaleBar.x(1):scaleBar.x(2),c) = scaleBar.color(c);
        end
    end
    %line(scaleBar.x, scaleBar.y, 'Color', scaleBar.color, 'LineWidth', scaleBar.thick);
end


if plotFlag
	if (newFigFlag || (isfield(PREFS,'plots') && ...
		isfield(PREFS.plots,'alwaysUseNewWindow') && ...
		PREFS.plots.alwaysUseNewWindow))
		newGraphWin;
	else
		selectGraphWin;
	end

	set(GRAPHWIN, 'Color', 'w');

	hPanel = uipanel('Units', 'norm', 'Position', [0 0 1 1], ...
						'BackgroundColor', 'w', 'BorderType', 'none');
	mainAxes = axes('Parent', hPanel, 'Units', 'norm', 'Position', [0 0 1 1]);

	% add cbar/ROIs legend panel if requested
	if cbarFlag==1 && ~isequal(viewGet(vw, 'displayMode'), 'anat')
		addCbarLegend(vw, GRAPHWIN);
	end

	if labelRois==1 & vw.ui.showROIs ~= 0
		addRoiLegend(vw, GRAPHWIN);
	end

	axes(mainAxes);
	image(img); axis image; axis off; truesize;

	if ispc
		figToCB(GRAPHWIN);
	end
end

fprintf('done.\n');

return;

