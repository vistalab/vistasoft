function mode = addReservedColors(mode)
%
% mode = addReservedColors(mode)
%
% Adds reserved colors to a displayMode and its underlying colormap.
%
% djh 1/98

mode.white=256; 
mode.cmap(256,:) = [1,1,1]; 		% white

mode.black=255; 
mode.cmap(255,:) = [0,0,0]; 		% black

mode.red=254; 
mode.cmap(254,:) = [1,0,0]; 		% red

mode.green=253; 
mode.cmap(253,:) = [0,1,0]; 		% green

mode.blue=252; 
mode.cmap(252,:) = [0,0,1]; 		% blue

mode.cyan=251; 
mode.cmap(251,:) = [0,1,1]; 		% cyan

mode.magenta=250; 
mode.cmap(250,:) = [1,0,1]; 		% magenta

mode.yellow=249; 
mode.cmap(249,:) = [1,1,0]; 		% yellow
