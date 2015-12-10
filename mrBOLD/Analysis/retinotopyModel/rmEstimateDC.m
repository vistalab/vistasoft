function [data, trendBetas]=rmEstimateDC(data,trendBetas,params,trends,dcid)
% rmEstimateDC - estimate DC component for each scan from a selected period
% of data
%
%  [data, trendBetas]=rmEstimateDC(data,trendBetas,params,trends,dcid)
%
% More comment needed.
%
% Not sure if it is used a lot.
%
% Probably originally from SOD

% check flag
if params.analysis.dc.datadriven==false
    return
end


%---------------------------------------------------------------------
% find datapoints where there is no stimulus. With this data we can 
% calculate the dc-component before we estimate the model parameters.  
%---------------------------------------------------------------------

numberOfScans = numel(params.stim);
sizeAllStimImages = sum([params.stim(:).nFrames]);
    
ind = 1;
noStimPoints = zeros(1,sizeAllStimImages);
for i = 1: numberOfScans
    nFramesToBeRemoved = ceil(params.analysis.dc.hrfTime/params.stim(i).framePeriod);             %remove at least the first 10 seconds of the blank
    nFrames = params.stim(i).nFrames;
    preScanDuration = params.stim(i).prescanDuration;
    noStimPointsOrig = sum(params.stim(i).images_org(:,1:end))== 0;
    rem = 0;
    for j = 1:length(noStimPointsOrig)
        if noStimPointsOrig(j) == 1
            if rem < nFramesToBeRemoved       %rem < nFramesToBeRemoved
                noStimPointsOrig(j) = 0;
                rem = rem + 1;
            end
        else
            rem = 0;
        end
    end

    % remove prescanduration and put in noStimPoints (all scans)
    indexEnd = ind + nFrames -1;
    noStimPoints(ind:indexEnd) = noStimPointsOrig(preScanDuration+1: end);
    ind = indexEnd + 1;
end
% mean-luminance data
noStimPoints = logical(noStimPoints);
dataNoStimulus = data(noStimPoints,:);

% calculate the dc-component for the data without stimulus
dcBetas = pinv(trends(noStimPoints,dcid))*dataNoStimulus;

% remove dc per scan for all stimuli
data = data - trends(:,dcid)*dcBetas;

% add dc component to trendBetas
trendBetas(dcid,:) = trendBetas(dcid,:)+dcBetas;

end
 
 
    