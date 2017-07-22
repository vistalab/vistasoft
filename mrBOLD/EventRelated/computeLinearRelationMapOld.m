function [map, co] = computeLinearRelationMapOld(view,scans,mapName,varargin);
% [map, co] = computeLinearRelationMapOld(view,[scans],[mapName],[options]);
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
X = []; % will be 1:nConds, once we find the # conds
nConds = [];
alpha = 0.01;

%%%%% parse the input options
for i = 1:length(varargin)
    switch lower(varargin{i})
    case {'x'},         X = varargin{i+1};
    case {'nconds'},    nConds = varargin{i+1};
    case {'alpha'},     alpha = varargin{i+1};
    end
end

%%%%% load the hAvg (estimated beta values)
hAvg = [];
coords = [];

hAvgStem = fullfile(tSeriesDir(view),['Scan' num2str(scans(1))],'hAvg');
for slice = 1:nSlices
    hAvgFile = [hAvgStem num2str(slice)];
    load(hAvgFile,'tSeries');
    hAvg = [hAvg tSeries];
    [xx yy] = meshgrid(1:dsz(1));
    zz = repmat(slice,1,dsz(1)*dsz(2));
    coords = [coords [xx(:)'; yy(:)'; zz]];
end

nVoxels = size(hAvg,2);

% hAvg contains both beta coefficients and
% estimated variance -- break into two
if isempty(nConds)
    % take all available conditions, get nConds from that    

    % first condition is baseline, all betas set to 0, ignore
    betas = hAvg(3:2:end);
    eresvar = hAvg(2:2:end); % first variance is overall variance of fitting

    nConds = size(betas,1);
else
    % user has specified # conditions to consider, take only those
    betas = hAvg(3:2:2*nConds+1,:);
    eresvar = hAvg(2:2:end,:);
end


%%%%% setup predictor 'design matrix', X
% set default predictors, if not passed in as an option
if isempty(X)
    X = 1:nConds;
end

% add a constant-term column
X = [X(:) ones(length(X),1)];


%%%%% main loop: regress each voxel
h = mrvWaitbar(0,'Regressing...');

for v = 1:nVoxels
    x = coords(1,v);
    y = coords(2,v);
    z = coords(3,v);   

    [b,bint,r,rint,stats] = regress(betas(:,v),X,alpha);
    
    map(x,y,z) = -1 * log10(stats(3));    % p-value
    co(x,y,z) = mean(eresvar(:,v));
    slope(x,y,z) = b(1);
    rsquare(x,y,z) = stats(1);

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

return
