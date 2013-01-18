%% t_glmRun
%
% Illustrates how to run a GLM on a functional data set.
%
% Tested 01/04/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
parfDir = fullfile(dataDir, 'Stimuli', 'parfiles');

% You must analyze with the matlab directory in the data directory.
curDir = pwd;   % We will put you back where you started at the end
chdir(dataDir);

% There can be several data types - we're using motion compensated dated
dataType = 'MotionComp';

%% Get data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Prepare scans for GLM

numScans = viewGet(vw, 'numScans');
whichScans = 1:numScans;

% If you're processing your own experiment, you'll need to produce parfiles
% More info @
% http://white.stanford.edu/newIm/index.php/GLM#Create_.par_files_for_each_scan
whichParfs = {'VWFALocalizer1.par' ...
              'VWFALocalizer2.par' ...
              'VWFALocalizer3.par'};

vw = er_assignParfilesToScans(vw, whichScans, whichParfs); % Assign parfiles to scans
vw = er_groupScans(vw, whichScans, [], dataType); % Group scans together

%% Set GLM Parameters:
% The GLM parameters are stored in a Matlab structure.
% We call the structure params.
% The parameters, such as params.timeWindow inform the GLM processing
% routine about the experiment.
% 
% A description of the parameters can be found on the wiki at:
%
% http://white.stanford.edu/newlm/index.php/MrVista_1_conventions#eventAnalysisParams
params.timeWindow               = -8:24;  %
params.bslPeriod                = -8:0;   % 
params.peakPeriod               = 4:14;   %
params.framePeriod              = 2;      % TR
params.normBsl                  = 1;
params.onsetDelta               = 0;
params.snrConds                 = 1;
params.glmHRF                   = 2;
params.eventsPerBlock           = 6;
params.ampType                  = 'betas';
params.detrend                  = 1;
params.detrendFrames            = 20;
params.inhomoCorrect            = 1;
params.temporalNormalization    = 0;
params.glmWhiten                = 0;

saveToDataType = 'GLMs'; % Data type the results will be saved to

%% Run GLM:
% Returns view structure and saved-to scan number in new data type
[vw, newScan] = applyGlm(vw, dataType, whichScans, params, saveToDataType);

% newScan indicates the scan # in which results are saved
% vw is a mrVista view structure.  If you just type vw, you will see a lot
% of the fields.  In this case, many of them are empty.  To understand what
% the fields can represent, see the vistalab wiki re: GLMs.

%% To delete the new GLM run:
removeScan(vw, newScan, saveToDataType, 1);

%% END











