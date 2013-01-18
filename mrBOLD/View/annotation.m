function annotationStr = annotation(view,scan);
% function annotationStr = annotation(view,scan);
%
% Returns the annotation string for this scan, given the views current data type  
%
% djh, 3/2001
% ras, 5/2004 -- changes underscores to spaces (otherwise the TeX
% interpreter thinks it's a subscript)
if notDefined('view'), view = getCurView;   end
if notDefined('scan'), scan = view.curScan; end

global dataTYPES

dt = viewGet(view,'curdt');
if ~isempty(dataTYPES(dt).scanParams)
    annotationStr = dataTYPES(dt).scanParams(scan).annotation;
else
    annotationStr = '(Empty Data Type)';
end

annotationStr(annotationStr=='_') = '-'; % dodge the TeX interpreter :)

return

