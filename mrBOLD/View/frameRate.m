function rate = frameRate(view,scan)
%
% rate = frameRate(view,scan)
%
% djh, 2/21/2001

global dataTYPES;

rate = dataTYPES(view.curDataType).scanParams(scan).framePeriod;
