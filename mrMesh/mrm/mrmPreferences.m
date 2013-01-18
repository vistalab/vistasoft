function prefs = mrmPreferences(newPrefs)
% Prompts user to adjust mrMesh preferences. Initializes defaults if ~exist.
% prefs = mrmPreferences
%
% USAGE:
% TO PROMPT FOR PREFERENCES: mrmPreferences; [no args]
% TO GET PREFERENCES WITHOUT PROMPTING: prefs = mrmPreferences;
% TO SET NEW PREFERENCES WITHOUT PROMPTING: mrmPreferences(newPrefs);
%
% The user will usually only be prompted if the preferences don't yet
% exist. However, if you call this function with no return arg, it will
% always prompt.
%
% HISTORY:
% 2005.08.11 RFD wrote it.
% 2006.02.06 RAS added pref for dimming cmap -- helps w/ phase maps.
%                also made the check for new prefs more robust.
% 2006.06.21 RAS added option to set preferences w/o prompting [in
% progress]
% 2008.05.16 RAS changed user prompt to use generalDialog instead of
% inputdlg: typing an invalid value for some preferences (such as
% 'layerMapMode') can create problems in other functions, without
% necessarily alerting the user. I figure it's safter to use this dialog to
% enforce only valid values for these fields.
% 2009.06.23 JW added 'min' as option data view

if nargin >= 1
    prefs = newPrefs;
    promptUser = false;
elseif(nargout==0) promptUser = true;
else               promptUser = false;
end

prefNames = {'overlayModulationDepth', 'dataSmoothIterations', ...
            'roiDilateIterations', 'clusterThreshold', ...
            'coTransparency', 'layerMapMode', 'overlayLayerMapMode'};
prefHelp = {'allows sulcal pattern to show through overlay', ...
            'try 1 or 2', ...
            '1 or 2 may help fill splotchy ROIs', ...
            '1 or 2 may help hide specle noise', ...
			'Determine transparency using co field', ...
            'options: ''all'' or ''layer1''', ...
            'options: ''mean'' or ''max'' or ''min'' or ''absval'''};
        
% layerMapMode values: 'all', 'layer1'
defaultVals = {0.2, 2, 0, 0, 0, 'layer1', 'max'};
if (~ispref('mesh'))
    setpref('mesh', prefNames, defaultVals);
    promptUser = true;
    disp(['Initializing mesh rendering preferences- run ' mfilename ' to change them in the future.']);
else
    % check if any new preferences were added or old preferences removed
    prefs = getpref('mesh');
    % Sometimes the 'mesh' preferences are an empty matrix. 
    % To prevent raising an error, we set them to default values:  
    if isempty(prefs) 
        setpref('mesh', prefNames, defaultVals);
        prefs = getpref('mesh'); 
    end 
    existingPrefs = fieldnames(prefs)';
    newPrefs = setdiff(prefNames, existingPrefs);
    for i = find(ismember(prefNames, newPrefs))
        % new preferences were added- try to keep this user's old values.
        % keep old vals by only adding new prefs.
        setpref('mesh', prefNames{i}, defaultVals{i});
        promptUser = true;
        disp(['New mesh rendering preferences were added (remember- use ' ...
                mfilename ' to change prefs in the future).']);
    end
    
    if ~isempty(newPrefs)
        % need to shuffle order of fields in prefs struct to 
        % correspond to the order in prefNames. <sigh>
        prefs = getpref('mesh');
        rmpref mesh
        for i = 1:length(prefNames)
            setpref('mesh', prefNames{i}, prefs.(prefNames{i}));
        end
        prefs = getpref('mesh')
    end
    
    % these prefs may have been set before, but are no longer relevant.
    removedPrefs = setdiff(existingPrefs, prefNames);
    for name = removedPrefs(:)',  rmpref('mesh', name{1});  end
end

if(promptUser)
	prefs = getpref('mesh');
	for ii = 1:length(prefNames)
		dlg(ii).fieldName = prefNames{ii};
		dlg(ii).style = 'number';
		dlg(ii).value = prefs.(prefNames{ii});
		dlg(ii).string = [prefNames{ii} ' - ' prefHelp{ii}];
		
		% special cases: these should be a different style than edit fields
		switch lower(prefNames{ii})
			case 'cotransparency', dlg(ii).style = 'checkbox';
			case 'layermapmode', 
				dlg(ii).style = 'popup';
				dlg(ii).list = {'layer1' 'all'};
				dlg(ii).value = prefs.layerMapMode;
			case 'overlaylayermapmode',
				dlg(ii).style = 'popup'; 
				dlg(ii).list = {'mean' 'max' 'min' 'absval'};
				dlg(ii).value = prefs.overlayLayerMapMode;
		end
	end
	
	[resp ok] = generalDialog(dlg, [mfilename ': Set Mesh Preferences']);
	if ~ok, return; end
	
	for ii = 1:length(prefNames)
		prefs.(prefNames{ii}) = resp.(prefNames{ii});
	end
	
	% set the modified preferences
	setpref('mesh', fieldnames(prefs), struct2cell(prefs));
end

prefs = getpref('mesh');

return;