function vw = computeResStdMap(vw, scanList, forceSave)
%
% vw = computeResStdMap(vw, [scanList], [forceSave])
%
% Cycles through tSeries, computing the residual std of the
% functional images.  Puts them together into a parameter map and
% calls setParameterMap to set vw.map = stdMap.
% Residual time series have the harmonics of freq removed
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
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeStdMap, computeMeanMap
%
% rmk, 05/05/99
% djh 2/2001, mrLoadRet-3.0

if notDefined('forceSave'),   forceSave = 0;   end

nScans = viewGet(vw,'numScans');

if strcmp(vw.mapName,'resStdMap')
    % If exists, initialize to existing map
    map=vw.map;
else
    % Otherwise, initialize empty cell array
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

% Compute it
waitHandle = mrvWaitbar(0,'Computing res std images from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan    = scanList(iScan);
    dims    = viewGet(vw, 'sliceDims', scanNum);
    nCycles = viewGet(vw, 'numcycles', scanNum);
    datasz  = viewGet(vw, 'dataSize',  scanNum);
    
    map{scan} = NaN*ones(datasz);
    for slice = sliceList(vw,scan)
        resStd = computeTSResStd(vw,scan,slice,nCycles);
        map{scan}(:,:,slice) = reshape(resStd,dims);
    end
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set parameter map
vw = setParameterMap(vw,map,'resStdMap');

% Save file
if forceSave >= 0, saveParameterMap(vw, [], forceSave); end


