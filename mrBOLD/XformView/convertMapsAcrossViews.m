% script convertMapsAcrossViews;
%
% Takes any maps in the Inplane subdir of a 
% session directory, and converts it across to
% any other existing views (Volume, Gray, and 
% Flat).
%
% Uses a filter string (default '*.mat') to pick
% the map files in the dataDir of the inplane view.
% This will include the corAnal.mat.
%
% 05/04 ras.
mrGlobals;
loadSession;
HOMEDIR = pwd;

filter = '*.mat';
ndt = size(dataTYPES); % # data types

% find out what views are available
viewsFound = [1 0 0 0];
viewNames = {'Inplane','Volume','Gray','Flat'};
for v = 2:4
    if exist(viewNames{v},'dir')
        viewsFound(v) = 1;
    end
end

fprintf('Views found: \t')
for v = find(viewsFound)
    fprintf('%s ',viewNames{v});
end
fprintf('\n\n');

% init hidden inplane
hI = initHiddenInplane;
scans = 1:numScans(hI);

% % inplane->volume, if volume exists
% if viewsFound(2)==1
%     fprintf('***** Converting from Inplane to Volume Views... *****\n\n');
%     
%     hV = initHiddenVolume;
%     
%     for dt = 1:ndt % for each data type
%         hI.curDataType = dt;
%         hV.curDataType = dt;
%         
%         % find files matching filter
%         pattern = fullfile(dataDir(hI),filter);
%         w = dir(pattern);
%         nfiles = length(w);
%         
%         dt
%         pattern
%         
%         for file = 1:nfiles
%             pth = fullfile(dataDir(hI),w(file).name);
%             if isequal(w(file).name,'corAnal.mat');
% %                 hI = loadCorAnal(hI);
% %                 hV = ip2volCorAnal(hI,hV,scans);
%             else
%                 hI = loadParameterMap(hI,pth);
%                 hV = ip2volParMap(hI,hV,scans);
%             end
%         end
%     end
% end
% clear hV
% 
% % inplane->gray, if gray exists
% if viewsFound(3)==1
%     fprintf('***** Converting from Inplane to Gray Views... *****\n\n');
%     
%     hG = initHiddenGray;
%     
%     for dt = 1:ndt % for each data type
%         hI.curDataType = dt;
%         hG.curDataType = dt;
%         
%         % find files matching filter
%         pattern = fullfile(dataDir(hI),filter);
%         w = dir(pattern);
%         nfiles = length(w);
%         
%         for file = 1:nfiles
%             pth = fullfile(dataDir(hI),w(file).name);
%             if isequal(w(file).name,'corAnal.mat');
% %                 hI = loadCorAnal(hI);
% %                 hG = ip2volCorAnal(hI,hG,scans);
%             else
%                 hI = loadParameterMap(hI,pth);
%                 hG = ip2volParMap(hI,hG,scans);
%             end
%         end
%     end
% end


% gray->flat, if gray and flat exist
if viewsFound(3)==1 & viewsFound(4)==1
    fprintf('***** Converting from Gray to Flat Views... *****\n\n');
    
    hF = initHiddenFlat;
    hG = initHiddenGray;
    
    for dt = 1:ndt % for each data type
        hF.curDataType = dt;
        hG.curDataType = dt;
        
        % find files matching filter
        pattern = fullfile(dataDir(hG),filter);
        w = dir(pattern);
        nfiles = length(w);
        
        for file = 1:nfiles
            pth = fullfile(dataDir(hG),w(file).name);
            if isequal(w(file).name,'corAnal.mat');
%                 hG = loadCorAnal(hG);
%                 hF = vol2flatCorAnal(hG,hF,scans);
            else
                hG = loadParameterMap(hG,pth);
                hF = vol2flatParMap(hG,hF,scans);
            end
        end
    end
end
clear hG hF hI


return            