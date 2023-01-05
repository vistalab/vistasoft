function dtiResetMouseImage(handles)
% Reset callbacks on the image planes in the main window
%
%    dtiResetMouseImage(handles)
%
% When the image is redrawn, matlab resets the callbacks.  So, we reset
% them again
%
% See also:  dtiRefreshFigure
%
% Brian (c) Stanford VISTASOFT Team, 2012

set(handles.x_cut_img,'HitTest','off');
set(handles.x_cut,'ButtonDownFcn','dtiFiberUI(''x_cut_click_Callback'',gcbo,[],guidata(gcbo))');

set(handles.y_cut_img,'HitTest','off');
set(handles.y_cut,'ButtonDownFcn','dtiFiberUI(''y_cut_click_Callback'',gcbo,[],guidata(gcbo))');

set(handles.z_cut_img,'HitTest','off');
set(handles.z_cut,'ButtonDownFcn','dtiFiberUI(''z_cut_click_Callback'',gcbo,[],guidata(gcbo))');

end
