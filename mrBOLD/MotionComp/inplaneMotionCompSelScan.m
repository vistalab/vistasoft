function view = inplaneMotionCompSelScan(view);
%
%  view = inplaneMotionCompSelScan(view);
%
% Opens a GUI so that the user can select the scans to compensate
% the motion inplane by inplane
%
% on, 12/23/99 - original code
%

scanList = selectScans(view);

for scan = scanList
  view = inplaneMotionComp(view, scan);
end   
