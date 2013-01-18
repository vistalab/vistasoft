function vw = restrictROI(vw,refScan,cothresh,phWindow,mapWindow,ROInum)
%
% vw = restrictROI(vw,refScan,cothresh,phWindow,[mapWindow],[ROInum])
%
% Restricts ROI according to cothresh. phWindow, and mapWindow.
% refScan: scan number
% ROInum: defaults to selectedROI
%
% djh, modified 7/13/99, added mapWindow and optional ROInum.
% dbr, 9/28/99  Added default empty definition for mapWindow var.
% ras, 11/04 made less picky in case no corAnal is run.
% ras, 03/08 does separate checks for phase data and co data. 
% Streamlined: does a series of sequential checks, instead of 
% intersecting a bunch of separate coords.
if ~exist('ROInum','var')
   % error if no current ROI
   if vw.selectedROI == 0
      myErrorDlg('No current ROI');
   else      
      ROInum = viewGet(vw, 'selected ROI');  
    end
end

if ~exist('mapWindow', 'var'), mapWindow = []; end

% Get current ROI coords
coords = vw.ROIs(ROInum).coords;

% Save prevSelpts for undo
vw.prevCoords = coords;

% Find indices of voxels that satisfy cothresh, phWindow, and mapWindow.
if ~isempty(vw.co) && ~isempty(vw.co{refScan})
	coords = aboveCoThresh(vw, refScan, coords, cothresh);
end

if ~isempty(vw.ph)
	coords = inPhWindow(vw, refScan, coords, phWindow);
end

if ~isempty(vw.map)   
    coords = inMapWindow(vw, refScan, coords, mapWindow);
end

% Modify ROI.coords
vw.ROIs(ROInum).coords = coords;

vw.ROIs(ROInum).modified = datestr(now);

return
