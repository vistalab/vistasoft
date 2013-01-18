function [fiberMetrics_New, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics, labels, collapsingVector, aggregatorFunction, weights)
%Collapse data for some fiber fiber groups
%
% [fiberMetrics_New, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics, labels, collapsingVector, aggregatorFunction)
%
% FiberMetrics is typically of dimensionality nSubjectsx20, where 20 are the mori
% groups. Some of these fiber groups are too smal and their data would be
% better off combined with other, bigger fiber groups. Another use case is
% collapsing the data from homologous fiber groups.
% Input parameters:
% fiberMetrics:     nSubjectsXnFiberGroups matrix of values
% labels:           string array of 1xnFiberGroups with labels for the fiber
% collapsingVector: prescribes final group assignment labels.
%                    E.g., to combine unstable/small Mori fiber groups together:
%                    - Cingulum (cingulate gyrus) and cingulum (hippocampus),
%                     labels([5 7]) as well as labels([6 8]);
%                    - Combine SLF components: fronto-parietal and temporal,
%                     labels([15 19]) and labels([16 20]);
%                     use collapsingVector=[1 2 3 4 5 6 5 6, ...
%                                           7 8 9 10 11 12 13 14 15 16 13 14];
%                    E.g.2, to also collapse across the hemispheres:
%                    use collapsingVector=[1 1 2 2 3 3 3 3, ...
%                                           4 5 6 6 7 7 8 8 9 9 8 8];
% aggregatorFunction: 'mean' (more appropriate for tensor stats, etc) or
%                     'sum' (appropriate for volume)
% weights            'mean' aggregatorFunction this method may be very biased
%                     in case you are collapsing groups of very difference size
%                     because the average computed will not be
%                     weighted to reflect the respective sizes of the fiber groups.
%                     The weights can be obtained, for example, as
%                     numberOfFibers property computed for each
%                     fiber group subject to collapsing. If
%                     aggregatorFunction is 'sum', the weights are ignored.
%

% HISTORY:
% 02/2010 ER wrote it

if ~strmatch(aggregatorFunction, {'mean', 'sum'})
    error('Only mean or sum are supported as aggregator function'); 
end

if exist('weights', 'var') && ~isempty(weights) && strcmp(aggregatorFunction,'mean')
    %normalize weights with respect to each "new group"
    
    if size(weights)~=size(fiberMetrics)
        error('Weights and fiberMetrics should be of the same size');
    end
    
    for iNewFg=collapsingVector
        weights(:, find(collapsingVector==iNewFg))=weights(:, find(collapsingVector==iNewFg))./repmat(sum(weights(:, find(collapsingVector==iNewFg)), 2), [1 length(find(collapsingVector==iNewFg))]); 
    end
    fiberMetrics=fiberMetrics.*weights; 
    aggregatorFunction='sum'; %weighted sum is the new mean
else
    fprintf(1, 'dti_LongitudeAggregateFiberPropertiesAcrossGroups: Weights not provided, and/or aggregator function is a sum\n'); 
end

    for iNewFg=unique(collapsingVector)

    fiberMetrics_New(:, iNewFg) = eval([aggregatorFunction '(fiberMetrics(:, find(collapsingVector==iNewFg)), 2)']);
    labels_New(iNewFg) = cellstr(horzcat(labels{find(collapsingVector==iNewFg)}));
    end
return




%Example code usage for fiberGroupVolume
% /biac3/wandell4/users/elenary/longitudinal/scripts/make_fgPropertyDisplays