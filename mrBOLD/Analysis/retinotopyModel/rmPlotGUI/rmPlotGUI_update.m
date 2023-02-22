function M = rmPlotGUI_update(M)
% Refresh the Retinotopy Model Plotting GUI.
%
% M = rmPlotGUI_update(M);
%
% Update function for rmPlotGUI. Visualizes the receptive field and time
% series (data, prediction, and residual) for a given voxel for a
% retinotopy model fit.
%
% All the information about the model should be in the struct M, created
% with rmPlotGUI_getModel.
%
% ras, 09/06.
% ras, 11/08: broekn off into separate subfunction.
if ~exist('M','var') || isempty(M), M = get(gcf, 'UserData'); end

% get current voxel from the GUI
voxel = get(M.ui.voxel.sliderHandle, 'Value');

% get needed params
coords = M.coords(:,voxel);
if isequal(M.roi.viewType, 'Gray')  % convert coords into an index
    coords = M.coords(voxel);
end

M.modelNum = get(M.ui.model, 'Value');

%% compute RF, get tSeries for this voxel
[pred, RF, rfParams, variance_explained, blanks] = rmPlotGUI_makePrediction(M, coords);

% check if the prediction for this voxel is empty. If so, don't plot it:
if all( isnan(pred) | isinf(pred) )
	a = axes(M.ui.tsAxes);  cla(a);  
	AX = axis;
	text(a, AX(2) + .5*(AX(2)-AX(1)), AX(3) + .5*(AX(4)-AX(3)), ...
		 '(No data available for this voxel)', ...
		 'FontSize', 14, ... 
		 'HorizontalAlignment', 'center');
	return
end

% store the current prediction
M.prediction = pred;
M.RF = RF;

%%%%% VISUALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (1) plot time series
%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes(M.ui.tsAxes); cla; hold on;

hTSeries = plot(M.x, M.tSeries(:,voxel), 'k--', 'LineWidth', 1.5);
hFit = plot(M.x, pred(:, 1), 'b', 'LineWidth', 1);
hResidual = plot(M.x, M.tSeries(:,voxel)-pred(:,1), 'r:', 'LineWidth', 1);


xlim([min(M.x) max(M.x)]);

% Determine appropriate limits for y-axis. To do so, we concatenate the
% visible series. These include some or all of raw, predicted, and residual
% tseries. The user selects which are visible by checkbox in the GUI.
allPlotted = [];
if get(M.ui.tsCheck,   'Value'), allPlotted = cat(1, allPlotted, M.tSeries(:,voxel)); end
if get(M.ui.predCheck, 'Value'), allPlotted = cat(1, allPlotted, pred(:,1)); end
if get(M.ui.resCheck,  'Value'), allPlotted = cat(1, allPlotted, M.tSeries(:,voxel)-pred(:,1)); end
if max(allPlotted) > min(allPlotted), ylim([min(allPlotted) max(allPlotted)]); end


h = axis;
for n=1:numel(M.sepx),
    plot([1 1].*M.sepx(n), [h(3) h(4)], 'k:', 'LineWidth', 2);
end;
xlabel('Time (sec)');
ylabel('BOLD signal change (%)');

% set a button-down function which will allow the user to double-click on
% any time point and view the stimuls aperture at that time point.
bdf = ['M = get(gcf, ''UserData''); ' ...
	   'pt = get(gca, ''CurrentPoint''); ' ...
	   'pt = round(pt(1) / M.params.stim(1).framePeriod); ' ...
	   'st = get(gcf, ''SelectionType''); ' ...
	   'if isequal(st, ''open''), ' ...
	   '  set(M.ui.overlayStimCheck, ''Value'', 1); ' ...
	   '  mrvSliderSet(M.ui.time, ''Value'', pt); ' ...
	   '  rmPlotGUI(''update''); ' ...
	   'end; ' ...
	   'clear M st pt'];
set(M.ui.tsAxes, 'ButtonDownFcn', bdf);   

% Indicate the time points with no stimulus
plot(M.x(blanks), zeros(sum(blanks),1), 'rx')

% set the user data of each checkbox to point to the PLOT curves
% we just created. The callbacks for these checkboxes will then toggle
% the visibility of each curve.
set(M.ui.tsCheck,   'UserData', hTSeries);
set(M.ui.predCheck, 'UserData', hFit);
set(M.ui.resCheck,  'UserData', hResidual);
if get(M.ui.tsCheck,   'Value')==0, set(hTSeries,  'Visible', 'off'); end
if get(M.ui.predCheck, 'Value')==0, set(hFit,      'Visible', 'off'); end
if get(M.ui.resCheck,  'Value')==0, set(hResidual, 'Visible', 'off'); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (2) set text fields  
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% on Windows, we can save space expressing the "degrees" units string
if ispc, degStr = char(176); 
else     degStr = 'deg'; end

% print out percent variance (R^2) explained: This calculation is incorrect
% because the predictions contain the trends. 
% (ras) so how do we make it correct?
txt = sprintf('Variance explained: %.2f%%', variance_explained*100);
set(M.ui.r2Text, 'String', txt);

% print out coords of voxel
txt = ['Coords: [' num2str(M.params.roi.coords(:,voxel)') ']'];
set(M.ui.coordsText, 'String', txt);

txt = sprintf('x=%.1f, y=%.1f (%s)',rfParams(1,1), rfParams(1,2), degStr);
set(M.ui.xyText, 'String', txt);

[th r] = cart2pol(rfParams(1,1), rfParams(1,2));
th = round( (pi/2 - th) * (180/pi) ); % rad -> deg CW from up
txt = sprintf('r=%.1f %s, theta=%i %s', r, degStr, th, degStr);
set(M.ui.rthText, 'String', txt);

if size(rfParams,1)<5 && rfParams(3)==rfParams(5)
	% sigma major and minor are the same: circular pRF
	% (on the rare instance where an oval Gaussian was fit with exactly the
	% same major and minor axes, I think this should still be sufficiently
	% clear)
	txt = sprintf('sigma=%.1f%s', rfParams(3), degStr);
elseif size(rfParams, 1)==2
    txt = sprintf('sigma_1=%.2f, sigma_2=%.2f %s', rfParams(1,3), rfParams(2,3), degStr);
else
	% oval Gaussian: report both major and minor sigma
	txt = sprintf('sigma_1=%.1f, sigma_2=%.1f %s', rfParams(3), rfParams(5), degStr);
end
set(M.ui.sigmaText, 'String', txt);

txt = sprintf('beta=%.1f %% %s/sec', rfParams(4), degStr);
set(M.ui.betaText, 'String', txt);

% from rmPlot: cache the data for the current time series plot as well
M.currTsData.x    = M.x;
M.currTsData.pred = pred;
M.currTsData.raw  = M.tSeries(:,voxel);
M.currTsData.sepx = M.sepx;
M.currTsData.pRF  = RF;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (3) show receptive field
%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(M.ui.peakCheck, 'UserData', hResidual);
rescaleToPeak = isequal( get(M.ui.peakCheck, 'Checked'), 'on' );
if get(M.ui.overlayStimCheck, 'Value')==0
    if min(M.params.analysis.Y) == max(M.params.analysis.Y)
        subplot(M.ui.rfAxes);
        plot(M.params.analysis.X,RF,'bo-','MarkerFaceColor','b');
        axis square
        
    else % default
        
        % show the RF only, don't overlay the stimulus image
        if rescaleToPeak==0,
            peak = [];
        else
            TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans
            peak = rfParams(4) .* M.params.analysis.sampleRate^2 .*  TR;
        end;
        
        rfPlot(M.params, RF, M.ui.rfAxes,peak);
        
        % jw add for exponentiated sigma
        modelName = rmGet(M.model{1}, 'desc');
        if strcmpi(modelName, 'fitprf')
            rfParamsExp    = rfParams;
            rfParamsExp(3) = rfParams(5); % put the exponentiated sigma into the sigma slot
            RFsEXP = rmPlotGUI_makeRFs(modelName, rfParamsExp, M.params.analysis.X, M.params.analysis.Y);
            rfPlot(M.params, RFsEXP, M.ui.rfAxes,peak);
            M.currTsData.pRF = RFsEXP; %store the exponentiated pRF in the User Data
        end
    end
    
    % make sure the time slider is not visible
    mrvSliderSet(M.ui.time, 'Visible', 'off');
    
else
	%% overlay the stimulus image on the RF
	TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans	
	
    % Our time series starts at t = 0, not t = TR, hence we need to
    % subtract 1 from the x-axis index before multiplying by the TR to get
    % the correct time
    %t = get(M.ui.time.sliderHandle, 'Value') * TR;
    t = (get(M.ui.time.sliderHandle, 'Value') -1 )* TR;
    
	% show the time point on the time series axes
	axes(M.ui.tsAxes); 
	delete( findobj('Parent', gca, 'Tag', 'CurStimPoint') );
	AX = axis;
	hLine = line([t t], AX(3:4), 'LineWidth', 2, 'LineStyle', '--', 'Color', 'm');
	set(hLine, 'Tag', 'CurStimPoint');
	
	% get the stimulus image for this frame
    %   becausae the t-series starts at t = 0, and the frame number starts at
    %   f = 1, the forumala to derive the frame from the time is 
    %       f = (t+tr)/tr; 
    %   and not
    %       f = t/tr;
    tr = M.params.stim(1).framePeriod; % MR frame
	f = round((t+tr)/ tr); 
	if f < 1 || f > size(M.params.analysis.allstimimages, 1)
		fprintf('Can''t visualize stimulus: selected time point outside scan range.\n');
		return
	end
	[stimImage RF] = getCurStimImage(M, f, RF);	
    if max(stimImage(:)) > 1 && max(stimImage(:)) < 256
        stimImage = stimImage/255;
    end
    if min(stimImage(:))<0
        stimImage = max(stimImage,0); % clip
    end
    
	% overlay and display
	axes(M.ui.rfAxes); cla
	RF_img(:,:,1) = stimImage;
	RF_img(:,:,2) = RF;
	RF_img(:,:,3) = RF;

    [x,y] = prfSamplingGrid(M.params);
    x = x(:); y = y(:);
    imagesc(x, -y, RF_img); hold on;
    plot([min(x) max(x)], [0 0], 'k-');
    plot( [0 0], [min(y) max(y)], 'k-');
    
    axis image  xy;
    ylabel('y (deg)');
    xlabel('x (deg)');
	    
    % make sure the time slider is visible
	mrvSliderSet(M.ui.time, 'Visible', 'on');
end

% turn on grid if the menu option is selected
if isequal( get(M.ui.grid, 'Checked'), 'on' ),	grid on	
else                                            grid off; end


%% store the updated M struct in the figure's user data
M.prevVoxel = voxel;  % also update the most recent voxel
set(M.fig, 'UserData', M);

return;
%--------------------------------------



%--------------------------------------
function [stimImage RF] = getCurStimImage(M, f, RFvals)
% Get a stimulus image matching the sampling positions as the RF.
% Also returns the RF resampled into a square grid.
x = prfSamplingGrid(M.params);

% account for the different stimuli that are shown next to each other
% f originally refers to the frame in the combined time series across scans:
% we want to break this down into scan n, frame f within that scan.
n = 1; 
nStimScans = numel(M.params.stim);
while n <= nStimScans,
    tmp = f + M.params.stim(n).prescanDuration; 
    if tmp > size(M.params.stim(n).images_org,2),
        f = tmp - size(M.params.stim(n).images_org,2);        
        n = n + 1;
    else
        f = tmp;
        break;
    end
end

% stim image
stimImage     = NaN(size(x));
stimImage(M.params.stim(1).instimwindow) = M.params.stim(n).images_org(:,f);
stimImage     = reshape(stimImage, size(x));

% RF
RF     = NaN(size(x));
RF(M.params.stim(1).instimwindow) = normalize(RFvals, 0, 1);
RF     = reshape(RF, size(x));

return
% -------------------------------------
