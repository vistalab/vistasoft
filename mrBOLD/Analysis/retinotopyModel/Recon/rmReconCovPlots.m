function rmReconCovPlots(vw,numOfStimuli,ROIs,method,threshold)

    % open view struct
    if ~exist('vw','var') || isempty(vw)
        vw = initHiddenGray;
    end
    
    % Define some stuff
    % Number of different stimuli used
    %numOfStimuli = 6;    
 
    % All the ROIs that need to be loaded
    if ~exist('ROIs','var') || isempty(ROIs)    
        ROIs = {'V1'};
    end
    
    if ~exist('method','var') || isempty(method)    
        method = 'clippedweightavg';
    end
    
    if ~exist('threshold','var') || isempty(threshold)
	threshold = 0.15;
    end

    % Load the retinotopy model   
    vw = rmSelect(vw);
    vw = rmLoadDefault(vw);
    
    fprintf('[%s]: Retinotopy model loaded \n',mfilename);
        
    % Load VE values from GLM fit
    load([viewGet(vw,'homedir') '/Recon/VE/VE.mat']);

    vw.dualVE = VE;

    % Loop through the ROIs
    for roi_index = 1 : numel(ROIs)

        fprintf('[%s]: ROI: %s \n',mfilename,ROIs{roi_index});

        % Load the ROI
        vw = loadROI(vw,ROIs{roi_index},[],[],[],1);

        % Load the t-values of the stimuli and create the cov plots
        for stim_index = 1 : numOfStimuli
            vw = loadParameterMap(vw,[viewGet(vw,'homedir') '/Gray/' viewGet(vw,'datatype') '/B-values-stim' num2str(stim_index) '.mat']);



                if ~exist( [viewGet(vw,'homedir') '/Gray/' viewGet(vw,'datatype') '/methods/' method], 'dir');
                    mkdir([viewGet(vw,'homedir') '/Gray/' viewGet(vw,'datatype') '/methods/' method]);
                end                    

                [CovPlot fig all_models weight] = rmPlotCoverage(vw,...
                                        'fieldRange',7.5,...            % Define the field of view
                                        'method',method,...             % Use this method for combining pRFs
                                        'newfig',-1,...                 % Just give us the data
                                        'normalizeRange',0,...          % Don't normalize the data
                                        'cothresh',threshold,...        % Coherence threshold
                                        'removeOutliers',true,...            % Remove odd sized pRFs
                                        'weight','parameter map');      % Use parameter map for weighting

                 % Save the results

                 save_dir = [ viewGet(vw,'homedir') '/' viewGet(vw,'type') '/' viewGet(vw,'datatype') '/methods/' method];
                 save_name = [ 'CovPlot_' ROIs{roi_index} '_stim' num2str(stim_index) '-' method '.mat' ];

                 disp(sprintf('[%s]: Saving result for stimulus #%d, to %s',mfilename,stim_index,[save_dir '/' save_name]));

                 save([save_dir '/' save_name],'CovPlot');

                 % Save the t-values for this ROI & stimulus (useful
                 % later on)

                 if ~exist([ viewGet(vw,'homedir') '/Recon/ROItValues/' viewGet(vw,'datatype') '/' ROIs{roi_index}],'dir')
                     mkdir([viewGet(vw,'homedir') '/Recon/ROItValues/' viewGet(vw,'datatype') '/' ROIs{roi_index}]);
                 end                     

                 save([viewGet(vw,'homedir') '/Recon/ROItValues/' viewGet(vw,'datatype') '/' ROIs{roi_index} '/tvalues-stim' num2str(stim_index) '.mat'],'weight');                     
                 
                    if ~exist( [viewGet(vw,'homedir') '/Recon/pRF models'], 'dir');
                        mkdir([viewGet(vw,'homedir') '/Recon/pRF models']);
                    end                         

                     save_dir = [ viewGet(vw,'homedir') '/Recon/pRF models'];

                     save_name = [ 'pRF_models-' ROIs{roi_index} '-stim' num2str(stim_index) '-' method '.mat' ];

                     save([save_dir '/' save_name],'all_models');

                     fprintf('[%s]: Saved pRF models to %s \n',mfilename,[save_dir '/' save_name]);

                 clear CovPlot fig all_models weight;
        end
    end
