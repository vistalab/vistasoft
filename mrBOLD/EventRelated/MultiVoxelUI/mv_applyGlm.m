function mv = mv_applyGlm(mv);
%
% mv = mv_applyGlm(mv):
%
% Apply a general linear model to the time series data
% for the currently-selected voxels, and
% append the resulting glm struct to the mv struct.
%
%
% ras, 04/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Data Matrix Y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y = double(mv.tSeries);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Predictors Matrix X 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[X, nh, hrf] = glm_createDesMtx(mv.trials, mv.params, Y, 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply the GLM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv.glm = glm(Y, X, mv.params.framePeriod, nh, mv.params.glmWhiten);
mv.glm.hrf = hrf;

% also store % variance explained for each voxel
nVoxels = size(mv.glm.betas, 3);
mv.glm.varianceExplained = 1 - var(mv.glm.residual) ./ var(Y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add to fig's user data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if checkfields(mv, 'ui', 'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig, 'UserData', mv);
end


return
