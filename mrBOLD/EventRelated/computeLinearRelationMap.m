function [map, co] = computeLinearRelationMap(view,scans,mapName,varargin);
% [map, co] = computeLinearRelationMap(view,[scans],[mapName],[options]);
%
% Compute a special kind of contrast map, which tests the
% hypothesis that the response to different conditions are 
% linearly related.
%
% This is effectively like a double GLM: after first applying
% a general linear model to a group of scans (see er_runSelxavgBlock),
% the beta values computed for each voxel are run through a 
% further regression, against a set of single-value predictors.
% By default these predictors are 1:numConditions, although a 
% different set of predictors can be entered as an option
% (using the flag 'X').
%
% 
%
% scans defaults to the view's current scan group; if mapName
% is omitted a prompt asks for the name.
%
% Options are:
% 
%       'X',[val],...: enter an array of predictor values for each
%                      condition as the next option
%
%       'nConds',[val],...: only regress the specified # of conditions.
%
%       'voxels',[name or coords]: specify which voxels to run 
%                                   the analysis on, either as a name
%                                   of an ROI to load, or a 3XN array
%                                   of coordinates.
%
% 08/04 ras.
if ieNotDefined('scans')
    [scans dt] = er_getScanGroup(view);
    cdt = viewGet(view,'curdatatype');
    view.curDataType = dt;
end

%%%%% params/defaults
nSlices = numSlices(view);
dsz = dataSize(view,scans(1));
X = [];             % will be 1:nConds, once we find the # conds
nConds = [];        % get from parfiles by default
alpha = 0.01;
rois = viewGet(view,'rois');
curRoi = viewGet(view,'selectedROI');
coords = rois(curRoi).coords;

%%%%% parse the input options
for i = 1:length(varargin)
    switch lower(varargin{i})
    case {'x'},         X = varargin{i+1};
    case {'nconds'},    nConds = varargin{i+1};
    case {'alpha'},     alpha = varargin{i+1};
    case {'voxels'},  
          roi = varargin{i+1};
          if ischar(roi)
              view = loadROI(view,roi);
              coords = view.ROIs(view.selectedROI).coords;
          else
              coords = roi;
          end
    end
end

%%%%% load the onset info from par files
trials = er_concatParfiles(view,scans);
if isempty(nConds)
    nConds = length(unique(trials.cond(trials.cond>0)));
end

%%%%% load the MRI time courses for each voxel
raw = ~(detrendFlag(view));
tSeries = [];
h = mrvWaitbar(0,'Loading tSeries...');
for s = scans
    scanTSeries = getTseriesOneROI(view,coords,s,raw);
    tSeries = [tSeries; scanTSeries{1}];
    mrvWaitbar(find(scans==s)/length(scans),h);
end
close(h);

% find the times from which to extract amplitudes
timeWindow = [0:22];
bslPeriod = [4:8];
peakPeriod = [10:16];

voxData = er_chopTSeries2(tSeries,trials,er_getParams(view,scans(1)),...
            'barebones');
nVoxels = length(voxData);

%%%%% setup predictor 'design matrix', X
% set default predictors, if not passed in as an option
if isempty(X)
    X = 1:nConds;
end

% add a constant-term column
X = [X(:) ones(length(X),1)];

%%%%% initialize the maps
map = zeros(dataSize(view,scans(1)));   % p-value of regression
co = zeros(dataSize(view,scans(1)));    % pct. variance explained by fit
slope = zeros(dataSize(view,scans(1))); % slope (beta) of best line
rsquare = zeros(dataSize(view,scans(1))); % R^2 value for regression
ind = roiCoords2MapIndex(view,coords);

%%%%% main loop: regress each voxel
h = mrvWaitbar(0,'Regressing...');

for v = 1:nVoxels
    % calculate amplitudes
    y = voxData(v).amps(1:nConds)';
    
    % regress amplitudes vs. des mtx
    [b,bint,r,rint,stats] = regress(y,X,alpha);
    
    % store values for this voxel
    map(ind(v)) = -1 * log10(stats(3));
    co(ind(v)) = r(1);
    slope(ind(v)) = b(1);
    rsquare(ind(v)) = stats(1);

    mrvWaitbar(v/nVoxels,h,sprintf('Voxel %i of %i',v,nVoxels));
end

close(h);

%%%% save the resulting contrast map
nScans = numScans(view);
if scans(1) < nScans
    tmp{nScans} = [];
    tmp2{nScans} = [];
end
tmp{scans(1)} = map;
tmp2{scans(1)} = co;
map = tmp;
co = tmp2;

if ieNotDefined('mapName')
    [mapName, pth] = myUiPutFile(dataDir(view),'*.mat','Name the saved map...');
    savePath = fullfile(pth,mapName);
    if ~isempty(findstr('.mat',mapName))
        mapName = mapName(1:end-4);
    end
else
    savePath = fullfile(dataDir(view),mapName);
end

save(savePath,'map','mapName','co','slope','rsquare');
fprintf('Saved param map %s with some extra info like slope and R^2.\n',savePath);

%%%%% set as the current map in the view (if not hidden)
if isfield(view,'ui')
	view = viewSet(view,'map',map);
	view = setDisplayMode(view,'map');
	refreshView(view);
end

return
