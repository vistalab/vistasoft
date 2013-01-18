function tc_plotGLMPredictors(tc);
% tc_plotGLMPredictors(tc): plot time course, along with 
% predictors used for each condition, scaled by the beta
% values obtained with the GLM.
%
%
% (Right now, I'm simply using the regress command to provide the 
% fit, once I've made the design matrix. This may in fact be a perfectly
% valid computation, but there may be more to it, also -- I'm checking.
% ras 07/27/04)
%
% 07/04 ras.
alpha = 0.05;
lineWidth = 0.5;

% create the design matrix
if tc.params.glmHRF==1
    % use the average selected time course as a predictor
    sel = tc_selectedConds(tc);
    hrf = mean(tc.meanTcs(:,find(sel)),2);
else 
    hrf = 'boynton';
end

tc.desMtx = er_createDesMtx(tc.trialInfo,hrf,length(tc.wholeTc));

% run the GLM (currently using regress command -- is this kosher?)
[B,BINT,R,RINT,STATS] = regress(tc.wholeTc',tc.desMtx,alpha);

% scale each predictor by the associated beta value
pred = tc.desMtx;
for i = 1:size(pred,2)
    pred(:,i) = B(i) .* pred(:,i);
end

% grab only the selected conditions' predictors
selConds = find(tc_selectedConds(tc));
pred = pred(:,selConds);

% add the time course at the end
pred = [pred tc.wholeTc'];

% construct colors for each trace
for i = 1:length(selConds)
    colors{i} = tc.condColors{selConds(i)};
end
colors{end+1} = 'k';

% plot the predictors and time course
render3DTraces(pred,colors);
view(0,0);
rotate3d;

% set line width
htmp = findobj('Type','line','Parent',gca);
set(htmp,'LineWidth',lineWidth);

% add labels
nConds = length(selConds);
for i = 1:nConds
    labels{i} = tc.condNames{selConds(i)};
end
set(gca,'XTick',[1:nConds],'XTickLabel',labels);
xlabel('Time, fMRI frames');
ylabel('Beta value, % Signal');

% add GLM results to tc struct
tc.glm.betas = B;
tc.glm.betaConfidenceIntervals = BINT;
tc.glm.residualVariance = R;
tc.glm.resConfidenceIntervals = RINT;
tc.glm.stats = STATS;
tc.glm.alpha = alpha;

set(gcf,'UserData',tc);

return