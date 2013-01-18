function view = rmLoad(view, varargin)
% rmLoad - load data maps from retModel file into mrVista interface fields
% (co, amp, ph, and map fields).
%
% USAGE:
% 
% To call a user interface, invoke:
%  view = rmLoad([view=current view]);
% 	
% To manually specify the data to load, invoke:
%  view = rmLoad([view=current view], model, parameter, field);
%
% INPUTS:
%	view:     mrVista view. Defaults to getCurView.
%
%	'model': number of the model to load. Default 1.
%	
%	'parameter': name of parameter to load. See the 'paramNames' list in
%	this code for the full list (uses 2nd column of names). Examples are
%	'varexplained', 'eccentricity', 'polar-angle', 'sigma', 'sigma2'.
%
%	'field': one of 'co', 'amp', 'ph', 'map'. Specifies the field in which
%	to load the selected data map. The map will be loaded for that field
%	in the current data type and scan; this may override pre-existing
%	maps (e.g., corAnal fields), so be careful.
%
%
% 2006/02 SOD: wrote it.
% 2007/07 RAS: allows manual specification of data to load.
% 2008/02 SOD: clean up.
% 2008/07 RAS: allows the user to load betas
% 2008/10 RAS: commented out the call to 'refreshScreen', and added a call
% to it in the menu callbacks. For some scripted functions, such as
% rmLoadDefault, we don't necessarily want to redraw each time we load a
% map (it's faster to just redraw once when we're done). 
if ~exist('view','var') || isempty(view), view = getCurView; end;

% load file and store it in the view struct so if we load
% other parameters we should be faster.
try
	model = viewGet(view,'rmModel');
catch %#ok<CTCH>
	model = [];
end
if isempty(model),
	load(viewGet(view,'rmFile'),'model');
	view = viewSet(view,'rmModel',model);
end


% get model names
modelNames = cell(numel(model),1);
for n=1:numel(model),
	modelNames{n} = rmGet(model{n},'desc');
end


% define params, but only for the ones most used
% format: 1. name for interface, 2. name for model
paramNames = {'variance explained', 'varexplained';...
	'coherence',    'coherence';...
    'eccentricity', 'eccentricity';...
	'polar-angle',  'polar-angle';...
	'pRF size 1st or only pRF (\sigma)',  'sigma';...
    'log(eccentricity)', 'logecc';...
	'pRF gaussian angle (\theta)',  's_theta';...
    'pRF size in mm','s_mm';...
    'sign-specified variance explained', 'spvarexp';...
    'sign-specified coherence', 'spcoh';...
	'eccentricity 2nd pRF', 'eccentricity2';...
	'polar-angle 2nd pRF',  'polar-angle2';...
	'pRF size 2nd pRF (\sigma)',          'sigma2';...
	'1st/2nd pRF ratio',              'sigma ratio';...
	'polar/radial pRF ratio',              'sigma ratio oval';...
    'position variance', 'position variance';...
    'log(eccentricity 2nd pRF)', 'logecc2';...	
	'recompute variance explained',   'recompvarexplained';...
	'fit residuals (rms)',            'rms';...
	'x0 (deg)',            'x';...
	'y0 (deg)',            'y';...
	'lateralization index (across x)','latx';...
	'lateralization index (across y)','laty';...
	'pRF betas',			'beta';...
    'volume',   'volume';...
    'exponent', 'exponent'...
    };

allNamesUI = paramNames(:,1);
allNamesModel = paramNames(:,2);

% define field names
fieldNames = {'co','map','ph','amp'};

% allow for manual selection of fields:
if length(varargin) >= 3
	% we can omit the model #, but need the other two
	if isempty(varargin{1})
		sel.model = 1;
	else
		sel.model = varargin{1};
	end
	
	sel.parameter = varargin{2};
	sel.field = cellfind(fieldNames, varargin{3});
end

% get user selection if needed
if ~exist('sel','var') || isempty(sel),
    sel = rmLoadInterface(modelNames, allNamesUI, fieldNames); drawnow;
    if isempty(sel),
        fprintf('[%s]:user cancelled\n',mfilename);
        return;
    end
    sel.parameterName = allNamesUI{sel.parameter};
    sel.parameter = allNamesModel{sel.parameter};
else
    % input check
    if isempty(sel.model), error('No model number specified.'); end
    if isempty(sel.parameter), error('Improper parameter specification.'); 
    else sel.parameterName = sel.parameter; end
    if isempty(sel.field), error('Invalid view field specified.'); end
end

% load the variable
switch sel.parameter,
    case 'recompvarexplained'
        coords = rmGetCoords(view, model);
        param = rmVarExplained(view, coords, sel.model);

	case 'beta'
		param = rmGet(model{sel.model},sel.parameter);
		param = param(:,:,1); % the other betas are for trends 
		
    otherwise
        param = rmGet(model{sel.model},sel.parameter);
end;

if isempty(param),
	fprintf('[%s]: %s: parameter not defined.\n',...
		mfilename,rmGet(model{sel.model},'desc'));
	return;
else
	% must do some sanity checks here
	param(param == Inf)  = max(param(isfinite(param(:))));
	param(param == -Inf) = min(param(isfinite(param(:))));
	param(isnan(param)) = 0;

	% if we put this in the 'co' field than we have to make sure the
	% data range from 0 to 1;
	if strcmp(fieldNames{sel.field},'co'),
        param = max(param,0);
        param = min(param,1);
	end;
    % if we put this in the 'ph' field than we have to make sure the
	% data range from 0 to 2*pi;
	if strcmp(fieldNames{sel.field},'ph'),
        param = max(param,0);
        param = min(param,2*pi);
	end;
end;

% get old field parameters
oldparam = viewGet(view,fieldNames{sel.field});
if isempty(oldparam),
	oldparam = cell(1,viewGet(view,'numscans'));
end;
oldparam{viewGet(view,'curscan')} = param;
view  = viewSet(view,fieldNames{sel.field},oldparam);
switch lower(fieldNames{sel.field}),
	case 'map',
		view  = viewSet(view, 'mapName', sel.parameterName);
		% also set 'ph' if you set 'co' Surface painting expects some
		% values here
		
		% set the map units for certain map types
		switch lower(sel.parameter)
			case {'eccentricity' 'logecc' 'sigma' 'sigma2' 'x' 'y'}
				if ispc
					% can use special characters
					view = viewSet(view, 'mapUnits', char(176));
				else
					view = viewSet(view, 'mapUnits', char(176));
				end
			case {'polar-angle' 'polar-angle2'}
				view = viewSet(view, 'mapUnits', 'rad');
			otherwise,  % do nothing
		end
		
	case 'co',
		if isempty(viewGet(view,'ph')),
			phparam = cell(1,viewGet(view,'numscans'));
			phparam{viewGet(view,'curscan')} = zeros(size(param));
			view  = viewSet(view,'ph',phparam);
		end;

		% also set the colorbar title to be appropriate
		if checkfields(view, 'ui', 'colorbarHandle')
			hTitle = get(view.ui.colorbarHandle, 'Title');
			set(hTitle, 'String', sel.parameterName);
		end
end;


% refresh
view  = setDisplayMode(view, fieldNames{sel.field});
% view  = refreshScreen(view);

return;
%--------------------------------------
