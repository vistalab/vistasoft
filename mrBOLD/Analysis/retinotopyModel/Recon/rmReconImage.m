function rmReconImage(vw,datatype)
% rmReconImage - reconstruct image from brain activity
%
% rmReconImage(vw)
%
% vw            = view structure

% open view struct
if ~exist('vw','var') || isempty(vw)
    vw = initHiddenGray;
end

% switch to dataType
if ~exist('datatype','var') || isempty(datatype)
    error('Please enter the datatype to be used.');
else
    vw = viewSet(vw,'curdatatype',datatype);
end

% define TR
tr = viewGet(vw,'tr');

% Create Recon directory structure
% if ~exist([viewGet(vw,'homedir') '/Recon'],'dir')
    fprintf('[%s] Creating Recon directory \n',mfilename);    
    
    mkdir([viewGet(vw,'homedir') '/Recon']);
    mkdir([viewGet(vw,'homedir') '/Recon/Correlations']);
    mkdir([viewGet(vw,'homedir') '/Recon/Correlations/' datatype]);
    mkdir([viewGet(vw,'homedir') '/Recon/pRF models']);
    mkdir([viewGet(vw,'homedir') '/Recon/RFcovs']);
    mkdir([viewGet(vw,'homedir') '/Recon/VE']);
    mkdir([viewGet(vw,'homedir') '/Recon/ROItValues']);
    mkdir([viewGet(vw,'homedir') '/Recon/Stimuli']);
    mkdir([viewGet(vw,'homedir') '/Recon/Stimuli/Seqfiles']);
    mkdir([viewGet(vw,'homedir') '/Recon/Presentations']);
    mkdir([viewGet(vw,'homedir') '/Recon/Presentations/' datatype]);
% end

% load different parameters 
reconParams = rmReconParams(vw);

% create seq files
rmStimSequence([viewGet(vw,'homedir') '/Recon/Presentations/' datatype],[viewGet(vw,'homedir') '/Recon/Stimuli/Seqfiles/' datatype], tr);

% load fMRI data 
fMRIData = rmLoadData(vw,reconParams);

fprintf('[%s] Loaded fMRI data \n',mfilename);

% make stimulus predictions
[stimPredicts numOfStimuli] = rmReconStimPredictions(vw,( 12 / tr ),datatype);

fprintf('[%s] Made stimulus predictions for %d stimuli \n',mfilename,numOfStimuli);

% make trends
[trends ntrends] = rmReconMakeTrends(reconParams);

fprintf('[%s] Made %d trends \n',mfilename,ntrends);

% fit
C = [[ones(1,numOfStimuli); eye(numOfStimuli)] zeros((numOfStimuli+1),ntrends)];

[t,df,RSS,B] = rmGLM(fMRIData, [stimPredicts trends], C);    
fprintf('[%s] Done GLM fit \n',mfilename);

fprintf('[%s] Saving t-values \n',mfilename);
for i = 1:size(t,1)

    for si = 1 : viewGet(vw,'numscans')
        vw = viewSet(vw,'scanmap',t(i,:),si);
    end

    if i == 1
        tname = 'all';
    else
        tname = ['stim' num2str( i-1 )];
    end

    vw = viewSet(vw,'mapname',['t-values-' tname]);
    saveParameterMap(vw,[],1);
end

fprintf('[%s] Saving B-values \n',mfilename);
for i = 1:size(B,1)

    for si = 1 : viewGet(vw,'numscans')
        vw = viewSet(vw,'scanmap',B(i,:),si);
    end

    if i == 1
        tname = 'all';
    else
        tname = ['stim' num2str( i-1 )];
    end

    vw = viewSet(vw,'mapname',['B-values-' tname]);
    saveParameterMap(vw,[],1);
end

fprintf('[%s] Calculating & saving variance explained \n',mfilename);

VE = 1 - (RSS ./ sum(fMRIData.^2));
VE(isinf(VE)) = 0;
VE = max(VE,0);
VE = min(VE,1);    

save([viewGet(vw,'homedir') '/Recon/VE/VE.mat'],'VE');

fprintf('[%s] Creating coverage plots \n',mfilename);

% Create coverage plots
rmReconCovPlots(vw,numOfStimuli);

% Calculate correlations
rmReconCorrelate(numOfStimuli,datatype);
% rmReconCrossCorrelate(numOfStimuli,'V1','clippedweightavg',datatype);

fprintf('[%s] Done. \n',mfilename);