function [vw, roi] = restrictRoiToGray(vw,roi)
%
% [vw, roi] = restrictRoiToGray(vw,roi):
%
% Restrict an roi to only gray matter voxels, independent
% of the current view type. Creates a new Roi named
% '[ROI name] (Gray)', and appends it to the view.
%
% ROI can be specified as an ROI name, index into the 
% view's ROI struct, 3 x N set of coordinates, or roi
% struct.
%
% For speed, converts non-gray Rois into a hidden gray view
% and back; because of issues related to subsampling, it 
% may be more accurate to xform over all gray coords to the 
% current view (maybe reduce partial voluming effects?), but 
% this would take a while.
% 
%
% ras, 04/05
% dar, 03/07 - bug fixes.  
if nargin < 2
    help(mfilename)
    return
end

% check that there's a segmentation/gray view installed
% for this session
mrGlobals;
if ~exist('sessDir','var') || isempty(sessDir) %#ok<*NODEF>
    sessDir = pwd;
else
    sessDir = HOMEDIR;
end

checkFile = fullfile(sessDir,'Gray','coords.mat');
if ~exist(checkFile,'file')
    myErrorDlg('You don''t seem to have a Gray/coords.mat file.')
end

% parse how roi was specified
% (this is from the TCUI toolbox, 
% maybe I'll move it to a more general place)
roi = tc_roiStruct(vw,roi);

viewType = viewGet(vw,'viewType');

% intersect w/ gray coords, appropriate to view
switch viewType
case 'Gray',
    % can do this easily, by intersecting w/ 
    % existing coords
    roi.coords = intersectCols(roi.coords,vw.coords);
    
case 'Volume',
    % this is also easy: the coords aren't
    % in the view, but they're in the right 
    % coordinate space -- just load the file
    load(checkFile,'coords')
    roi.coords = intersectCols(roi.coords,coords);
    
    % append to view
    rois = viewGet(vw,'ROIs');
    if isempty(rois)
        rois = roiCheck(roi);
    else
        rois = roiCheck(rois);
        rois(end+1) = roiCheck(roi);
    end
    
case 'Inplane',
    % need to initialize a hidden
	% gray and xform back and forth: 
	gray = initHiddenGray;
    grayRoi = ip2volROI(roi,vw,gray);

    % restrict by gray coords
	grayRoi.coords = intersectCols(grayRoi.coords,gray.coords);

    if isempty(grayRoi.coords)
        msg = sprintf('%s was found to have no gray coords.',roi.name);
        msg = sprintf('%s Check the ROI definition, and maybe the alignment or segmentation.',msg);
        myWarnDlg(msg);
        return
    end
    
    % xform back (update roi)
    roi = vol2ipROI(grayRoi,gray,vw);  
    
case 'Flat',
    % By definition, these are restricted to gray:
    warnDlg('You''re in a FLAT view -- all Rois are already restricted to gray!')
    return
    
end

% set ROI name
roi.name = [roi.name '_Gray'];

% append to view
rois = viewGet(vw,'ROIs');
if isempty(rois)
    rois = roi;
    roiNum = 1;
else
    if isfield(rois(1), 'save')
        rois = rmfield(rois, 'save');
    end
    rois = roiCheck(rois);
    rois(end+1) = roiCheck(roi);
    roiNum = length(rois);
end
vw = viewSet(vw,'ROIs',rois);
vw = viewSet(vw,'selectedROI',roiNum);

% update roi popup, if appropriate:


% and we're done!

return
