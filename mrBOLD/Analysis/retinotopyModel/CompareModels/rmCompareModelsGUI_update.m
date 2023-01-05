function M = rmCompareModelsGUI_update(M)
% Refresh the GUI for comparing pRF estimates across data types.
%
% M = rmCompareModelsGUI_update([M=get from GUI]);
%
%
% ras, 02/2009.
if notDefined('M')
    M = get(gcf, 'UserData');
end

recomputeFlag = isequal( get(M.ui.recompFit, 'Checked'), 'on' );

%% loop across models
for m = 1:M.nModels
    %% get a vector of time points for the model -- will be used for plotting
    TR = M.params{m}.stim(1).framePeriod;
    t = [0:size(M.tSeries{m}, 1)-1]' .* TR;

    v = M.voxel;
    
    %% get the tSeries / pRF params for the selected voxel
    sigma = 0;
    for f = {'tSeries' 'x0' 'y0' 'sigma' 'pol' 'ecc'}
        eval( sprintf('%s = M.%s{m}(:,v);', f{1}, f{1}) );
    end
    
    %% Create a vector of params
    % (Todo: make this work for different model types)
    rfParams = [x0 y0 sigma 0 sigma 0];

    % modify the params if specified by the GUI
    rfParams = movePRF(M, rfParams, v);
    x0 = rfParams(1);
    y0 = rfParams(2);
    sigma = rfParams(3);

    %% get the stimulus grid
    % X and Y are the x and y coordinates of the stimulus grid
    X = M.params{m}.analysis.X;
    Y = M.params{m}.analysis.Y;

    % The stimulus grid may be different from the different models we are
    % comparing. We need the correct stimulus grid for each model (X, Y;
    % above). We will need the grid in order to take pRF parameters (x, y,
    % sigma) and convert this into a pRF image. The pRF image must have the
    % right dimensions because we will predict the t-series for each voxel
    % by mulitplying the stimulus images * the pRF image. 
    %
    % But we also want to store the stimulus grid for the first model. This
    % way, when we show an image of the pRF from each model, they can be
    % the same scale. This is especially useful if you are comparing models
    % that were solved on different size stimuli, say one model at 3 deg
    % and one model at 14 deg. We would like to visualize the pRFs from the
    % two models in the same space (say, a 14 deg radius grid) for ease of
    % comparison. Hence we sotre the X,Y grid values from model 1 in
    % addition to the X,Y grid values for the current model as we loop
    % through the models.
    X1 = M.params{1}.analysis.X;
    Y1 = M.params{1}.analysis.Y;

    %% get pRF values as column vectors (the vector will later be reshaped to a 2D image)
    % we first get the pRF values using the current model's grid (for calculations)
    RFvals  = rmPlotGUI_makeRFs(M.modelName, rfParams, X, Y);
	
    % we then get the pRF values using the grid from model 1 (for display)
    RFvals1 = rmPlotGUI_makeRFs(M.modelName, rfParams, X1, Y1);

    %% get the pRF image and predicted time series
	pred = rmCompareModelsGUI_prediction(m, M, RFvals, tSeries);
	
    if recomputeFlag==1
        % compute variance explained for this voxel
        R = corrcoef([pred tSeries]);
        varexp = 100 * R(2) .^ 2;
    else
        % take the stored value
        varexp = 100 * M.varexp{m}(v);
    end

    %% plot results
    % time series
    axes(M.ui.tSeriesAxes(m));  cla;  hold on
    plot(t, tSeries, t, pred);  hold on
    axis tight
    setLineColors({'k' 'b'});
    setLineStyles({'1.5-' '1.5-'});
    line([t(1) t(end)], [0 0], 'LineWidth', 1.5, 'LineStyle', ':', 'Color', 'r');
    if m==M.nModels
        axis on
        set(gca, 'Box', 'off');
        xlabel('Time (s)', 'FontSize', 12);
        ylabel('% Signal', 'FontSize', 12);
    else
        axis off;
    end
    title( sprintf('%s: %2.0f%% variance explained', M.dtList{m}, varexp) );

    % for the time series plot, show the time point on the time series axes
    if get(M.ui.overlayStimCheck, 'Value')==1
        % delete the last line
        delete( findobj('Parent', gca, 'Tag', 'CurStimPoint') );

        % get the current time point
        TR = M.params{m}.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans
        tStim = get(M.ui.time.sliderHandle, 'Value') * TR;

        % draw the new line
        AX = axis;
        hold on
        hLine = line([tStim tStim], AX(3:4), 'LineWidth', 2, ...
            'LineStyle', '--', 'Color', 'm');
        set(hLine, 'Tag', 'CurStimPoint');
    end

    % pRF
    axes(M.ui.rfAxes(m));  cla;  hold on

    % Note that we use the the stimulus grid from the first model to
    % displau the pRF (RFvals1), not the grid from the current model
    % (RFvals). The pRF paramters (x,y,s) come from the current model.
    showPRF(M, RFvals1, gca, m); %showPRF(M, RFvals, gca, m);

    txt = sprintf('(x, y, \\sigma) = (%.1f, %.1f, %.1f)', x0, y0, sigma);
    txt = sprintf('%s\n(pol, ecc) = (%.1f, %.1f)', txt, pol * (180/pi), ecc);
    title(txt);

end
% colormap hot

% normalize the time series axes
normAxes( M.ui.tSeriesAxes );


%% set information fields
% voxel coords
set(M.ui.coordsText, 'String', ['Coords: ', num2str( [M.roi.coords(:,v)]')]);

% update the previous voxel
M.prevVoxel = M.voxel;
set(M.fig, 'UserData', M);

return
% ---------------------------------------------------------------



% ---------------------------------------------------------------
function rfParams = movePRF(M, rfParams, voxel)
% Subroutine to manually alter the pRF center for visualizing other fits.
% The stored model is not altered.
%
% This is constrained right now to the circular Gaussian case. This is
% mainly because of simple contraints of space in the GUI window for adding
% more sliders. I think a better long-term solution is to break off a
% separate subfunction, expressly designed for editing a single pRF, which
% would lack the voxel slider, and a number of other options, but would
% have sliders for sigma major/minor, theta (angle b/w axes), etc. (ras)

%% has the selected voxel changed?
if voxel ~= M.prevVoxel
    % let's update the 'pRF adjust params' sliders to match the new voxel.
    % (we'll wait until the user adjusts one of the sliders to modify
    % rfParams.)
    mrvSliderSet(M.ui.moveX, 'Value', rfParams(1));
    mrvSliderSet(M.ui.moveY, 'Value', rfParams(2));
    mrvSliderSet(M.ui.moveSigma, 'Value', rfParams(3));
    set(M.ui.moveToPreset, 'Value', 1);
end

%% if we got here, we haven't changed the voxel:
% we can adjust the rfParams, *if* the option is selected...

% test whether the 'adjust PRF' option is selected
if get(M.ui.movePRF, 'Value')==1
    % either manually move the pRF according to slider values...
    mrvSliderSet(M.ui.moveX, 'Visible', 'on');
    mrvSliderSet(M.ui.moveY, 'Visible', 'on');
    mrvSliderSet(M.ui.moveSigma, 'Visible', 'on');
    set( M.ui.moveToPreset, 'Visible', 'on' )

    rfParams(1) = get(M.ui.moveX.sliderHandle, 'Value');
    rfParams(2) = get(M.ui.moveY.sliderHandle, 'Value');
    rfParams(3) = get(M.ui.moveSigma.sliderHandle, 'Value');
    rfParams(5) = rfParams(3);   % circular case

else
    % ... or use stored values  (and keep the sliders hidden)
    mrvSliderSet(M.ui.moveX, 'Visible', 'off');
    mrvSliderSet(M.ui.moveY, 'Visible', 'off');
    mrvSliderSet(M.ui.moveSigma, 'Visible', 'off');
    set(M.ui.moveToPreset, 'Visible', 'off');
    set(M.ui.moveToPreset, 'Value', 1);
end

return
% ---------------------------------------------------------------



% ---------------------------------------------------------------
function showPRF(M, RFvals, axs, m)
%% show the pRF in the axes (axs), superimposing the stimuli if that option
%% is selected.
rescaleToPeak = isequal( get(M.ui.peakCheck, 'Checked'), 'on' );
if get(M.ui.overlayStimCheck, 'Value')==0
    %% show the RF only, don't overlay the stimulus image
    if rescaleToPeak==0,
        peak = [];
    else
        TR = M.params{m}.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans
        peak = rfParams(4) .* M.params{m}.analysis.sampleRate^2 .*  TR;
    end;

    % use stimulus parameters from first model (1), not current model (m)
    [x, y, z] = rfPlot(M.params{1}, RFvals, axs, peak); %rfPlot(M.params{m}, RFvals, axs, peak);

    % make sure the time slider is not visible
    mrvSliderSet(M.ui.time, 'Visible', 'off');
else
    %% overlay the stimulus image on the RF
    TR = M.params{m}.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans
    t = get(M.ui.time.sliderHandle, 'Value') * TR;

    % get the stimulus image for this frame
    f = round(t / M.params{m}.stim(1).framePeriod); % MR frame
    if f < 1 || f > size(M.params{m}.analysis.allstimimages, 1)
        warning('Can''t visualize stimulus: selected time point outside scan range.')
        return
    end
    
    
    %[stimImage RF] = getCurStimImage(M, f, RFvals, m);
    [stimImage RF] = getCurStimImage(M, f, RFvals, 1);
    
    % overlay and siplay
    axes(axs); cla
    % 	RF_img(:,:,1) = RF;
    % 	RF_img(:,:,2) = 1-RF;
    % 	RF_img(:,:,3) = stimImage;
    RF_img(:,:,1) = stimImage;
    RF_img(:,:,2) = RF;
    RF_img(:,:,3) = RF;

    [x,y] = prfSamplingGrid(M.params{m});
    x = x(:); y = y(:);
    imagesc(x, -y, RF_img); hold on;
    plot([min(x) max(x)], [0 0], 'k-');
    plot( [0 0], [min(y) max(y)], 'k-');

    axis image xy;
    ylabel('y (deg)');
    xlabel('x (deg)');

    % make sure the time slider is visible
    mrvSliderSet(M.ui.time, 'Visible', 'on');
end

% Determine which model has the largest field size and use its field size
% as the limit for the pRF plots for all models
for ii = 1:length(M.params)
    tmp(ii)  = M.params{ii}.analysis.fieldSize;
end
maxFieldSize = max(tmp);
xlim([-maxFieldSize maxFieldSize])
ylim([-maxFieldSize maxFieldSize])

% add a dotted line to indicate stimulus extent for current model
nPoints = 100;
th = linspace(0, 2* pi, nPoints);
r = th * 0 + M.params{m}.analysis.fieldSize;
[x, y] = pol2cart(th, r);
hold on; plot(x, y, 'w-', x, y, 'k--');
return
%--------------------------------------



%--------------------------------------
function [stimImage RF] = getCurStimImage(M, f, RFvals, m)
% Get a stimulus image matching the sampling positions as the RF.
% Also returns the RF resampled into a square grid.
x = prfSamplingGrid(M.params{m});

% account for the different stimuli that are shown next to each other
% f originally refers to the frame in the combined time series across scans:
% we want to break this down into scan n, frame f within that scan.
n = 1;
nStimScans = numel(M.params{m}.stim);
while n <= nStimScans,
    tmp = f + M.params{m}.stim(n).prescanDuration;
    if tmp > size(M.params{m}.stim(n).images_org,2),
        f = tmp - size(M.params{m}.stim(n).images_org,2);
        n = n + 1;
    else
        f = tmp;
        break;
    end
end

% stim image
stimImage     = NaN(size(x));
stimImage(M.params{m}.stim(1).instimwindow) = M.params{m}.stim(n).images_org(:,f);
stimImage     = reshape(stimImage, size(x));

% RF
RF     = NaN(size(x));
RF(M.params{m}.stim(1).instimwindow) = normalize(RFvals, 0, 1);
RF     = reshape(RF, size(x));

return
