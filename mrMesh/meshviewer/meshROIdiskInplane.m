function [selectedINPLANE,selectedVOLUME,nROI] = meshROIdiskInplane(handles);
%
%    [selectedINPLANE,selectedVOLUME,nROI] = meshROIdiskInplane(handles);
%
%  Beginning with the position of the cursor in a mrMesh window, create a
%  disk ROI in the inplane window.  The disk size and related parameters
%  are taken from the window.
%
%  We use this function is used when we analyze time series data in the
%  INPLANE window.
%
% Example:
%   [sINP,selectedVOLUME] = meshROIdiskInplane(handles);
%   [sINP,selectedVOLUME,nROI] = meshROIdiskInplane(handles);

global VOLUME
global selectedVOLUME
selectedVOLUME = viewSelected('volume'); 

global INPLANE
global selectedINPLANE
selectedINPLANE = viewSelected('inplane'); ; 

pos = meshCursor2Volume(VOLUME{selectedVOLUME});

roiName = sprintf('mrm-%.0f-%.0f-%.0f',pos(1),pos(2),pos(3));
roiRadius = str2double(get(handles.editROISize,'String'));
[VOLUME{selectedVOLUME},volROI] = makeROIdiskGray(VOLUME{selectedVOLUME},roiRadius,roiName,[],[],pos,0);
ipROI = vol2ipROI(volROI,VOLUME{selectedVOLUME},INPLANE{selectedINPLANE});

[INPLANE{selectedINPLANE},nROI] = addROI(INPLANE{selectedINPLANE},ipROI);

% Should we refresh the INPLANE window?  Why not.  We just added an ROI.
if ~strcmp(viewGet(INPLANE{selectedINPLANE},'name'),'hidden')
    INPLANE{selectedINPLANE} = refreshScreen(INPLANE{selectedINPLANE},1);
end

return;