function name = dtiGetCurAnatName(handles)
% OBSOLETE
%
% name = dtiGetCurAnatName(handles)
%
% HISTORY:
% 2004.02.09 RFD (bob@white.stanford.edu) wrote it.
%

warning('Use dtiGet(handles,''currentAnatomyName'')');

opts = get(handles.popupBackground,'String');
name = opts{get(handles.popupBackground,'Value')};

return
