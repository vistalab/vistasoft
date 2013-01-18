function mv = mv_mutualInformation(mv,trialAmps,thresh,threshType);
%
% mv = mv_mutualInformation(mv,trialAmps,thresh,threshType);
%
% Compute mutual information of each voxel with
% the stimulus set. Uses an implementation based
% on the description in Dayan and Abbott, Theoretical
% Neuroscience, 2001, Chapter 4.1 (pgs 124-129).
%
%
% trialAmps should be of the format: nVoxels x nConds x nTrials.
%
% thresh is the threshold to use. If omitted,
% defaults to mu + sigma, where mu is the 
% mean for each voxel and sigma the std. dev.
% If entered as 'auto', searches among a range of
% thesholds and chooses the best one for each voxel
% (to maximize MI).
%
% threshType is the type of threshold to 
% use: if 0, use separate thresholds for
% each voxel (thresh is interpreted
% as mu + thresh*sigma), otherwise use
% a global threshold for all voxels.
%
% ras, 05/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('trialAmps')
    trialAmps = permute(mv.voxAmps,[2 3 1]);
end

if ieNotDefined('threshType')
    threshType = 0;
end

% recursive option: if thresh is entered
% as 'auto', searches through possible 
% voxel-based thresholds and chooses the
% optimal one for each voxel:
if exist('thresh','var') & isequal(thresh,'auto')
    threshVals = [-0.2:0.2:4];
    for i = 1:length(threshVals)
        mi = mv_mutualInformation(mv,trialAmps,threshVals(i),threshType);
        ImAll(:,i) = mi.mutualInf.Im;
    end

    % params
    nVoxels = size(trialAmps,1);
    nConds = size(trialAmps,2);
    nTrials = size(trialAmps,3);
    
    % find column w/ highest MI for each voxel
    for i = 1:nVoxels
        tmp = find(ImAll(i,:)==max(ImAll(i,:)));
        cols(i) = tmp(1);
    end
    ind = sub2ind(size(ImAll),1:nVoxels,cols);

    % new thresholds
    thresh = threshVals(cols);

    % calculate associated values w/ this optimal
    % set of thresholds
    threshMat = repmat(thresh(:),[1 nConds nTrials]);
    A = double(trialAmps>threshMat);

    mv.mutualInf.Im = ImAll(ind)';
    mv.mutualInf.thresh = thresh';
    mv.mutualInf.binnedResponses = A; 
    mv.mutualInf.responseBins = unique(A(:))';

    return
end

%%%%% params
nVoxels = size(trialAmps,1);
nConds = size(trialAmps,2);
nTrials = size(trialAmps,3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first, and most critical, step:
% decide how to threshold voxel amplitudes
% into a reasonable number of possible response
% bins to compute conditional probabilities 
% p(s|r) and p(r|s), where r is a response level
% and s is a stimulus. 
%
% We use only 2 bins here, responsive and nonresponsive,
% since fMRI data tends to have very few trials for
% each condition. This leaves the problem of 
% deciding a threshold. Our current threshold for
% each voxel is the mean + 1 standard deviation of 
% the amplitudes across all trials for that voxel.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mu = mean(mean(trialAmps,3),2);
sigma = std(std(trialAmps,1,3),1,2);
if ieNotDefined('thresh')
    thresh = mu+0.2*sigma;
else
    if threshType==0
        % separate thresh for each voxel
        thresh = mu + thresh*sigma;
    else
        % global thresh
        thresh = repmat(thresh,[nVoxels 1]);
    end
end

% Make A the binary matrix denoting whether a given
% voxel exceeded thresh to a given stimulus on a given
% trial:
threshMat = repmat(thresh,[1 nConds nTrials]);
A = double(trialAmps>threshMat);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Second: Compute entropy of trial responses, independent
% of any conditions (Dayan & Abbott, Eq. 4.3, pg. 125):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = zeros(nVoxels,1);   % initialize total entropy for each voxel
R = unique(A(:))';       % possible responses
nRespBins = length(R);
for r = R
    B = (A==r); % binary matrix identifying elements w/ response level r
    Pr = sum(sum(B,3),2) ./ (nConds*nTrials); % probability of response r
    Pr(Pr==0) = 1^-10; % avoid 'log of zero' warnings
    H = H - Pr.*log2(Pr); % sum up entropy across responses
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Third: Compute 'noise entropy' associated with response 
% variability that does _not_ arise from changes in the stimulus
% (Dayan & Abbott, Eq. 4.6, pg. 126):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Hnoise = zeros(nVoxels,1);
for s = 1:nConds
    for r = R
        % probability of stimulus S -- assuming each stimulus
        % occurs with equal probability
        % (may need to generalize later):
        Ps = 1/nConds; 

        % binary matrix identifying elements w/ response level r
        B = (A==r); 
        
        % conditional probability of response r given stimulus s:
        subData = B(:,s,:);
        Pr1s = sum(subData,3) ./ nTrials;
        
        % to avoid "Warning: Log of zero" messages,
        % replace 0 values in Pr1s with very, very small values:
        Pr1s(Pr1s==0) = 1^-10;
        
        % sum up noise entropy across r,s
        Hnoise = Hnoise - Ps.*Pr1s.*log2(Pr1s);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lastly: subtract Hnoise from H to get mutual information
% for each voxel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Im = H - Hnoise;

% let's also 'mask out' voxels which produce NaN mutual information:
% this is likely due to log-of-zero considerations resulting from
% their being lousy voxels, so set the mutual inf to zero:
Im(isnan(Im)) = 0;

% append the results to an output struct in mv
mv.mutualInf.Im = Im;
mv.mutualInf.thresh = thresh;
mv.mutualInf.binnedResponses = A;
mv.mutualInf.responseBins = R;

return

