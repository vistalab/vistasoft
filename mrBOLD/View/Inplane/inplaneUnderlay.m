function [vw, img, hImg] = inplaneUnderlay(vw, axs, slices);
%
% [vw, img, hImg] = inplaneUnderlay(vw, <axs>, <slices>);
%
% For Inplane Views, compute the underlay (antomy) image.
% If an axis handle is entered as the second argument, 
% will display/update the image in those axes. Also, 
% if the handle [axs] points to an image object, will update the
% CData for that object without modifying other things in the
% axes. This is used to quickly update parts of a view while
% leaving other parts (overlays, ROIs) unchanged.
%
%
% If 0 is entered as the axis handle, will grab the handles from 
% the view structure. 
%
% Returns the view, which is unmodified for hidden views, but is updated
% to reflect the underlay object in non-hidden views 
% (in vw.ui.underlayHandle), the image data, and the handle to the
% image object if created.
%
% ras 05/2006
img = []; hImg = [];

if nargin<3
    % get slices from view
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
            im = recomputeAnatImage(vw,'anat',slice);

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

% make truecolor
clim = viewGet(vw, 'anatClip');
img = rescale2(img, clim, clim);
img = repmat(normalize(img), [1 1 3]);

% if axs provided as 0, grab handle from vw structure
if exist('axs', 'var')  & axs==0
    if ~isfield(vw, 'ui')
        warning('Can''t grab handles from field -- no UI');
        return
    end
    if isfield(vw.ui,'underlayHandle') & ishandle(vw.ui.underlayHandle)
        axs = vw.ui.underlayHandle;
    else
        axs = vw.ui.mainAxisHandle;
    end
end          

% if handle provided to display object, put up image
if exist('axs', 'var') & ishandle(axs)
    type = get(axs, 'Type');
    if isequal(type, 'axes')
        axes(axs); hImg = image(img); axis equal; axis off
    elseif isequal(type, 'image')
        szX = size(img,2); szY = size(img,1);
        set(axs, 'CData', img, 'XData', 1:szX, 'YData', 1:szY);
        axis([1 szX 1 szY]);
        hImg = axs;
    end
    
    % update vw struct
    vw.ui.underlayHandle = hImg;
end


return