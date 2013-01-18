function view = makeDataTypePopup(view)
% 
% view = makeDataTypePopup(view)
%
% Calls makePopup with the appropriate callbackStr

% Make callback string: 
%   selectDataType(view,get(view.ui.dataType.popupHandle,'Value');
%   refreshScreen(view)
callbackStr = ...
    [view.name,'=selectDataType(',view.name,',get(',view.name,'.ui.','dataType.popupHandle,''Value'')); ',...
	view.name,'=refreshScreen(',view.name,');'];

view = makePopup(view,'dataType','none',[.85,.95,.15,.05],callbackStr);
