function vw = computeCrossScanCorrelationMap(vw,scanList, confirm, doAverageflag)
%
% vw = computeCrossScanCorrelationMap(vw,[scanList], [confirm])
%
% Computes the correlation of the time series across scans for
% each voxel. The mean of all pairwise correlations for each
% voxel is put into a parameter map and calls setParameterMap to set
% vw.map = crossScanCorrMap. 
%
% Inputs:
%   vw: mrVista view struct
%   scanList:
%       0 - do all scans
%       number or list of numbers - do only those scans
%       'group' or any text: compute a separate corrMap for each set of
%                            scans with the same annotation
%       default - prompt user via selectScans dialog
%   confirm: boolean. if false, proceed without user ok. useful for scripting
%
% note: all scans must have same nFrames or you will get an error
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeResStdMap, computeMeanMap
%
% jw 11/11/2008
% hh 07/07/2010 - add another function to compute correlation between 
% one scan and averaged others

%-------------------------------------------------------------------------
% (Re-)set scanList
if ~exist('scanList','var') || isempty(scanList),
                              scanList = selectScans(vw);           end
if isempty(scanList),         error('Analysis aborted');            end
if ~iscell(scanList),         scanList = {scanList};                end
if ~exist('doAverageflag','var'), doAverageflag = true;             end
    
if length(scanList) == 1,
    % if a char, assume we want to get groups of scans from a dialog
    if strcmpi(scanList{1}, 'group') || ischar(scanList{1})
        % group the scans by annotation
        if notDefined('confirm'), confirm = true; end
        [annotations, scanList] = getScanGroups(vw, [], confirm);
        if isempty(annotations), disp('Analysis abborted.'); return; end
    end
    
    if isequal(scanList{1}, 0), scanList{1} = 1:viewGet(vw, 'nscan');  end    
end

%-------------------------------------------------------------------------

% initialize to empty cell array
nScanGroups = length(scanList);

if doAverageflag,
    map = cell(1,nScanGroups);
else % don't average all
    map = {};
    for ii = 1:nScanGroups,
        map{ii}.submap = cell(1,length(scanList{ii}));
    end
end

% to avoid annoying massages for deviding by zero
warning off all

for scanGroup = 1:nScanGroups
    
    thisscanlist = scanList{scanGroup};
    nScans       = length(thisscanlist);
    scan         = thisscanlist(1);
    dims         = viewGet(vw, 'sliceDims', scan);
    nVoxels      = dims(1)*dims(2);
    slices       = sliceList(vw,scan);
    nFrames      = numFrames(vw, scan);
    detrend      = detrendFlag(vw,scan);
    smoothFrames = detrendFrames(vw,scan);
    tmp          = zeros(1, nVoxels);

    if doAverageflag,
        map{scanGroup} = 0*ones(dataSize(vw,scan));
    else
        Submaps = 1:length(scanList{scanGroup});
        for ii = Submaps,
        map{scanGroup}.submap{ii} = 0*ones(dataSize(vw,scan));
        end
    end
    
    msg = sprintf('Computing group %d correlation images from tSeries.', scanGroup);
    waitHandle = mrvWaitbar(0,msg);

    % loop through slices
    for slice = slices

        tSeriesAllVoxels = NaN(nFrames, nVoxels, nScans);

        %loop through scans
        for scan = 1:nScans
            
            tSeries = loadtSeries(vw,thisscanlist(scan),slice);
            tSeriesAllVoxels(:,:,scan) = detrendTSeries(tSeries,detrend,smoothFrames);
        
        end

        %calculate mean of pair-wise corr's for each voxel
        
        if doAverageflag,
            for v = 1:nVoxels
                foo = corr(tSeriesAllVoxels(:,v,:));
                tmp(v) = mean(foo(foo ~=1));
                
                % eliminate negatives
                tmp(tmp < 0) = 0;
                
                % reshape
                map{scanGroup}(:,:,slice) = reshape(tmp,dims);
        
            end
        else
            
            for TargetScan = Submaps,
                TargetTS   = tSeriesAllVoxels(:,:,TargetScan);
                AveOtherTS = tSeriesAllVoxels;
                AveOtherTS(:,:,Submaps(TargetScan)) = [];
                AveOtherTS = mean(AveOtherTS, 3);
                tmp = cat(3,TargetTS,AveOtherTS);
                
                for v = 1:nVoxels
                    foo = corr(tmp(:,v,:));
                    submap(v) = mean(foo(foo ~=1));
                end
                
                % eliminate negatives
                submap(submap < 0) = 0;

                % reshape
                Maps{scanGroup}.submap{TargetScan}(:,:,slice) = reshape(submap,dims);
            end
        end
        
        mrvWaitbar(slice/length(slices))
    end


    close(waitHandle);
end
warning on all

%%
if doAverageflag,
else % sort 
    for scanGroup = 1:nScanGroups
       mapind = scanList{scanGroup};
       for ii = 1:length(mapind)
           map{mapind(ii)} = Maps{scanGroup}.submap{ii}; 
       end 
    end
end

% Set parameter map
vw = setParameterMap(vw,map,'crossScanCorrMap');

% Save file
if doAverageflag,
    pathStr = fullfile(dataDir(vw), 'crossScanCorrMapDoAve.mat') ; 
else
    pathStr = fullfile(dataDir(vw), 'crossScanCorrMap.mat');
end
saveParameterMap(vw, pathStr);


return



