function [handles, bgNum] = dtiAddBackgroundImage(handles, img, name, mmPerVoxel, xform, clipRange, histClipFlag, unitStr, dispValRange)
%
% [handles, bgNum] = dtiAddBackgroundImage(handles, img, name, mmPerVoxel, xform, [clipRange=[0,1]], [histClipFlag=0], [unitStr=''], [dispValRange=[min(img(:)) max(img(:)) 1])
%
% RETURNS:
%  handles, with a new background image. Also updates the ui structs.
%
% If clipRange is omitted, then the image is scaled to 0-1 and the original
% max/min values are recorded. If clipRange is a scalar, then the image is
% cliped so that the maximum value is the value specified in clipRange. If
% clipRange is 1x2, then it specifies the [min,max] clipping value. 
%
% If the histClip flag is set, then the image is clipped using the
% [min,max] values specified in clipRange (see mrAnatHistogramClip for
% details).
%
% HISTORY:
% 2003.12.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.11.28 RFD: cleaned up some crusty old code. We also no longer set
% the new background to be the current background.

% we allow for dummy entries in the bg image list (ie. empty images)
if(isempty(img))
    if(~exist('clipRange','var') || isempty(clipRange)) clipRange = [0 1]; end
else
    if(~exist('histClipFlag','var') || isempty(histClipFlag))
        histClipFlag = 0;
    end
    if(~exist('clipRange','var') || isempty(clipRange))
        clipRange = [min(img(:)) max(img(:))];
    end
    if(~histClipFlag)
        if(length(clipRange)==1) clipRange = [min(img(:)) clipRange]; end
        img = img - clipRange(1);
        img = img./diff(clipRange);
    else
        if(length(clipRange)==1) clipRange = [0 clipRange]; end
        [img, clipRange] = mrAnatHistogramClip(img, clipRange(1), clipRange(2));
    end
    img(img<0) = 0;
    img(img>1) = 1;
end
if(~exist('unitStr','var') || isempty(unitStr))
	unitStr = '';
end

if(~exist('dispValRange','var') || isempty(dispValRange) || numel(dispValRange)<2)
	dispValRange = [min(img(:)) max(img(:)) 1];
else
    nz = clipRange~=0;
    dispValRange(nz) = dispValRange(nz)./clipRange(nz);
    dispValRange(~nz) = 0;
end
if(numel(dispValRange)<3)
    dispValRange(3) = 1;
end

if(isfield(handles,'bg')) bgNum = length(handles.bg)+1;
else bgNum = 1; end

% Ensure that name is unique
str = get(handles.popupBackground, 'String');
uniqueName = name;
ii = 2;
while(~isempty(strmatch(lower(uniqueName), lower(str))))
    uniqueName = [name '(' num2str(ii) ')'];
    
    ii = ii+1;
end

%  Fill in the background image data structure
handles.bg(bgNum).name = uniqueName;
handles.bg(bgNum).mmPerVoxel = mmPerVoxel;
handles.bg(bgNum).img = img;
handles.bg(bgNum).mat = xform;
handles.bg(bgNum).minVal = clipRange(1);
handles.bg(bgNum).maxVal = clipRange(2);
handles.bg(bgNum).unitStr = unitStr;

% The following will allow images to be contrast/brightness 'windowed'
handles.bg(bgNum).displayValueRange = dispValRange;

set(handles.popupBackground, 'String', {handles.bg(:).name}');
set(handles.popupOverlay, 'String', {handles.bg(:).name}');
%set(handles.popupBackground, 'Value', bgNum);

return;