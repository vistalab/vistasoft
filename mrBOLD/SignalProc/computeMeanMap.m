function vw = computeMeanMap(vw,scanList,forceSave)
% Computing the mean functional image for each tSeries
%
%  vw = computeMeanMap(vw,[scanList],[forceSave])
%
% The mean functional images are combined into a parameter map and
% calls setParameterMap to set vw.map = meanMap.
%
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% forceSave: 1 = true (overwrite without dialog)
%            0 = false (query before overwriting)
%           -1 = do not save
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeResStdMap, computeStdMap
%
% djh, 12/30/98
% djh, 2/22/2001 updated to version 3
% ras, 01/05, added forceSave flag
% ras 10/05, checks if the meanMap file is saved already

if notDefined('forceSave'), forceSave = 0; end

% nScans = numScans(vw);
nScans = viewGet(vw,'numscans');

if strcmp(vw.mapName,'meanMap')
    % If exists, initialize to existing map
    map=vw.map;
elseif exist(fullfile(dataDir(vw),'meanMap.mat'),'file')
    % load from the mean map file
    load(fullfile(dataDir(vw),'meanMap.mat'),'map')    
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = er_selectScans(vw);
elseif scanList == 0
    scanList = 1:nScans;
end
if isempty(scanList),  error('Analysis aborted: scan list is empty.'); end

% Compute it
waitHandle = mrvWaitbar(0,'Computing mean images from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan = scanList(iScan);
    dims = viewGet(vw, 'sliceDims', scan);
    map{scan} = NaN*ones(dataSize(vw,scan));
    switch lower(viewGet(vw, 'viewType'))
        case 'inplane'
            % since data in the inplane view is stored as a nifti, we can
            % get the whole data slab in one call to load tseries rather
            % than looping over slices.
            [~, nii] = loadtSeries(vw,scan);
            tSeries = niftiGet(nii, 'data');
            timeDim = length(size(tSeries));
            map{scan} = mean(tSeries, timeDim);
            
        otherwise
            for slice = sliceList(vw,scan)
                tSeries = loadtSeries(vw,scan,slice);
                nValid = sum(isfinite(tSeries));
                tSeries(isnan(tSeries(:))) = 0;
                
                % if there is one time point, we will have problems, so duplicate
                % the data
                if size(tSeries,1) == 1,
                    tSeries = repmat(tSeries, 3, 1);
                    nValid = sum(isfinite(tSeries));
                end
                
                tmp = sum(tSeries) ./ nValid;
                if strcmp(vw.viewType,'Inplane')
                    map{scan}(:,:,slice) = reshape(tmp,dims);
                else
                    map{scan}(:,:,slice) = tmp;
                end
            end
    end
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set Parameter MAp
vw = setParameterMap(vw, map, 'meanMap');

% Save file
if forceSave >= 0, saveParameterMap(vw, [], forceSave); end

return
