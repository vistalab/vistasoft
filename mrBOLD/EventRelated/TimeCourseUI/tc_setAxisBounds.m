function tc_setAxisBounds(tc,newBounds);
%
% tc_setAxisBounds(tc,[newBounds]):
%
% Set the axis bounds for the time Course UI plots.
%
% If not provided,  puts up a dialog.
%
%
% ras 03/05.
if ieNotDefined('tc')
    tc = get(gcf,'UserData');
end


if ieNotDefined('newBounds')
    % put up a dialog
    def = {num2str(axis)};
    prompt{1} = 'New Axis Bounds [xmin xmax ymin ymax]: ';
	dlgTitle='Set Axis Bounds';
	answer=inputdlg(prompt,dlgTitle,1,def);
    newBounds = str2num(answer{1});
elseif isequal(newBounds,'auto')
    % set empty, so that will always autoscale
    newBounds = [];
end

tc.params.axisBounds = newBounds;

set(tc.ui.fig,'UserData',tc);
timeCourseUI;

return