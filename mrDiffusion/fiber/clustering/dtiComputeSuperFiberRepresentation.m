function [SuperFiber, fg] = dtiComputeSuperFiberRepresentation(fg, clusterlabels, numNodes, M)
%
% [SuperFiber, fg] = dtiComputeSuperFiberRepresentation(fg, [clusterlabels], [numNodes])
%
% Superfibers are a single curve (fiber) that summarizes all of the fibers
% in a single labeled cluster.  For example, one might compute the super
% fiber associated with the arcuate.
%
% Create SuperFiber representation of all the fibers assigned to one
% cluster. If numNodes is not provided, it is assumed that they all are
% resampled to same number of Nodes as in fg.fibers{1}.
%
%  INPUTS:
%    fg            - fiber group structure
%    clusterLabels - Possible labels of the fiber subgroups
%    numNodes      - Number of samples (nodes) along the fiber
%    M             - 'mean' or 'median' for calculating tract core
%
%  OUTPUTS:
%   The parameters in the returned representation are:
%   SuperFiber.fibermeans: means (for every coordinate, every node)
%   SuperFiber.fibervarcovs: low diag var/cov matrix for coordinates
%                          (every node)): [var(x), cov(x, y),
%                          cov(x, z), var(y), cov(y, z), var(z)]
%   SuperFiber.n is number of fibers included in this cluster.
%   fg - returned containes flipped and resampled fibers that produced the
%        superfiber.
%
% Note: while computing superFiber representation, some fibers (or even
% majority of fibers) may have to have been  flipped to group first and
% last points together. The 'fg' returned containes flipped and resampled
% fibers that produced the superfiber.
%
% Algorithm:
%
% All fibers in the group (e.g., optic tract) are resampled to represent
% equal numbers of nodes. We determine the mean and 3D covariance of the
% voxel positions representing that node. We define the core fiber as the
% set of mean positions of the sample nodes.
%
% In subsequent routines, we determine the weight contributed by each voxel
% to the diffusivity measure using the covariance matrix. Specifically, we
% calculate the Mahalanobis distance of each voxel from the mean. If a
% voxel position is X, the mean position is X0, and the covariance matrix
% of the 3D positions is C, then the Mahalanobis distance, d, is sqrt(delta
% Cinv delta), where X-X0 is delta.
%
% The assgined weight is the inverse of the distance, d. This procedure
% assigns more weight to fibers close to the core of the bundle, and the
% meaning of close is derived from the distribution of the points at each
% node as captured by the covariance matrix.
%
%  WEB RESOURCES:
%   mrvBrowseSVN('dtiComputeSuperFiberRepresentation');
%   http://white.stanford.edu/newlm/index.php/Diffusion_properties_along_tr
%   ajectory
%
%  EXAMPLE USAGE:
%   % Create superfiber
%       fg = mtrImportFibers('fiberGroupName.pdb');
%       numNodes = 30;
%       [SuperFiber, sfg] = dtiComputeSuperFiberRepresentation(fg, [], numNodes);
%       sFg = dtiNewFiberGroup([fg.name '_superFiber'],[0 0 155],[],[],SuperFiber.fibers);
%   % Save the superfiber
%       mtrExportFibers(sFg,sFg.name);
%
%  HISTORY:
%   2008       ER wrote it
%   08/11/2009 ER added checks that all start points and all end points are
%              grouped respectively.
%   09.13.2011 LMP Added comments, example usage, web resources and
%              input/output descriptions


if(notDefined('numNodes'))
    numNodes=length(fg.fibers{1});
    if length(unique(cellfun(@length, fg.fibers)))>1
        % The numNodes should be the same across all fiber groups, or
        % The user should provide the numNodes for each of the fiber groups
        error('Either provide numNodes to resample the fg to, or number of nodes in the existing fg should be same across the fibers');
    end
end
if notDefined('M')
    M='mean';
elseif ~strcmp(M,'mean') && ~strcmp(M,'median')
    error('M must be either mean or median')
end
% If cluster labels is not sent in, then we assign cluster labels all the
% value of one according to the size of fg.fibers.  FG is a fiber group,
% and it consists of a set of cells that define the nodes of fibers.  This
% assignment says that all of the fibers in the fiber group are in the same
% cluster.  That cluster is labeled cluster 1.
if(notDefined('clusterlabels')), clusterlabels = ones(size(fg.fibers));end

%Check that the all the starting points and all the end points are grouped.
%This routine also resamples the fibers to numNodes samples.
fg = dtiReorientFibers(fg, numNodes);

% The super name
SuperFiber.name=[fg.name '_SuperFiber'];

%The number of fibers in the fiber group
nfibers = size(fg.fibers, 1);
% This should be the same numNodes we sent in above
numNodes= size(fg.fibers{1}, 2);

% curves is the 3D representation of each node for each fiber.
curves  = zeros(3, numNodes, nfibers);
for ii=1:nfibers
    curves(:, :, ii) = fg.fibers{ii};
end

% For every cluster, there is a superfiber representation
% The clusters are labeled as numbers, so max(clusterlabels) is the number
% of clusters.
for clust = 1:max(clusterlabels)
    
    % For this cluster, find the number of fibers.
    SuperFiber.n(clust, 1) = size(find(clusterlabels==clust), 1);
    
    % For every node in the numNode list, compute the mean and covariance
    % cloud of the nodes in 3-space.
    for node = 1:numNodes
        
        %Find the mean position of the 3D coordinates at this node, for
        %this cluster.
        if strcmp(M,'mean')
            SuperFiber.fibers{clust, 1}(:, node) = mean(curves(:, node, clusterlabels==clust), 3);
        elseif strcmp(M,'median')
            SuperFiber.fibers{clust, 1}(:, node) = median(curves(:, node, clusterlabels==clust), 3);
        end
        % Find the lower diagonal matrix of the cloud of points at this
        % node.  Say, for cluster 1 we find the 3D values at this node.  We
        % permute the coordinates to because (help, explain why and what it
        % is matched to), we compute the covariance matrix of these 3D
        % points. The function tril zeros the upper diagonal entries.
        % Later, ER stores the lower triangular part of the symmetric)
        % matrix.
        %
        % This is a very complicated representation that is probably
        % unpacked later in other functions.  It would be nice to specify
        % in the header what functions need to be aware of this
        % representation.
        LowDiagonalMatrixThisNode = ...
            tril(cov(permute(curves(:, node, clusterlabels==clust), [3 1 2])));
        
        if size(find(clusterlabels==clust), 1)==1
            %ONLY ONE FIBER IN THE GROUP
            LowDiagonalMatrixThisNode = zeros(3);
        end
        
        %These are low diagonal elements of the 3x3 covariance matrix.
        SuperFiber.fibervarcovs{clust, 1}(:, node) = ...
            LowDiagonalMatrixThisNode([1:3 5:6 9]');
        
    end %node
    
end %clust

return

