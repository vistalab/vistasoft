function tc = tc_visualizeCorAnal(tc, params, parent);
%
% tc = tc_visualizeCorAnal(tc, params, <parent=tc.ui.plot panel>);
%
% Apply a corAnal to an ROI time course, and visualize the
% results in the TCUI.
%
% params: struct w/ params for the corAnal:
%   nCycles: # of cycles per scan for the fitted sinusoid.
%   frames: frames to use from the wholeTc. Default: use all frames.
% Pops up a dialog if omitted.
%
% ras, 09/2005.
if notDefined('tc'), tc = get(gcf,'UserData'); end

if notDefined('params')
    if isfield(tc, 'corAnal')
        % we can use the existing corAnal
    else
        tc = tc_applyCorAnal(tc);
    end
else
    tc = tc_applyCorAnal(tc, params);
end

if notDefined('parent'),  parent = tc.ui.plot;                end
if parent==gcf | parent==get(gcf, 'CurrentAxes')
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
        'Units', 'normalized', ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'Position', [0 0 1 1])
end

nCycles = tc.corAnal.nCycles;
frames = tc.corAnal.frames;

%%%%%get the cor anal data
C = tc.corAnal;

%%%%%visualize the results
% delete existing objects in display
delete( findobj('Parent', tc.ui.plot) );

% show FFT, highlighting corAnal peak
tc = tc_plotFFT(tc,C.nCycles,[.12 .58 .3 .3]);
set(gca,'Box','off')

%%%%%plot amp, ph, and co values
% (we also check if there are polar angle retinotopy params defined,
% and if so, use it to match the angle to the estimated true polar angle)
subplot(222);
x = C.co .* cos(C.ph);
y = C.co .* sin(C.ph);

% check if retinotopy params have been set for this scan,
% and if so, and it's a polar angle scan, make it plot
% the expected polar angle:
try
    V = getCurView;
    p = retinoGetParams(V);
    if ~isempty(p) & isequal(p.type, 'polar_angle')
        disp('Setting Phase to match expected polar angle...')
        theta = polarAngle(C.ph, p)
        theta = -deg2rad( theta - 90 );
        x = C.co .* cos(theta);
        y = C.co .* sin(theta);
    end
    
catch
    % don't worry
end

params.grid = 'on';
params.line = 'off';
params.gridColor = [.4 .4 .4];
params.fontSize = 12;
params.symbol = 'o';
params.size = 5;
params.color = 'w';
params.fillColor = 'w';
params.maxAmp = 1;
params.ringTicks = [0:0.2:1];
polarPlot(0, params); 
h = plot(x, y, 'ro', 'MarkerSize', params.size);
set(h,'MarkerFaceColor','r')
title('Coherence Vs. Phase Polar Plot', 'FontSize', 14);
text(1, .5, sprintf('Co: %2.2f',C.co), 'FontWeight', 'bold');
text(1, .25, sprintf('Amp: %2.2f',C.amp), 'FontWeight', 'bold');
text(1, 0, sprintf('Ph: %2.2f rad (%2.2f deg)',C.ph, rad2deg(C.ph)), ...
    'FontWeight', 'bold');
if exist('p', 'var') & ~isempty(p) & isequal(p.type, 'polar_angle')
    text(1, -.25, '(Expected Polar Angle)', 'FontWeight', 'bold');
end

%%%%%plot mean 2 cycles (for clarity) and fitted predictor
subplot(223);
framesPerCycle = length(frames)/nCycles;
t = [1:framesPerCycle] .* tc.TR;
cycles = reshape(tc.wholeTc(frames),[framesPerCycle nCycles]);
meanCycle = mean(cycles,2);
semCycle = std(cycles,1,2) / sqrt(nCycles);
predCycle = mean(reshape(C.predictor,[framesPerCycle nCycles]),2);
hold on
errorbar(t,meanCycle,semCycle,'k-','LineWidth',2.5);
plot(t, predCycle, 'r', 'LineWidth', 1.5);
xlabel('Cycle time, sec','FontSize',14);
ylabel('% Signal','FontSize',14);
set(gca,'Box','off')
title('Mean Cycle + Predictor', 'FontSize', 14);

%%%%%%show time course + selected predictors
subplot(224);
t = [1:length(frames)] .* tc.TR;
hold on
plot(t, tc.wholeTc(frames), 'k-.', 'LineWidth', 2.5);
plot(t, C.predictor, 'r', 'LineWidth', 1.5);
xlabel('Time, sec','FontSize',14)
ylabel('% Signal','FontSize',14)
title('Time course + Scaled Predictor', 'FontSize', 14)
set(gca,'Box','off')

% for longer time courses, may want a UI control
scale = 300;  % max seconds to nicely plot TC
scrollbar(gca, scale);

return