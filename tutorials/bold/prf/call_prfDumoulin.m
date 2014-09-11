%% script to run Dumoulin prf analysis on Knk stimulus
% rl 08/2014

clear all; close all; clc; 

%% modify  --------------------------------------------------------------------------

% scan numbers to average over (scans which have bar/wedgering ret)
path_session = '/biac4/wandell/data/reading_prf/ariel/20140527_1008'; 
tem.barScans = [7]; 
tem.name = 'Wedgering15hz'; 

% datatype name to average over, if we don't have an average
% so this involves loading mrSESSION and checking through dataTYPES.name
% go for the one that is motion and sliced-timed corrected
tem.dtToAverage = 'Timed'; 

%% checking things here, no need to modify

% open the session
cd(path_session); 
vw = mrVista; 
load mrSESSION; 

% see if we have a dataTYPE named AveragesBars ...
match = false;
for ii = 1:length(dataTYPES)
    
    thisdt = dataTYPES(ii).name;
    if strcmpi(tem.name, thisdt), 
        match = true; 
        vw = viewSet(vw, 'current dt', thisdt); 
    end
    
end


% - if we haven't averaged over vista ret bar time series, do it here
if ~match
    % change to the datatype we want to be in to average
    vw = viewSet(vw, 'current dt', tem.dtToAverage);
    
    % average the time series
    averageTSeries(vw, tem.barScans, tem.name, 'Average of ret scans');
    
end

% - set dataNum to be that of tem.name
for ii = 1:length(dataTYPES)
    if strcmpi(dataTYPES(ii).name, tem.name)
        % dataNum is the datayTYPE number of tem.name
        dataNum = ii;
        vw = viewSet(vw, 'current dt', dataNum); 
    end
end

% if we have not xformed these time series in Gray, do it here
vol = mrVista('3');
vol = viewSet(vol, 'current dt', dataNum); 

if ~exist(['Gray/' tem.name '/TSeries/Scan1'], 'dir')
    tem.whichScans = viewGet(vw, 'current scan');
    vol = ip2volTSeries(vw, vol, tem.whichScans, 'linear'); 
end

% - check whether we have stimulus files
if ~exist('Stimuli', 'dir')
    error('There needs to be a directory called ''Stimuli'' within the project directory.');
end

fnames = dir('Stimuli/*.mat');
if isempty(fnames), error('We need a file of images and image sequence within Stimulu directory'); end


%% no need to modify: getting parameter values for prf model fit ----------------------

tem.nFrames             = mrSESSION.functionals(tem.barScans(1)).nFrames; 
tem.framePeriod         = mrSESSION.functionals(tem.barScans(1)).framePeriod; 
tem.totalFrames         = mrSESSION.functionals(tem.barScans(1)).totalFrames;  
tem.prescanDuration     = (tem.totalFrames - tem.nFrames)*tem.framePeriod; 

%% modify these: parameter values for prf model fit -------------------------------------
params.framePeriod      = tem.framePeriod;  % framePeriod
params.nFrames          = tem.nFrames;      % including clipped. mrSESSION.functionals.nFrames. will crash otherwise.
params.prescanDuration  = tem.prescanDuration; 

params.fliprotate       = [0 0 0]; 
params.stimType         = 'StimFromScan';
params.stimSize         = 6; 
params.stimWidth        = 90;               % wedgeDeg
params.stimStart        = 0;                % startScan
params.stimDir          = 0;                % probably referring to clockwise or counter clockwise, for now go with Jon's
params.nCycles          = 1;                % numCycles. going with params.mat but this seems largely different from Jon's (6)
params.nStimOnOff       = 0;                % going with Jon
params.nUniqueRep       = 1;                % going with Jon
params.nDCT             = 1;                % going with Jon

params.hrfType          = 'two gammas (SPM style)';
params.hrfParams        = {[1.6800 3 2.0500] [5.4000 5.2000 10.8000 7.3500 0.3500]}; % got this from Jon's wiki
params.imFile           = 'Stimuli/images_knk.mat'; 
params.imfilter         = 'binary';
params.jitterFile       = 'Stimuli/none';
params.paramsFile       = 'Stimuli/params_knkfull_wedgering.mat';  

    
%% no need to modify, closing up

% store it
dataTYPES(dataNum).retinotopyModelParams = params;

% save it
saveSession; 

% put the rm params into the view structure
vw = rmLoadParameters(vw); 
 
% check it 
% rmStimulusMatrix(viewGet(vw, 'rmparams'), [],[],2,false);



%% Run it!
vw = rmMain(vol,[],3);

% Now we've got a dataTYPE to use
updateGlobal(vw);
