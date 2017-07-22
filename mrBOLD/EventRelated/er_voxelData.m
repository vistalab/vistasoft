function [data, saveDir] = er_voxelData(view, roi, scans, recomputeFlag, preserveCoords)
% get (load or compute) data from all voxels in a mrVista ROI.
%
% [data, savePath] = er_voxelData(view, [roi, scans, recomputeFlag, preserveCoords]);
%
% Inputs:
% view: mrVista view struct
%
% roi: name or # of ROI,  or the struct itself (see loadROI).
%
% scans: scans from which to take data. Default:
% current scan group (see er_getScanGroup).
% recomputeFlag: force recomputation of data; don't load any
%   existing files (see below).
%
% recomputeFlag: flag to recompute data if it's cached.
%
% preserveCoords: if 1,  will not remove redundant coords
% in the ROI definition,  but will preserve a 1->1 mapping of
% each coordinate,  even if some of the tSeries are exactly the
% same. By default this is turned off. (Is used for comparing
% ROI data across sessions,  at diff't resolutions.)
%
%
% Outputs: 
% data: struct w/ following fields:
%   tSeries: original tSeries from struct,  stored as int16.
%            Format is scan time [frames] x voxels.
%
%   coords: 3 x nVoxels array of coordinates for each voxel, 
%           relevant to the current view.
%
%   voxData: 4-D double matrix consisting of trial data.
%           Format is:
% trial time [frames] x trials x voxels x conditions.
%
%   voxAmps: 3D matrix of voxel amplitudes (double).
%           Format is trials x voxels x conditions.
%
%   trials: info about design of scans (see er_concatParfiles).
%
%
% savePath:  directory in which the data are saved.
%           A 'VoxelData' directory is created under
%           the view's data dir (e.g. Inplane/Original), 
%           containing these files. A further directory
%           is created,  named after the ROI. Within
%           this saveDir,  tSeries for 
%
%           Data are only saved if the ROI name is
%           not 'ROI[#]' (e.g.,  an ROI you created 
%           to check out,  but may not use down the line).
%           Note that if you use this function,  then
%           update your ROI,  you should re-run this
%           with a recomputeFlag = 1 to generate an
%           updated set of voxel data; otherwise,  it will
%           load the data for the older set of voxels.
%   
% ras,  written 04/05/05.
if notDefined('view'),              view = getSelectedInplane;     end
if notDefined('recomputeFlag'),     recomputeFlag = 0;             end
if notDefined('preserveCoords'),    preserveCoords = 0;            end
if notDefined('scans'),             
    [scans dt] = er_getScanGroup(view); 
    view = selectDataType(view, dt);
end

if notDefined('roi')
	rois = viewGet(view, 'rois');
    selRoi = viewGet(view, 'curRoi');
    roi = rois(selRoi);
else
    roi = tc_roiStruct(view, roi);
end

% check if the ROI is defined in the current data 
if ismember(view.viewType, {'Volume' 'Gray'})
    [commonCoords I] = intersectCols(roi.coords, view.coords);
    if isempty(commonCoords)
        myWarnDlg('This ROI is not contained within the current data.')
        return
    else
        if preserveCoords==0
            roi.coords = roi.coords(:,I); % sub-select
        end
    end
end

% check if this is a 'named' or 'unnamed' ROI --
% 'unnamed' means e.g. 'ROI2'
if length(roi.name)>3 && strncmp(roi.name, 'ROI', 3) &&...
        isnumeric(str2double(roi.name(4:end)))
    named = 0;
else
    named = 1;
end

% get the data dir; check if we need to compute
% the data or can load existing files
if named==1, saveDir = fullfile(voxDataDir(view), roi.name);
else         saveDir = '';
end

if recomputeFlag~=1
    recomputeFlag = loadFilesCheck(saveDir, scans, recomputeFlag);
end

% an override: if preserving coordinates,  we'll need to
% re-load every time,  w/o caching the data:
if preserveCoords==1
    recomputeFlag = 1;
    saveDir = '';
end

% if a file exists and we're not forcing a recompute
% load it; otherwise,  compute the data and save if
% appropriate:
if recomputeFlag==0
    % load data
    data = er_loadVoxelData(view, roi, scans, saveDir, preserveCoords);
else
    % (re-)compute data
    data = er_computeVoxelData(view, roi, scans, saveDir, preserveCoords);
end

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function data = er_computeVoxelData(view, roi, scans, saveDir, preserveCoords)
% data = er_computeVoxelData(view, roi, scans, saveDir);
% Load tSeries data from the selected ROI,  compute
% relevant trial time course and amplitude matrices, 
% save the results in a file if a non-empty saveDir
% is provided,  and return the results in a data 
% struct.
% ras,  04/05.
verbose = prefsVerboseCheck;

if (~exist('preserveCoords') || isempty(preserveCoords)),  preserveCoords=0; end
data.tSeries = [];
if verbose, hwait = mrvWaitbar(0, 'Loading tSeries'); end
for s = scans
	%%%%%%%%%%%%%%%%%%%%
	% Load the tSeries %
	%%%%%%%%%%%%%%%%%%%%
	% (we keep them raw so we can detrend differently 
	% down the line)
	[tSeries coords] = voxelTSeries(view, roi.coords, s, 1, preserveCoords);
    if verbose, mrvWaitbar(find(scans==s)/length(scans), hwait); end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% find range,  rescale and convert to int16 to save space %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	dataRange = [min(tSeries(:)) max(tSeries(:))];
    if unique(mod(tSeries,  1))==0
        % all integers -- can make int16
    	tSeries = int16(tSeries);
    end        
	        
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Save file if appropriate %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if ~isempty(saveDir)
        if s==scans(1)
            if ~exist(saveDir, 'dir')
                [p f] = fileparts(saveDir);
                mkdir(p, f);
            end
            fprintf('Saving ROI voxel data in %s...', saveDir);
        end
        savePath = fullfile(saveDir, sprintf('Scan%i.mat', s));
        try
            save(savePath, 'tSeries', 'dataRange', 'coords');
        catch
            disp('Problem saving cache of voxel data. Won''t cache for now...')
            saveDir = '';
        end
        if s==scans(end)   
            fprintf('Done.\n');
        end
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Detrend before handing back tSeries %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 	params = er_getParams(view, s); 
    if params.inhomoCorrect==3      % divide by spatial gradient
        [gradient coords view] = checkSpatialGradMap(view, s, roi, preserveCoords);
        tSeries = er_preprocessTSeries(tSeries,  params,  dataRange,  ...
                                       gradient, coords);
    else
        tSeries = er_preprocessTSeries(tSeries,  params,  dataRange);
    end
    tSeries = outlierCheck(tSeries, data.tSeries);
    
    data.tSeries = [data.tSeries; tSeries];
       
end
if verbose, close(hwait); end

trials = er_concatParfiles(view, scans);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assign to output struct %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
data.params = params; % assuming all scans have same params as last one
data.coords = coords; 

data.voxData = er_voxDataMatrix(data.tSeries, trials, params);
% data.voxAmps = er_voxAmpsMatrix(data.voxData, params);
data.trials = trials; 

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function data = er_loadVoxelData(view, roi, scans, saveDir, preserveCoords);
% data = er_loadVoxelData(view, roi, scans, saveDir, preserveCoords);
% Load ROI data from selected roi scans,  and compute
% relevant fields. This should be much faster
% than computing the data de novo.
%
% ras,  04/05.
verbose = prefsVerboseCheck;

% get params,  trials,  coords
data.trials = er_concatParfiles(view, scans);
data.params = er_getParams(view, scans(1)); % assume all scans have same params
if preserveCoords==0
    data.coords = double(roiSubCoords(view, roi.coords)); %, scans(1))); % remove redundant voxels
else
    data.coords = double(roi.coords);
end

% get tSeries from each scan,  detrend
data.tSeries = [];
if verbose, hwait = mrvWaitbar(0, 'Loading tSeries...'); end
for s = scans
    pth = fullfile(saveDir, sprintf('Scan%i.mat', s));
    load(pth, 'tSeries', 'dataRange', 'coords');

	% do sanity check if coords have changed
    if ~isequal(coords, data.coords)
        % we'll just go ahead and recompute
        % (maybe I'll want to add a prompt)
        disp('It appears the ROI definition was updated since voxel data were last saved.')
        disp('Recomputing...')
        if verbose, close(hwait); end
        data = er_computeVoxelData(view, roi, scans, saveDir);
        return
    end
    
    % baseline remove,  detrend,  etc:
    if data.params.inhomoCorrect==3     % divide by spatialGrad
        [gradient coords view] = checkSpatialGradMap(view, s, roi, preserveCoords);
        tSeries = er_preprocessTSeries(tSeries, data.params, dataRange, ...
                                       gradient, coords);        
    else
        tSeries = er_preprocessTSeries(tSeries, data.params, dataRange);
    end
    
    % check if the 1st frame is an outlier:
    tSeries = outlierCheck(tSeries, data.tSeries);    
    
    % append to existing tSeries
    data.tSeries = [data.tSeries; tSeries];
    
    if verbose, mrvWaitbar(find(scans==s)/length(scans), hwait); end
end
if verbose, close(hwait); end

% add voxData matrix
data.voxData = er_voxDataMatrix(data.tSeries, data.trials, data.params);

% % add voxAmps matrix
% data.voxAmps = er_voxAmpsMatrix(data.voxData, data.params);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function flag = loadFilesCheck(saveDir, scans, flag);
% check if the voxel data files for all the selected scans
% exist,  and if they do,  return 0 (don't recompute); otherwise, 
% return 1 (do recompute).
if flag==1
    % if we're already set to recompute,  don't change that decision
    return
elseif isempty(saveDir)
    % 'named' ROI,  return
    flag = 1;
    return
end

flag = 0;

% check that files exist for each scan
for s = scans
    checkPath = fullfile(saveDir, sprintf('Scan%i.mat', s));
    if ~exist(checkPath, 'file')
        flag = 1;
        return
    end
end    

return
% /--------------------------------------------------------------------/ %





% /--------------------------------------------------------------------/ %
function tSeries = outlierCheck(tSeries, prevTSeries)
% outlier check: the first frame of a scan often
% is an outlier,  due to some artifact of preprocessing.
% if this is the case,  replace it w/ the mean of the
% 2nd frame and,  if available,  last frame of previous scan:
%
dev = abs(tSeries(1, :)-mean(tSeries));
outliers = find(dev > 2*nanstd(tSeries));
if ~isempty(prevTSeries)
    % avg between last frame and next frame
    lastframe = prevTSeries(end, outliers);
    nextframe = tSeries(2, outliers);
    tSeries(1, outliers) = mean([lastframe; nextframe]);
else
    % just replace w/ 2nd frame
    tSeries(1, outliers) = tSeries(2, outliers);
end
return