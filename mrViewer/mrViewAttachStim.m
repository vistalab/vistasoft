function ui = mrViewAttachStim(ui, stim);
% Attach stimulus / .par files to a mrViewer UI, checking
% that they exist and loading them.
%
% ui = mrViewAttachStim([ui], stim);
%
%
% ras, 12/05
if notDefined('ui'), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

% TO DO: would like to use stimParse here to parse the stimuli,
% but it's not cleaned up yet: there's the issue of setting
% the # of frames for each stim file to match the tSeries.
if isstruct(stim)
    ui.stim = stim;
    
elseif ischar(stim) | iscell(stim)
%     % check that the file exists
%     if ~exist(stim, 'file'), error(sprintf('%s not found.', stim)); end
    
    % load the file, using tSeries info if it's available
    if ~isempty(ui.tSeries)
        % guess the # secs per scan based on the first scan:
        % won't work in all situations, but since loading headers
        % is currently not as fast as it could be, this is a lot
        % faster than loading all the headers:
        hdr = mrLoadHeader(ui.tSeries{1});   
        secsPerScan = hdr.dims(4);
        framePeriod = hdr.voxelSize(4);        
        ui.stim = stimLoad(stim, secsPerScan, framePeriod);
    else
        ui.stim = stimLoad(stimFiles);
    end
else, error('stim specified in invalid format'); 
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