function overlayMapFiles(view)
% overlayMapFiles(view);
% 
% Prompts for two files containing param maps, and puts up a plot with the
% two superimposed over tha view's anatomy image (with sliders for things
% like threshold, colormap).
%
%
% 06/04 ras: wrote it.
% 11/04 ras: broken off from overlayMapsSameSession.


%%%%% get the file paths --
%%%%% if a map is being viewed, set the default first map to
%%%%% the currently-viewed map
dispMode = viewGet(view,'displayMode');

if isequal(dispMode,'map')
    default = [view.mapName '.mat'];
else
    default = '';
end
scan  = getCurScan(view);

ttl = 'Pick the 1st Param Map...';
[fname pth] = myUiGetFile(dataDir(view),'*.mat',ttl,default);
map1Path = fullfile(pth,fname);

ttl = 'Pick the 2nd Param Map...';
[fname pth] = myUiGetFile(dataDir(view),'*.mat',ttl,default);
map2Path = fullfile(pth,fname);

hbox = msgbox('Getting maps to overlay...');

% check that files exist, load
if ~exist(map1Path,'file')
    error(sprintf('%s not found.',map1Path));
else
    load(map1Path,'map','mapName');
    map1Name = mapName;

    % figure out which scan to use
    vol1 = map{scan};
    if isempty(vol1)  
        % take 1st assigned scan
        s1 = 1;
        while isempty(map{s1})
            s1 = s1 + 1;
        end
        vol1 = map{s1};
    end
end

if ~exist(map2Path,'file')
    error(sprintf('%s not found.',map2Path));
else
    load(map2Path,'map','mapName');
    map2Name = mapName;
    if isequal(map1Name,map2Name)
        map1Name = [map1Name '1'];
        map2Name = [map2Name '2'];
    end

    % figure out which scan to use
    vol2 = map{scan};
    if isempty(vol2)
        % take 1st assigned scan
        s2 = 1;
        while isempty(map{s2})
            s2 = s2 + 1;
        end
        vol2 = map{s2};
    end
end

overlayMaps(view,vol1,vol2,1,map1Name,map2Name);

close(hbox);

return
