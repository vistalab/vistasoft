function rx = rxLoadSettings(rx,loadPath);
%
% rx = rxLoadSettings(rx,loadPath);
%
% Load settings fields in a mrRx struct.
%
%
% ras 03/05.
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
elseif ishandle(rx)
	rx = get(rx, 'UserData');
end

if ieNotDefined('loadPath')
    loadPath = 'mrRxSettings';
	if ~check4File(loadPath)
		loadPath = mrvSelectFile('r', 'mat', 'Select an rx settings file');
	end
end

fprintf('Loading settings from %s ...\n',loadPath);
tmp = load(loadPath);


% whatever params were saved,
% load into rx struct
fields = fieldnames(tmp);

for i = 1:length(fields)
    rx.(fields{i}) = tmp.(fields{i});
end

% set the list of settings to match
% the loaded settings
names = {rx.settings.name};
names = [{'(Default)'} names];
set(rx.ui.storedList,'String',names,'Value',length(names));
rx = rxReset(rx, length(names));


return
