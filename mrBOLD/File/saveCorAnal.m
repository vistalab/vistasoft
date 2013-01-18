function view = saveCorAnal(view, savePath, forceSave, saveDisplaySettings, saveMap, corners)
%
%   view = saveCorAnal(view, [savePath], [forceSave=0], [saveDisplaySettings=0], [saveMap=0], corners)
%
% Save the co, amp, and ph arrays in the view's
% subdirectory.
%
% Other inputs:
%   forceSave: if 1, won't prompt to save over an existing corAnal file.
%   saveDisplaySettings: if 1, will save the phMode settings for each scan.
%                       (setColorBar has been updated to read this info).
%
% If you change this function make parallel changes in:
%   saveCorAnal, saveParameterMap
%
% djh, 2/99
% djh, 2/2001, mrLoadRet 3.0
% ras, 11/2006: added ability to save display settings (for phMode):
% so you don't have to keep selecting / rotating / flipping color map
% between retinotopy scans.
% ka, 04/2008: added ability to save map array (for the retinotopy model
% data) and corners of atlas (for the atlas fitting)

if notDefined('savePath'),		
	savePath = fullfile(dataDir(view), 'corAnal.mat');
end
if notDefined('forceSave'),              forceSave = 0;                 end
if notDefined('saveDisplaySettings'),    saveDisplaySettings = 0;       end
if notDefined('saveMap'),    saveMap = 0;       end
if notDefined('corners')
    saveCorners = 0;
else
    saveCorners = 1;
end
    
% allow user to save as under a different name/location
if ismember(lower(savePath), {'select' 'dialog' 'ask'})
	msg = 'Save Coeherence Analysis as ...';
	savePath = mrvSelectFile('w', 'mat', msg, dataDir(view));
end

% check for existing file
if exist(savePath, 'file') & forceSave==0
    saveFlag = questdlg([savePath,' already exists. Overwrite?'], ...
                        'Save CorAnal?','Yes','No','No');
else
    saveFlag = 'Yes';
    
end

% save if we've opted to do so...
if strcmp(saveFlag, 'Yes')
    fprintf('Saving %s...',savePath);
    co = view.co;
    amp = view.amp;
    ph = view.ph;
    map = view.map;
    if saveMap==1
        if saveDisplaySettings==1
            if saveCorners==1
                phMode = view.ui.phMode;
                save(savePath, 'co', 'amp', 'ph', 'map', 'phMode', 'corners');
            else
                phMode = view.ui.phMode;
                save(savePath, 'co', 'amp', 'ph', 'map', 'phMode');
            end
        else
            if saveCorners==1
                save(savePath, 'co', 'amp', 'ph', 'map', 'corners');
            else
                save(savePath, 'co', 'amp', 'ph', 'map');
            end
        end
    else
        if saveDisplaySettings==1
            phMode = view.ui.phMode;
            save(savePath, 'co', 'amp', 'ph', 'phMode');
        else
            save(savePath, 'co', 'amp', 'ph');

        end
    end
    
    fprintf('done\n');
        
else
    fprintf('corAnal not saved...');
    
end


return;
