function prefs = mrPrefs;
% Prompts user to adjust MR object-related preferences. Initializes defaults 
% if they don't exist.
%
% prefs = mrPrefs;
%
% The user will usually only be prompted if the preferences don't yet
% exist. However, if you call this function with no return arg, it will
% always prompt.
%
% STILL UNDER CONSTRUCTION
%
% ras, 04/2006.
if(nargout==0)
    promptUser = true;
else
    promptUser = false;
end

% get default values for prefs --
% to edit new prefs, define them in this sub-routine.
dlg = defaultPrefsDialog;
prefNames = {dlg.fieldName}; % names of all prefs to be defined

% check that all methods are defined
if ispref('mr')
    prefs = getpref('mr');
    notAssigned = setdiff(prefNames, fieldnames(prefs));
    if ~isempty(notAssigned)
        promptUser = true;
    end
else
    % need to initialize
    disp('Initializing mrVista2 MR object preferences')
    dlg = defaultPrefsDialog;
    for i = 1:length(dlg)
        setpref('mr', dlg(i).fieldName, dlg(i).value);
    end
    prefs = getpref('mr');
    promptUser = true;
end
    
% put up a dialog, if requested or necessary
if promptUser           
    % plug in any already-defined prefs over the default values
    if exist('prefs') & ~isempty(prefs)
        for f = fieldnames(prefs)
            ii = cellfind(prefNames, f{1});
            if ii>0 % this is a valid pref to set
                dlg(ii).value = prefs.(f{1});
            end
        end
    end
    
    prefs = generalDialog(dlg, 'mrVista2 MR Preferences');
    
    % exit quietly if canceled -- otherwise update prefs
    if isempty(prefs)
        return;  
    else 
        for f = fieldnames(prefs)'
            setpref('mr', f{1}, prefs.(f{1}));
        end
    end
end


return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function dlg = defaultPrefsDialog;
% return the default MR prefs names/values as a dialog. This seems
% to be the easiest way to describe new preferences.
dlg(1).fieldName = 'interp';
dlg(1).style = 'popup';
dlg(1).string = 'Interpolation Method for Different Coordinate Spaces?';
dlg(1).list = {'Nearest-Neighbor' 'Linear' 'Cubic' 'Spline'};
dlg(1).value = 'Linear'; 

dlg(end+1).fieldName = 'alphaMethod';
dlg(end).style = 'popup';
dlg(end).string = 'Alpha Method for Multiple Overlays?';
dlg(end).list = {'Average: [1 0 0] + [.2 0 1] => [.6 0 .5]' ...
                'Add and saturate: [1 0 0] + [.2 0 1] => [1 0 1]' ...
                'Opaque: [1 0 0] + [.2 0 1] => [.2 0 1]'};
dlg(end).value = 1; 

return

