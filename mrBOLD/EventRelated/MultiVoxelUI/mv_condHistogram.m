function mv = mv_condHistogram(mv);
%
% mv = mv_condHistogram(mv);
%
% For MultiVoxel UI:
% Plot a histogram of the # of voxels which have
% a significant response (using the 'alpha' field
% of the current parameters, via T-test of peak V
% baseline across trials) to different #s of 
% conditions.
%
% This was designed for the Hires ER / AdaptNSelect
% experiments, where we could visualize how many
% images/categories, respectively, to which different
% voxels were responsive.
%
% ras, 04/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

% run T tests across trials on trial time courses:
p = er_significantResponse(mv.voxData,mv.params,1);


% threshold at the appropriate alpha
H = (p < mv.params.alpha);

% count the # of conditions to which each
% voxel had a significant response:
nResponsiveConds = sum(H,2);

% put up the histogram
nConds = size(mv.voxData,4);
hist(nResponsiveConds,0:nConds);
xlabel('# Conditions',...
        'FontName',mv.params.font,'FontSize',mv.params.fontsz);
ylabel('# Voxels',...
    'FontName',mv.params.font,'FontSize',mv.params.fontsz);
ttl = sprintf('Conditions w/ Significant Response, \\alpha = %0.3f',mv.params.alpha);
title(ttl,'FontName',mv.params.font,'FontSize',mv.params.fontsz+2);

return
