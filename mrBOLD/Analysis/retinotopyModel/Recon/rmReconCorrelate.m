function rmReconCorrelate(numOfStimuli,datatype,ROI,method)

    if ~exist('HOMEDIR','var') || isempty(HOMEDIR)
        homedir = pwd;
    else
        homedir = HOMEDIR;
    end

    if ~exist([homedir '/Recon/Presentations/' datatype '/stimfile.mat'],'file')
        error('Need a stimfile.mat in the /Recon/Presentations folder');
    else
        stimulus = [homedir '/Recon/Presentations/' datatype '/stimfile.mat'];
    end   
    
    if ~exist('numOfStimuli','var') || isempty(numOfStimuli)
        error('Need the number of different stimuli.');
    end    
    
    if ~exist('ROI','var') || isempty(ROI)
        ROI = 'V1';
    end
    
    if ~exist('method','var') || isempty(method)
        method = 'clippedweightavg';
    end

    a = load(stimulus);

    correl = zeros(numOfStimuli);
    pval = zeros(numOfStimuli);

    for stimnumber = 1 : numOfStimuli

    % Create coverage plot for natural images            

            load([homedir '/Recon/pRF models/pRF_models-' ROI '-stim' num2str(stimnumber) '-' method '.mat']); 

            img = a.images(:,:,stimnumber);

            img = single(imresize(mat2gray(img,[0 255]),[128 128]));

            img = flipud(img);

            weight = zeros(1,size(all_models,2));

            % compute sds for images
            for vi = 1 : size(all_models,2)
                stats = wstat(img,all_models(:,vi));   

                if isnan(stats.stdev)
                    weight(vi) = 0;
                elseif isinf(stats.stdev)
                    weight(vi) = 1;
                else               
                    weight(vi) = stats.stdev;
                end
            end            

            % recompute all_models_weighted
            tmp = ones( size(all_models,1), 1, 'single' );
            all_models_weighted = all_models .* (tmp * weight);

            switch method
                    % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i))
                    case {'beta-sum','betasum','weight average','weightavg'}
                        RFcov = sum(all_models_weighted, 2) ./ sum(all_models,2);

                    % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i)) + clipping
                    case {'clipped beta-sum','clippedbeta','clipped weight average','clippedweightavg'}
                        % set all pRF beyond 2 sigmas to zero
                        clipval = exp( -.5 *((1./1).^2));
                        % clip to FWHM
                        %clipval = 2*sqrt(2*log(2));
                        all_models(all_models<clipval) = 0;
                        n = all_models > 0;

                        % recompute all_models_weighted
                        tmp = ones( size(all_models,1), 1, 'single' );
                        all_models_weighted = all_models .* (tmp*weight);

                        % compute weighted clipped sum/average
                        sumn = sum(n,2);
                        mask = sumn==0;
                        sumn(mask) = 1; % prevent dividing by 0
                        RFcov = sum(all_models_weighted,2) ./ sum(all_models,2);
                        RFcov(mask) = 0;
           

                    % coverage = sum(pRF(i)*w(i)) / (sum(w(i))
                    case {'sum','add','avg','average','pRF average','prfavg'}
                        RFcov = sum(all_models_weighted, 2) ./ sum(weight);

                    % coverage = sum(pRF(i)*w(i)) / (sum(w(i)) + clipping
                    case {'clipped average','clipped','clipped pRF average','clippedprfavg'}
                        % set all pRF beyond 2 sigmas to zero
                        clipval = exp( -.5 *((2./1).^2));
                        all_models(all_models<clipval) = 0;
                        n = all_models > 0;

                        % recompute all_models_weighted
                        tmp = ones( size(all_models,1), 1, 'single' );
                        all_models_weighted = all_models .* (tmp*weight);

                        % compute weighted clipped mean
                        sumn = sum((tmp*weight).*n);
                        mask = sumn==0;
                        sumn(mask) = 1; % prevent dividing by 0
                        RFcov = sum(all_models_weighted,2) ./ sumn;
                        RFcov(mask) = 0;

                    % coverage = max(pRF(i))
                    case {'maximum profile', 'max', 'maximum'}
                        RFcov = max(all_models_weighted,[],2);

                    case {'signed profile'}
                        RFcov  = max(all_models_weighted,[],2);
                        covmin = min(all_models_weighted,[],2);
                        ii = RFcov<abs(covmin);
                        RFcov(ii)=covmin(ii);

                    case {'p','probability','weighted statistic corrected for upsampling'}
                        RFcov = zeros(vfc.nSamples);

                        % I guess this upsample factor assumes your functional data are
                        % 2.5 x 2.5 x 3 mm?
                        upsamplefactor = 2.5*2.5*3; % sigh.....
                        for ii = 1:size(all_models,1)
                            s = wstat(all_models(ii,:),weight,upsamplefactor);
                            if isfinite(s.tval)
                                RFcov(ii) = 1 - t2p(s.tval,1,s.df);
                            end
                        end

        otherwise
            error('Unknown method %s',vfc.method)
            end       
            
            saveDir = [homedir '/Recon/RFcovs/' datatype '/' ROI '/' method];
            
            if ~exist(saveDir,'dir')
                mkdir(saveDir);
            end

            fprintf('[%s] Saving stimulus coverage plot to %s \n',mfilename,[saveDir '/RFcov-stim' num2str(stimnumber) '.mat']);
            save([saveDir '/RFcov-stim' num2str(stimnumber) '.mat'],'RFcov');           
            
            fprintf('[%s] Correlating stimulus with estimates \n',mfilename);

%             for ti = 1:numOfStimuli
                covstim = load([homedir '/Gray/' datatype '/methods/' method '/CovPlot_' ROI '_stim' num2str(stimnumber) '-' method '.mat']);

                cond = single(reshape(covstim.CovPlot,1,128*128));

                clear covstim

                [cor, p] = corr(cond(:), RFcov);

                correl(stimnumber) = cor;
                pval(stimnumber) = p;
                
                clear cond      
%             end
    end
    
    if ~exist([homedir '/Recon/Correlations/' datatype],'dir')
        mkdir([homedir '/Recon/Correlations/' datatype],'dir')
    end
    
    fprintf('[%s] Saving correlations \n',mfilename);
    save([homedir '/Recon/Correlations/' datatype '/Corr-' ROI '-' method '.mat'],'correl');

    fprintf('[%s] Saving p-values \n',mfilename);
    save([homedir '/Recon/Correlations/' datatype '/Pval-' ROI '-' method '.mat'],'pval');    
end