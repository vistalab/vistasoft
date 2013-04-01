function [vw, img, hImg] = inplaneOverlay(vw, axs, slices, mode);
%
% [vw, img, hImg] = inplaneOverlay(vw, <axs>, <slices>, <mode>);
%
% For inplane views, compute the overlay (map, co/amp/ph) image.
% Will parse the view's settings to get the appropriate data field
% and will threshold it using inplaneOverlayMask. 
%
% If axs is provided as an axes handle, will display the image
% in those axes, using the view's display mode settings. If axs
% is an image handle, will change the image data to quickly updated
% the overlay. Otherwise, will not display the image, only return
% it.
%
% slices defaults to the inplane's selected slices, but can be
% over-ridden without changing the inplane settings.
%
% mode can be a display mode struct containing display settings
% for the overlay, as in ampMode, mapMode, etc.
%
% ras 05/2006.
img = []; hImg = [];

if nargin<4
    % not display mode info: see if it's in the view
    try 
        mode = vw.ui.displayMode; 
    catch
        error('No display mode info.');
    end
end

if nargin<3
    % get slices from vw
    if checkfields(vw, 'ui', 'montageSize')
    nSlices = get(vw.ui.montageSize.sliderHandle,'Value');
    else
        nSlices = 1;
    end

    firstSlice = viewGet(vw, 'Current Slice');
    slices = [firstSlice:firstSlice+nSlices-1];
    slices = slices(slices <= numSlices(vw));
end


if checkfields(vw, 'ui', 'zoom')
    zoom = vw.ui.zoom;
else
    zoom = [1 size(viewGet(vw,'Anatomy'), 2) 1 size(viewGet(vw,'Anatomy'), 1)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% non-hidden views: get info from UI %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modeInfo = viewGet(vw,[mode 'Mode']);

% Get cothresh, phWindow, and mapWindow from sliders
cothresh = getCothresh(vw);
phWindow = getPhWindow(vw);
mapWindow = getMapWindow(vw);
clipMode = modeInfo.clipMode;
numGrays = modeInfo.numGrays;
numColors = modeInfo.numColors;
cmap = modeInfo.cmap;


% for anat modes, return empty
if isequal(vw.ui.displayMode, 'anat'), return; end

% get # of slices; figure out a good # of rows, cols for montage
nSlices = length(slices);
nrows = ceil(sqrt(nSlices));
ncols = ceil(nSlices/nrows);

for row = 1:nrows
    rowIm = [];

    for col = 1:ncols
        sliceind = (row-1)*ncols + col;

        if sliceind <= length(slices)
            % if there's a slice for this row/col
            slice = slices(sliceind);
        else
            % otherwise, set it to show black space below
            slice = slices(end) + 1;
        end

        if slice <= slices(end)
            % Get anatomy image
            im = cropCurSlice(vw, mode, slice);

            % zoom
            zoom = round(zoom);
            im = im(zoom(3):zoom(4), zoom(1):zoom(2));
        else
            % there may be blank spaces at the end of the montage image
            im = zeros(size(im));
        end

        rowIm = [rowIm im];
    end

    img = [img; rowIm];
end

vw.ui.image = img;

% get a mask for the overlay, which will be used below
mask = inplaneOverlayMask(vw, img);

% make truecolor
if isequal(clipMode, 'auto')
    clim = [min(img(mask)) max(img(mask))];
else
    clim = clipMode;
end
img = rescale2(img, clim, [1 numColors]);
img = ind2rgb(img, cmap(numGrays+1:end,:));

% if axs provided as 0, grab handle from view structure
if exist('axs', 'var')  & axs==0
    if ~isfield(vw, 'ui')
        warning('Can''t grab handles from field -- no UI');
        return
    end
    if isfield(vw.ui,'overlayHandle') & ishandle(vw.ui.overlayHandle)
        axs = vw.ui.overlayHandle;
    else
        axs = vw.ui.mainAxisHandle;
    end
end          

% if handle provided to display object, put up image
if exist('axs', 'var') & ishandle(axs)
    % when we display it, we intend for it to be on top of
    % an underlay image which may have a different resolution,
    % so we want to figure out on what X and Y values to plot:
    rsFactor = upSampleFactor(vw, 1);
    szX = size(img,2); %./rsFactor(2); 
    szY = size(img,1); %./rsFactor(1);

    type = get(axs, 'Type');
    if isequal(type, 'axes')
        axes(axs); hold on
        hImg = image(1:szX, 1:szY, img); 
        axis equal; axis off
    elseif isequal(type, 'image')
        set(axs, 'CData', img, 'XData', 1:szX, 'YData', 1:szY);
        axis([1 szX 1 szY]);
        hImg = axs;
    end
    
    try 
        set(hImg, 'AlphaData', double(mask));
    catch 
        disp('Nope')
    end
    
    % update view struct
    vw.ui.overlayHandle = hImg;
end


return