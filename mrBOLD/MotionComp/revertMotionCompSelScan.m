function view = revertMotionCompSelScan(view);
%
%  view = revertMotionCompSelScan(view);
%
% Opens a GUI so that the user can select the scans to
% revert the motion compensation to the original Tseries.
%
% on, 12/23/99 - original code
%

scanList = selectScans(view);

for scan = scanList
  view =  revertMotionComp(view, scan);
end   
