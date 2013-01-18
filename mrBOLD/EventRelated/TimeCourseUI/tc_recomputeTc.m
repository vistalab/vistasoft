function tc = tc_recomputeTc(tc,useDefaults);
% tc = tc_recomputeTc(tc,[useDefaults]);
%
% For time course UI, put up a dialog to get
% parameters such as baseline period, peak period,
% onsetDelta, etc., for chopping up a tSeries 
% according to condition onsets, then re-chop up
% the time course and add it back to the UI.
%
% If the optional useDefaults flag is set to 1 (default
% 0), then it will forego the dialog and just recompute with
% the default values.
%
% 07/04 ras.
% 06/06 ras: uses er_editParams now.
if nargin < 2
    useDefaults = 0;
end

mrGlobals;


% update dataTYPES parameters for these scans
if useDefaults==0 & exist(fullfile(HOMEDIR, 'mrSESSION.mat'), 'file')
    hV = eval(sprintf('initHidden%s',tc.roi.viewType));
    hV = selectDataType(hV, tc.params.dataType);
    hV = setCurScan(hV, tc.params.scans(1));
    params = er_editParams(tc.params, tc.params.dataType, tc.params.scans);
    er_setParams(hV, params);
else
    params = tc.params;
end

% assign to tc struct
tc.params = mergeStructures(tc.params, params);

anal = er_chopTSeries2(tc.wholeTc,tc.trials,tc.params);
       
% assign over to tc struct
tc = mergeStructures(tc, anal);

% re-apply the GLM if needed
if isfield(tc, 'glm')
    tc = tc_applyGlm(tc);
end

% assign back to the UI and refresh
if checkfields(tc, 'ui', 'fig') & ishandle(tc.ui.fig)
    set(tc.ui.fig, 'UserData', tc);
    timeCourseUI;
end

return




% OLD CODE:
% 
% % try to get defaults from tc struct, otherwise use factory settings
% defaults{1} = num2str(tc.timeWindow);
% defaults{2} = num2str(tc.bslPeriod);
% defaults{3} = num2str(tc.peakPeriod);
% defaults{4} = num2str(tc.params.alpha);
% defaults{5} = num2str(tc.params.onsetDelta);
% defaults{6} = num2str(tc.params.snrConds);
% defaults{7} = num2str(tc.params.glmHRF);
% defaults{8} = num2str(tc.params.normBsl);
% 
% if useDefaults==0
% 	prompt{1} = 'Time Window, in seconds (incl. pre-stimulus onset period):';
% 	prompt{2} = 'Baseline Period, in seconds:';
% 	prompt{3} = 'Peak Period, in seconds:';
% 	prompt{4} = 'Alpha for significant activation (peak vs baseline):';
% 	prompt{5} = 'Shift onsets relative to time course, in seconds:';
%     prompt{6} = 'Use which conditions for computing SNR / HRF?';
%     prompt{7} = ['HRF to use for GLM? (0 = deconvolve, 1 = avg TC for ROI, ',...
%                  '2 = Boynton gamma; 3 = SPM difference-of-gammas; '...
%                  '4 = Dale & Buckner HRF): '];
% 	prompt{8} = 'Normalize all trials during the baseline period? (0 for no, 1 for yes)';
% 	
% 	AddOpts.Resize = 'on';
% 	AddOpts.Interpreter = 'tex';
% 	AddOpts.WindowStyle = 'Normal';
% 	answers = inputdlg(prompt,'Event-Related Analysis Parameters...',1,defaults,AddOpts);
% else
%     answers = defaults;
% end
% 
% % exit if cancel is selected
% if isempty(answers)
%     return;
% end
% 
% % parse the user responses / defaults
% params.timeWindow = str2num(answers{1});
% params.bslPeriod = str2num(answers{2});
% params.peakPeriod = str2num(answers{3});
% params.alpha = str2num(answers{4});
% params.onsetDelta = str2num(answers{5});
% params.snrConds = str2num(answers{6});
% params.glmHRF = str2num(answers{7});
% if isempty(params.glmHRF), params.glmHRF = answers{7}; end  % HRF file name
% params.normBsl = str2num(answers{8});
% 
