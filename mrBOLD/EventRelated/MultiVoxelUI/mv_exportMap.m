function mv = mv_exportMap(mv, param, saveFlag, varargin);
%
% mv = mv_exportMap(mv, [param], [saveFlag], [options]);
%
% For Multi-Voxel UI,  export a set of voxel parameter values 
% as a map. [more]
%
%
% ras 08/05.
if notDefined('mv')
    mv = get(gcf, 'UserData');
end

if notDefined('param')
    % put up a dialog
    paramList = {'D-prime' 'D-prime-refcond' 'Preferred Condition' ...
                 'Selectivity Index' 'Voxel Reliability'  ...        
                 'Mutual Information' 'Omnibus Reliability' ...
                 'Mean Voxel Amplitudes' 'Amplitudes for Each Condition' ...
                 'Contrast'};
             
    dlg.fieldName = 'param';
    dlg.style = 'popup';
    dlg.string = 'Export which parameter?';
    dlg.list = paramList;
    dlg.value = 1;
    
    dlg(2).fieldName = 'saveFlag';
    dlg(2).style = 'checkbox';
    dlg(2).string = 'Save Parameter To File';
    dlg(2).value = 1;
    
    resp = generalDialog(dlg, 'Export to Map...');
    if isempty(resp),  disp('mv_exportMap: User Aborted'); return; end
    param = resp.param;
    saveFlag = resp.saveFlag;
end

% Get the map name,  and values for the map
switch lower(param)
    case 'd-prime', 
        mapName = 'd-prime';
        vals = mv_dprime(mv);
    case 'd-prime-refcond', 
        mapName = 'd-prime-refcond';
        [vals mapName] = mv_dprime_cond(mv);          
    case 'preferred condition', 
        mapName = 'Preferred Condition';
        [dprime vals] = mv_dprime(mv);
        
    case 'voxel reliability', 
        if ~isfield(mv, 'voxRSorting'),  mv = mv_sortByVoxR(mv);  end
        mapName = 'Voxel Reliability';
        vals = mv.voxRSorting.metric;
        
    case 'mutual information', 
        if ~isfield(mv, 'wta'),   mv = mv_reliability(mv, 'plotFlag', 0);  end
        mv = mv_mutualInformation(mv, [], 'auto', 1);
        mapName = 'Mutual Information';
        vals = mv.mutualInf.Im;
        
    case 'omnibus reliability', 
        if ~isfield(mv, 'MISorting'),  mv=mv_sortByOmniR(mv); end
        mapName = 'Omnibus Reliability';
        vals = mv.MISorting.metric;
        
    case 'selectivity index', 
        % special function call for high-res / lo-res comparisons
        mv = mv_exportSelectivity(mv, saveFlag);
        return
        
    case 'mean voxel amplitudes', 
        % ask user what sort of amplitudes to export
        ampNames = {'Peak-Baseline Amplitude' 'Beta Weights' ...
                    'Dot-product Amplitudes'};
        n = cellfind({'difference' 'betas' 'relamps'}, mv.params.ampType);
        mapName = ampNames{n};
        vals = mean(mv_amps(mv), 2)'; 
        
    case 'amplitudes for each condition', 
        % special function call: multiple maps
        mv = mv_exportAmplitudeMap(mv);
        return
        
    case 'contrast', 
        % contrast map values: conditions specified in varargin
        if length(varargin) < 2
            % get from dialog
           prompt = {'Active Conditions' 'Control Conditions' 'Map Name'};
           name = 'Input for Peaks function';            
           resp = inputdlg(prompt, mfilename, 1, {'1' '0' ''});
           active = str2num(resp{1});
           control = str2num(resp{2});
		   mapName = resp{3};
           
        else
            active = varargin{1};
            control = varargin{2};
			if length(varargin) > 2 
				mapName = varargin{3};
			end
            
        end
        if ~isfield(mv, 'glm'), mv = mv_applyGlm(mv); end        
        vals = glm_contrast(mv.glm, active, control);
        
        activeName = [mv.trials.condNames{active+1}];
        ctrlName = [mv.trials.condNames{control+1}];
	   if isempty(mapName)
			mapName = sprintf('%sV%s', activeName, ctrlName);
	   end
	   
	otherwise,
		myErrorDlg(sprintf('Parameter %s is not defined.', param));
        
end

% initialize a view to get parameters about the 
% map volume
fn = sprintf('getSelected%s', mv.roi.viewType);
view = eval(fn);
if isempty(view)
    % no selected view of the proper type -- make a hidden one 
    mrGlobals; loadSession; saveFlag = 1;
    fn = sprintf('initHidden%s', roi.viewType); view = eval(fn);
end
mapdims = viewGet(view, 'dataSize');
nScans = viewGet(view, 'numScans');
scan = mv.params.scans(1);

% plug in the values to the map volume:
mapvol = zeros(mapdims);
ind = roiIndices(view,mv.coords);
if ~exist('vals','var')
	fprintf('error: %s map does not exist\n',lower(param));
else
	mapvol(ind) = vals;
end

% plug the map volume into the view
fprintf('Assigning %s data to param map for scan %i\n', mapName, scan);
map = cell(1, nScans);
map{scan} = mapvol;
if ~isequal(view.name, 'hidden')
    view = setParameterMap(view, map, mapName);
    refreshScreen(view);
end

% evaluate this in the workspace,  so the view
% itself is updated
assignin('base', 'map', map);
evalin('base', sprintf('%s=setParameterMap(%s, map, ''%s'');', ...
    view.name, view.name, mapName));

% save if selected
if saveFlag==1
    mapName = sprintf('%s_%s', mapName, mv.roi.name);
    mapPath = fullfile(dataDir(view), mapName);
    if exist(mapPath, 'dir')
        load(mapPath, 'map', 'mapName'); 
        map{scan} = mapvol;
    end    
    save(mapPath, 'map', 'mapName');
    fprintf('Saved map %s.\n', mapPath);
end

% this is a check for mrVista 2: if we're running a mrVista2 session GUI,
% update it to show the new map
global GUI
if ~isempty(GUI)
    sessionGUI_selectDataType;
end


return

                 