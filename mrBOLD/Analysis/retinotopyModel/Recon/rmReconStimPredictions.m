function [pred numOfStim predictMat]= rmReconStimPredictions(vw, preScanDuration, datatype)
% rmReconStimPredictions - predict HRF responses based on stimulus
% presentations
%
% vw            = view structure
%
% NOTE: Make sure rmStimSequence is ran first to create the seq files!

% load sequence files
seqDir = [viewGet(vw,'homedir') '/Recon/Stimuli/Seqfiles/' datatype '/'];
seqFiles = dir([seqDir '*.seq']);

pred = [];

% loop through seq files
%for i = 1 : numel(seqFiles)
i = 1;
    seq = dlmread([seqDir seqFiles(i).name],'\t');
    
    % determine mean luminance code
    mlc = seq(1);    
        
    % create a timeseries with 0s and 1s
    seq( seq == mlc ) = 0;
    
    % get the different stimulus codes and lose the 0
    uniStim = unique(seq);
    uniStim = uniStim(2:end);
    
    % determine the number of stimuli
    numOfStim = numel(uniStim);    
    
    predictMat = zeros(length(seq),numOfStim);
    
    for stimInd = 1 : numOfStim
        
        % Create stimulus-specific sequence
        tempSeq = seq;
        tempSeq( tempSeq ~= uniStim( stimInd )) = 0;
        tempSeq( tempSeq > 0) = 1;
        
        % Add sequence to prediction matrix
        predictMat(:,stimInd) = tempSeq;
    end
    
    predictMat = predictMat((preScanDuration+1):end, :);
    
    % convolve with hrf
    prediction = rfConvolveTC(predictMat,viewGet(vw,'tr'),'t');
    
    pred = [pred; prediction];

%end

return;

