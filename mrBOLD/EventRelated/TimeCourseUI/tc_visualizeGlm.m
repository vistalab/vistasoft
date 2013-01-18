function tc = tc_visualizeGlm(tc, parent);
%
% tc = tc_visualizeGlm(tc, parent);
%
% Provide graphics that visualize the
% setup and result of applying a general
% linear model to a time course. Requires
% that you first run tc_applyGlm on
% the tc time course struct.
%
%
% ras 04/05.
if nargin<1,    tc = get(gcf,'UserData');     end
if nargin<2,    parent = tc.ui.plot;          end
if parent==gcf | parent==get(gcf, 'CurrentAxes')
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
        'Units', 'normalized', ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'Position', [0 0 1 1]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply a GLM if needed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(tc, 'glm')
    tc = tc_applyGlm(tc);
end
X = tc.glm.designMatrix;
Y = tc.wholeTc(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up existing objects in figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherAxes = findobj('Type', 'axes','Parent', parent);
delete(otherAxes);
otherUiControls = findobj('Type', 'uicontrol', 'Parent',parent);
delete(otherUiControls);
axes('Parent', parent); % shift focus to parent uipanel
delete(gca);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualize results: diff't options for deconvolved
% data and non-deconvolved (using HRF)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isequal(tc.glm.type, 'selective averaging')
    tc = tc_plotDeconvolvedTCs(tc, parent);
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if we got here, the GLM is non-deconvolved, using HRF   %
% show hemodynamic response function used for GLM         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes('Parent', parent, 'Position', [.05 .6 .15 .2]); % [.13 .58 .21 .34]
plot(tc.glm.hrf,'k','LineWidth',2);
if tc.params.grid==1
    grid on
end
xlabel('Time, frames')
ylabel('Arbitrary Units')
if isnumeric(tc.params.glmHRF)
    opts = {sprintf('Mean trial for conditions \n %s',num2str(tc.params.snrConds)), ...
        'Boynton gamma function', 'SPM difference-of-gammas' ...
        'Dale & Buckner ''97'};
    hrfName = opts{tc.params.glmHRF};
else
    hrfName = tc.params.glmHRF; hrfName(hrfName=='_') = ' ';
end
title({'HRF function used: ' hrfName}, 'FontWeight', 'bold')
axis tight, axis square, set(gca, 'Box', 'off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% show design matrix                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
axes('Parent', parent, 'Position', [.3 .55 .2 .34]); % [.13 .11 .21 .34]
hImg = imagesc(X);
colormap autumn
nConds = sum(tc.trials.condNums>0);
tickPts = [1:nConds];
tickLabels = {'Individual Conditions' 'DC Predictors for each run'};
set(gca,'XTick',tickPts);
xlabel('Predictors (Conditions + DC)')
ylabel('Time, Frames')
title('Design Matrix', 'FontWeight', 'bold')
set(hImg, 'ButtonDownFcn', 'zoom');
colorbar vert

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bar beta values for selected conditions %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes('Parent', parent, 'Position', [.6 .55 .33 .34]);  %[.57 .58 .33 .34]
sel = setdiff( find(tc_selectedConds(tc)), 1);
tmp = tc.trials.condColors(sel);
for i = 1:length(sel), col(i,:) = tmp{i}; end
xstr = tc_condInitials(tc.trials.condNames(sel));
% for i = 1:length(sel), xstr{i} = num2str(tc.trials.condNums(sel(i))); end
mybar(tc.glm.betas(sel-1), tc.glm.sems(sel-1), xstr, [], col);
% xlabel Predictors
% ylabel('% Signal Change')
set(gca, 'Box', 'off');
if tc.params.grid, grid on; else grid off; end
title('Beta Values', 'FontWeight', 'bold');
ylabel('\beta', 'FontWeight', 'bold', 'Rotation', 0, 'FontSize', 14);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% show time course + selected predictors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if tc.params.legend, ysz = .58; else ysz = .72; end
tc.glm.tcAxes = axes('Parent', parent, 'Position', [.1 .1 ysz .3]); 

% construct matrix of predictor functions for each condition:
% (these predictors will include the dc components as well, so we 
% won't have them as separate traces):
dc = nConds+1:size(tc.glm.betas, 2);  % indices of DC components
for c = 1:nConds
	predictors(:,c) = X(:,[c dc]) * [tc.glm.betas(:,[c dc])'];
end

% plot
t = [1:length(tc.wholeTc)] .* tc.TR;
hold on
hY = plot(t, tc.wholeTc(:), 'k-', 'LineWidth', 2);
hPred = plot(t, predictors(:,sel-1), 'LineStyle', '-', 'LineWidth', 1.5);
hTot = plot(t, X*tc.glm.betas', 'k-', 'LineWidth', 2); 
hRes = plot(t, tc.glm.residual(:), 'k--', 'LineWidth', 1.5);
plot(t, zeros(size(t)), 'k:');
set(hPred, 'Visible', 'off');
set(hRes, 'Visible', 'off');
set(gca, 'Box', 'off');
if tc.params.grid, grid on; else grid off; end
setLineColors([{'k'} tc.trials.condColors(sel) {[.2 .4 .8] [.8 0 0]}]);
xlabel('Time, sec')
ylabel('% Signal')
title('Time course + Scaled Predictors', 'FontWeight', 'bold')
zoom

% for longer time courses, may want a UI control
% scrollbar(tc.glm.tcAxes, tc.wholeTc);
scale = 300;  % max seconds to nicely plot TC
scrollbar(gca, scale);

% create toggles for the different traces
if tc.params.legend, xx = .72; else xx = .9; end
cb = ['tmp = {''off'' ''on''}; val = get(gcbo, ''Value'')+1; ' ...
      'set(get(gcbo,''UserData''), ''Visible'', tmp{val}); ' ...
      'clear tmp val '];
  
h3 = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
               'Position', [xx .4 .08 .04], 'String', 'Time Course', ...
               'BackgroundColor', 'w', 'UserData', hY, ...
               'Value', 1, 'Callback', cb);
h4 = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
               'Position', [xx .32 .08 .04], 'String', 'Predictors', ...
               'BackgroundColor', 'w', 'UserData', hPred, ...
               'Value', 0, 'Callback', cb);
h5 = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
               'Position', [xx .24 .08 .04], 'String', 'Best Fit', ...
               'BackgroundColor', 'w', 'UserData', hTot, ...
               'Value', 1, 'Callback', cb);
h6 = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
               'Position', [xx .16 .08 .04], 'String', 'Residual', ...
               'BackgroundColor', 'w', 'UserData', hRes, ...
               'Value', 0, 'Callback', cb);

% lastly, show % variance explained
varEx = sprintf('%2.1f%% Variance Explained', tc.glm.varianceExplained * 100);
uicontrol('Style', 'text', 'Units', 'normalized', ...
          'Position', [xx-.1 .08 .18 .04], 'String', varEx, ...
          'BackgroundColor', 'w','FontSize', 15);
           
return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function tc = tc_plotDeconvolvedTCs(tc, parent)
% plot the deconvolved time courses in the same way as for the
% default plot, combining mean amplitudes on one side and mean time
% courses on the other.
sel = find(tc_selectedConds(tc));
% sel = sel(sel>1); % no baseline estimated
nConds = length(sel);
frameWindow = unique(round(tc.timeWindow./tc.TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(tc.peakPeriod./tc.TR));
bslFrames = unique(round(tc.bslPeriod./tc.TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));

%%%%%%%%%%%%%%%%%%%%%%%%
% plot mean amplitudes %
%%%%%%%%%%%%%%%%%%%%%%%%
axes('Position', [.1 .2 .35 .6], 'Parent', parent);
% exp7_plotAmps(tc);
hold on

h1 = gca;

lineWidth = 2;
labels = {};

colors = tc.trials.condColors(sel);
X = tc.trials.condNums(sel);
Y = tc.glm.amps(sel-1);
E = tc.glm.amp_sems(sel-1);
mybar(Y, E, tc_condInitials(tc.trials.condNames(sel)), [], colors);
axis tight
set(gca, 'Box', 'off')
if tc.params.grid==1
    grid on
end

% set line width
htmp = findobj('Type','line','Parent',gca);
set(htmp,'LineWidth',lineWidth);

% add labels
set(gca,'XTick',[1:nConds]);
if tc.params.legend==0, set(gca, 'XTickLabel', labels); end
xlabel('Condition', 'FontWeight', 'bold', 'FontAngle', 'italic');
ylabel('Mean Amplitude, % Signal', 'FontWeight', 'bold', ...
    'FontAngle', 'italic');
title('Deconvolved Amplitudes', 'FontWeight', 'bold');

% set axes to frame bars nicely
% axis auto;
AX = axis;
AX(1:2) = [0 nConds+1];
if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
    AX(3:4) = tc.params.axisBounds(3:4);
end
axis(AX);

%%%%%%%%%%%%%%%%%%%%%
% mean time courses %
%%%%%%%%%%%%%%%%%%%%%
h2 = axes('Position', [.5 .2 .4 .6], 'Parent', parent);
hold on

for i = sel-1
    htmp = errorbar(tc.timeWindow, tc.glm.betas(:,i), tc.glm.sems(:,i));
    set(htmp, 'Color', tc.trials.condColors{i+1}, 'LineWidth', 2);
end

% indicate the peak and baseline periods, if selected
if tc.params.showPkBsl==1
    AX = axis;
    plot(tc.bslPeriod, repmat(AX(3),size(tc.bslPeriod)), ...
        'k', 'LineWidth', 3.5);
    plot(tc.peakPeriod, repmat(AX(4),size(tc.peakPeriod)), ...
        'r', 'LineWidth', 3.5);
end

if tc.params.grid==1
    grid on
end

if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
    axis(h2, tc.params.axisBounds);
end

xlabel('Trial time, secs', 'FontWeight', 'bold', 'FontAngle', 'italic');
ylabel('% Signal', 'FontWeight', 'bold', 'FontAngle', 'italic');
title('Deconvolved Time Courses', 'FontWeight', 'bold');

AX = axis;
txt = sprintf('Variance Explained: %3.1f%%', 100*tc.glm.varianceExplained);
text(AX(1) + .1*diff(AX(1:2)), AX(3) + .9*diff(AX(3:4)), txt, ...
           'FontSize', 12, 'FontWeight', 'bold');

return


