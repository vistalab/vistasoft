function amps = mv_amps(mv,runs);
%
% amps = mv_amps(mv,[runs]);
%
% Return a 2D matrix of format
% voxels x conditions containing
% response amplitudes, evaluated 
% according to the 'ampType' parameter
% set in the params struct. Does not compute amps
% for the null (0) condition.
%
% ras, 05/05.

if notDefined('mv')
    mv = get(gcf,'UserData');
end

allRuns = unique(mv.trials.run);

if notDefined('runs')
    runs = allRuns;
end

% check that we have an amplitude type defined
if ~checkfields(mv,'params','ampType')
    % set up a dialog, get it
    ui.string = 'Method to Calculate Amplitudes?';
    ui.fieldName = 'ampType';
    ui.list = {'Peak-Bsl Difference', 'GLM Betas', ...
        'Dot-product Relative Amps' 'raw'};
    ui.style = 'popup';
    ui.value = ui.list{1};
    
    resp = generalDialog(ui,'Select Amplitude Type');
    ampInd = cellfind(ui.list,resp.ampType);
    opts = {'difference' 'betas' 'relamps' 'raw'};
    mv.params.ampType = opts{ampInd};
end

nConds = sum(mv.trials.condNums > 0);

switch mv.params.ampType
    case 'difference',   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % peak-bsl difference              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        [tSeries, trials] = er_dataSubset(mv, runs);
        voxData = er_voxDataMatrix(tSeries, trials, mv.params);

        voxAmps = er_voxAmpsMatrix(voxData, mv.params);
        amps = permute(nanmeanDims(voxAmps,1), [2 3 1]);

    case 'betas',       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % apply a GLM and get beta values  %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get data from selected runs only
        [tSeries, trials] = er_dataSubset(mv, runs);
        
        % Build a design matrix, apply the glm, grab betas
        [X, nh, hrf] = glm_createDesMtx(trials, mv.params, tSeries, 0);
               

        model = glm(double(tSeries), X, mv.params.framePeriod, nh);       
        amps = permute(model.betas(1,1:nConds,:), [3 2 1]);
        
%         % also add dc components to each beta value, to ensure the shift is
%         % not lost
%         dc = permute( model.betas(1,nConds+1:end,:), [3 2 1]);
%         amps = amps + repmat(mean(dc,2), [1 nConds]);
        
    case 'trialbetas'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % apply a GLM and get beta values for each trial %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [tSeries, trials] = er_dataSubset(mv, runs);
        nConds = sum(trials.cond > 0);
        counter = 0;
        for i = 1:length(trials.cond)
            if (trials.cond(i))
                counter = counter + 1;
                trials.cond(i) = counter;
            end
        end
        
        [X, nh, hrf] = glm_createDesMtx(trials, mv.params, tSeries, 0);

        model = glm(double(tSeries), X, mv.params.framePeriod, nh);       
        amps = permute(model.betas(1,1:nConds,:), [3 2 1]);
        return;
        
        
    case 'raw', 
		[tSeries, trials] = er_dataSubset(mv, runs);
		mv.params.normBsl=0;
		mv.params.ampType='raw'
		mv.voxData = er_voxDataMatrix(tSeries,mv.trials,mv.params);
		mv.mvAmps=er_voxAmpsMatrix(mv.voxData, mv.params);
		amps = permute(nanmeanDims(mv.voxAmps(runs,:,:),1), [2 3 1]);
    case 'zscore',
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Mean peak-bsl / std. deviation   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        tmp = mv;
        tmp.params.ampType = 'difference';
        mu = mv_amps(tmp, runs);
        sigma = mv_stdev(tmp, runs);
        amps = mu ./ sigma;
        return      % already chose selected conditions
        
        
    case 'relamps',
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % dot-product relative amplitudes: %
        % * not currently implemented *    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
        amps = er_relamps(mv.voxData(:,runs,:,:));
        amps = squeeze(nanmean(amps));

        % return amplitudes for selected conditions only
        sel = find(tc_selectedConds(mv));
        amps = amps(:,sel-1);

        
    case 'deconvolved',
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Amplitudes of deconvolved time courses %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Get data from selected runs only
        [tSeries, trials] = er_dataSubset(mv, runs);
        
        % set up and run a GLM
        params = mv.params;
        params.glmHRF = 0;
        TR = mv.params.framePeriod;
        [X nh] = glm_createDesMtx(trials, params, tSeries);
        model = glm(tSeries, X, TR, nh);
        
        % get peak-bsl amplitudes from the deconvolved time courses
        frameWindow = unique(round(mv.params.timeWindow./TR));
        prestim = -1 * frameWindow(1);
        peakFrames = unique(round(mv.params.peakPeriod./TR));
        bslFrames = unique(round(mv.params.bslPeriod./TR));
        peakFrames = find(ismember(frameWindow,peakFrames));
        bslFrames = find(ismember(frameWindow,bslFrames));

        nConds = size(model.betas, 2);

        if mv.params.normBsl==1
            offset = mean(model.betas(bslFrames,:,:), 1);
            offset = repmat(offset, [length(frameWindow) 1 1]);
            model.betas = model.betas - offset;
        end

        for i = 1:nConds
            bsl = model.betas(bslFrames, i, :);
            peak = model.betas(peakFrames, i, :);
            amps(:,i) = squeeze(nanmean(peak) - nanmean(bsl))';
		end    
	otherwise
		fprintf(1,'error ampType %s does not exist \n', mv.params.ampType);
end


% return amplitudes for selected conditions only
sel = find(tc_selectedConds(mv));
amps = amps(:,sel-1);

return
