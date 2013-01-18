function v = roiToggleFilledPerimeter(v);
%
%  v = roiToggleFilledPerimeter(v);
%
%Author: Wandell
%Purpose:
%   Toggle the fill perimeter drawing state.  When on, the perimeters are
%   always continuous.  When off, some perimeters appear as a set of open
%   loops. 
%
% v = FLAT{1};

t = viewGet(v,'filledperimeterstate');
if isempty(t), t = 0; end
v = viewSet(v,'filledperimeterstate',1 - t);

return;
