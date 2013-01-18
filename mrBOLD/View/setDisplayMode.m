function vw = setDisplayMode(vw, mode)
%
% vw = setDisplayMode(vw, mode)
%
% Sets vw.ui.displayMode. Checks if necessary data is available for that
% displayMode. If not, loads it if possible, or returns with warning.
%
% mode: 'anat', 'co', 'cor', 'ph', 'amp', 'map'
%
% djh, 1/98
% ras, 10/07: checks the uimenu appropriate to the new mode.

% make sure the data are loaded before switching modes
switch mode
    case 'anat'
        if isempty(vw.anat)
            vw=loadAnat(vw);
        end
        
    case 'co'
        if isempty(vw.co)
            vw=loadCorAnal(vw);
        end
        
    case 'cor' % correlation coefficient
        if isempty(vw.co) || isempty(vw.ph);
            vw=loadCorAnal(vw);
        end
        
    case 'amp'
        %     vw = setAmplitudeWindow(vw);
        if isempty(vw.amp)
            vw=loadCorAnal(vw);
        end
        
    case 'projamp' % phase-projected amplitude
        if isempty(vw.amp) || isempty(vw.ph);
            vw=loadCorAnal(vw);
        end
        
    case 'ph'
        if isempty(vw.ph)
            vw=loadCorAnal(vw);
        end
        
    case 'map'
        if isempty(vw.map)
            warning('No parameter map. Use load parameter map from the File menu.'); %#ok<WNTAG>
        end
        vw = UpdateMapWindow(vw);
        
    otherwise
        myErrorDlg(['Unknown display mode: ',mode]);
end

% set the key field: vw.ui.displayMode
vw.ui.displayMode = mode;

% for hidden views, create a dummy mode field
if ~checkfields(vw, 'ui', [mode 'Mode']);
    f = [mode 'Mode']; % field name
    vw.ui.(f).clipMode = 'auto';
    vw.ui.(f).numGrays = 128;
    vw.ui.(f).numColors = 128;
    if isequal(mode, 'ph')
        vw.ui.(f).cmap = [gray(128); hsv(128)];
        vw.ui.(f).name = 'hsvCmap';
    else
        vw.ui.(f).cmap = [gray(128); hot(128)];
        vw.ui.(f).name = 'hotCmap';
    end
end

% for views with a GUI open, check the appropriate uimenu in
% the View menu:
if checkfields(vw, 'ui', 'windowHandle') && ishandle(vw.ui.windowHandle)
	viewMenu = findobj('Type', 'uimenu', 'Parent', vw.ui.windowHandle, ...
					   'Label', 'View');
	if isempty(viewMenu), return; end
	
	% find all of the relevant sub-menus in the view, for each mode
	labels = {'Anatomy and ROIs (no overlay)' 'Coherence Map' ...
			  'Amplitude Map' 'Phase Map' 'Parameter Map'};
	for i = 1:length(labels)
		menus(i) = findobj('Type', 'uimenu', 'Parent', viewMenu, ...
					   'Label', labels{i});
	end
	
	% set all the labels to unchecked
	set(menus, 'Checked', 'off');
	
	% now, check the appropriate menu
	ii = cellfind({'anat' 'co' 'amp' 'ph' 'map'}, mode);
	set(menus(ii), 'Checked', 'on');
	
	% also refresh the color bar (you may not need to refresh the
	% whole screen, but just the colorbar):
	if ismember(mode, {'co' 'amp' 'ph' 'map'})
		hideState = 'on';
	else
		hideState = 'off';
	end
	setColorBar(vw, hideState);
end
	


return;
