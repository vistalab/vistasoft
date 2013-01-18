function [correls pvals] = rmReconCorrelateVoxels(roi,conditions)

    if ~exist('HOMEDIR','var') || isempty(HOMEDIR)
        homedir = pwd;
    else
        homedir = HOMEDIR;
    end

    % Load the data

    if isempty(conditions)
        conditions = ['A','B'];
    end
    
    load([homedir '/Recon/pRF models/pRF_models-' roi '-stim1-betasum.mat']); 

    fprintf('[%s] pRF models loaded \n',mfilename);   
    
    if ~exist([homedir '/Recon/Stimuli/stimulus-' roi '.mat'],'file')
        
        fprintf('[%s] Loading scanner stimuli \n',mfilename);

        scanStim = load([homedir '/Recon/Presentations/stimfile.mat']);
        scanStim = scanStim.original_stimulus.images{1};

        fprintf('[%s] Loading natural images \n',mfilename);

        stimuli = load([homedir '/Recon/Stimuli/expstimuli.mat']);
        stimuli = stimuli.naturalimg;    

        for i = 1:6
            stimulus(i).image = flipud(scanStim(:,:,i));
        end

        stimulus(7:(7+size(stimuli,2))-1) = stimuli(:);

        fprintf('[%s] Stimulus structure loaded \n',mfilename);        
    
        fprintf('[%s] Computing SD maps',mfilename);

        for j = 1 : numel(stimulus)

            fprintf('.');

            img = stimulus(j).image;

            img = single(imresize(mat2gray(img,[0 255]),[128 128]));

            %img = flipud(img);

            weight = single(zeros(size(all_models,2),1));

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

            stimulus(j).sdmap = weight;
        end

        fprintf('\n');
        
        if ~exist([homedir '/Recon/Stimuli'],'dir')
            mkdir([homedir '/Recon/Stimuli']);
        end
        
        fprintf('[%s] Saving SD maps to %s/Recon/Stimuli/stimulus-%s.mat \n',mfilename,homedir,roi);  
        
        save([homedir '/Recon/Stimuli/stimulus-' roi '.mat'],'stimulus');    
    else
        fprintf('[%s] Loading stimulus structure \n',mfilename);
        
        load([homedir '/Recon/Stimuli/stimulus-' roi '.mat']);        
    end
    
    correls = single(zeros( 6, 6));
    pvals   = single(zeros( 6, 6));  
    
    for i = 1 : 6

        tValues = [];

        for ci = 1:numel(conditions)
            tValuesTemp = load([homedir '/Recon/ROItValues/' roi '/Condition ' conditions(ci) '/tvalues-stim' num2str(i) '.mat']);
            tValues = horzcat(tValues,tValuesTemp.weight(:));
        end

        tMeanValues = mean(tValues,2);       
        
        % Calculate SD maps for all images & correlate with t-map
        
        for j = 1 : numel(stimulus)
            fprintf('[%s] Calculating correlation %d - %d \n',mfilename,i,j);
            
            [correls(i,j) pvals(i,j)] = corr(stimulus(j).sdmap(:),tMeanValues(:));
        end
    end
    
    normCorrels = correls ./ repmat(max(correls,[],2),1,size(correls,2));
    
    percentCorrect = sum( diag( normCorrels==1 ) ) / numel( diag( normCorrels==1 ) );
    
    figure; imagesc(normCorrels); axis equal; colormap(gray); colorbar; title(['Percentage correct: ' num2str(percentCorrect*100)]);
end