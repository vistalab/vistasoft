function tc_plotWholeTc(tc, parent);
% tc_plotWholeTc(tc, <parent=tc.ui.plot panel>);
%
% timeCourseUI (mrLoadRet):
% plots the mean time course across the entire selected scans,
% designating different condition periods / half-cylces with different
% colors. Everything's specified in the tc struct.
%
% 02/23/04 ras: broken off as a separate function (previously kept in
% ras_tc).
% 03/06 ras: integrated uipnanel changes.
if nargin<1,    tc = get(gcf,'UserData');     end
if nargin<2,    parent = tc.ui.plot;          end
if parent==gcf 
    % make a uipanel to fit on the target
    parent = uipanel('Parent', gcf, ...
                     'Units', 'normalized', ...
                     'BackgroundColor', get(gcf, 'Color'), ...
                     'Position', [0 0 1 1]);
	axes('Parent', parent);				 
end

set(gca, 'Units', 'norm', 'Position', [.1 .2 .6 .5]);

% set axis bounds to a nice default
plot(tc.wholeTc); % just to get axis bounds
axis tight; axis auto;
if isfield(tc.params,'axisBounds') & ~isempty(tc.params.axisBounds)
    axis(tc.params.axisBounds);
end
AX = axis;

cla;
hold on
condNums = unique(tc.trials.cond);

% shift onsets by a specified delta, if it exists 
% (this is useful e.g. if the n discarded frames is incorrectly
% specified, or to compensate for h.r.f. rise time)
if isfield(tc.params,'onsetDelta') & tc.params.onsetDelta ~= 0
    tc.trials.onsetSecs = tc.trials.onsetSecs + tc.params.onsetDelta;
end

% trial boundaries
tx = [tc.trials.onsetSecs length(tc.wholeTc)*tc.TR]; 

% make patches for the different trial conditions
for i = 1:length(tx)-1
    t1 = tx(i);
    t2 = tx(i+1);
    X = [t1 t1 t2 t2];
    Y = [AX(3) AX(4) AX(4) AX(3)];
    cond = tc.trials.cond(i);
    ind = find(condNums==cond);
    C = tc.trials.condColors{ind};
    if isunix
        patch(X,Y,C);
    else
        patch(X,Y,C); %,'EdgeAlpha',0);
        if length(tc.trials.condNames)==1
            patch(X,Y,C,'EdgeAlpha',1);
        end    
    end
end

% plot the time course over the patches
t = [1:length(tc.wholeTc)] .* tc.TR;
plot(t,tc.wholeTc, 'LineWidth', 4, 'color', 'w'); 
ylabel('% Signal');
xlabel('Time, secs');
set(gca, 'Box', 'off');

% for longer time courses, may want a UI control
scale = 300;  % max seconds to nicely plot TC
scrollbar(gca, scale);

return

