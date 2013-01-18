function vw=loadtSNRMap(vw)
%
% vw=loadtSNRMap(vw)
%
% Checks vw.mapName field of the view structure.  
% If vw.mapName is not "tSNRMap", then load it,
% and call setParameterMap.
% 
% kgs, 06/12, modified loadMeanMap 

if ~strcmp(vw.mapName,'tSNRMap')
    pathStr=fullfile(dataDir(vw),'tSNRMap.mat');
    if ~exist(pathStr,'file')
        % go ahead and compute tSNR map for all scans
        % (disk space is cheap, processors fast, etc)
        vw = computetSNRMap(vw,0);
    else
        disp(['Loading tSNRMap from ',pathStr]);
        load(pathStr);
        vw = setParameterMap(vw,map,'tSNRMap'); 
        foo = cell2mat(map); m = max(foo(:));
        vw = setClipMode(vw, 'map', [0  m]);
               
    end
end

return
