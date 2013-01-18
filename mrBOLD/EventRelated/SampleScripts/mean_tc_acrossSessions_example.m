% mean ROI tcs across all sessions
%
% kgs 1/2007
clear all
% for PC: 
expDir = ('y:\RAID\projects\Kids\fmri\adolescents');
% for linux: 
%expDir='/biac1/kgs/projects/Kids/fmri/adolescents';


sessions = { 'ar_12yo_011908' 'is_16yo_121607' 'kwl_14yo_011208' 'dw_14yo_102707'};  
roi=      {'lPPA_IOvsOJ_p3' 'lPPA_IOvsOJ_p3' 'lPPA_IOvsOJ_p3' 'lPPA_IOvsOJ_p3'};

%% data type:
dt =    [4 3 4 3]; % motion corrected both within and between
%  scan number
scan = [7 8 8 8]; % 
nsbj=length(sessions);

% get some basic params from first session e.g. eventParams 
cd( fullfile(expDir, sessions{1}) );
fprintf('*** Session 1 *** \n', sessions{1});
% initialize hidden inplane
hI = initHiddenInplane(dt(1), scan(1));

% params is a struct in which i set the following fields the following fields:
params.dataType=dt;
params.scan=scan;
params.studyDir=expDir;
params.viewType='INPLANE';

% enforce all analysis params to be the same
params.eventParams  = er_getParams(hI);


params.eventParams.ampType='difference'; % params.eventParams.ampType can be one of the following: 
                                        % 'difference' or 'betas' or 'relamps' or 'deconvolved';
                                        % this field specifies which amptype will be plotted in the meanamps plot
                                        % and which amps will be calculated in the tc.allMeanAmps and tc.meanAmps
params.eventParams.peakPeriod=[4:12];

params.methodFlag=4; % method to combine Tcs across subjects; Across-sessions analysis ("random effects")
                     % Note that the function tc_acrossSessions
                     % first generates the subjectTcs array which is a
                     % structure array of individual subjects tc
                     % and then calls tc_combineTcs to calculate the across
                     % subject average; Check tc_combineTcs to learn about
                     % methods to combine data across subjects
                     
params.openUI=1; % 1 to open TC UI with average time course across subjects
                 % will open a left panel with mean amps according to params.eventParams.ampType field
                 % and a right panel with the event trigged average time
                 % course (except if
                 % params.eventParams.ampType='deconvolved' in that case
                 % will show the mean deconvolved time course

% set glm and analysis params to be the same across sessions
params.eventParams.detrend = 1; % high-pass filter (low-pass is blurring, below)
params.eventParams.inhomoCorrection = 1; % divide by mean
params.eventParams.temporalNormalization = 0; % no matching 1st temporal frame

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set HRF function to be the GLM SPM HRF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params.eventParams.glmHRF = 3; % 
% number of events per block
params.eventParams.eventsPerBlock = 6; % see above

params.sessionPlots={'betas' 'meanAmps' 'meantcs'}; % single subject plots - see all options in tc_sessionPlots
params.savePlotsPath='Images';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop across sessions
% returns mean tc across subject in the tc variable
% and structure array containing single subject tcs in subjectTcs
% calls tc_combineTcs and tc_sessionPlots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[tc subjectTcs] = tc_acrossSessions(sessions, roi, params);
