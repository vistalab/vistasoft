function cortMag = computeCortMagFunction(cortMag, flatView, grayView)
%
%  cortmag = computeCortMagFunction(cortMag, flatView, grayView)
%
%  Computes the cortical magnification function.
%  Adds these fields to the cortMag struct: corticalDist, stimulusDeg.
%
% HISTORY:
%   2002.03.05 RFD (bob@white.stanford.edu) wrote it, based
%   on code by Wandell, Baseler and Brewer.


% The basic steps that we need to do:
% * find a start point
%    - ROI coords are already sorted, so we just take the first coord
% * find a gray node for each point
% * find distance from start node to every other node
% * grab the co and ph for each node, drop those that are below threshold
% * unwrap phases (apply template unwrap function?)
% * fit the cortMag function to the (cumulative) distance vs. phase

for(roiNum=1:length(cortMag.ROIs))
    if((~isempty(cortMag.excludeROIs) & any(cortMag.excludeROIs==roiNum)) ...
            | length(cortMag.bins{roiNum})<2)
        % Exclude specified 'exclude ROIs' and those ROIs with only one bin
        dist{roiNum} = [];
        meanPh{roiNum} = [];
        stimDeg{roiNum} = [];
    else
        distTmp = [];
        meanPhTmp = [];
        sePhTmp = [];
        for(binNum=1:length(cortMag.bins{roiNum}))
            % drop points below coThresh and points for 
            keepers = find(cortMag.bins{roiNum}(binNum).allCo >= cortMag.coThresh);
            if(~isempty(keepers))
                distTmp(end+1) = cortMag.bins{roiNum}(binNum).distToPrev;
                % We do all phase work in complex space to avoid wrapping                % issues
                meanPhTmp(end+1) = mean(exp(i.*cortMag.bins{roiNum}(binNum).allPh(keepers)));
                sePhTmp(end+1) = std(exp(i.*cortMag.bins{roiNum}(binNum).allPh(keepers))) ...
                                        ./ sqrt(length(keepers));
            end
        end
        % We check again for ROIs that need to be excluded- the cothresh        % may have eliminated some
        if(length(distTmp)<2)
            dist{roiNum} = [];
            meanPh{roiNum} = [];
            stimDeg{roiNum} = [];
        else
            dist{roiNum} = cumsum(distTmp);
            meanPh{roiNum} = meanPhTmp;
            sePh{roiNum} = sePhTmp;
        end
    end
end

cortMag.corticalDist = dist;
cortMag.meanPh = meanPh;
cortMag.sePh = sePh;

%cortMag.meanPh = unwrapPhases(cortMag.meanPh);

% Slide all merida to fit the first one
% In theory, we could infer the shift from the ring atlas and reduce the% number
% of free parameters.
cortMag.distanceShift = cmSlideFitPh(cortMag);
%cortMag.distanceShift = zeros(size(cortMag.corticalDist));

% Apply the distance shift
for(roiNum=1:length(cortMag.ROIs))
    cortMag.corticalDist{roiNum} = cortMag.corticalDist{roiNum} + cortMag.distanceShift(roiNum);
end

% Combine all measurements into one sorted list
cortMag.allCorticalDist = cat(2, cortMag.corticalDist{:});
cortMag.allMeanPh = cat(2, cortMag.meanPh{:});
cortMag.allSEPh = cat(2, cortMag.sePh{:});

% Sort the list by distance, then apply the sort index (si) to the pahses,% to maintain data pairs.
[cortMag.allCorticalDist, si] = sort(cortMag.allCorticalDist);
cortMag.allMeanPh = cortMag.allMeanPh(si);
cortMag.allSEPh = cortMag.allSEPh(si);

% Now that all the data are in one sorted list, we can unwrap again to% clean up the stragglers
%cortMag.allMeanPh = unwrapPhases(cortMag.allMeanPh);

fprintf('Fitting standard exponential Cort Mag Function to allUxxx data.\n');
if isfield(cortMag,'initParms')
   cortMag = fitStandardCMF(cortMag,cortMag.initParms);
else
   cortMag = fitStandardCMF(cortMag);
end

% Now, we convert the complex phase data into degrees of visual angle.
% This requires knowing the foveal phase and the stimulus radius
%
fprintf('Converting from phase to degree.\n');
cortMag = ph2deg(cortMag);

return;