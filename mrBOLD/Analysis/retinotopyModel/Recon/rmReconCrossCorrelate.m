function rmReconCrossCorrelate(numOfStimuli,roi,method,datatype)

    if ~exist('HOMEDIR','var') || isempty(HOMEDIR)
        homedir = pwd;
    else
        homedir = HOMEDIR;
    end
    
    if ~exist('numOfStimuli','var') || isempty(numOfStimuli)
        error('Need the number of different stimuli.');
    end
    
    if ~exist('method','var') || isempty(method)
        method = 'betasum';
        fprintf('[%s] No method supplied, using default (betasum) \n',mfilename);
    end
    
    if ~exist('roi','var') || isempty(roi)
        roi ='V1';
        fprintf('[%s] No ROI supplied, using default (V1) \n',mfilename);
    end
    
    numstim = numOfStimuli;

    correl = zeros(numstim,numstim);
    pval = zeros(numstim,numstim);
    cond = single(zeros(128*128,numstim));
    
    for i = 1:numstim
        stimuli(i) = load([homedir '/Recon/RFcovs/' datatype '/' roi '/' method '/RFcov-stim' num2str(i) '.mat']);

        covstim = load([homedir '/Gray/' datatype '/methods/' method '/CovPlot_' roi '_stim' num2str(i) '-' method '.mat']);
        
        cond(:,i) = single(reshape(covstim.CovPlot,1,128*128));
    end
        
    for si = 1 : numstim  
        for si2 = 1 : numstim

            [cor, p] = corr(cond(:,si), stimuli(si2).RFcov(:));
            
            correl(si,si2) = cor;
            pval(si,si2) = p;
        end
    end

    save([homedir '/Recon/Correlations/CrossCorr-' roi '-' method '.mat'],'correl');
    save([homedir '/Recon/Correlations/CrossPval-' roi '-' method '.mat'],'pval');
end