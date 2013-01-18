function tc = tc_plotGLMAmplitudes(tc);
% tc = tc_plotGLMAmplitudes(tc):
%
% (Time Course UI): Fit a General Linear Model to the time course in tc,
% and plot the amplitudes as % signal, +/- measure of goodness-of-fit 
% (such as % variance explained).
% 
% (Right now, I'm simply using the regress command to provide the 
% fit, once I've made the design matrix. This may in fact be a perfectly
% valid computation, but there may be more to it, also -- I'm checking.
% ras 07/27/04)
%
% 07/04 ras.
alpha = 0.05;
lineWidth = 1.5;

% create the design matrix
tc.desMtx = glm_createDesMtx(tc.trials);

% run the GLM (currently using regress command -- is this kosher?)
[B,BINT,R,RINT,STATS] = regress(tc.wholeTc',tc.desMtx,alpha);

% plot the betas
selConds = find(tc_selectedConds(tc));
for i = 1:length(selConds)
    cond = selConds(i);
    starbar(B(cond),BINT(cond,1),[],'X',i,'color',tc.condColors{cond});
end

% add GLM results to tc struct
tc.glm.betas = B;
tc.glm.betaConfidenceIntervals = BINT;
tc.glm.residualVariance = R;
tc.glm.resConfidenceIntervals = RINT;
tc.glm.stats = STATS;
tc.glm.alpha = alpha;

% set line width
htmp = findobj('Type','line','Parent',gca);
set(htmp,'LineWidth',lineWidth);

% add labels
nConds = length(selConds);
for i = 1:nConds
    labels{i} = tc.condNames{selConds(i)};
end
set(gca,'XTick',[1:nConds],'XTickLabel',labels);
ylabel('Beta value, % Signal');

axis auto;
AX = axis;
AX(1:2) = [0 nConds+1];
axis(AX);

set(gcf,'UserData',tc);

return