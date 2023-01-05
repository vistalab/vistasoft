function ui = mrViewAddMap(ui, newMR);
%
% Add a new map to a ui struct.
% ui = mrViewAddMap(ui,newMR);
%
% ras 09/2005
if notDefined('ui'),	ui = mrViewGet;				end
if ishandle(ui),		ui = get(ui, 'UserData');	end

% allow map to be a struct array of new maps, and recursively add them:
if length(newMR) > 1
	for i = 1:length(newMR)
		ui = mrViewAddMap(ui, newMR(i));
	end
	return
end

% integer check
if ~isa(newMR.data,'double'), newMR.data = double(newMR.data); end

if isempty(ui.maps) % first map loaded
	ui.maps = newMR;
else                % add to other maps
	% check if name exists; if so, make unique
	exNames = {ui.maps.name}';
	test = strmatch(newMR.name,exNames);
	if ~isempty(test)
		newMR.name = sprintf('%s (%i)',newMR.name,length(test)+1);
	end

	ui.maps(end+1).baseXform = []; % will initialize new entry

	% copy fields over, in a memory-efficient way (?)
	for f = fieldnames(newMR)'
		ui.maps(end).(f{1}) = newMR.(f{1});
		newMR.(f{1}) = []; % clear to save memory
	end
end
ui.maps(end).baseXform = mrBaseXform(ui.mr, ui.maps(end));


% if loading a map for the first time, open
% a new overlay for the map:
if length(ui.maps)==1
	ui = mrViewAddOverlay(ui);
end

% also add the map to any popup lists of maps which
% may exist for overlays:
for o = 1:length(ui.overlays)
	if isfield(ui.overlays(o),'mapPopup') & ...
			ishandle(ui.overlays(o).mapPopup)
		set(ui.overlays(o).mapPopup,'String',{ui.maps.name});

		for j = 1:length(ui.overlays(o).threshMap)
			str = get(ui.overlays(o).threshMap(j),'String');
			str{end+1} = ui.maps(end).name;
			set(ui.overlays(o).threshMap(j),'String',str);
		end
	end
end

% update the info panel to include the new map as an option:
if checkfields(ui,'panels','info') & ishandle(ui.panels.info)
	ui = mrViewSet(ui,'infopanel');
end

ui = mrViewRefresh(ui);

return