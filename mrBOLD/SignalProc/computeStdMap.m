function vw = computeStdMap(vw,scanList, forceSave)
%
% vw = computeStdMap(vw,[scanList], [forceSave])
%
% Cycles through tSeries, computing the std of the
% functional images.  Puts them together into a parameter map and
% calls setParameterMap to set vw.map = stdMap.
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
%    computeCorAnal, computeResStdMap, computeMeanMap
%
% djh, 12/30/98
% djh, 2/22/2001 updated to version 3

nScans = viewGet(vw,'numScans');

if notDefined('forceSave'), forceSave = 0; end

if strcmp(vw.mapName,'stdMap')
    % If exists, initialize to existing map
    map=vw.map;
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = selectScans(vw);
elseif scanList == 0
    scanList = 1:nScans;
end
if isempty(scanList)
  error('Analysis aborted');
end

waitHandle = mrvWaitbar(0,'Computing std images from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan = scanList(iScan);
    slices = sliceList(vw,iScan);
    dims    = viewGet(vw, 'sliceDims', iScan);
    nCycles = viewGet(vw, 'numcycles', iScan);
    datasz  = viewGet(vw, 'dataSize',  iScan);
    
    map{scan} = NaN*ones(datasz);
    for slice = slices
        tSeries = loadtSeries(vw,scan,slice);
        tmp = std(tSeries);
        map{scan}(:,:,slice) = reshape(tmp,dims);
    end
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set parameter map
vw = setParameterMap(vw,map,'stdMap');

% Save file
if forceSave >= 0, saveParameterMap(vw, [], forceSave); end


