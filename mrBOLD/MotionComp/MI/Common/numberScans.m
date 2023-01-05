function n = numberScans(view)
%
%    n = numberScans(view)
%
% Returns the number of scans
%
% gb 03/30/2005
global dataTYPES;n = length(dataTYPES(view.curDataType).scanParams);

return