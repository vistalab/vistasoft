function mv = mv_twModel(mv, rmParams, view, varargin);
%
% mv = mv_twModel(mv, [rmParams], [view], [options]);
%
% Visualize the results of a simple traveling-wave based retinotopic model 
% applied to multivoxel data.
%
% rmParams is the set of retinotopy model parameters. For an example of the
% structure of this, load a saved model file, or see rmDefineParameters.
%
% In order to get the retinotopy model data, you should provide a view with
% a loaded model. Otherwise, a hidden view will be initialized with the
% same data type / scans as the mv data; the code will look for the first
% file named "retModel-" in the view's data dir. If none are found, it will
% throw an error.
%
% rot: rotation compensation value [default=0]. If nonzero, will rotate the
% stimulus images created by rmStimulusMatrix by the specified amount (in
% degrees clockwise).
% guiFlag: if set to 0, won't open a GUI, just return the mv struct with the .tw and .amps
% fields, and rotations applied. [default 1, open a GUI]
%
%
% ras, 08/21/06.
% ras, 03/28/07: removed GLM criterion, replaced with a view argument.
if isequal(mv, 'update')
    % callback to update the GUI
    mv_twModelUpdate;
    return
end

if notDefined('mv'), mv = get(gcf, 'UserData'); end
if notDefined('rmParams'), rmParams = exp7_retinoParams(mv.trials); end
if notDefined('view')
	view = eval( sprintf('getSelected%s', mv.roi.viewType) );
	if isempty(view)	% init hidden view
		view = feval( sprintf('initHidden%s', mv.roi.viewType), ...
					   mv.params.dataType, mv.params.scans );
	end
end	


%%%%% params / defaults
rot = 0; % rotation compensation 
guiFlag = 1;    % make GUI
xRange = -20:.5:20;
yRange = -14:.5:14;
dt = 'Averages';	% data type from which to get tw estimates
scans = [1 2];  % [polar_angle ecc] scans from which to get tw estimates
% parse options
for i = 1:2:length(varargin)
    eval( sprintf('%s = %s', varargin{i}, num2str(varargin{i+1})) );
end

% get voxel amplitudes
mv.amps = mv_amps(mv);

% remove NaNs
[rows cols] = find( isnan(mv.amps) );
if any(rows)
	noNans = setdiff(1:size(mv.amps, 1), rows);
	mv = mv_selectSubset(mv, noNans, 'voxels');
	mv.amps = mv_amps(mv);
end

% convert stimuli in rmParams to a more useable format
[rmParams images] = rmStimulusMatrix(rmParams, xRange, yRange, 0);

nVoxels = size(mv.amps, 1);
nConds = min(size(mv.amps, 2), size(images, 3));


%%%%%%%%%%%%%%%%%%%
% get predictions %
%%%%%%%%%%%%%%%%%%%
mv.tw = twEstimateRFs(view, mv.roi, dt, scans, ...
					'xRange', xRange, 'yRange', yRange);

% rotation compensation for the model as well
if rot ~= 0
    R = sqrt(mv.tw.x0{1}.^2 + mv.tw.y0{1}.^2);
    theta = atan2(mv.tw.y0{1}, mv.tw.x0{1});
    theta = theta - deg2rad(rot);
    theta = mod(theta, 2*pi);
    mv.tw.x0{1} = R .* cos(theta);
    mv.tw.y0{1} = R .* sin(theta);
end

% % remove voxels for which the pRF model really doesn't work:
% % <10% variance explained, for a model with as many free parameters as
% % the pRF model, means a really poor fit.
% mv = mv_selectSubset(mv, find(mv.tw.varexp{1} >= .1), 'voxels');
if size(mv.coords, 2) < 3
	error('<3 voxels have reasonable data! Aborting.')
end

%% loop through voxels, making a prediction for each
[mv.tw.amps] = twEventPrediction(mv, rmParams, mv.tw);


%% scale each predicted response pattern to be close to the observed amps
% for c = 1:nConds
% 	[t df rss b] = rmGlm(mv.amps(:,c), [mv.tw.amps(:,c) ones(nVoxels, 1)]);
% 	mv.tw.amps(:,c) = b(1) .* mv.tw.amps(:,c) + b(2);
% end
mv.tw.amps = mv.tw.amps .* (max(mv.amps(:)) / max(mv.tw.amps(:)));
% mv.tw.amps = mv.tw.amps - mean(mv.tw.amps(:));

% compute the correlation for each voxel between the pattern of observed
% amplitudes across conditions, and the predicted amplitudes
mv.tw.voxR = zeros(1, nVoxels);
for v = 1:nVoxels
	y1 = mv.amps(v,:)';
	y2 = mv.tw.amps(v,:)';
	
	if any(isnan(y2) | isinf(y2)) | all(y2)==0
		continue
	end
		
	% also try scaling each voxel's responses according to its own scale
	% factor (will definitely need to test again on noise)
	R = corrcoef(y1, y2);
	
	if isnan(R(2)) | isinf(R(2))
		continue
	end
	
	mv.tw.voxR(v) = R(2);	
% 	[t df rss b] = rmGlm(y1, [y2 ones(size(y2, 1), 1)]);		
% 	mv.tw.amps(v,:) = mv.tw.amps(v,:) .* b(1);
end

% compute overall correlation between patterns of amplitudes
% (we compute this as a weighted regression, using the proportion
% variance explained in the training stage as the weights)
ok = find( ~isnan(mv.tw.amps(:)) & ~isnan(mv.amps(:)) & ...
		   ~isinf(mv.tw.amps(:)) & ~isinf(mv.amps(:)) );
weights = 1 - repmat(mv.tw.varexp{1}', [1 nConds]);
[a_fit sig_a yy chisqr r] = linreg(mv.tw.amps(ok), mv.amps(ok), weights(ok));
mv.tw.patternR = r;
% mv.tw.p = p;

mv.tw.params = rmParams;
mv.tw.images = images;

if guiFlag==1      
	mv = mv_twModelGUI(mv);
end

return
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function mv = mv_twModelGUI(mv);
% create GUI for viewing the results of the retinotopy model.
javaFigs = feature('javafigures');
if ispref('VISTA', 'javaOn') 
    feature('javafigures', getpref('VISTA', 'javaOn'));
else
    feature('javafigures', 0);
end

nVoxels = size(mv.amps, 1);
nConds = size(mv.amps, 2);

% if we have a figure open, use it; otherwise open a new one
if checkfields(mv, 'ui', 'fig') & ishandle(mv.ui.fig)
    % delete existing objects
    delete( findobj('Parent', mv.ui.fig) );
    
else
    mv.ui.fig = figure('Color', 'w', 'Position', [0 100 800 600], ...
					   'Name', sprintf('%s Traveling Wave Model', mv.roi.name));
    
end

% set up axes for plotting population responses
mv.ui.rmVoxAmps = subplot('Position', [.05 .1 .45 .3]);
mv.ui.rmVoxAmpsLine = plot(mv.amps(:,1), 'k', 'LineWidth', 1.5);
mv.ui.rmVoxAmpsPred = plot(mv.tw.amps(:,1), 'b', 'LineWidth', 1.5);
axis auto; AX = axis;
set(gca, 'Box', 'off');
mv.ui.rmVoxAmpsSel = line([1 1], AX(3:4), 'Color', 'r', ...
                          'LineStyle', '--', 'LineWidth', 1.5);
scrollbar(mv.ui.rmVoxAmps, 100);

% add text uicontrols reporting on the current voxel
mv.ui.ampText = uicontrol('Style', 'text', 'String', '', ...
                    'Units', 'norm', 'Position', [.25 .46 .18 .04], ...
                    'HorizontalAlignment', 'left', ...
					'ForegroundColor', 'r', ...
					'BackgroundColor', 'w', 'FontSize', 10);
                
mv.ui.predText = uicontrol('Style', 'text', 'String', '', ...
                    'Units', 'norm', 'Position', [.05 .46 .18 .04], ...
                    'HorizontalAlignment', 'left', ...
					'ForegroundColor', 'r', ...
                    'BackgroundColor', 'w', 'FontSize', 10);



% set up axes for plotting RF / stimulus in retinotopic space
mv.ui.rmImage = subplot('Position', [.55 .55 .45 .35]);

% set up axes for displaying the predicted amplitudes of the selected voxel
% for each condition:
mv.ui.rmCondAmps = subplot('Position', [.6 .1 .3 .3]);

% set up axes for regressing predicted and observed patterns
% against one another
mv.ui.rmPredCompare = subplot('Position', [.05 .6 .45 .3]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now add a control panel to the side, with the main controls %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv.ui.rmPanel = mrvPanel('right', .2);
set(mv.ui.rmPanel, 'BackgroundColor', 'w', 'Title', 'Controls');

% common callback for controls
cb = 'mv_twModel(''update''); ';

% add a slider for selecting voxels
mv.ui.rmVoxel = mrvSlider([.1 .85 .8 .05], 'Voxel', 'Parent', mv.ui.rmPanel, ...
                          'Callback', cb, 'Range', [1 nVoxels], 'Value', 1, ...
                          'IntFlag', 1);
                      
% add a popup for selecting condition (stimulus)
mv.ui.stimPopup = uicontrol('Parent', mv.ui.rmPanel, 'Style', 'popup', ...
                    'Units', 'normalized', 'Position', [.1 .75 .8 .05], ...
                    'Callback', cb, 'BackgroundColor', 'w', 'FontSize', 10, ...
                    'String', mv.trials.condNames(2:end), 'Value', 1);
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'text', 'Units', 'normalized', ...
          'Position', [.1 .8 .8 .05], 'String', 'Stimulus', 'FontSize', 11, ...
          'BackgroundColor', 'w');
      
% add toggle switches for the time course elements
callback = ['opt = get(gcbo, ''Value'') + 1;  tmp = {''off'' ''on''}; ' ...
            'set( get(gcbo, ''UserData''), ''Visible'', tmp{opt} ); ' ...
            'clear opt tmp; '];

% text to display voxel coords
mv.ui.coordsText = uicontrol('Parent', mv.ui.rmPanel, 'Style', 'text', 'String', '', ...
                    'Units', 'norm', 'Position', [.1 .5 .8 .05], ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', 'w', 'FontSize', 10);
                     
% add buttons to sort the voxels according to different criteria:
cb = ['tmp = get(gcf, ''UserData''); ' ...
      '[tmp2 newOrder] = sort(tmp.tw.varexp{1}); ' ...
	  'set(gcf, ''UserData'', tmp); ' ...
      'mv_selectSubset(tmp, newOrder, ''voxels'', 0); ' ...
	  'mv_twModel(''update''); ' ...
	  'clear tmp tmp2 newOrder'];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .3 .8 .03], ...
          'String', 'Sort by variance explained (training)', ...
          'BackgroundColor', [.8 1 .7], 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);

cb = ['tmp = get(gcf, ''UserData''); ' ...
      'mv_sortVoxels(tmp, ''varexplained''); ' ...
	  'set(gcf, ''UserData'', tmp); ' ...
	  'mv_twModel(''update''); ' ...
	  'clear tmp tmp2 newOrder'];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .27 .8 .03], ...
          'String', 'Sort by variance explained (test)', ...
          'BackgroundColor', [.8 1 .7], 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);
	  
cb = ['tmp = get(gcf, ''UserData''); ' ...
      'mv_sortVoxels(tmp, ''sortrows''); ' ...
	  'set(gcf, ''UserData'', tmp); ' ...
	  'mv_twModel(''update''); ' ...
	  'clear tmp tmp2 newOrder'];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .24 .8 .03], ...
          'String', 'Sort by condition amps...', ...
          'BackgroundColor', [.8 1 .7], 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);
	  
cb = ['tmp = get(gcf, ''UserData''); ' ...
      '[tmp2 newOrder] = sort(tmp.tw.voxR); ' ...
	  'set(gcf, ''UserData'', tmp); ' ...
      'mv_selectSubset(tmp, newOrder, ''voxels'', 0); ' ...
	  'mv_twModel(''update''); ' ...
	  'clear tmp tmp2 newOrder'];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .21 .8 .03], ...
          'String', 'Sort by voxel pRF fits...', ...
          'BackgroundColor', [.8 1 .7], 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);	  
	  
	  
                     
% add buttons which let you launch a time course UI for the current
% voxel, or a multiVoxelUI:
cb = ['tmp = get(gcf, ''UserData''); ' ...
      'voxel = get(tmp.ui.rmVoxel.sliderHandle, ''Value''); ' ...
      'mv_selectSubset(tmp, voxel, ''voxels'', 2); ' ...
      'clear tmp voxel'];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .6 .8 .05], ...
          'String', 'Time Course UI (cur voxel)', ...
          'BackgroundColor', 'w', 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);
      
cb = ['tmp = get(gcf, ''UserData''); ' ...
      'voxel = get(tmp.ui.rmVoxel.sliderHandle, ''Value''); ' ...
      'mv_selectSubset(tmp, voxel, ''voxels'', 1); ' ...
      'clear tmp '];
uicontrol('Parent', mv.ui.rmPanel, 'Style', 'pushbutton', ...
          'Units', 'norm', 'Position', [.1 .65 .8 .05], ...
          'String', 'Multi Course UI (cur voxel)', ...
          'BackgroundColor', 'w', 'FontName', mv.params.font, ...
          'FontSize', 9, 'Callback', cb);      
                     
% update figure w/ mv stuff
set(gcf, 'UserData', mv);
                      
feature('javafigures', javaFigs);

mv_twModel('update');

return
% /----------------------------------------------------------------------/ %




% /----------------------------------------------------------------------/ %
function mv_twModelUpdate;
% update the GUI for the retinotopy model viewer.
mv = get(gcf, 'UserData');

% get params from GUI
cond = get(mv.ui.stimPopup, 'Value');
voxel = get(mv.ui.rmVoxel.sliderHandle, 'Value');

nVoxels = size(mv.tw.amps, 1);
nConds = size(mv.tw.amps, 2);

X = mv.tw.X; Y = mv.tw.Y;
xRange = unique(X); yRange = unique(Y);

%%%%% display:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% population responses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes(mv.ui.rmVoxAmps);
try
    set(mv.ui.rmVoxAmpsLine, 'YData', mv.amps(:,cond));
    set(mv.ui.rmVoxAmpsPred, 'YData', mv.tw.amps(:,cond));
    set(mv.ui.rmVoxAmpsSel, 'XData', [voxel voxel]);
catch
    cla
    hold on
    mv.ui.rmVoxAmpsLine = plot(1:nVoxels, mv.amps(:,cond), 'k-');
    mv.ui.rmVoxAmpsPred = plot(1:nVoxels, mv.tw.amps(:,cond), 'b:', 'LineWidth', 1.5);
    axis auto
    AX = axis;
    mv.ui.rmVoxAmpsSel = line([voxel voxel], [AX(3) AX(4)]);
    set(mv.ui.rmVoxAmpsSel, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
    xlabel('Voxel', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);
    ylabel('% Signal', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);
end
name = mv.trials.condNames{cond+1};
% legend({['Amps: ' name] 'Prediction' 'Current Voxel'}, -1);

mv.tw.amps(isnan(mv.tw.amps)) = 0;
[R p] = corrcoef([mv.amps(:,cond) mv.tw.amps(:,cond)]);
ttl = sprintf('R^2 = %1.2f, %s', R(2)^2, pvalText(p(2)));
title(ttl, 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);

% place text /symbols indicating the current voxel amplitude / prediction
plot(voxel, mv.amps(voxel,cond), 'sm');
plot(voxel, mv.tw.amps(voxel,cond), 'ok');
txt = sprintf('Voxel Amplitude: %1.1f', mv.amps(voxel,cond));
set(mv.ui.ampText, 'String', txt);
txt = sprintf('Prediction: %1.1f', mv.tw.amps(voxel,cond));
set(mv.ui.predText, 'String', txt);
txt = sprintf('Coords: %s', num2str(mv.coords(:,voxel)'));
set(mv.ui.coordsText, 'String', txt);

% (let's have a callback so we can select a voxel by clicking on the axes)
bdf = ['tmp = get(gcf, ''UserData''); ' ...
       'pt = get(gca, ''CurrentPoint''); ' ...
       'mrvSliderSet(tmp.ui.rmVoxel, ''Value'', round(pt(1))); ' ...
       'mv_twModel(''update''); ' ...
       'clear tmp pt '];
set(gca, 'ButtonDownFcn', bdf);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retinotopy images: stimulus / receptive field
% (first, compute the receptive field)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sigma = mv.tw.sigma{1}(voxel);
x0 = mv.tw.x0{1}(voxel);
y0 = mv.tw.y0{1}(voxel);
beta = mv.tw.beta{1}(voxel);
% sig = mv.tw.log10p{1}(voxel);

RF = rfGaussian2D(X, Y, sigma, sigma, 0, x0, y0);
RF = normalize(RF);

% (now, show both, using the alpha to see superimposed features)
axes(mv.ui.rmImage);
cla
hold on
stim = normalize(double(mv.tw.images(:,:,cond)));
img = cat(3, RF, RF, stim);
image(xRange, yRange, flipdim(img,1));  % counter IMAGE's Y-axis flip
axis image;
overlap = 100 * sum(RF(logical(stim))) / sum(RF(:));
ttl = sprintf('RF / stim overlap: %2.4f%%', overlap);
title(ttl, 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Responses to each condition (for the selected voxel)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes(mv.ui.rmCondAmps);
cla
hold on
plot(mv.amps(voxel,:), 'ko-', 'LineWidth', 1.5);
plot(mv.tw.amps(voxel,:), 'bs--', 'LineWidth', 1.5);
R = corrcoef(mv.amps(voxel,:), mv.tw.amps(voxel,:));
title(sprintf('R^2: %1.2f', R(2)^2), 'FontName', mv.params.font, ...
		'FontSize', mv.params.fontsz);
% legend('Data', 'Model', 'Current Condition', -1);
AX = axis;
htmp = line([cond cond], [AX(3) AX(4)]);
set(htmp, 'Color', [.2 .1 .9], 'LineStyle', '--', 'LineWidth', 1.5);
tickLabel = tc_condInitials(mv.trials.condNames(2:nConds+1));
set(gca, 'XTick', 1:nConds, 'XTickLabel', tickLabel, 'Box', 'off');
Xlabel('Condition', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);
ylabel('% Signal', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);

% (let's have a callback so we can select a condition by clicking on the axes)
bdf = ['tmp = get(gcf, ''UserData''); ' ...
       'pt = get(gca, ''CurrentPoint''); ' ...
       'set(tmp.ui.stimPopup, ''Value'', round(pt(1))); ' ...
       'mv_twModel(''update''); ' ...
       'clear tmp pt '];
set(gca, 'ButtonDownFcn', bdf);



return
