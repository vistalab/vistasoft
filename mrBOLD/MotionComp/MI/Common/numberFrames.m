function n = numberFrames(view,scan)
%
%    n = numberFrames(view,scan)
%
% Returns the number of frames of a selected scan
%
% gb 03/30/2005
if ieNotDefined('scan')
    scan = viewGet(view,'curScan');
end

global dataTYPES;n = dataTYPES(view.curDataType).scanParams(scan).nFrames;

return