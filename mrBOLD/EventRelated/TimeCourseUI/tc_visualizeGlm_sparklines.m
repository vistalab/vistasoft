function tc = tc_visualizeGlm_sparklines(tc);
%
% tc = tc_visualizeGlm_sparklines(tc);
%
% Visualize results of a general linear model on a time
% course, using the sparkline method. (See Edward Tufte,
% "Beautiful Evidence".)
%
% This is a test to see whether this would work.
%
% ras. 01/2007.
if notDefined('tc')
    tc = get(gcf, 'UserData');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% apply a GLM if needed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(tc, 'glm')
    tc = tc_applyGlm(tc);
end
X = tc.glm.designMatrix;
Y = tc.wholeTc(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up existing objects in figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherAxes = findobj('Type', 'axes','Parent', tc.ui.fig);
delete(otherAxes);
otherUiControls = findobj('Type', 'uicontrol', 'Parent', tc.ui.fig);
delete(otherUiControls);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nConds = sum(tc.trials.condNums>0);
nRows = nConds + 1;
rowSize = min(.15, 1/(nRows+1)); % normalized height of rows
t = [1:length(tc.wholeTc)] .* tc.TR; % time poitns for wholeTc

lo = min(tc.wholeTc); % min and max time series values
hi = max(tc.wholeTc); 

if isnumeric(tc.params.glmHRF)
    opts = {sprintf('Mean trial for conditions \n %s',num2str(tc.params.snrConds)), ...
        'Boynton gamma function', 'SPM difference-of-gammas' ...
        'Dale & Buckner ''97'};
    hrfName = opts{tc.params.glmHRF};
else
    hrfName = tc.params.glmHRF; hrfName(hrfName=='_') = ' ';
end
title({'HRF function used: ' hrfName}, 'FontWeight', 'bold')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for row = 1:nRows
   subplot('Position', [.3 1-row*rowSize .65 rowSize]);
   
   if row==1        % plot time series data
       plot(t, tc.wholeTc, 'k');       
   else             % plot predictor
       plot(t, tc.glm.designMatrix(:,row-1) .* tc.glm.betas(:,row-1), ...
            'Color', tc.trials.condColors{row});
   end
   axis([t(1) t(end) lo hi]);   
   axis off
   
   % label condition
   if row==1
       text(-5, [lo + .3*(hi-lo)], 'Data');
   else
       text(-5, [lo + .3*(hi-lo)], tc.trials.condNames{row});
   end
end



return
