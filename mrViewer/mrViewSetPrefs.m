function ui = mrViewSetPrefs(ui,prefs);
% Set preferences for a mrViewer UI.
%
% ui = mrViewSetPrefs(ui,prefs);
% 
% [more info]
%
%
% ras, 07/05.
if notDefined('ui'), ui = mrViewGet;        end

if ispref('VISTA','alphaMethod')
    alphaMethod = getpref('VISTA','alphaMethod');
else
    alphaMethod = 1;
end

if notDefined('prefs')
    % put up a dialog
    dlg(1).fieldName = 'baseInterp';
    dlg(1).style = 'popup';
    dlg(1).string = 'Interpolation Method for Base Volume?';
    dlg(1).list = {'Nearest-Neighbor' 'Linear' 'Cubic' 'Spline'};
    dlg(1).value =  cellfind(dlg(1).list,ui.settings.baseInterp); 
    
    dlg(end+1).fieldName = 'mapInterp';
    dlg(end).style = 'popup';
    dlg(end).string = 'Interpolation Method for Map Volumes?';
    dlg(end).list = {'Nearest-Neighbor' 'Linear' 'Cubic' 'Spline'};
    dlg(end).value = cellfind(dlg(1).list,ui.settings.mapInterp);    
    
    dlg(end+1).fieldName = 'alphaMethod';
    dlg(end).style = 'popup';
    dlg(end).string = 'Alpha Method for Multiple Overlays?';
    dlg(end).list = {'Average: [1 0 0] + [.2 0 1] => [.6 0 .5]' ...
                    'Add and saturate: [1 0 0] + [.2 0 1] => [1 0 1]' ...
                    'Opaque: [1 0 0] + [.2 0 1] => [.2 0 1]'};
    dlg(end).value = alphaMethod; 
    
    prefs = generalDialog(dlg,'mrViewer Preferences');
    
    % exit quietly if canceled
    if isempty(prefs), return;  end
end

for i = fieldnames(prefs)'
    ui.settings.(i{1}) = prefs.(i{1});
end

% deal w/ alphaMethod separately: make a MATLAB pref
% (may want to start doing this for most settings)
ui.settings = rmfield(ui.settings,'alphaMethod');
alphaMethod = cellfind(dlg(3).list,prefs.alphaMethod);
setpref('VISTA','alphaMethod',alphaMethod);

mrViewRefresh(ui);

return
