function [view,savePath] = computeContrastMapOld(view,scans,activeConds,controlConds,savePath,varargin);
% [view,savePath] = computeContrastMapOld(view,scans,activeConds,controlConds,[savePath],[options]);
%
% Contrast map launcher, for old (FS-FAST inspired) code.
%
% Computes a contrast map comparing the selected activeConds to the
% selected controlConds, using the selected view and scans. Location to 
% save the resulting contrast map can be entered as an argument, or else
% a UI pops up to get the location.
%
% Creates two contrast maps: one a statistical map which shows (by default)
% the -log10(p) of a ttest between active and control conds. The other is a
% contrast effect size map showing the level of difference in % signal.
%
%
% written 03/08/04 by ras. Initially written to deal with block-design
% contrasts only, but will soon expand to rapid-event-related (deconvolved)
% time course contrasts as well.
% 03/12/04 ras: the '[mapName]_ces' map now has an associated 'co' field,
% which is the absolute value of the statistical map, normalized b/w 0 and
% 1. This, combined with a parallel update to loadParameterMap, should
% allow you to leave the MapWindow at full range, but threshold using the
% cothresh slider, and see both significant positive and negative-effect
% regions.
% 10/04/04 ras: updated to deal with eccentricities of the 
% flat across-levels view (tSeries stored as coords, maps as 3D imgs)
%
% 04/20/05 gb : updated to accept coefficients instead of a list of
%               conditions for activeConds and controlConds
%
% 11/14/06 ras: renamed computeContrastMapOld.
if notDefined('view'),  view = getCurView;             end
if notDefined('scans'), scans = er_getScanGroup(view); end

global dataTYPES HOMEDIR;

% PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
saveover = 0;
scans = er_getScanGroup(view);
scan = scans(1); % we'll save all files in the Inplane/[datatype]/TSeries/Scan[#] directory of the 1st selected scan
TR = dataTYPES(view.curDataType).scanParams(scans(1)).framePeriod;
nSlices = numSlices(view);
scanDir = ['Scan' num2str(scan)];
seriesDir = dataTYPES(view.curDataType).name;
cesFlag = 1;  % flag to save contrast effect size map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse the option flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(varargin)
    switch lower(varargin{i})
        case {'-force','-saveover','-override'};
                % set to redo selxavg even if hAvg files already exist
                saveover = 1;
                
            otherwise,
                if (i < length(varargin)) & (ischar(varargin{i}))
                    if (isnumeric(varargin{i+1}))
                        cmd = sprintf('%s = %i;',varargin{i},varargin{i+1})
                    elseif ischar(varargin{i+1})
                        cmd = sprintf('%s = ''%s'';',varargin{i},varargin{i+1})
                    elseif iscell(varargin{i+1});
                        tmp = unNestCell(varargin{i+1});
                        cmd = sprintf('%s = {',varargin{i});			
                        for j = 1:length(tmp)-1
                            cmd = [cmd '''' tmp{j} ''','];
                        end		
                        cmd = [cmd '''' tmp{end} '''};']
                    end
                    eval(cmd);
                end
        
    end
end

if ~exist('savePath','var') | isempty(savePath)
    [fname,pth] = myUIPutFile(fullfile(view.subdir,seriesDir),'*.mat','Select a save file name / path: ');
    savePath = fullfile(pth,['contrastMap_' fname]);
end

% check that the selected scans have parfiles assigned
checkParfiles(view, scans);

% check if selxavg has already been run for this session (unless saveover
% option is set, then automatically redo)
if ~saveover
    % we'll check by looking at the first slice of each type of file --
    % hopefully the others will be there too
    meanFile1 = fullfile(tSeriesDir(view), scanDir, 'mean_001.mat');
    hAvgFile1 = fullfile(tSeriesDir(view), scanDir, 'hAvg1.mat');
    hDatFile =  fullfile(tSeriesDir(view), scanDir, 'h.dat');
    % selxavg also creates an X.mat file, but this shouldn't be needed here
    if ~exist(meanFile1,'file') | ~exist(hAvgFile1,'file') | ~exist(hDatFile,'file')
        saveover = 1;
    end
end

if saveover==1
    % run selxavg for these scans
    fprintf('***************RUNNING SELXAVG FOR SELECTED SCANS PRIOR TO STXGRINDER **************\n');
    er_runSelxavgBlock(view, -1, 1); % changed to use scan group flag
end

% build contrast struct
hdr = fmri_lddat3(fullfile(dataDir(view),'TSeries',scanDir,'h.dat'));
nConds = hdr.Nnnc; 
if hdr.Nnnc==hdr.Nc % if the # of non-null conds equals the total # conds
    contrast.condNums = 1:hdr.Nc;
else
    contrast.condNums = [hdr.NullCondId 1:hdr.Nnnc];
end
WCond = zeros(1,hdr.Nnnc);
 
% 04/20/05 gb
%     Check whether activeConds and controlConds are a list of conditions
%     or coefficients for each one.
if (length(activeConds) >= hdr.Nnnc) & (length(activeConds) == length(controlConds))
    WCond = activeConds(2:end) + controlConds(2:end);
else
    WCond(activeConds(activeConds>0)) = 1/sum(activeConds>0);
    WCond(controlConds(controlConds>0)) = -1/sum(controlConds>0);
end

contrast.WCond = WCond;
contrast.ContrastMtx_0 = WCond; % for blocked designs, expand later for rapid E-R
contrast.WDelay = 1; % this is empirical from FS-FAST, and probably unnecessary

% init maps
dSize = sliceDims(view,1);
map = cell(1,numScans(view));
cesmap = cell(1,numScans(view));

% for flat views, the size of each 'slice' is not constant -- 
% different hemispheres/gray levels have diff't #s of nodes
% So, initialize the map to be as large as the largest slice
if isequal(view.viewType,'Flat')
    for slice = 1:numSlices(view)
        sliceVoxels(slice) = size(view.coords{slice},2);
    end
    maxVoxels = max(sliceVoxels);
    map{scan} = zeros(1,maxVoxels,numSlices(view));
    cesmap{scan} = zeros(1,maxVoxels,numSlices(view));
end
    
    
% loop through slices
h = mrvWaitbar(0,'Computing contrast map...');
for slice = 1:nSlices
    if isequal(view.viewType,'Flat')    dSize = [1 size(view.coords{slice},2)];     end
    inputPath = fullfile(HOMEDIR,view.subdir,seriesDir,'TSeries',scanDir,['hAvg' num2str(slice) '.mat']);
    if dSize(2) > 20 % avoid 'blank' slices in flat levels 
        if cesFlag==0
            statslice = er_stxgslice(inputPath,contrast,'dataSize',dSize);
        else
            [statslice,cesslice] = er_stxgslice(inputPath,contrast,'dataSize',dSize);
            cesmap{scan}(1:dSize(1),1:dSize(2),slice) = cesslice;
        end
        map{scan}(1:dSize(1),1:dSize(2),slice) = statslice;
    end
    mrvWaitbar(slice/nSlices,h);
end
close(h);

[ignore mapName] = fileparts(savePath);

% ras, 10/04: for flat across-level contrast maps,
% remap the image from 1D indices to 3D coords:
if isequal(view.viewType,'Flat')
    map{scan} = flatLevelIndices2Coords(view,map{scan});
    cesmap{scan} = flatLevelIndices2Coords(view,cesmap{scan});
end

% Associating the normalized stat map as a 'co' field now -- see notes, and notes in
% loadParameterMap
co = map;
co{scan} = abs(co{scan}./max(max(max(co{scan})))); % normalize, ignore sign

% save the map
save(savePath,'map','mapName','co');
fprintf('Saved statistic (-log10(p) from T test) in file %s.\n',savePath);

% also save a param map containing ces data
if cesFlag==1
    map = cesmap;
    mapName = [mapName '_ces'];
    save([savePath '_ces'],'map','mapName','co');
    fprintf('Saved contrast effect size (units?) in file %s.\n',[savePath '_ces']);
end

% load the stat map as the view's current param map
% figure(view.ui.windowHandle);
view = loadParameterMap(view,[savePath '.mat']);
view = refreshScreen(view);


return
