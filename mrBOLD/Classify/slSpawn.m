function slSpawn(searchlight, process, processes, partitions)
% slSpawn(searchlight, process, processes, partitions)
% SEARCHLIGHT - SPAWN 
% ---------------------------------------------------------
% Used by SLRUN to complete bite-sized portions of a searchlight.   
%
% INPUTS
% 	searchlight - Structure initialized with slInit.
% 	process - Which of N portions to complete.
% 	processes - Number of portions to be completed. 
% 	partitions - How many smaller-sized portions to break up each portion
%       into.
%
% OUTPUTS
%   N/A
%
% USAGE
%   Calling this is either handled by the SGE or layed out explicitly by
%   provided commands.  Assuming you'd like to write up a command on your
%   own, let's suppose we want to run the first portion of a searchlight
%   broken into three pieces.  Each of those portions we'll divide into 30
%   bite-sized portions to iterate over.
%       searchlight = slInit(...);
%       slSpawn(searchlight, 1, 3, 30);
%
% See also SLINIT, SLRUN, SLCOMPLETE, SVMINIT.
%
% renobowen@gmail.com [2010]
%
    isGray = strcmpi(searchlight.searchView, 'gray');
    growBy = searchlight.growBy;
    
    processesToRun = (((process - 1) * partitions):(process * partitions - 1)) + 1;
    for i = processesToRun
        filename = sprintf('%s/%s/searchlight%04d.mat', searchlight.path, searchlight.tmpDir, i);
        processString = sprintf('[%d/%d]', i, processes);
        if (exist(filename, 'file'))
            fprintf('%s Process already completed.  Proceeding...\n', processString);
            continue;
        end
        
        indices = searchlight.startInds(i):searchlight.endInds(i);
        
        if (isGray)
            centers = searchlight.ipInds(:, indices);
        else
            centers = searchlight.allCoords(:, indices);
        end
        nCenters = size(centers, 2);

        fprintf('%s Processing coordinate block...', processString);
        meanAccs = zeros(1, nCenters);
        for j = 1:nCenters
            [roiCoords centers(:, j)] = growROI(searchlight, centers(:, j), isGray);
            if (isempty(roiCoords))
                meanAccs(j) = 0;
            else
                meanAccs(j) = runSVM(searchlight, roiCoords);
            end
        end
        fprintf('done.\n');
        fprintf('%s Saving...', processString);
        save(filename, 'meanAccs', 'centers', 'growBy', '-v7.3');
        fprintf('done.\n');
    end
end

function [roiCoords center] = growROI(searchlight, center, isGray)
    growBy = searchlight.growBy;
    if (isGray)
        % Set nodes and edges to relevant hemisphere
        ind = center(1);
        isRightHemi = center(2);
        if (isRightHemi)
            nodes   = searchlight.vw_gray.allRightNodes;
            edges   = searchlight.vw_gray.allRightEdges;
        else
            nodes   = searchlight.vw_gray.allLeftNodes;
            edges   = searchlight.vw_gray.allLeftEdges;
        end
        
        % Compute coordinates of grown disc
        dist        = mrManDist(nodes, edges, double(ind), [1 1 1], 0, growBy);
        discCoords  = nodes(1:3, dist > 0);
        if (isempty(discCoords)), roiCoords = []; return; end
        roiCoords  = [discCoords(2, :); discCoords(1, :); discCoords(3, :)]; % rearranging because of fudged order
        
        % Recompute hemispheric index to parameter map index
        if (isRightHemi)
            [c center(1)] = intersectCols(searchlight.vw_gray.nodes(1:3, :), ...
                searchlight.vw_gray.allRightNodes(1:3, ind)); % for 3 coordinates
        else
            [c center(1)] = intersectCols(searchlight.vw_gray.nodes(1:3, :), ...
                searchlight.vw_gray.allLeftNodes(1:3, ind)); % for 3 coordinates
        end
        
    else
        minmax = repmat(center, [1 2]);
        minmax(:, 1) = minmax(:, 1) - growBy;
        minmax(:, 2) = minmax(:, 2) + growBy;
        if (sum(minmax(:, 1) < 1) || sum(minmax(:, 2) > searchlight.dims)), roiCoords = []; return; end % out of bounds

        cubewidth = growBy * 2 + 1;
        xcoords = reshape(repmat(minmax(1, 1):minmax(1, 2), [cubewidth^2 1]), [1 cubewidth^3]);
        ycoords = repmat(reshape(repmat(minmax(2, 1):minmax(2, 2), [cubewidth 1]), [1 cubewidth^2]), [1 cubewidth]);
        zcoords = repmat(minmax(3, 1):minmax(3, 2), [1 cubewidth^2]);

        roiCoords = [xcoords; ycoords; zcoords];
    end
end

function meanAcc = runSVM(searchlight, roiCoords)
    meanAcc = [];
    if (isempty(roiCoords)), return; end
    
    svmTmp = searchlight.svm;
    if (strcmp(searchlight.searchView, 'inplane'))
        coords = svmTmp.coordsInplane;
    else
        coords = svmTmp.coordsGray;
    end
    
    [c svmInds] = intersectCols(coords, roiCoords); % for 3 coordinates
    if (isempty(svmInds)), svmInds = 1:0; end
    svmTmp.data = svmTmp.data(:, svmInds);
    svmTmp.data = svmTmp.data(:, ~isnan(svmTmp.data(1,:)));
    svmTmp.voxel = [];
    
    [meanAcc models] = svmRun(svmTmp, 'options', searchlight.runOptions);
end
