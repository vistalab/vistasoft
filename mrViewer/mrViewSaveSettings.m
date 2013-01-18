function ui = mrViewSaveSettings(ui, format);
%
% Save the settings of a mrViewer ui in the base
% mr data file. 
%
% ui = mrViewSaveSettings(ui);
%
% Only works if the file is a MATLAB or NIFTI file.
%
% ras 10/2005.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;            end
if ishandle(ui),                     ui = get(ui,'UserData');   end
if notDefined('format'),             format = 'mat';            end

if ~isequal(format,'mat') & ~isequal(format,'nifti')
    error('Can only save settings for MATLAB or NIFTI format files.');
end

if isfield(ui.mr,'settings')
    % append the UI settings one-by-one
    for f = fieldnames(ui.settings)'
        ui.mr.settings.(f{1}) = ui.settings.(f{1});
    end
else
    % copy wholesale
    ui.mr.settings = ui.settings;
end

disp('Saving MR settings...')
mrSave(ui.mr, ui.mr.path, format);

return
