function p = er_significantResponse(tcs,params,trialsFlag);
%
% p = er_significantResponse(tcs,params,[trialsFlag]);
%
% Compute the p-value of a 2-tailed T-test between 
% peak and baseline periods  (specified in the 
% event-related params struct) for trial time courses.
%
% tcs: matrix in which rows represent trial time (see
% er_chopTSeries, er_voxelData). tcs can be N-dimensional (up to 4);
% the returned p matrix will have all singleton dimensions
% (including the rows dimension) squeezed out.
%
% params: event-related parameters specifying peak and
% baseline periods. See er_getParams.
%
% trialsFlag: if 1, will interpret the columns of the
% tcs matrix as different trials of the same condition, and
% will return the p value for all trials. In this case,
% both the rows and columns will be squeezed out of the
% p matrix. [Default 0]
% 
%
%
% ras, 04/05
if ieNotDefined('trialsFlag')
    trialsFlag = 0;
end

%%%%% convert params expressed in secs into frames
TR = params.framePeriod;
timeWindow = params.timeWindow(mod(params.timeWindow,TR)==0);
frameWindow = unique(round(timeWindow./TR));
peakFrames = unique(round(params.peakPeriod./TR));
bslFrames = unique(round(params.bslPeriod./TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));

if trialsFlag==1
    % loop across 3rd and 4th dimensions
    for i = 1:size(tcs,3)
        for j = 1:size(tcs,4)
            subdata = tcs(:,:,i,j);
            peak = subdata(peakFrames,:);
            bsl = subdata(bslFrames,:);
            [ignoreH, p(i,j)] = ttest2(peak(:),bsl(:));
        end
    end
else
    % loop across 2nd-4th dimensions
    for i = 1:size(tcs,2)
        for j = 1:size(tcs,3)
            for k = 1:size(tcs,4)
                subdata = tcs(:,i,j,k);
                peak = subdata(peakFrames);
                bsl = subdata(bslFrames);
                [ignoreH, p(i,j,k)] = ttest2(peak(:),bsl(:));
			end
        end
    end
end

% p = squeeze(p);

return