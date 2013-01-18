function [xRgb,yRgb,zRgb,xform,xAxes,yAxes,zAxes] = dtiGetCurSlices(handles)
% Determine current slices and return them (and potentially a lot of other info)
%
%  [xRgb,yRgb,zRgb,xform,xAxes,yAxes,zAxes] = dtiGetCurSlices(handles)
%
% The potential background and overlay images are stored in the background
% slots, dtiH.bg().  This is a structure in which the image is always
% between 0 and 1, but the values of the original are stored in the
% .bg(1).minVal and .bg(1).maxVal slots.
%
% Note: mmPerVox and xform are for the current space that the slices are
% in, NOT the original image space. This is typically 1mm isotropic, ac-pc
% aligned space.
%
% HISTORY: 
%  ?????: Dougherty & Wandell wrote it.
%  2005.06.09 RFD: minor code optimizations to make refreshes closer to 'realtime'.
%  2006.11.08 RFD: default interpolation method is now nearest-neighbor
%    rather than trilinear. We should make this a use option.
%  2006.11.10 RFD: interpolation method is now an option.
%  2009.06.16 RFD: added 0.5 offset to xAxes,yAxes,zAxes to make the axes
%    tick marks line up with the voxel centers.
%
% Brian and Bob (c) Stanford VISTA Team 2005

%% Get key parameters from the GUI
curPosition   = dtiGet(handles,'acpcpos');
overlayThresh = dtiGet(handles,'cur overlay thresh');
overlayAlpha  = dtiGet(handles,'cur overlay alpha');
mmPerVox      = dtiGet(handles,'render mm');
bb            = dtiGet(handles,'default Bounding Box');
anat          = dtiGet(handles,'current anatomy data');      % anat      = handles.bg(curBgNum).img;
anatXform     = dtiGet(handles,'bg img2acpc xform'); 
dispRange     = dtiGet(handles,'display range');
% handles.bg(curBgNum).displayValueRange;
% dispRange     = dtiGet(handles,handles.bg(curBgNum).displayValueRange;

%% Here we get the anatomical slices transformed into image space
[zRgb,x,y,z] = dtiGetSlice(anatXform, anat, 3, curPosition(3), bb, handles.interpType, mmPerVox, dispRange);
zAxes = [x(1), x(end); y(1), y(end)]+0.5;
[yRgb,x,y,z] = dtiGetSlice(anatXform, anat, 2, curPosition(2), bb, handles.interpType, mmPerVox, dispRange);
yAxes = [x(1), x(end); z(1), z(end)]+0.5;
[xRgb,x,y,z] = dtiGetSlice(anatXform, anat, 1, curPosition(1), bb, handles.interpType, mmPerVox, dispRange);
xAxes = [y(1), y(end); z(1), z(end)]+0.5;
%  mrvNewGraphWin; imagesc(flipud(zRgb)); axis image; colormap(gray)

if(ndims(anat) == 3)
    % Turn the images into RGB
    xRgb = repmat(xRgb,[1 1 3]);
    yRgb = repmat(yRgb,[1 1 3]);
    zRgb = repmat(zRgb,[1 1 3]);
elseif(ndims(anat)==4)
    % 3d views can only handle grayscale anatomy, so we'll just use a
    % luminance map from the RGB data.
    % We are not sure this works all that well. - FP
    anat = mean(anat,4);
end
%  mrvNewGraphWin; image(zRgb); axis image; colormap(gray)

% Force the background image to be between 0 and 1
xRgb(xRgb<0) = 0; xRgb(xRgb>1) = 1;
yRgb(yRgb<0) = 0; yRgb(yRgb>1) = 1;
zRgb(zRgb<0) = 0; zRgb(zRgb>1) = 1;

if(overlayAlpha>0)
    %[overlayImg, oMmPerVoxel, oXform] = dtiGetCurAnat(handles,1);
    n          = dtiGet(handles,'overlay number');
    overlayImg = dtiGet(handles,'overlay image',n);
    oXform     = dtiGet(handles,'overlay xform',n);
    dispRange  = dtiGet(handles,'overlay display range',n);

    % Get the color map and add a black where we place NaNs.
    cmap = handles.cmaps(get(handles.popupOverlayCmap,'Value')).rgb;
    cmap = [cmap; 0 0 0];   
    
    interpType = dtiGet(handles,'interp type');

    if(ndims(overlayImg)==3)
        % Get the transformed overlay slices and combine them with the
        % background slices.
        % The disp range we send in is used to return an image between 0
        % and 1.  We need to remember the display range, somehow. The
        % spatial interpolation type is set somewhere.  Not sure where. It
        % is a string, by default n, which I think means nearest neighbor.
        ox = dtiGetSlice(oXform, overlayImg, 1, curPosition(1), bb, interpType, mmPerVox, dispRange);
        oy = dtiGetSlice(oXform, overlayImg, 2, curPosition(2), bb, interpType, mmPerVox, dispRange);
        oz = dtiGetSlice(oXform, overlayImg, 3, curPosition(3), bb, interpType, mmPerVox, dispRange);
        
        % Find the locations above the threshold
        mx = ox > overlayThresh;
        my = oy > overlayThresh;
        mz = oz > overlayThresh;
        
        % Here we merge the overlay image (which is colorful) with the
        % background image created above, which is gray scale.
        % We do this by taking every value in the overlay image and
        % assigning it an index into the color map, cmap.
        %
        % The cmap rows are 1:256.  We require the overlay to be between 0
        % and 1. That way the entires of the overlay, e.g., oz, map into a
        % row of cmap.  So, oz*255 + 1 is a an integer between 1 and 256.
        
        % We set the NaNs to the 257th entry of the table, which is 0 0 0.
        oz(isnan(oz)) = (256 / 255);
        oy(isnan(oy)) = (256 / 255);
        ox(isnan(ox)) = (256 / 255);
        
        % This makes a list of cmap values that is a vector, and we reshape
        % it to an RGB image.
        oz = reshape(cmap(round(oz*255+1),:), [size(mz) 3]);
        oy = reshape(cmap(round(oy*255+1),:), [size(my) 3]);
        ox = reshape(cmap(round(ox*255+1),:), [size(mx) 3]);
        
        % Now, we mix the background gray image with the overlay image at
        % the locations specified by mx.
        mx = repmat(mx,[1,1,3]);
        my = repmat(my,[1,1,3]);
        mz = repmat(mz,[1,1,3]);
        xRgb(mx) = (1-overlayAlpha).*xRgb(mx) + overlayAlpha.*ox(mx);
        yRgb(my) = (1-overlayAlpha).*yRgb(my) + overlayAlpha.*oy(my);
        zRgb(mz) = (1-overlayAlpha).*zRgb(mz) + overlayAlpha.*oz(mz);
        
    elseif(ndims(overlayImg)==4)
        % If there is a 4th dim, then this overlay is an RGB map.
        % dtiGetSlice will return an XxYx3 RGB slice.
        % BROKEN! _ See Franco P
        ox = dtiGetSlice(oXform, overlayImg, 1, curPosition(1), bb, interpType, mmPerVox, dispRange);
        oy = dtiGetSlice(oXform, overlayImg, 2, curPosition(2), bb, interpType, mmPerVox, dispRange);
        oz = dtiGetSlice(oXform, overlayImg, 3, curPosition(3), bb, interpType, mmPerVox, dispRange);
        % We'll treat these differnt from the intensity image overlay case.
        % Rather than use a fixed transparency everywhere, we'll set the
        % transparency per-voxel by modulating it with the luminaince
        % component.
        if(overlayAlpha>1)
            % alpha>1 applies a gamma to the transparency map
            g = 1/overlayAlpha;
            overlayAlpha = 1;
        else
            g = 1;
        end
        lumz = repmat(mean(oz,3).^g,[1,1,3]);
        lumy = repmat(mean(oy,3).^g,[1,1,3]);
        lumx = repmat(mean(ox,3).^g,[1,1,3]);
        mz = lumz>overlayThresh;
        my = lumy>overlayThresh;
        mx = lumx>overlayThresh;
        xRgb(mx) = (1-lumx(mx).*overlayAlpha).*xRgb(mx) + lumx(mx).*overlayAlpha.*ox(mx);
        yRgb(my) = (1-lumy(my).*overlayAlpha).*yRgb(my) + lumy(my).*overlayAlpha.*oy(my);
        zRgb(mz) = (1-lumz(mz).*overlayAlpha).*zRgb(mz) + lumz(mz).*overlayAlpha.*oz(mz);        
    end
end

%% Set up the return transform from acpc

% The xform that we return is from acpc to the space that we put the slices
% in, which is ac-pc aligned on the specific sample grid (mmPerVox,
% typically 1mm isotropic) and filling the bounding box. The xform is
% returned and used in say, dtiRefreshFigure.
xform = [[diag(mmPerVox) bb(1,:)'-1];[0 0 0 1]];

return;
