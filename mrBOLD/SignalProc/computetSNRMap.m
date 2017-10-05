function view = computetSNRMap(view,scanList,forceSave)
% Computing the mean functional image for each tSeries
%
%  view = computetSNRMap(view,[scanList],[forceSave])
%
% The mean functional images are combined into a parameter map and
% calls setParameterMap to set view.map = meanMap.
%
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeResStdMap, computeStdMap
%
% kgs 6/12 modified from computemeanMap

if notDefined('forceSave'), forceSave = 0; end

% nScans = numScans(view);
nScans = viewGet(view,'numscans');

if strcmp(view.mapName,'tSNRMap')
    % If exists, initialize to existing map
    map=view.map;
elseif exist(fullfile(dataDir(view),'tSNRMap.mat'),'file')
    % load from the mean map file
    load(fullfile(dataDir(view),'tSNRMap.mat'),'map')    
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = er_selectScans(view);
elseif scanList == 0
    scanList = 1:nScans;
end
if isempty(scanList),  error('No scans in list, Analysis aborted'); end

% Compute it
waitHandle = mrvWaitbar(0,'Computing tSNR map from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan = scanList(iScan);
    dims = sliceDims(view,scan);
    map{scan} = NaN*ones(dataSize(view,scan));
    for slice = sliceList(view,scan)
        tSeries = loadtSeries(view,scan,slice);
        nValid = sum(isfinite(tSeries));
        tSeries(isnan(tSeries(:))) = 0;

        % if there is one time point, we will have problems, so duplicate
        % the data
        if size(tSeries,1) == 1,
            tSeries = repmat(tSeries, 3, 1);
            nValid = sum(isfinite(tSeries));
        end

        tmp = sum(tSeries) ./ nValid;
        stdtSeries=nanstd(tSeries);
        tSNR=tmp./stdtSeries;
        map{scan}(:,:,slice) = reshape(tSNR,dims);
    end
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set Parameter MAp
view = setParameterMap(view, map, 'tSNRMap');

% Save file
saveParameterMap(view, [], forceSave);

return
