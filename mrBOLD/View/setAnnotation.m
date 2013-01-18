function view = setAnnotation(view, str);
% Set the annotation string describing the current scan / data type
% for a view, updating the UI if needed.
%
% view = setAnnotation(view, str);
%
%
% ras, 01/06.
mrGlobals;
scan = view.curScan;
dt = view.curDataType;
dataTYPES(dt).scanParams(scan).annotation = str;
saveSession(0);
return
