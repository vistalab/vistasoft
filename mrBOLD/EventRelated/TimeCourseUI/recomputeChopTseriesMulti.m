function anal = recomputeChopTseriesMulti(tSeries);
% anal = recomputeChopTseriesMulti(tSeries);
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
if nargin < 2
    useDefaults = 0;
end
defaults{1} = num2str(tc.timeWindow);
defaults{2} = num2str(tc.bslPeriod);
defaults{3} = num2str(tc.peakPeriod);
defaults{4} = num2str(tc.settings.alpha);
defaults{5} = num2str(tc.settings.onsetDelta);
defaults{6} = num2str(tc.settings.snrConds);
defaults{7} = num2str(tc.settings.glmHRF);
defaults{8} = num2str(tc.settings.normBsl);

if useDefaults==0
	prompt{1} = 'Time Window, in seconds (incl. pre-stimulus onset period):';
	prompt{2} = 'Baseline Period, in seconds:';
	prompt{3} = 'Peak Period, in seconds:';
	prompt{4} = 'Alpha for significant activation (peak vs baseline):';
	prompt{5} = 'Shift onsets relative to time course, in seconds:';
    prompt{6} = 'Use which conditions for computing SNR?';
    prompt{7} = 'HRF to use for GLM? (0 = Boynton gamma, 1 = avg TC for ROI):';
	prompt{8} = 'Normalize all trials during the baseline period? (0 for no, 1 for yes)';
	
	AddOpts.Resize = 'on';
	AddOpts.Interpreter = 'tex';
	AddOpts.WindowStyle = 'Normal';
	answers = inputdlg(prompt,'Re-chop tSeries Settings...',1,defaults,AddOpts);
else
    answers = defaults;
end

% exit if cancel is selected
if isempty(answers)
    return;
end

% parse the user responses / defaults
twin = str2num(answers{1});
bsl = str2num(answers{2});
peak = str2num(answers{3});
alpha = str2num(answers{4});
onsetDelta = str2num(answers{5});
snrConds = str2num(answers{6});
glmHRF = str2num(answers{7});
normBsl = str2num(answers{8});


anal = er_chopTSeries2(tc.wholeTc,tc.trialInfo,'timeWindow',twin,...
                       'bslPeriod',bsl,'peakPeriod',peak,...
                       'alpha',alpha,'onsetDelta',onsetDelta,...
                       'snrConds',snrConds,'normBsl',normBsl);
                   
% assign over to tc struct (ugly, but there are other fields
% in tc I don't want to erase -- is there a way to eat the whole
% struct in one go?)
tc.wholeTc = anal.wholeTc;
tc.allTcs = anal.allTcs;
tc.meanTcs = anal.meanTcs;
tc.sems = anal.sems;
tc.timeWindow = anal.timeWindow;
tc.peakPeriod = anal.peakPeriod;
tc.bslPeriod = anal.bslPeriod;
tc.Hs = anal.Hs;
tc.ps = anal.ps;
tc.amps = anal.amps;
tc.relamps = anal.relamps;
tc.SNR = anal.SNR;
tc.SNRdb = anal.SNRdb;
tc.settings.alpha = alpha;
tc.settings.onsetDelta = onsetDelta;
tc.settings.snrConds = snrConds;
tc.settings.glmHRF = glmHRF;
tc.settings.normBsl = normBsl;

% update dataTYPES parameters for these scans
if isfield(tc.params,'viewName') 
	mrGlobals;
    tmp = findstr('{',tc.params.viewName);
    varName = tc.params.viewName(1:tmp(1)-1);
    if exist(varName,'var')
        view = eval(tc.params.viewName);
        
		settings.timeWindow = anal.timeWindow;
		settings.peakPeriod = anal.peakPeriod;
		settings.bslPeriod = anal.bslPeriod;
		settings.normBsl = normBsl;
		settings.alpha = alpha;
		settings.onsetDelta = onsetDelta;
		settings.glmHRF = glmHRF;
		
		for s = tc.params.scans
            er_setParams(view,settings,s);
        end
    end
end

% assign back to the UI and refresh
set(gcf,'UserData',tc);
timeCourseUI;

return
