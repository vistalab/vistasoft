function view = plotResidualErrorSelScan(view);
%
%  view = plotResidualErrorSelScan(view);
%
% Opens a GUI so that the user can select the scans to plot their
% residual error
%
% on, 12/23/99 - original code
%

scanList = selectScans(view);

for scan = scanList
  view = plotResidualError(view, scan);
end   
