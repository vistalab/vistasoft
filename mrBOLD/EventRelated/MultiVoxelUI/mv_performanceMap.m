function mv = mv_performanceMap(mv, costFunction, N, mapPath);
%
% mv = mv_performanceMap([mv], costFunction, [nSeeds], [mapPath]);
%
% Generate a map of performance at each voxel according
% to a cost function, testing a _large_ number of spatially
% contiguous subsets of voxels.
%
% This function tests the hypothesis that a subset of spatially-
% contiguous voxels in multivoxel data are particularly good at 
% performing a task, which is evaluated by the specified cost
% function. It does this by applying the following algorithm:
%
% (1) Get the gray matter nodes and edges associated with the 
% voxel data, discarding non-gray voxels. (So there should
% be at least some voxels in the gray matter.)
%
% (2) Choose a seed point at random, in the gray matter.
%
% (3) Determine the distance of all other nodes from the seed node.
%
% (4) Create a series of disc ROIs, centered on the node, which begin
% very small and grow very big. 
%
% (5) For each disc ROI, apply the specified cost function to evaluate
% performance. Record the performance for all voxels in the ROI.
%
% (6) Repeat steps 2-5 for a large number of points. 
% (Save results at the end of each iteration, so if the user breaks,
% intermediate results are saved.)
%
% (7) Compute, for each voxel, the mean performance across all instances
% in which it was included in the ROI (the 'performance map'). 
%
% Arguments:
%       INPUT: mv: multi-voxel struct (see mv_init).
%              costFunction: string describing function to call when evaluating
%              performance. Should be of the form 'func(mv, [args])', where 
%              the multivoxel data are plugged in as argument mv. 
%              mapPath: if specified, will create a map for a mrVista 1.0 gray view
%                       and save the performance map there.
%
%       OUTPUT: appends a sub-struct 'bootstrap' to the mv struct. Has the following
%               fields:
%               'performanceMap': mean performance values across iterations.
%               'seeds': index of columns into the multivoxel data, specifying
%                        which voxels had been chosen as seeds for each iteration.
%               'seedCoords': 3xN coordinates of each seed node, in the gray data.
%               'discSizes': Sizes, in mm, of the ROI disc for each iteration.
%               'curves': performance curves for each iteration. Rows are the disc
%                         size, columns are the iterations starting at a given seed.
%               
%
% NOTE: right now the only cost function used is the winner-take-all
% classifier described in Sayres et al., NIPS 2005. May generalize this
% later, if this proves to be useful.
%
%
%
%
% ras, 10/2005. [Ignores cost function right now -- generalize later!]
if ieNotDefined('mv'),  mv = get(gcf,'UserData');   end
if ieNotDefined('N'),   N = 1000;                   end

if ieNotDefined('costFunction')
    % temp cost function for hires e-r analyses
    costFunction = 'er_wtaClassifier';
end

% params
cachePath = 'mvBootstrapCache.mat';
nSteps = 40; % steps per seed
minDist = 9; % distance from the seed of the smallest disc

% get gray nodes / edges
global HOMEDIR; % mrVista 1.0 specific
coordsPath = fullfile(HOMEDIR, 'Gray', 'coords.mat');
if ~exist(coordsPath,'file')
    fprintf('Sorry, no gray coords found for this data.\n');
    return
end

% get nodes and edges 
% (NOTE: if you know the hemisphere, and don't want to limit
% yourself to the nodes defined during one session, use
% 'allRightNodes' and 'allRightEdges' (or left, respectively)
% instead of the 'nodes' and 'edges' variables -- it's supposed
% to be better.)
load(coordsPath, 'nodes', 'edges', 'coords');

% find for each node the index into the relevant voxel:
% (if there isn't one, set to 0):
voxNodes = zeros(1,size(nodes,2));
if isequal(mv.roi.viewType, 'Inplane')
    % convert into gray coords
    global mrSESSION
    nVoxels = size(mv.coords,2);
    voxCoords = mrSESSION.alignment * [mv.coords; ones(1,nVoxels)];
    voxCoords = round(voxCoords(1:3,:));
else
    voxCoords = mv.coords;    
end
[C, voxInds, grayInds] = intersectCols(voxCoords, coords);
voxNodes(grayInds) = voxInds;

totalNodes = length(nodes); % total # of nodes in segmentation
nNodes = length(voxInds); % # of nodes in the voxel data
nVoxels = size(mv.coords,2); % # of voxels, incl. non-node voxels
coords = mv.roi.coords;
roiName = mv.roi.name;

% get all even/odd voxel amplitudes
sel = tc_selectedConds(mv);
runs = unique(mv.trials.run);
odd = runs(1:2:end);
even = runs(2:2:end);
A1 = mv_amps(mv,odd);
A2 = mv_amps(mv,even);
A1 = A1(:,sel); A2 = A2(:,sel);

% counter of # of iterations per voxel
ct = zeros(1,nVoxels); 

% values for performance map; -1 means node not tested yet
Y = -1*ones(1,nVoxels); 

% if an existing cache file is found, load it, and set the
% range for n to augment the existing values, rather than
% replace them:
if exist(cachePath,'file')
    load(cachePath,'Y','ct','curves','seeds','discBounds');
    M = length(seeds); % # of existing iterations
    range = M + [1:N];
else
    range = 1:N;
end


% Init for main loop
seeds = [];
newSeed = round(nNodes*rand); 
tic

%%%%%%%%%%%%%
% Main Loop %
%%%%%%%%%%%%%
for n = range
    % choose a random seed (index into voxel coords), w/o replacement
    while ismember(newSeed, seeds), newSeed = round(nNodes*rand); end
    seeds(n) = newSeed;
    
    % get distances from the seed (mapped to gray index) to each node
    dist = mrManDist(nodes, edges, grayInds(seeds(n)));
    
    % create a set of radii centered on the seed 
    % (ignore the last step -- it's always the entire set of voxels)
    radius = linspace(minDist, max(dist), nSteps+1);
    discBounds(n,:) = [radius(1) radius(nSteps)];
    
    for i = 1:nSteps
        % Find indices of all nodes within radius i
        I = find(dist>=0 & dist<=radius(i));
        
        % re-map from nodes into indices of the voxel data:
        I = voxNodes(I); I = I(find(I));
        
        if length(I)<=1 | any(isnan(A1(I,:))) | any(isnan(A2(I,:)))
            % if only one voxel, default to 0% correct
            curves(i,n) = 0;
        else
            % evaluate the cost function for these nodes
            anal = er_wtaClassifier(A1(I,:), A2(I,:));
            curves(i,n) = anal.pctCorrect;  
        end
        
        % iterate counter
        ct(I) = ct(I) + 1;              
        
        % the new values for the map (for voxels I) are a combination of 
        % the old values and the present values, weighted by the # of 
        % observations each represents:
        Y(I) = [Y(I) .* (ct(I)-1)./ct(I)] + [curves(i,n) .* 1./ct(I)];
        
        if mod(i,10)==1
            fprintf('Seed %i, step %i, %f secs\n', n, i, toc);
        end
    end    
    
    % update cache file
    save(cachePath, 'Y', 'ct', 'curves', 'seeds', ...
        'discBounds', 'coords', 'roiName');
end

% save all data
save(cachePath);

% create the map (in gray view first, xform if needed)
mapFlag = 1;
scan = mv.params.scans(1);
switch mv.roi.viewType
    case 'Inplane', hV = initHiddenInplane(mv.params.dataType,scan);
    case 'Gray', hV = initHiddenGray(mv.params.dataType,scan);
    otherwise, mapFlag = 0;
end
if mapFlag==1
    % save a map of the performance, with a co field
    map = cell(1,numScans(hV));
    map{scan} = zeros(dataSize(hV));
    map{scan}(roiIndices(hV, mv.coords)) = Y;
    mapName = 'Performance Map';

    co = cell(1,numScans(hV));
    co{scan} = zeros(dataSize(hV));
    co{scan}(roiIndices(hV, mv.coords)) = ct;

    fname = fullfile(dataDir(hV),'PerformanceMap.mat');
    save(fname, 'map', 'mapName', 'co');
    fprintf('Saved performance map in file %s.\n',fname);

    % also save a seed location map
    map{scan} = zeros(dataSize(hV));
    map{scan}(roiIndices(hV, mv.coords(:,seeds))) = 1;
    
    % ...and save a count map outright
    map{scan}(roiIndices(hV, mv.coords)) = ct;
    fname = fullfile(dataDir(hV),'PerformanceMap_Count.mat');
    save(fname, 'map', 'mapName');
    fprintf('Saved performance map in file %s.\n',fname);
end
        
% record values in mv struct
mv.bootstrap.performanceMap = Y;
mv.bootstrap.seeds = seeds;
mv.bootstrap.seedCoords = [];
mv.bootstrap.discSizes = radius;
mv.bootstrap.curves = curves;

return