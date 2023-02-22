function [T p df B X Y] = rmCompareModelsGUI_ttest(M, active, control, varargin);
% Run a T-test comparing the response magnitude across different models.
%
%    [T p df B X Y] = rmCompareModelsGUI_ttest([M], [active, control=dialog], [options]);
%
% This T test applies a general linear model (see rmGLM) on the data from
% the compared models. The response magnitude of the time series from each
% model is computed as the beta coefficient in this GLM. The betas are then
% compared according the contrast (active > control), and the corresponding
% T value, p value and degrees of freedom are returned.
%
% More specifically, the predicted and measured time series are compared in
% the following way: the measured time series from each model are
% concatenated into a single long data vector (Y). Then a design matrix (X) is 
% constructed, in which each column represents a predictor for one of the
% models. The predictor for model j is set to the predicted time series (as
% depicted in the rm compare models GUI*) for the corresponding time points
% in Y, and zero elsewhere. A separate DC trend is also included for each
% time series. 
% 
% INPUTS:
%		M: model information from the GUI. [default: get from cur figure]
%
%		active: vector indicating which models (in M.dtList, M.modelList)
%		to use as the active condition;
%
%		control: vector indicating which models (in M.dtList, M.modelList)
%		to use as the control condition;
%
% OPTIONS:
%		'silent': do not output a message window with results. Otherwise,
%		the code will produce this window.
%
% OUTPUTS:
%		T: T value for the contrast.
%
%		p: p value associated with the T value and degrees of freedom.
%
%		df: degrees of freedom.
%
%		B: beta values for each model's predictor
%
% * NOTE: the predicted time series shown in the GUI are _not_ guaranteed to be
% exactly the same as the predictions used in solving the model), 
%
%
% ras, 03/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end
if ishandle(M),			M = get(M, 'UserData');				end

if notDefined('active') || notDefined('control')
	% dialog
	ui(1).fieldName = 'active';
	ui(1).style = 'listbox';
	ui(1).list = M.dtList;
	ui(1).string = 'Active condition(s):';
	ui(1).value = 2; 

	ui(2).fieldName = 'control';
	ui(2).style = 'listbox';
	ui(2).list = M.dtList;		
	ui(2).string = 'Control condition(s):';
	ui(2).value = 1; 

	resp = generalDialog(ui, 'pRF Model Contrast...', [.2 .6 .15 .15]);
	if isempty(resp), return; end % leave quietly
	[tmp active] = intersect(M.dtList, resp.active);
	[tmp control] = intersect(M.dtList, resp.control);
end

%% default params
silent = 0;

%% parse the options
for i = 1:length(varargin)
    switch lower(varargin{i})
        case 'silent', silent = 1;
    end
end

%% buld the X and Y matrices for the GLM
% for this I make the simplifying assumption that all time series are the
% same length. Fix if I need to compare tseries of different lengths later.
nFrames = size(M.tSeries{active(1)}, 1);
O = ones(nFrames, 1);  % ones and zeros columns will be useful below
Z = zeros(nFrames, 1); 

% build Y
v = M.voxel;
Y = [];  
for a = active
	Y = [Y; M.tSeries{a}(:,v)];
end
for c = control
	Y = [Y; M.tSeries{c}(:,v)];
end

% get the sampling grid for the pRF (not to be confused with the X and Y
% matrices for the GLM, I'll name the grid matrices xx and yy):

% build X
X = [];
condList = [active control];
nConds = length(condList);
for n = 1:nConds
	% index into nth model
	m = condList(n);
	
	% construct the predicted time series for this condition
	for f = {'x0' 'y0' 'sigma'}
		eval( sprintf('%s = M.%s{m}(:,v);', f{1}, f{1}) );
	end
	
	% get pRF values as column vectors
	RFvals = rmPlotGUI_makeRFs(M.modelName, [x0 y0 sigma 0 sigma 0], ...
								M.params.analysis.X, M.params.analysis.Y);
	
	% make predictions
	pred = M.params.analysis.allstimimages * RFvals;

	% in order to compare the beta values across models, we want the
	% predictors which the beta values reflect to have the same maximum
	% absolute value (1). This way, the scaling coefficient maps from a
	% normalized unit, to data units:
	pred = pred ./ repmat( max(abs(pred)), [nFrames 1] );
	
	% pad the prediction with zeros for other data
	predictor = [];
	for ii = 1:n-1, predictor = [predictor; Z]; end
	predictor = [predictor; pred]; 
	for ii = n+1:nConds, predictor = [predictor; Z]; end
		
	% append to design matrix
	X = [X predictor];
end

% add DC predictors to each run
for n = 1:nConds
	dc = []; 
	for ii = 1:n-1, dc = [dc; Z]; end
	dc = [dc; O]; 
	for ii = n+1:nConds, dc = [dc; Z]; end

	X = [X dc];
end

% build the contrast vector C
C = [ones(1, length(active)), -1*ones(1, length(control)), zeros(1, nConds)];


%% apply the GLM and run the contrast
[T df RSS B] = rmGLM(Y, X, C);

% look up an associated p value for T
p = er_ttest(df, T, -1);

%% display results if selected
if silent==0
	nA = length(active);
    namesA = implode(' ', M.dtList(active));
    namesC = implode(' ', M.dtList(control));	
    msg = sprintf('Voxel %i\n%s > %s Results: \n\n', v, namesA, namesC);
    msg = [msg sprintf('%s, -log10(p) = %.2f \n\n',...
                pvalText(p), -log10(p))];
    msg = [msg sprintf( 'Mean betas: active %.3f,  control %.3f\n\n', ...
						 mean( B(1:nA) ), mean( B(nA+1:end) ) )];
    msg = [msg sprintf('T-value: %.3f \n\n', T)];
	set(M.fig, 'Units', 'Normalized');
    figPos = get(M.fig, 'Position');
    msgPos = [figPos(1)-.2 figPos(2)+figPos(4)-.2 .2 .2];
    mrMessage(msg, 'left', msgPos, 11);
end



return
