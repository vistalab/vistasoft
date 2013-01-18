function tc = tc_applyGlm(tc);
%
% tc = tc_applyGlm(tc):
%
% Apply a general linear model to the current time course,
% and append the resulting glm struct to the tc struct.
%
% ras, 04/05.
if notDefined('tc')
    tc = get(gcf,'UserData');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Data Matrix Y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y = tc.wholeTc(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Predictors Matrix X 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now get the design matrix
[X, nh, hrf] = glm_createDesMtx(tc.trials, tc.params, Y, 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply the GLM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tc.glm = glm(Y, X, tc.TR, nh, tc.params.glmWhiten);
tc.glm.hrf = hrf;

% if deconvolving, also compute the amplitudes of
% the deconvolved time courses 
if isequal(tc.glm.type, 'selective averaging')
    tc = tc_deconvolvedAmps(tc);
end

% estimate the proportion variance explained
tc.glm.varianceExplained = 1 - var(tc.glm.residual(:)) / var(Y(:));
% pred =  [tc.glm.betas * X']';
% R = corrcoef(pred(:), Y(:));
% tc.glm.varianceExplained = R(2) ^ 2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add to fig's user data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(tc,'ui')
    set(gcf,'UserData',tc);
end


return
% /------------------------------------------------------------------/ %





% /------------------------------------------------------------------/ %
function tc = tc_deconvolvedAmps(tc)
% compute the peak-bsl amplitudes of deconvolved
% time courses (and relamps, when I implement that):

%%%%%% get params
frameWindow = unique(round(tc.params.timeWindow./tc.TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(tc.params.peakPeriod./tc.TR));
bslFrames = unique(round(tc.params.bslPeriod./tc.TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));


%%%%% norm baseline periods
nConds = size(tc.glm.betas, 2);

if tc.params.normBsl==1
    offset = mean(tc.glm.betas(bslFrames,:), 1);
    tc.glm.betas = tc.glm.betas - repmat(offset, [length(frameWindow) 1]);
end

%%%%% calc amplitudes
for i = 1:nConds
    bsl = tc.glm.betas(bslFrames, i);
    peak = tc.glm.betas(peakFrames, i);
    tc.glm.amps(:,i) = (nanmean(peak) - nanmean(bsl))';
    tc.glm.amp_sems(:,i) = nanmean(tc.glm.sems(:,i))';
end    

% % Some options for plotting the "HRF" at this point
% figure; plot(frameWindow,tc.glm.betas)
% [u s v] = svd(tc.glm.betas);  % if first component of u is large compared to others, then the mean will likely approximate the HRF well
% figure; plot(u(:,1))

return
