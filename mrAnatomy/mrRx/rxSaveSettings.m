function rxSaveSettings(rx,savePath);
%
% rxSaveSettings([rx,savePath]);
%
% Save only the interface-related fields
% of an rx struct, without the actual volumes.
% Leaves a much smaller footprint.
%
% Currently saves settings and points fields.
%
%
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('savePath')
    savePath = 'mrRxSettings';
end

if isfield(rx,'points')
    points = rx.points;
else
    points = {};
end

if ~isfield(rx,'settings')
    % store at least current settings
    rx = rxStore(rx);
end

settings = rx.settings;

save(savePath,'points','settings');

fprintf('Saved UI settings in %s.\n',savePath);

return

