function [myValsFgWa, SuperFiber, weightsNormalized, weights, fgResampled] = ...
    dtiFiberGroupPropertyWeightedAverage(fg, dt, numberOfNodes, valNames, p)
% Average eigenvalues across the fibers, along the bundle length
%
% [eigValFG,SuperFiber, weightsNormalized, weights, fgResampled] = ...
%   dtiFiberGroupPropertyWeightedAverage(fg, dt, numberOfNodes, valNames)
%
% The average is weighted with a gaussian kernel, where fibers close to the
% center-of-mass of a bundle contribute more, whereas fibers at the edges
% contribute less. The variance for this measure, for the subsequent
% t-tests, can be [in the future] computed two ways:
%
%  1. across subjects
%  2. within a subject -- with a bootstrapping procedure, removing one fiber
%        at a time from the bundle, and recomputing your average valNames.
%
% Important assumptions: the fiber bundle is compact. All fibers begin in
% one ROI and end in another. An example of input bundle is smth that
% emerges from clustering or from manualy picking fibers + ends had been
% clipped to ROIs using dtiClipFiberGroupToROIs or smth like that .
%
% INPUTS:
%          valNames - a string array of tensor statistics to be returned.
%                     Possible values: see dtiGetValFromTensors
%                     Default: {'eigvals'}.
%
%             p     - rate of fall off in weight with distance. This can
%                     also be 'mean' or 'median' which will not do a 
%                     weighted avg.
% OUTPUTS:
%            valsFG - array with resulting tensor stats. Rows are nodes,
%                     columns correspond to valNames.
%       Superfiber  - a structure describing the mean (core) trajectory and
%                     the spatial dispersion in the coordinates of fibers
%                     within a fiber group.
% weightsNormalized - numberOfNodes by numberOfFibers array of weights
%                     denoting, how much each node in each fiber
%                     contributed to the output tensor stats.
% weights           - numberOfNodes by numberOfFibers array of weights
%                     denoting, the gausssian distance of each node in
%                     each fiber from the fiber tract core
% fgResampled       - The fiber group that has been resampled to
%                     numberOfNodes and each fiber has been reoriented to
%                     start and end in a consitent location
%
% WEB RESOURCES:
%       mrvBrowseSVN('dtiFiberGroupPropertyWeightedAverage');
%       See also: dtiComputeDiffusionPropertiesAlongFG
%
% TODO: Add checks that the bunch is indeed tight -- e.g., critical var/cov
%       values... length of fibers...
%
% HISTORY:
%   ER 08/2009 wrote it
%
% Elena (c) Stanford VISTASOFT Team, 2009

if notDefined('fg'), error('Fiber group required'); end
if ~exist('valNames', 'var') || isempty(valNames)
    valNames = 'eigvals';
end

% This is a parameter that speeds up (> 1) or slows down (< 1) the rate of
% fall off for the assignment of weights.  By default, the rate of fallof
% is just the typical multivaraite Gaussian falloff.
if ~exist('p', 'var') || isempty(p), p = 1; end

% Number of fibers in the whole fiber group
numfibers = size(fg.fibers, 1);

% Should I add checks if fibers need to be reoriented?
% No, dtiComputeSuperFiberRepresentation takes care of that.
% This function will resample the fibers to numberOfNodes and will also
% reorient some fibers, so the notion of "first" and "last" may end up
% converted. [fg] returned in the line below will be resampled and reoriented.
[SuperFiber, fgResampled] = dtiComputeSuperFiberRepresentation(fg, [], numberOfNodes);

% Each fiber is represented by numberOfNodes, so can easily loop over 1st
% node, 2nd, etc...
fc = horzcat(fgResampled.fibers{:})';


% Compute properties if you the argument image is passed into valNames then
% we will compuute a weighted average of values from that image.  Otherwise
% the dt6 file will be used
if strcmp(valNames,'image');
    [myVals] = dtiGetValFromImage(dt.data, fc, dt.qto_ijk);
else
    [myVals1,myVals2, myVals3, myVals4, myVals5, myVals6, myVals7] = ...
        dtiGetValFromTensors(dt.dt6, fc, inv(dt.xformToAcpc), valNames);
    myVals = [myVals1(:) myVals2(:) myVals3(:) myVals4(:) myVals5(:) myVals6(:) myVals7(:)];
end;

% Preallocate weights when you understand its size
% weights = zeros(numberOfNodes,???)
% Compute weights
for node=1:numberOfNodes
    % Compute gaussian weights y = mvnpdf(X,mu,SIGMA);
    % Returns the density of the multivariate normal distribution with zero
    % mean and identity covariance matrix, evaluated at each row of X.
    X=fc((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :);
    sigma = [SuperFiber.fibervarcovs{1}(1:3, node)'; ...
        0 SuperFiber.fibervarcovs{1}(4:5, node)';...
        0 0 SuperFiber.fibervarcovs{1}(6, node)'];
    sigma = sigma + sigma' - diag(diag(sigma));
    mu    = SuperFiber.fibers{1}(:, node)';
    % Weights for the given node.
    weights(node, :) = mvnpdf(X,mu,sigma)';
end

% By default the weights are the Mahalnobis distance.  The parameter p
% adjust the rate at which the weights fall of with distance.  If the
% typical falloff is exp(- 1/2 d^2) by this exponentiation we turn the rate
% into exp (- 1/2 p d^2).  If p > 1, then the the falloff is faster.
if ~isnumeric(p), falloff=1; else, falloff=p; end
weights = weights .^ falloff;

% The weights for each node should add up to one across fibers.
weightsNormalized = weights./(repmat(sum(weights, 2), [1 numfibers]));

% Calculate values along the tract profile
if isnumeric(p)
    
    % Here we have a vector with elements referenced the same as
    % fc: fiber1 node 1 : numberOfNodes; fiber 2 node 1 : numberOfNodes ....
    fw = weightsNormalized(:);
    
    % Apply weights. Vals for each fiber, every node, weighted with a gaussian
    % kernel.
    myValsW = myVals.*repmat(fw, [1 size(myVals,2)]);
    
    % Average for N nodes to obtain N measures; take average across fibers for
    % each node.
    % The loop below cacluates weighted average. Let's assume there are 100
    % nodes. This means that every 100 entries in myValsW corresponds to a
    % new fiber. So by sampling myValsW every numberOfNodes we can pull out
    % a given node for every fiber
    for node = 1:numberOfNodes
        myValsFgWa(node, :)=sum(myValsW((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :));
    end
    
elseif strcmp(p ,'median')
    % Compute the median rather than the weighted mean
    
    for node = 1:numberOfNodes
        % myVals((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :) is
        % a matrix of values for node n with dimensionality Nfibers by
        % diffusion properties
        myValsFgWa(node, :) = median(myVals((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :));
    end

elseif strcmp(p ,'mean')
    % Compute the mean rather than the weighted mean. This is equivalent to
    % setting p=0
    
    for node = 1:numberOfNodes
        % myVals((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :) is
        % a matrix of values for node n with dimensionality Nfibers by
        % diffusion properties
        myValsFgWa(node, :) = mean(myVals((1:numberOfNodes:numfibers*numberOfNodes)+(node-1), :));
    end
    
end

return
