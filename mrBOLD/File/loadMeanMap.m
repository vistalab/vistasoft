function vw=loadMeanMap(vw, normalized)
%
% vw=loadMeanMap(vw, [normalized = false])
%
% Checks vw.mapName field of the view structure.  
% If vw.mapName is not "meanMap", then load it,
% and call setParameterMap.
%
% If you change this function make parallel changes in:
%   loadCorAnal, loadResStdMap, loadStdMap, loadMeanMap
%
% djh, 7/16/99, modified from loadCorAnal
% ras, 1/21/05, computes mean map if it doesn't exists
% jw,  8,25/11, add optional boolean input, 'normalized': if true,
%               normalize range of mean map by dividing by 99.9th
%               percentile and then clipping at 1.%
%
%   Inputs:
%       vw: mrVista view structure
%       normalized: boolean. if true, normalize mean map in each scan to
%       range [0 1] by dividing by 99.9th percentile and then clipping at
%       1.
%   Outputs:
%       vw: mrVista view structure
%
% Example: (assumes vistadata repository)
%   dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
%   cd(dataDir);
%   vw = mrVista;
%   vw = viewSet(vw, 'current dataTYPE', 'Original');
%   vw=loadMeanMap(vw);

if notDefined('normalized'), normalized = false; end

if ~strcmp(vw.mapName,'meanMap')
    pathStr=fullfile(dataDir(vw),'meanMap.mat');
    if ~exist(pathStr,'file')
        % go ahead and compute mean map for all scans
        % (disk space is cheap, processors fast, etc)
        vw = computeMeanMap(vw,0);
    else
        disp(['Loading meanMap from ',pathStr]);
        load(pathStr);
        vw = setParameterMap(vw,map,'meanMap'); 
        foo = cell2mat(map); m = max(foo(:));
        vw = setClipMode(vw, 'map', [0  m]);
               
    end
end

% if requested, normalied mean map to range [0 1] by dividing by 99% ile of
% mean map for each scan, and then clipping values over 1.
if normalized
    disp('Normalizing (but not saving) mean map to range [0 1]');
    map = viewGet(vw, 'map');
    for scan = 1:numel(map) % loop through each scan
        
        if max(map{scan}(:)) <= 1, % do nothing: already normalized
            fprintf('Scan %d appears to be normalized already\n', scan);
        else
            
            % normalize by the 99.9th percentile (the max may be an outlier)
            m = prctile(map{scan}(:), 99.9); 
            fprintf('Normalizing scan %d by the 99th percentile %3.3f\n', scan, m);
            map{scan} = map{scan} / m;
            % clip values over 1
            inds = map{scan} > 1;
            map{scan}(inds) = 1;            
        end
    end
    vw = viewSet(vw, 'map', map);
    vw = viewSet(vw, 'map win', [0 1]);
    vw = viewSet(vw, 'map clip', [0 1]);
end

return
