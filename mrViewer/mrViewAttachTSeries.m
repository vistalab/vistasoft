function ui = mrViewAttachTSeries(ui, tSeries);
% Attach tSeries paths / files to a mrViewer UI, checking
% that the files exist, but not loading them.
%
% ui = mrViewAttachTSeries(ui, tSeries);
%
% ras, 12/05.
if notDefined('ui'), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

% allow loaded tSeries files to be passed -- it may be memory-hogging,
% but it may make it easier in some situations to have the data pre-loaded
if isstruct(tSeries)
    ui.tSeries{end+1} = tSeries;
else
    % either a path to one file, or several paths, were passed: check
    % that the files exist
    if ischar(tSeries)
        % path string
%         if ~exist(tSeries, 'file')
%             error(sprintf('tSeries file %s not found.', tSeries));
%         end
        ui.tSeries{end+1} = tSeries;
    elseif iscell(tSeries)
        for i = 1:length(tSeries)
            ui = mrViewAttachTSeries(ui, tSeries{i});
        end
    end
end

% check if we should make the button for plotting time courses
% in the ROI panel visible:
if isfield(ui.controls,'roiTimeCourse') & ishandle(ui.controls.roiTimeCourse)
    if ~isempty(ui.tSeries) & ~isempty(ui.stim)
        set(ui.controls.roiTimeCourse, 'Visible', 'on');
    else
        set(ui.controls.roiTimeCourse, 'Visible', 'off');        
    end
end

return