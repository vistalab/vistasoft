function [anat, mmPerVoxel, xform, name, valRange, dispRange, unitStr] = dtiGetCurAnat(handles,getOverlayFlag)
% OBSOLETE
%  Returns various parameters related to anatomy
%
% [anat, mmPerVoxel, xform, name, valRange, dispRange, unitStr] = dtiGetCurAnat(handles,[getOverlayFlag=0])
%
% This routine will be replaced by separate calls to dtiGet
%
% valRange is the [min,max] of the original data.
%
% HISTORY:
% 2003.10.01 RFD (bob@white.stanford.edu) wrote it.
% 2004.07.03 xform comes back with a bad scale factor sometimes -- BW
%
% Bob (c) Stanford VISTASOFT 2003

if(~exist('getOverlayFlag','var') || isempty(getOverlayFlag) || ~getOverlayFlag)
    n = dtiGet(handles,'bg num');
    % n = get(handles.popupBackground,'Value');
else
    n = dtiGet(handles,'o num');
    % n = get(handles.popupOverlay,'Value');
end

% allNames = get(handles.popupBackground,'String');
% name = allNames{curAnatNum};
% anat = handles.bg(curAnatNum).img;
% mmPerVoxel = handles.bg(curAnatNum).mmPerVoxel;
% valRange = [handles.bg(curAnatNum).minVal,handles.bg(curAnatNum).maxVal];
% xform = handles.bg(curAnatNum).mat;
% dispRange = handles.bg(curAnatNum).displayValueRange;
% unitStr = handles.bg(curAnatNum).unitStr;

% Retrieve key anatomical parameters
anat       = dtiGet(handles,'bg image',n);
mmPerVoxel = dtiGet(handles,'bg mmpervox',n);
xform      = dtiGet(handles,'bg img2acpc xform',n);
valRange   = dtiGet(handles,'bg range',n);
name       = dtiGet(handles,'bg name',n);
dispRange  = dtiGet(handles,'display range',n);
unitStr    = dtiGet(handles,'unit string',n);

return;
