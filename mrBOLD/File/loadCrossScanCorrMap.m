function vw=loadCrossScanCorrMap(vw)
%
% vw=loadCrossScanCorrMap(vw)
%
% Checks view.mapName field of the view structure.  
% If view.mapName is not "crossScanCorrMap", then load it,
% and call setParameterMap.
%
% If you change this function make parallel changes in:
%   loadCorAnal, loadResStdMap, loadStdMap, loadMeanMap,
%   loadCrossScanCorrMap
%
% djh, 7/16/99, modified from loadCorAnal
% ras, 1/21/05, computes mean map if it doesn't exists
% jw, 3/29/09, modified from loadMeanMap 

if ~strcmp(vw.mapName,'crossScanCorrMap')
    pathStr=fullfile(dataDir(vw),'crossScanCorrMap.mat');
    if ~exist(pathStr,'file')
        % go ahead and compute cross scan corr map for all scans
        vw = computeCrossScanCorrelationMap(vw);
    else
        disp(['Loading crossScanCorrMap from ',pathStr]);
        load(pathStr);
        vw = setParameterMap(vw,map,'crossScanCorrMap');
        vw = setClipMode(vw, 'map', [0 1]);         
    end
end

return
