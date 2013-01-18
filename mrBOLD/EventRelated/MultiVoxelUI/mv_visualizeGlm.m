function mv_visualizeGlm(mv, v);
%
% mv_visualizeGlm(mv, [voxel=1]);
%
% Display the design matrix used, and the results of, a general linear
% model for a single voxel. The voxel # should be an index into the columns
% of mv.tSeries. 
%
% ras, 09/2006.
if notDefined('mv'), mv = get(gcf, 'UserData'); end
if ishandle(mv), mv = get(mv, 'UserData'); end
if notDefined('v'), v = 1; end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute GLM-related values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(mv, 'glm')
    mv = mv_applyGlm(mv);
end
X = mv.glm.designMatrix;
Y = mv.tSeries(:,v);
betas = squeeze(mv.glm.betas(:,:,v));
sems = squeeze(mv.glm.sems(:,:,v));
residual = mv.glm.residual(:,v);
varExplained = 100 * [1 - var(residual(:)) / var(Y(:))];
nConds = sum(mv.trials.condNums>0);

% construct matrix of predictor functions for each condition:
% (these predictors will include the dc components as well, so we 
% won't have them as separate traces):
dc = nConds+1:size(mv.glm.betas, 2);  % indices of DC components
for c = 1:nConds
	predictors(:,c) = X(:,[c dc]) * [mv.glm.betas(:,[c dc],v)'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the params are set to deconvolve, we can't visualize
% that yet:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isequal(mv.glm.type, 'selective averaging')
    warning('Sorry, Can''t visualize Deconvolutions yet.')    
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deal w/ panels: make control panel visible, set up
% second panel for display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% control panel: ensure exists and is visible, show voxel location
if ~checkfields(mv, 'ui', 'glmPanel'),
    mv = mv_glmPanel(mv);
end

if isequal(get(mv.ui.glmPanel, 'Visible'), 'off')
    mrvPanelToggle(mv.ui.glmPanel, 'on');
end

voxDesc = sprintf('Location: %s', num2str(mv.roi.coords(:,v)'));
set(mv.ui.glmVoxCoords, 'String', voxDesc);      

% display panel: create anew
delete( findobj('Tag', 'GLM Display Panel', 'Parent', gcf) ); % old panels
panel = uipanel('Parent', gcf, 'Units', 'norm', 'Position', [0 0 .8 1], ...
                'Tag', 'GLM Display Panel', ...
                'BackgroundColor', 'w', 'Title', '', 'BorderType', 'none');
            



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% show hemodynamic response function used for GLM         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes('Parent', panel, 'Position', [.05 .55 .15 .15]); % [.13 .58 .21 .34]
plot(mv.glm.hrf, 'k', 'LineWidth', 2);
grid on
xlabel('Time, frames')
ylabel('Arbitrary Units')
if isnumeric(mv.params.glmHRF)
    opts = {sprintf('Mean trial for conditions \n %s',num2str(mv.params.snrConds)), ...
        'Boynton gamma function', 'SPM difference-of-gammas' ...
        'Dale & Buckner ''97'};
    hrfName = opts{mv.params.glmHRF};
else
    hrfName = mv.params.glmHRF; hrfName(hrfName=='_') = ' ';
end
title({'HRF function used: ' hrfName}, 'FontWeight', 'bold')
axis square, set(gca, 'Box', 'off');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% show design matrix                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
axes('Parent', panel, 'Position', [.3 .55 .2 .34]); % [.13 .11 .21 .34]
hImg = imagesc(X);
colormap autumn
tickPts = [1:nConds];
tickLabels = {'Individual Conditions' 'DC Predictors for each run'};
set(gca,'XTick',tickPts);
xlabel('Predictors (Conditions + DC)')
ylabel('Time, Frames')
title('Design Matrix', 'FontWeight', 'bold')
set(hImg, 'ButtonDownFcn', 'zoom');
colorbar vert

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bar beta values for selected conditions %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axes('Parent', panel, 'Position', [.6 .55 .33 .34]);  %[.57 .58 .33 .34]
sel = find(tc_selectedConds(mv));
tmp = mv.trials.condColors(sel);
for i = 1:length(sel), col(i,:) = tmp{i}; end
xstr = tc_condInitials(mv.trials.condNames(sel));
mybar(betas(sel-1), sems(sel-1), xstr, [], col);
% xlabel Predictors
ylabel('% Signal Change')
% % also report d'
% if ~isfield(mv, 'dprime')
%     mv.dprime = mv_dprime(mv, [], 0);
% end
ttl = sprintf('Beta Values, Voxel %i\n', v);
title(ttl, 'FontWeight', 'bold');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% show time course + selected predictors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if mv.params.legend, ysz = .58; else, ysz = .72; end
mv.glm.tcAxes = axes('Parent', panel, 'Position', [.1 .1 ysz .3]); 

% plot
t = [1:size(mv.tSeries,1)] .* mv.params.framePeriod;
hold on
h{1} = plot(t, Y, '-', 'LineWidth', 2);
h{2} = plot(t, predictors(:,sel-1), 'LineWidth', 1.5);
h{3} = plot(t, X*betas', '-', 'LineWidth', 2); 
h{4} = plot(t, residual, '-', 'LineWidth', 1);
plot(t, zeros(size(t)), 'k:');
setLineColors([{'k'} mv.trials.condColors(sel) {[.2 .4 .8] [.8 0 0]}]);
xlabel('Time, sec')
ylabel('% Signal')
title('Time course + Scaled Predictors', 'FontWeight', 'bold')
zoom

% for longer time courses, may want a UI control
% scrollbar(mv.glm.tcAxes, mv.wholeTc);
scale = 300;  % max seconds to nicely plot TC
if max(t) > scale
    % shrink the axes a little for the control
    oldPos = get(gca,'Position');
    newPos = [oldPos(1) oldPos(2)+.08 oldPos(3) oldPos(4)-.08];
    set(gca,'Position',newPos);

    % set the axes to have a nice aspect ratio
    AX = axis;
    newAX = [1 scale AX(3) AX(4)];
    axis(newAX);

    % add a slider to move back and forth
    cb = 'val = get(gcbo,''Value''); axes(get(gcbo, ''UserData'')); ';
    cb = sprintf('%s \n axis([val val+%i %f %f]); clear val',...
                    cb, scale, AX(3), AX(4));
    
    sliderPos = [oldPos(1)+.06 oldPos(2)-.04 oldPos(3)-.16 .04];
    if mv.params.legend, sliderPos = sliderPos + [-.15 0 -.05 0]; end
    h1 = uicontrol('Parent', panel, 'Style', 'slider', ...
		'UserData', mv.glm.tcAxes, ...
        'Units','Normalized', 'Position', sliderPos, ...
        'Min', 0, 'Max', max(t)-scale, ...
        'Callback',cb,'BackgroundColor','w');
    
    zoomPos = [oldPos(1)-.06 oldPos(2)-.04 .08 .04];
    if mv.params.legend, zoomPos = zoomPos + [-.12 0 -.02 0]; end    
    h2 = uicontrol('Style','pushbutton', 'Units', 'Normalized',...
        'Position', zoomPos, ...
        'BackgroundColor', 'w', 'String', 'Whole Tc', ...
        'Callback','axis auto');
    
    set(h1, 'Units', 'pixels')
    set(h2, 'Units', 'pixels')

end

% set toggle checkboxes to toggle the different traces
for ii = 1:4
    set(mv.ui.glmToggles(ii), 'UserData', h{ii});
    
    % initialize each trace according to toggle
    if get(mv.ui.glmToggles(ii), 'Value')==0
        set(h{ii}, 'Visible', 'off');
    end
end    


% lastly, show % variance explained
varEx = sprintf('%2.1f%% Variance Explained', varExplained);
uicontrol('Parent', panel, 'Style', 'text', 'Units', 'normalized', ...
          'Position', [.8 .08 .18 .04], 'String', varEx, ...
          'BackgroundColor', 'w');
	  
return
