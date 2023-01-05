function rois = rxAlignAnatomies_convertROIs(rx, rois, savePath);
% Given an alignment from mrRx, convert ROIs saved on an existing anatomy
% into a new anatomy's coordinate space.
%
%   rois = rxAlignAnatomies_convertROIs([rx], [rois], [savePath]);
%
%
% INPUTS: 
%	rx: mrRx alignment structure. This should contain a transform which 
%	accurately maps from the old to the new anatomy. [default: get from
%	mrRx control figure]
%
%	rois: cell array list of ROI files, or a mrVista ROIs struct
%	variable. [default: prompt user to select files.]
%
%	savePath: path in which to save ROIs. If you are converting just one
%	ROI, this should be a full path to the ROI file to be saved. If you are
%	saving multiple ROIs, savePath can either be a cell array, with a full
%	path for each ROI, or else a directory in which to save all the ROIs.
%	Each ROI will be saved with the same file name as the old ROI, but in
%	the new directory.
%	[If omitted, will prompt the user to select a file path for each ROI.]
%
%
% OUTPUTS:
%
%	rois: struct array of ROIs, with the coordinates aligned and resampled
%	to match the new anatomy.
%
%
% ras, 11/19/2009.
if notDefined('rois')
	if exist( fullfile(pwd, '3DAnatomy', 'ROIs') )
		startDir = fullfile(pwd, '3DAnatomy', 'ROIs');
	else
		startDir = pwd;
	end
	[rois ok] = mrvSelectFile('r', 'mat', 'Select mrVista ROI File(s)', startDir);
	if ~ok
		disp('Aborted.')
		return
	end
end

if notDefined('rx')
    cfig = findobj('Tag', 'rxControlFig');
    rx = get(cfig, 'UserData');
end

if ishandle(rx),		
	rx = get(rx, 'UserData');		
end


% parse the ROI specification: ensure we have a struct array of ROIs
oldAnat = mrCreateEmpty;
oldAnat.data = rx.ref;
oldAnat.voxelSize = rx.rxVoxelSize;
oldAnat.dims = rx.rxDims;
rois = roiParse(rois, oldAnat);

% loop across ROIs, xforming the coordinates to the new anatomy
for r = 1:length(rois)
	rois(r).coords = xformROIcoords(rois(r).coords, rx.xform, ...
								    rx.volVoxelSize, rx.rxVoxelSize);
end

% give the user the chance to save the ROI
verbose = prefsVerboseCheck;
if notDefined('savePath')
	for r = 1:length(rois)
		msg = sprintf('Save Resampled ROI %s as...?', rois(r).name);
		[pth ok] = mrvSelectFile('w', 'mat', msg, pwd);
		if ~ok, disp('Aborted.'); return;  end
		
		saveXformedRoi(rois(r), pth, verbose);
	end
	
elseif length(rois)==1
	% single ROI to save
	if iscell(savePath), savePath = savePath{1}; end
	saveXformedRoi(rois, savePath, verbose);
	
else
	if iscell(savePath)
		% one path for each ROI
		for r = 1:length(rois)
			saveXformedRoi(rois(r), savePath{r}, verbose);
		end
		
	elseif ischar(savePath)
		% save all ROIs in the provided directory
		% first check that the dir exists
		if ~exist(savePath, 'dir')
			error(['You provided a string save path to save many ' ...
				   'ROIs. This string should point to a save directory ' ...
				   'which already exists.']);
		end
		
		for r = 1:length(rois)
			pth = fullfile(savePath, rois(r).name);
			saveXformedRoi(rois(r), pth, verbose);
		end
	
	else
		error('Invalid format for ROI save path.')
		
	end
end
		
		
	
return
% /-------------------------------------------------------------- %


% /-------------------------------------------------------------- %
function saveXformedRoi(ROI, pth, verbose);
% quick sub-function to save a given ROI in the provided path.
save(pth, 'ROI');
if verbose >= 1
	fprintf('Saved %s.\n', pth);
end
return

