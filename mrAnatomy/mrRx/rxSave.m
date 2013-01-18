function rxSave(rx,savePath);
%
% rxSave(rx,[savePath]);
%
% Save a mrRx 'rx' struct, containing
% information on a volume transformation,
% as well as view settings, for later use.
%
%
% ras 02/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('savePath')
    [fname parent] = uiputfile('*.mat','Save Rx File as...');
    savePath = fullfile(parent,fname);
end

% make sure ui settings are saved
if ~isfield(rx,'settings')
    rx = rxStore(rx);
end

save(savePath,'rx');

fprintf('Saved ALL prescription information, including volumes, in %s.\n',savePath);

return
