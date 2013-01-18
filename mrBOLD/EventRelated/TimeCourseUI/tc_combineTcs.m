function tc = tc_combineTcs(tcs, methodFlag);
%
% tc = tc_combineTcs(tcs, <methodFlag=4>);
%
% Combine multiple Time Course UI structs into a single combined struct.
%
% The input tcs argument can be a struct array or cell-of-structs of tc
% structures. The code will combine them in an output tc struct,
% using multiple methods, depending on how much the input tcs have in
% common, set by the methodFlag:
%
%   methodFlag=1: Average the whole time courses together. This will only
%                 work if the condition order is the same for each tc.
%                 It will produce a tc struct with the same number of
%                 trials per condition as the input tcs.
%
%              2: Concatenate whole time courses together, and re-chop.
%              Basically is a "fixed effects analysis" of the concatenated
%              tc across all subjects.
%              Mean and sems will be computed based on all individual
%              events (number subjects x number of events per subject).
%              For example, if tc.params.ampType='betas' will estimate one
%              beta per condition across the entire concatenated (whole) time
%              course across all subjects.
%              There will be a wholeTc field in the output tc struct.
%
%              3: Combine via allTcs. Rory- please clarify.
%              This will work as long as each input
%              tc has the same set of conditions, and will produce a tc
%              struct with [# input tcs] * [# trials/condition] total
%              trials per condition. When combining, this reduces the
%              number of trials according to the non-null trials for each
%              input tc, throwing out some null trials, but minimizing the
%              footprint of the output tc (a lot of padded NaNs are avoided
%              as well; see er_chopTSeries2).
%
%              4: Across-sessions analysis. Basically does a "random effects analysis"
%               First derives meantcs and meanamps for each subject and
%               then calculates the across subject mean responses and sems.
%               E.g, if tc.params.ampType='betas' will first estimate the betas for each subject
%               and then calculate the mean betas (and sems) across subjects.
%               The wholeTc field is concatenated across tcs, as for method 2, but the other
%               fields reflect differences in the mean response across
%               sessions. meanTcs is the mean of the meanTcs fields, while
%               sems is the standard error between the meanTcs fields of each
%               input tc. Also adds 'meanAmps' and 'semAmps' fields, which
%               reflect, respectively, the mean amplitudes for each
%               condition across inputs, and the SEM. These amplitudes,
%               use the tc.params.ampType field which can be
%               'difference'(peak-bsl); 'betas' 'relamps' or 'deconvolved';
%               In contrast the 'amps' field, always reflects the
%               peak-bsl ('difference') amps from the event triggered
%               average
%
%                tc.allMeanTcs(:,:,subject) => contains the mean tc per
%                condition across the time window per subject
%                tc.allMeansAmps(subject,:) => contains the mean amp per
%                condition per subject; amps willl be calculated according
%                to tc.params.ampType field
%                tc.meanAmps= across subject mean Amps
%                tc.semAmps=sem across subject Amps
%                tc.meanTcs=mean TCs across subjects
%                tc.sems = sems across subjects of the tc data
% ras, 08/02/06
% ras; kgs; kw; 03/08 fixed method 4 to first estimate params per subject and
% then average across subjects
% also added the deconvolution option
%
if notDefined('methodFlag'), methodFlag = 4; end

% for cell arrays, allow for some empty entries (this helps some scripts
% run)
if iscell(tcs), tcs = tcs( cellfind(tcs) ); end

% initialize output tc w/ first input tc
if iscell(tcs), tc = tcs{1}; else, tc = tcs(1); end

%% check for a consistent temporal resolution across tcs
% Some may come from sessions with different sampling rates. Auto-adjust if
% needed.
for ii = 2:length(tcs)
	if iscell(tcs), currTc = tcs{ii}; else, currTc = tcs(ii); end	
	if currTc.TR ~= tc.TR
		if prefsVerboseCheck
			fprintf('[%s]: Resampling time course %s to TR = %2.1f\n', ...
					mfilename, tc.params.sessionCode, tc.TR);
		end
		currTc = tc_resample(currTc, tc.TR);
	end
	if iscell(tcs), tcs{ii} = currTc; else, tcs(ii) = currTc; end		
end
	
%% main section: combine according to the specified method
switch methodFlag
	case 1, % average wholeTc fields
		for ii = 2:length(tcs)
			if iscell(tcs), currTc = tcs{ii}; else, currTc = tcs(ii); end
			tc.wholeTc = [tc.wholeTc; currTc.wholeTc];
		end
		tc.wholeTc = mean(tc.wholeTc, 1);
		tc = tc_recomputeTc(tc, 1);

	case 2,  % concatenate wholeTc field together "fixed effects"
		tc = concatenateTcs(tc, tcs);

	case 3,  % combine allTcs fields
		tc = combineAllTcs(tc, tcs);

	case 4,  % across-sessions analysis
		tc = acrossSessionAverages(tc, tcs);

	otherwise,
		error('Unknown method flag.')
end

% set the session code to reflect all sessions
tc.params.sessionCode = 'Combined';
if iscell(tcs)
	for i = 1:length(tcs)
		tc.params.sessions{i} = tcs{i}.params.sessionCode;
	end
else
	for i = 1:length(tcs)
		tc.params.sessions{i} = tcs(i).params.sessionCode;
	end
end


return
% /----------------------------------------------------------/ %



% /----------------------------------------------------------/ %
function tc = acrossSessionAverages(tc, tcs)
%% "Standard" method for combining across-session data:
%% first compute mean time courses / amplitudes within each tc struct,
%% then combined tc structs. This adds some fields that are not added with
%% the other methods: tc.allMeanTcs, tc.allMeanAmps
%% (see main help for details)

% don't concatenate 1st run twice, so reset all these values
tc.wholeTc = [];
tc.trials.run = [];
tc.trials.onsetSecs =[];
tc.trials.onsetFrames =[];
tc.trials.cond=[];
tc.trials.label=[];
tc.trials.color=[];
tc.trials.parfiles=[];
tc.trials.framesPerRun=[];

for ii = 1:length(tcs)  
	if iscell(tcs), currTc = tcs{ii}; else, currTc = tcs(ii); end

	tc.wholeTc = [tc.wholeTc currTc.wholeTc];

    if ii==1, onsetSecs = currTc.trials.onsetSecs; else, onsetSecs = currTc.trials.onsetSecs + tc.trials.onsetSecs(end); end
	if ii==1, onsetFrames = currTc.trials.onsetFrames; else, onsetFrames = currTc.trials.onsetFrames + tc.trials.onsetFrames(end); end
	cond = currTc.trials.cond;
	label = currTc.trials.label;
	color = currTc.trials.color;
	run = currTc.trials.run;
	parfiles = currTc.trials.parfiles;
	framesPerRun = currTc.trials.framesPerRun;

	% for the run field, we want each session's runs to be unique
	if ii==1, tc.trials.run = currTc.trials.run; else, tc.trials.run = [tc.trials.run run + max(tc.trials.run)]; end
	tc.trials.onsetSecs = [tc.trials.onsetSecs onsetSecs];
	tc.trials.onsetFrames = [tc.trials.onsetFrames onsetFrames];
	tc.trials.cond = [tc.trials.cond cond];
	tc.trials.label = [tc.trials.label label];
	tc.trials.color = [tc.trials.color color];
	tc.trials.parfiles = [tc.trials.parfiles parfiles];
	tc.trials.framesPerRun = [tc.trials.framesPerRun framesPerRun];

	% special case: for the deconvolution option, use the
	% deconvolved time courses as the meanTc estimate:
	if currTc.params.glmHRF==0 %'deconvolve'
		if ~isfield(currTc, 'glm'), currTc = tc_applyGlm(currTc); end
		% add a blank condition at the beginning betas are zero
		% because this is the baseline to which the glm is
		% estimated
		currTc.meanTcs = [zeros(currTc.glm.nh, 1) currTc.glm.betas];
	end

	meanTcs(:,:,ii) = currTc.meanTcs;
	allAmps(ii,:) = tc_amps(currTc);
end

% make modifications to make the errors between input sessions,
% rather than a large joint analysis
nTcs = length(tcs);

tc.meanAmps = mean(allAmps, 1);
tc.semAmps = std(allAmps, [], 1) ./ sqrt(nTcs - 1);
tc.meanTcs = nanmean(meanTcs, 3);
tc.sems = nanstd(meanTcs, [], 3) ./ sqrt(nTcs - 1);
tc.allMeanTcs = meanTcs;
tc.allMeanAmps = allAmps;

% let's also make the plotting use the
% across-subjects ("random effects") amplitudes
tc.amps = [zeros(length(tcs), 1) allAmps];

% one more special case: for particular types of amplitude
% estimates, we signal the plotting code that the y axis isn't the
% mean amplitude.
if isequal(lower(tc.params.ampType), 'betas')
	tc.params.ampType = 'meanbetas';
end
if isequal(lower(tc.params.ampType), 'deconvolved')
	tc.params.ampType = 'meandeconvolved';
end

return
% /----------------------------------------------------------/ %



% /----------------------------------------------------------/ %
function tc = combineAllTcs(tc, tcs);
%% combine time courses according to the 'allTcs' field.
for ii = 2:length(tcs)
	if iscell(tcs), currTc = tcs{ii}; else, currTc = tcs(ii); end

	% an intervention to save space:
	% the allTcs matrix is of size time points x trials x
	% conditions, where the # of columns is the max trials per
	% condition. This is generally 0, the null trials, which have a
	% lot, but are infrequently analyzed. For now, clip the columns
	% to the max non-null trials.
	N = 1;
	for cond = find(currTc.trials.condNums>0)
		[rows cols] = find(isnan(currTc.allTcs(:,:,cond)));
		N = max(N, length(unique(cols)));
	end
	tc.allTcs = cat(2, tc.allTcs(:,1:N,:), currTc.allTcs(:,1:N,:));
end

% re-chop
TR = tc.params.framePeriod;
frameWindow = unique(round(tc.params.timeWindow./TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(tc.params.peakPeriod./TR));
bslFrames = unique(round(tc.params.bslPeriod./TR));
peakFrames = find(ismember(frameWindow, peakFrames));
bslFrames = find(ismember(frameWindow, bslFrames));

condNums = unique(trials.cond(trials.cond >= 0));
nConds = length(condNums);

tc.meanTcs = zeros(length(frameWindow), nConds);
tc.sems = zeros(length(frameWindow), nConds);
maxNTrials = size(allTcs,2);

for i = 1:nConds
	nTrials = size(tc.allTcs, 2) - sum(any(isnan(tc.allTcs(:,:,i))));
	if maxNTrials > 1
		tc.meanTcs(:,i) = nanmean(tc.allTcs(:,:,i)')';
		tc.sems(:,i) = nanstd(tc.allTcs(:,:,i)')' ./ sqrt(nTrials);
	else
		tc.meanTcs(:,i) = allTcs(:,:,i);
	end
end

%%%%% calc amplitudes, do t-tests of post-baseline v. baseline
Hs = NaN*ones(1,nConds);

for i = 1:nConds
	bsl = tc.allTcs(bslFrames,:,i);
	peak = tc.allTcs(peakFrames,:,i);
	tc.amps(:,i) = (mean(peak) - mean(bsl))';
end

return
% /----------------------------------------------------------/ %



% /----------------------------------------------------------/ %
function tc = concatenateTcs(tc, tcs);
%% concatenate the wholeTcs field together across tcs, then re-analyze the
%% whole thing as though it were a single long time course.
for ii = 1:length(tcs)
	if iscell(tcs), currTc = tcs{ii}; else, currTc = tcs(ii); end

	tc.wholeTc = [tc.wholeTc currTc.wholeTc];

	onsetSecs = currTc.trials.onsetSecs + tc.trials.onsetSecs(end);
	onsetFrames = currTc.trials.onsetFrames + tc.trials.onsetFrames(end);
	cond = currTc.trials.cond;
	label = currTc.trials.label;
	color = currTc.trials.color;
	run = currTc.trials.run;
	parfiles = currTc.trials.parfiles;
	framesPerRun = currTc.trials.framesPerRun;

	% for the run field, we want each session's runs to be unique
	tc.trials.run = [tc.trials.run run + max(tc.trials.run)];
	tc.trials.onsetSecs = [tc.trials.onsetSecs onsetSecs];
	tc.trials.onsetFrames = [tc.trials.onsetFrames onsetFrames];
	tc.trials.cond = [tc.trials.cond cond];
	tc.trials.label = [tc.trials.label label];
	tc.trials.color = [tc.trials.color color];
	tc.trials.parfiles = [tc.trials.parfiles parfiles];
	tc.trials.framesPerRun = [tc.trials.framesPerRun framesPerRun];
end

tc = tc_recomputeTc(tc, 1);

return
