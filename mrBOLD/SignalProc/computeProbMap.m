function view = computeProbMap(view,scanList)
%
% view = computeProbMap(view,[scanList])
%
% Cycles through tSeries, computing the -log10 P values
% for each voxel. This is a first pass at a P map - not taking into account
% the non-gaussian properties of the spatio-temporal noise distribution.
%
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% Based on computeMeanMap
% and  Bantettini el al, 1993, 
% Processing Strategies for Time Course Data Sets
% MRM 30:161-173 (1993) pp 171
% 

nScans = numScans(view);
logProb=cell(1,nScans);
if strcmp(view.mapName,'logProbMap')
    % If exists, initialize to existing map
    map=view.map;
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = selectScans(view);
elseif scanList == 0
    scanList = 1:nScans;
end
if isempty(scanList)
    error('Analysis aborted');
end

% Compute it
waitHandle = mrvWaitbar(0,'Computing log10 P values from the tSeries.  Please wait...');
ncScans = length(scanList);
for iScan = 1:ncScans
    scan = scanList(iScan);
    nFrames=numFrames(view,scan);
    
    logProb{scanList(iScan)}=-(log10(computeCoherenceSignificance(view.co{scanList(iScan)},nFrames)));
    
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set parameter map
view = setParameterMap(view,logProb,'log10Prob');

% Save file
saveParameterMap(view);

