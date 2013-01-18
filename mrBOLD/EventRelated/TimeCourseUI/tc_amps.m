function [amps, sems] = tc_amps(tc);
%
% [amps, sems] = tc_amps(tc);
% 
% Return the mean amplitude and standard error of the mean for each
% condition in a tc struct, computed according to the
% tc.params.ampType field. Analogous to the mv_amps and mv_stdev commands
% for MultiVoxel structures.
%
% Returns only amplitudes for the selected (non-null) conditions.
%
%
% ras, 02/2007.
if nargin<1, tc = get(gcf, 'UserData');  end

switch tc.params.ampType
    case 'difference',   % peak-bsl difference    
		
        amps = nanmean(tc.amps);
        sems = nanstd(tc.amps) ./ sqrt(sum(~isnan(tc.amps)) - 1);

    case 'betas',   % apply a GLM and get beta values  
        if ~isfield(tc, 'glm'), tc = tc_applyGlm(tc); end
        nConds = sum(tc.trials.condNums > 0);
        amps = tc.glm.betas(:,1:nConds);
        sems = tc.glm.sems(:,1:nConds);        
		
		% add zeros for the null condition
		amps = [0 amps];
		sems = [0 sems];
        
    case 'zscore', % Mean peak-bsl / std. deviation   
        mu = nanmean(tc.amps);
        sigma = nanstd(tc.amps);
        amps = mu/sigma;
        sems = sigma ./ sqrt(size(tc.amps,1) - 1);        
		
    case 'relamps', % dot-product relative amplitudes: 
        % * not currently implemented * : need to check algorithm
        error('Sorry, dot-product amps not yet implemented.')
        
    case 'deconvolved',  % Amplitudes of deconvolved time courses %
%         if ~isfield(tc, 'glm') | ~isequal(tc.glm.type, 'selective averaging')
            tc.params.glmHRF = 0;  % deconvolve
            tc = tc_applyGlm(tc);
%         end
        
        % get peak-bsl amplitudes from the deconvolved time courses
        TR = tc.params.framePeriod; 
		frameWindow = unique(round(tc.params.timeWindow./TR));
        prestim = -1 * frameWindow(1);
        peakFrames = unique(round(tc.params.peakPeriod./TR));
        bslFrames = unique(round(tc.params.bslPeriod./TR));
        peakFrames = find(ismember(frameWindow,peakFrames));
        bslFrames = find(ismember(frameWindow,bslFrames));

        nConds = size(tc.glm.betas, 2);

        if tc.params.normBsl==1
            offset = mean(tc.glm.betas(bslFrames,:,:), 1);
            offset = repmat(offset, [length(frameWindow) 1 1]);
            tc.glm.betas = tc.glm.betas - offset;
        end

        for i = 1:nConds
            bsl = tc.glm.betas(bslFrames,i);
            peak = tc.glm.betas(peakFrames,i);
            amps(:,i) = squeeze(nanmean(peak) - nanmean(bsl))';
            sems(:,i) = mean(tc.glm.sems(:,i));
		end            
            
		% add zeros for the null condition
		amps = [zeros(size(amps, 1)) amps];
		sems = [zeros(size(amps, 1)) sems];
		
        
	otherwise
		fprintf(1,'error ampType %s does not exist \n', tc.params.ampType);
end

% return only selected conditions
sel = find(tc_selectedConds(tc));
amps = amps(sel);
sems=sems(sel);
return
