function rate = getFrameRate(view,scan)
%
% rate = getFrameRate(view,scan)
%
% djh, 2/21/2001
% ARW Renamed to getFrameRate 102402 to avoid conflict with BP psychToolbox
% function
% $Author: sayres $
% $Date: 2004/12/16 22:38:10 $


global dataTYPES;

rate = dataTYPES(view.curDataType).scanParams(scan).framePeriod;
