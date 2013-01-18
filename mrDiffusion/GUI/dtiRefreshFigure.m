function handles = dtiRefreshFigure(handles, update3D)
% General routine for refreshing the display windows.
%
%   handles = dtiRefreshFigure(handles, update3D)
%
% General routine for refreshing the display windows.  The 3 planar cuts
% in the main window are updated.  If show3d is set, then the 3D Matlab
% window is updated.  If mrMesh is set then the mrMesh window is updated
% also.
%
% The handles may be modified, so they are returned.  They are not
% attached to the window here, but rather in the calling routine.
%
% The handles are the return from handles = guidata(gcf); where the current
% figure is the mrDiffusion (dtiFiberUI) window.  The dtiGet routines
% only use a subset of the returned handles.  I am not exactly sure why
% there are so many handles returned by the guidata call.  There are even
% more handles returned by the guihandles call.
%
% HISTORY:
% ?????: Dougherty & Wandell wrote it.
% 2005.06.09 RFD: minor code optimizations to make refreshes closer to
% 'realtime'. 
%
% B&B (c) Stanford VISTA Team, 2004

%% Parameters

% Default is do not update the 3d.
% But if update3D = 1, then we update mrMesh and/or Matlab 3D window.
if ~exist('update3D','var') || isempty(update3D), update3D = 0; end

% Read the window settings to determine what we will show during the
% refresh. The handles contain data from the mrDiffusion GUI Window.
useMrMesh     = dtiGet(handles,'show MrMesh');
show2dFibers  = dtiGet(handles,'show 2d fibers');
showMatlab3d  = dtiGet(handles,'show 3d fibers matlab ');
curBgNum      = dtiGet(handles,'bg num'); 
overlayThresh = dtiGet(handles,'overlay threshold');
overlayAlpha  = dtiGet(handles,'overlay alpha');
curOvNum      = dtiGet(handles,'overlay number');
showCurPosMarker  = dtiGet(handles,'show CurPos Marker');

%% Decide which ROIs to show
showTheseRois = dtiROIShowList(handles);

% Refresh the ROI popup window.
% Do we need to call this from here?
dtiFiberUI('popupCurrentRoi_Refresh',handles);

%% Refresh the FG popup window.
dtiFiberUI('popupCurrentFiberGroup_Refresh',handles);

%% Now the image windows

% Retrieve information abaout the image slices in the three principal axes.
% This routine also merges overlay data onto the RGB images.
%
% This routine needs to be divided up because sometimes we want part of the
% information, not all. And this code is ugly.
[xRGB,yRGB,zRGB,xform,xAxes,yAxes,zAxes] = dtiGetCurSlices(handles);

%% Overlay ROIs ont three planar images
curPosition  = str2num(get(handles.editPosition, 'String')); %#ok<ST2NM>
invXform     = inv(xform);
curPosImg    = round(mrAnatXformCoords(invXform,curPosition));

for ii=showTheseRois
    if(~isempty(handles.rois(ii).coords) && handles.rois(ii).visible)
        % Put this ROI into the image using the assigned color.
        cmap = dtiRoiGetColor(handles.rois(ii),0.5);
        roiCoords = round(mrAnatXformCoords(invXform,handles.rois(ii).coords));
        xRGB = dtiOverlayROIs(xRGB,curPosImg,roiCoords,cmap,'x');
        yRGB = dtiOverlayROIs(yRGB,curPosImg,roiCoords,cmap,'y');
        zRGB = dtiOverlayROIs(zRGB,curPosImg,roiCoords,cmap,'z');
    end
end

handles = dtiShowInplaneImages(handles,xAxes,xRGB,yAxes,yRGB,zAxes,zRGB);

%% Show fiber groups in three planar images
if show2dFibers, dtiShowFGs(handles); end

%% Mark position point
if(showCurPosMarker), dtiShowCurPos(handles); end

%% Reset the mouse-click callbacks
% Redrawing the axes resets these properties, so we have to return them to
% the desired state by this code. Also, we have to turn the image object's
% hit-test off to allow mouse clicks to pass though to the axis object.
dtiResetMouseImage(handles);

%% Sets a string in the 'Image Value' field
% This should be shorter, or pushed out into a function.
curBg = dtiGet(handles,'bg num');
sz    = dtiGet(handles,'bg size');
T     = dtiGet(handles,'bg img2acpcx form',curBg);

% Convert the current position in acpc space to image space.  The T\c
% calculation is like applying inv(T) to the position.   The appended 1
% puts the data in homogeneous coordinates.
imCoord = round(T\[curPosition 1]');
imCoord = imCoord(1:3)';    % Pull out the (x,y,z) locs in image space
if(all(curPosImg>0) && all(imCoord<=sz(1:3)))
    % We are in the range.  So, we get the values at that coordinate from
    % the background image.  This could be a dtiGet call.
    curBgVal = squeeze(handles.bg(curBg).img(imCoord(1),imCoord(2),imCoord(3),:))';
    % Not sure what the heck this is.  Probably scaling the data into
    % range. Should be in dtiGet, too.
    curBgVal = handles.bg(curBg).minVal+curBgVal*(handles.bg(curBg).maxVal-handles.bg(curBg).minVal);
    % Create the string that will display the value in the image.
    if(length(curBgVal)>1),  curBgValueStr = sprintf('%0.2f ',curBgVal);
    else                     curBgValueStr = num2str(curBgVal,4);
    end
else
    curBgValueStr = 'NaN';
end
% More screwing around the with string, and then setting it into the
% window.
curBgValueStr = [curBgValueStr ' ' handles.bg(curBg).unitStr];
set(handles.textImgVal,'String',curBgValueStr);

%% Matlab 3d plots
% Rarely used these days.  We should replace these calls with the nicer
% ones produced by Franco and Jason.
if ((showMatlab3d || useMrMesh) && (update3D))
    anat          = dtiGet(handles,'current anatomy data');
    anatXform     = dtiGet(handles,'bg img2acpc xform');
    [zIm,zImX,zImY,zImZ] = dtiGetSlice(anatXform, anat, 3, curPosition(3), [], handles.interpType);
    [yIm,yImX,yImY,yImZ] = dtiGetSlice(anatXform, anat, 2, curPosition(2), [], handles.interpType);
    [xIm,xImX,xImY,xImZ] = dtiGetSlice(anatXform, anat, 1, curPosition(1), [], handles.interpType);
end

% Matlab 3D window
if (showMatlab3d && update3D)
    handles = dtiMatlab3dWindow(handles,zImX,zImY,zImZ,zIm,yIm,yImX,yImY,yImZ,xIm,xImX,xImY,xImZ);
end

%% MrMesh window (DTI)
if (useMrMesh)
    if(~isfield(handles,'mrMesh'))
        handles.mrMesh = [];
    end
    % Set the 3d cursor (the mrMesh 3d space is just ac-pc space)
    mrmSet(handles.mrMesh,'cursorRaw',curPosition);
    if(update3D)
        [xIm,yIm,zIm] = dtiMrMeshSelectImages(handles,xIm,yIm,zIm);
        origin = dtiGet(handles,'origin');
        handles = dtiMrMesh3AxisImage(handles,origin, xIm, yIm, zIm);
    end
end

%% Update other mrDiffusion windows that are yoked to this one
% Rarely used.  The multiple mrDiffusion thing never really happened, did
% it. (BW)
if(isfield(handles,'yokeTo') && ~isempty(handles.yokeTo))
    %handles.yokeTo = dtiGet(handles,'allMrdFigs');
    for ii=1:length(handles.yokeTo)
        h = guidata(handles.yokeTo(ii));
        if(~isempty(h) && h.figure1~=handles.figure1)
            % *** TODO: Sanity-check these values!
            set(h.popupBackground,'Value',curBgNum);
            set(h.slider_overlayThresh, 'Value',overlayThresh);
            set(h.editOverlayAlpha, 'String',num2str(overlayAlpha));
            set(h.popupOverlay,'Value',curOvNum);
            % Finally, we can just call dtiFiberUI to set the last thing.
            % This will also trigger a refersh of that window.
            dtiFiberUI('setPositionAcPc', h, curPosition);
        else
            % Figure was probably closed- remove it from our list
            handles.yokeTo(ii) = [];
        end
    end
end

return
