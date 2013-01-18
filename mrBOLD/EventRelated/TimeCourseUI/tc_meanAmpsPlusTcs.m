function tc_meanAmpsPlusTcs(tc);
% tc_meanAmpsPlusTcs(tc);
%
% Provide a quick summary of ROI response
% to different conditions, by plotting both
% the mean time courses and mean amplitudes
% to each condition. Combines the
% routines from tc_plotMeanTrials and 
% tc_barMeanAmplitudes.
%
%
% ras 03/05.

% delete existing large legend
otherAxes = findobj('Parent', gcf, 'Type', 'axes');
delete(otherAxes);

%%%%%%%%%%%%%%%%%%%
% mean amplitudes %
%%%%%%%%%%%%%%%%%%%
axes('Parent', tc.ui.plot, 'Position',[.1 .2 .35 .6]);
hold on

h1 = gca;

tc_barMeanAmplitudes(tc, h1, 'difference');  % Rory prefers it this way

%%%%%%%%%%%%%%%%%%%%%
% mean time courses %
%%%%%%%%%%%%%%%%%%%%%
h2 = axes('Parent', tc.ui.plot, 'Position', [.55 .2 .4 .6]);
tc_plotMeanTrials(tc, h2, 2);


return

