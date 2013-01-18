function dtiXformFibersToMrVistaVolume(handles, fgNum)
%
% dtiXformFibersToMrVistaVolume(handles, [fiberGroupNum])
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert the specified
% fiber group to mrVista vAnatomy coords and sends them to the selected volume.
%
% HISTORY:
% 2004.05.03 RFD (bob@white.stanford.edu) wrote it.

if(~exist('fgNum','var') | isempty(fgNum))
    fgNum = handles.curFiberGroup;
end
view = getSelectedVolume;
fg = dtiXformFibersToMrVista(handles,fgNum);
if(~isempty(fg.seeds))
    view = newROI(view, ['dti_' fg.name '_seeds'], 1, [0 0 0]);
    view.ROIs(view.selectedROI).coords = unique(round(fg.seeds)','rows')';
end

view = newROI(view, ['dti_' fg.name], 1, [0 0 0]);
view.ROIs(view.selectedROI).coords = unique(round(horzcat(fg.fibers{:})), 'rows')';
% Is there a better way to do this?
mrGlobals;
eval([view.name '=view;']);
return;
