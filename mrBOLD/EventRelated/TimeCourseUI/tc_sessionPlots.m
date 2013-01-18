function h = tc_sessionPlots(tcs, plotType, titleType);
% h = tc_sessionPlots(tcs, plotType, [titleType = 1]);
% 
% produce a figure showing individual subjects time course or amplitude data 
% each subject's data will be a subplot of the figure
% plotType (string): 
% 'wholetc'         raw timecourse 
% 'meanampsplustcs' left panel will show mean amps according to tc.params.ampType; right panel will show event-triggered average   
% 'meantcs'         event trigerred averaging mean time course 
% 'deconvolvedTcs'  deconvolved time courses 
% 'amps'            Means amplitudes of each condition according to the
%                   value in the tc.params.ampType filed which can be
%                   one of the following: 'difference' 'betas' 'relamps' or 'deconvolved';
% 'meanamps'        estimated from the event-triggered average based on the
%                   baseline and peak periods
% 'betas'           one beta per condition (no beta for baseline)estimated
%                   from a glm on the tc
% 'relamps'         David Ress's method for amplitude estimatation
% 'deconvolvedamps' Etimate of the mean amps from the deconvolved time
%                   course based on the peak and baseline period
%
% titleType: 1 (default) uses tcs.sessionCode for chart titles (usually
% corresponds to the directory of the session); 2 uses tcs.description.
%
%
% ras, 02/2007.
% ras, 04/2007: was part of tc_acrossSessions, but broke off to be its own 
% function, since it's pretty useful. Also allows cells of tc structs as 
% inputs.
% remus 10/2007: added titleType flag.
% kgs 3/2008: added deconvolvedtc and deconvolvedamps options
% 
h = [];

% set titleType parameters
if exist('titleType') & titleType == 2
    titleField = 'description';
else
    titleField = 'sessionCode';
end

% allow input to be a cell array
if iscell(tcs)
	% remove empty entries
	tcs = tcs( cellfind(tcs) );
	
	C = tcs;
	tcs = tcs{1};
	for i = 2:length(C)
		tcs(i) = mergeStructures(tcs(i-1), C{i});
	end
end

nSessions = length(tcs);
maxSubplotsPerFig = 16;  % if length(tcs)>this, make multiple figures
nFigs = ceil(nSessions / maxSubplotsPerFig);
subplotsPerFig = min(nSessions, maxSubplotsPerFig);

if nFigs > 1
    nRows = 5;
    nCols = 4;
else
    nRows = ceil( sqrt(subplotsPerFig) );
    nCols = ceil( subplotsPerFig / nRows );
end

% adjustment for plot types which display >1 axis per session
if isequal(lower(plotType), 'meanampsplustcs')
    nFigs = ceil(2 * nSessions / maxSubplotsPerFig); % 2 subplots per session
    subplotsPerFig = maxSubplotsPerFig / 2;
    nRows = nRows*2;
    nCols = nCols*2;
end

for s = 1:nSessions
    if mod(s, subplotsPerFig)==1
        h(end+1) = figure('Color', 'w', 'Position', [100 100 600 800], ...
                    'Name', sprintf('%s Session Plots', tcs(1).roi.name));
	end
	
	% get text for the title for this subplot
	titleText = tcs(s).params.(titleField);
	titleText( titleText=='_' ) = '-';  % TeX markup--avoid subscripts

    switch lower(plotType)
        case {'wholetc' 'wholetcs'}
            subplot(nRows, nCols, s);
            tc_plotWholeTc(tcs(s), gca);
            title(titleText, 'FontSize', 10);
			
        case 'meanampsplustcs'                    
            subplot(ceil(nRows/2), nCols, (2*s-1));
            tc_barMeanAmplitudes(tcs(s), gca, 0); % this will plot the event triggered average plots
            title(titleText, 'FontSize', 10);

            subplot(ceil(nRows/2), nCols, (2*s));
            tc_plotMeanTrials(tcs(s), gca);

			if isfield(tcs(s), 'SNR') & ~isempty(tcs(s), 'SNR')
				snrNums = tcs(s).condNums(tcs(s).params.snrConds);
				snrConds = sprintf('%i ', snrNums);
				title(sprintf('SNR: %3.2f (conds [%s])', tcs(s).SNR, snrConds));
			end
			
        case {'meantc' 'meantcs'}
            subplot(nRows, nCols, s);
            tc_plotMeanTrials(tcs(s), gca); % this will plot what is in the meantc field
            title(titleText, 'FontSize', 10);

        case {'deconvolved' 'deconvolvedTcs' 'deconvolvedtcs'}  % will plot the deconvolved time courses
                currTc=tcs(s);
     			currTc.params.glmHRF=0 % set glm flag for deconvolution 
                % deconvolve
                 currTc = tc_applyGlm(currTc);
                 % add a blank condition at the beginning betas are zero
                % because this is the baseline to which the glm is
                 % estimated
                currTc.meanTcs = [zeros(currTc.glm.nh, 1) currTc.glm.betas];
                subplot(nRows, nCols, s);
                tc_plotMeanTrials(currTc, gca);
                title(titleText, 'FontSize', 10);
          
        case 'amps'
            subplot(nRows, nCols, s);
            %   0 - Use the value in the tc.params.ampType field.
            tc_barMeanAmplitudes(tcs(s), gca, 0);
            title(titleText, 'FontSize', 10);
			
        case 'meanamps'
            subplot(nRows, nCols, s);
            %  1 - Plot Peak/Baseline difference of event-triggered average
            tc_barMeanAmplitudes(tcs(s), gca, 1);
            title(titleText, 'FontSize', 10);
	  
        case 'betas'
            subplot(nRows, nCols, s);
            %   2 - Plot GLM Beta values
            tc_barMeanAmplitudes(tcs(s), gca, 2);
            title(titleText, 'FontSize', 10);
        
        case {'relamps' 'dotproductamps' 'projamps'}
            subplot(nRows, nCols, s);
            %   3 - Plot Dot-Product Projection Amplitudes
            tc_barMeanAmplitudes(tcs(s), gca, 3);
            title(titleText, 'FontSize', 10);
		
        case { 'deconvolvedamps'  'deconvolvedAmps'} 
            subplot(nRows, nCols, s);
            %   4 - Plot Peak/Baseline from deconvolved time courses
            tc_barMeanAmplitudes(tcs(s), gca, 4);
            title(titleText, 'FontSize', 10);
			
        otherwise, warning( sprintf('Unknown plot type %s', plotType) )
    end

end


return
