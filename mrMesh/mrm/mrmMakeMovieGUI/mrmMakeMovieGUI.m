function varargout = mrmMakeMovieGUI(varargin)
% mrmMakeMovieGUI(meshID)
%   Given a mesh ID #, opens a GUI allowing you to set up a series of
%   events to be displayed in a .avi file.
%
%   Events consist of waypoints, transitions, and pauses.  All pauses must
%   follow waypoints.  Transitions must appear with waypoints on either
%   side.  Move the mesh manually to find the desired waypoint location, or
%   use the presets.
%
% Usage:
%   mrmMakeMovieGUI(meshID);
%
% Known issues:
%   Jump to view isn't accurate with diffusion meshes for whatever reason.
%   Probably need to edit mrmRotateCamera and add a conditional for when
%   we're rotating such meshes, providing different coordinates (should
%   they be consistent across diffusion meshes).
%
% [renobowen@gmail.com 2010]
%

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @mrmMakeMovieGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @mrmMakeMovieGUI_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
    
end

function mrmMakeMovieGUI_OpeningFcn(hObject, eventdata, handles, meshID)
    if (~exist('meshID', 'var')), meshID = []; end
    
    % Choose default command line output for mrmMakeMovieGUI
    handles.output      = hObject;
    handles.meshID      = meshID;
    handles.events      = {};
    handles.isSaved     = true;
    handles.filename    = [];
    handles.filedir     = [];
    handles.clipboard   = [];
    handles.index       = 0;
    
    set(handles.EventTypeMenu, 'String', {'Waypoint', 'Transition', 'Pause'});
    
    % Update handles structure
    handles = UpdateFileStatus(handles, true);
    guidata(hObject, handles);
    
end

function varargout = mrmMakeMovieGUI_OutputFcn(hObject, eventdata, handles) 
    if (isempty(handles.meshID))
        fprintf(1, 'No mesh ID # specified - closing GUI.\n');
        close(handles.MakeMovieGUI);
    end
end

function handles = TurnOffInvalidButtons(handles)
    if (isempty(handles.clipboard))
        enablePaste = 'off';
    else
        enablePaste = 'on';
    end
    if (length(handles.events) < 1)
        enableEventDependent = 'off';
    else
        enableEventDependent = 'on';     
    end
    % Paste buttons
    set(handles.EventMenu_Paste, 'Enable', enablePaste);
    set(handles.EventContextMenu_Paste, 'Enable', enablePaste);
    
    % Buttons dependent on existence of events
    set(handles.ExportButton, 'Enable', enableEventDependent);
    set(handles.EditEventButton, 'Enable', enableEventDependent);

    set(handles.PreviewButton, 'Enable', enableEventDependent);
    set(handles.DeleteEventButton, 'Enable', enableEventDependent);

    set(handles.MoveDownButton, 'Enable', enableEventDependent);
    set(handles.MoveUpButton, 'Enable', enableEventDependent);

    set(handles.MovieMenu_Export, 'Enable', enableEventDependent);
    set(handles.MovieMenu_Preview, 'Enable', enableEventDependent);
    set(handles.EventMenu_Delete, 'Enable', enableEventDependent);
    set(handles.EventMenu_Edit, 'Enable', enableEventDependent);
 
    set(handles.EventMenu_Copy, 'Enable', enableEventDependent);
    set(handles.EventMenu_Cut, 'Enable', enableEventDependent);

    set(handles.EventContextMenu_Delete, 'Enable', enableEventDependent);
    set(handles.EventContextMenu_Edit, 'Enable', enableEventDependent);

    set(handles.EventContextMenu_Copy, 'Enable', enableEventDependent);
    set(handles.EventContextMenu_Cut, 'Enable', enableEventDependent);

    set(handles.FileMenu_SaveAs, 'Enable', enableEventDependent);
    set(handles.FileMenu_Save, 'Enable', enableEventDependent);
end

function handles = UpdateFileStatus(handles, saving)
    if (~isempty(handles.filename))
        if (saving)
            handles.isSaved = true;
            set(handles.FilenameText, 'String', handles.filename);
        else
            handles.isSaved = false;
            set(handles.FilenameText, 'String', [handles.filename '*']);
        end
    else
        if (saving)
            handles.isSaved = true;
        else
            handles.isSaved = false;
        end
        set(handles.FilenameText, 'String', 'No save file.');
    end
    handles = TurnOffInvalidButtons(handles);
end

function EventList_Callback(hObject, eventdata, handles)
    if (length(handles.events) < 1), return; end
    
    index = get(handles.EventList, 'Value');
    event = handles.events{index};
    if (strcmp(event.eventType,'waypoint'))
        mrmRotateCamera(handles.meshID, event.rotation, [], event.frustum, [], event.origin);
    end
end

function MoveUpButton_Callback(hObject, eventdata, handles)
    index = get(handles.EventList, 'Value');
    
    ExchangeEvents(hObject, handles, index, index - 1);
    
end

function MoveDownButton_Callback(hObject, eventdata, handles)
    index = get(handles.EventList, 'Value');
    
    ExchangeEvents(hObject, handles, index, index + 1);
    
end

function ExchangeEvents(hObject, handles, selected, exchanged)
    strings = get(handles.EventList, 'String');
    if ((exchanged > length(strings)) || exchanged < 1), return; end
    
    tmpString           = strings{exchanged};
    strings{exchanged}  = strings{selected};
    strings{selected}   = tmpString;
    
    tmpEvent                    = handles.events{exchanged};
    handles.events{exchanged}   = handles.events{selected};
    handles.events{selected}    = tmpEvent;
    
    selected = exchanged;
    set(handles.EventList, 'String', strings);
    set(handles.EventList, 'Value', selected);
    
	handles = UpdateFileStatus(handles, false);
    guidata(hObject, handles);
    
end

function AddEvent_Callback(hObject, eventdata, handles, eventType, doInsert)
    % Navigating around a godawful bug with single selection GUIs
    if (length(handles.events) < 1), set(handles.EventList, 'Value', 1); end
    
    % Get event type from drop down if it's not specified
    if (~exist('eventType', 'var') || isempty(eventType))
        eventTypes = get(handles.EventTypeMenu, 'String');
        eventType = eventTypes{get(handles.EventTypeMenu, 'Value')};
    end
    
    % Ship off task of getting parameters about event to smaller GUIs
    switch lower(eventType)
        case 'waypoint'
            waitfor(mrmMakeMovieGUI_Waypoint(handles.MakeMovieGUI, handles.meshID));

        case 'transition'
            waitfor(mrmMakeMovieGUI_Transition(handles.MakeMovieGUI));
            
        case 'pause'
            waitfor(mrmMakeMovieGUI_Pause(handles.MakeMovieGUI));
            
        otherwise
            fprintf(1, 'Unrecognized radio button selected.\n');
            
    end
    
    % Get data back from the GUIs, if any
    data = get(handles.MakeMovieGUI, 'UserData'); % Get the data back from the pop up
    if (isempty(data)), return; end % We're done if there are no params
    
    % If we're not inserting, tack it after current selection
    numEvents = length(handles.events);
    if (~exist('doInsert', 'var') || isempty(doInsert) || (numEvents < 1))
        index = numEvents + 1;
    else
        index = get(handles.EventList, 'Value') + 1;
    end
        
    handles = InsertEvent(hObject, handles, data, index);
    
    set(handles.MakeMovieGUI, 'UserData', []); % Done with the GUI data, clear it
    guidata(hObject, handles);
end

function handles = InsertEvent(hObject, handles, event, position)
% Insert event into visible list and storage array at specified position
    handles.events = CellInsert(handles.events, event, position);
    strings = get(handles.EventList, 'String');
    strings = CellInsert(strings, GetListString(event), position);
    set(handles.EventList, 'Value', position);
    set(handles.EventList, 'String', strings);
    handles = UpdateFileStatus(handles, false);
end


function cells = CellInsert(cells, value, index)
% Insert a value into a cell, shifting over the values in its place if
% necessary
    numCells = length(cells);
    if (numCells >= index)
        for i = numCells:-1:index
            cells{i+1} = cells{i};
        end
    end
    cells{index} = value;
end

function listString = GetListString(data)
    switch (data.eventType)
        case 'waypoint'
            string = '[WAYPOINT]';

        case 'transition'
            string = '[TRANSITION]';

        case 'pause'
            string = '[PAUSE]';
            
        otherwise
            fprintf(1, 'Unrecognized event type ''%s''', data.eventType);
            listString = [];
            return;
            
    end
    
    listString = sprintf('%s %s', string, data.label);
end

function DeleteEvent_Callback(hObject, eventdata, handles)
    index = get(handles.EventList, 'Value');
    
    strings = get(handles.EventList, 'String');
    
    strings{index}              = [];
    handles.events{index}       = [];
    
    strings             = cellRemoveEmpty(strings);
    handles.events      = cellRemoveEmpty(handles.events);
    
    set(handles.EventList, 'String', strings);
    
    numEvents = length(handles.events);
    if (numEvents == 0)
        index = 1;
    else
        if (index > numEvents)
            index = numEvents;
        end
    end
        
    set(handles.EventList, 'Value', index);
    
	handles = UpdateFileStatus(handles, false);
    guidata(hObject, handles);
    
end

function frames = CountFrames(events)
    frames = 0;
    numEvents = length(events);
    for i = 1:numEvents
        event = events{i};
        if (isfield(event, 'frames'))
            frames = frames + event.frames;
        end
    end       
end

function RenderMovie_Callback(hObject, eventdata, handles, preview)
    if (AreEventsWellFormed(handles))
        frames = CountFrames(handles.events);
        framesPerSec    = str2num(get(handles.FPSTextField, 'String'));
        events          = handles.events;
        nEvents         = length(events);
        lastWaypoint    = [];

        if (~preview) % Set up for saving out movie
            [movFile, movDir]   = uiputfile('brainMovie.avi');
            if (movFile == 0), return; end
            
        	host                = 'localhost';
            f.filename          = 'nosave';
            frame               = 1;
            ShowProgress(handles, movFile, 0);
            % Skipping preallocation of M, will do so if it's too slow
        end
        
        for i = 1:nEvents
            event = handles.events{i};
            switch (event.eventType)
                case 'transition'
                    [rotation frustum origin] = BuildTransition(event, lastWaypoint, GetNextWaypoint(events, i));
                    for j = 1:event.frames
                        mrmRotateCamera(handles.meshID, rotation(j, :), [], frustum(j, :), [], origin(j, :));
                        if (~preview)
                            [id,stat,res] = mrMesh(host, handles.meshID, 'screenshot', f);
                            ShowProgress(handles, movFile, frame/frames * 100);
                            M(frame) = im2frame(permute(res.rgb, [2,1,3])./255);
                            frame = frame + 1;
                        end
                    end
                case 'waypoint'
                    lastWaypoint = event;
                    mrmRotateCamera(handles.meshID, event.rotation, [], event.frustum, [], event.origin);
                case 'pause'
                    if (preview)
                        pause(event.frames/framesPerSec);
                    else
                        [id,stat,res] = mrMesh(host, handles.meshID, 'screenshot', f);
                        for j = 1:event.frames
                            ShowProgress(handles, movFile, frame/frames * 100);
                            M(frame) = im2frame(permute(res.rgb, [2,1,3])./255);
                            frame = frame + 1;
                        end
                    end
                otherwise
                    fprintf(1, 'Unrecognized event type ''%s''', data.eventType);
                    return;
            end
        end
        
        if (~preview)
            if ispc
                % Compressors for Windows are annoying.  None works.  Not
                % sure if the others in doc movie2avi work.
                movie2avi(M, fullfile(movDir,movFile), ...
                    'FPS', framesPerSec, ...
                    'Compression','RLE');
            else
                % Unix/Mac
                movie2avi(M, fullfile(movDir,movFile), ...
                    'FPS', framesPerSec, ...
                    'Compression','None');

            end
            
            set(handles.ProgressText, 'String', []);
        end
        
    else
        errordlg('Invalid events list.  See wiki for guidelines.');
    end
           
end

function ShowProgress(handles, filename, percent)
    set(handles.ProgressText, 'String', sprintf('Exporting %s... %2.0f%%', filename, percent));
end

function [rotation frustum origin] = BuildTransition(transition, waypointStart, waypointEnd)
    nFrames     = transition.frames;
    rotation    = zeros(nFrames, 3);
    rotStart    = waypointStart.rotation;
    rotEnd      = waypointEnd.rotation;
    
    for i = 1:3
        if (rotEnd(i) == rotStart(i))
            rotation(:, i) = rotStart(i);
            continue;
        end
        
        switch (transition.rotate{i})
            case '+'
                if (rotEnd(i) < rotStart(i))
                    rotEnd(i) = pi + (pi + rotEnd(i));
                end
                
            case '-'
                if (rotEnd(i) > rotStart(i))
                    rotEnd(i) = -pi - (pi - rotEnd(i));
                end
                
            case 'FIX'
                rotation(:,i) = rotStart(i);
                continue;
                
            otherwise
                fprintf(1, 'Unrecognized rotation direction ''%s''', transition.rotate{i});
        end
        
        if (rotEnd(i) == rotStart(i))
            rotation(:, i) = rotStart(i);
            continue;
        end
        
        delta           = rotEnd(i) - rotStart(i);
        rotation(:, i)  = rotStart(i):(delta/(nFrames - 1)):rotEnd(i);
    end
            
    frustum = InterpolateFrames(waypointStart.frustum, waypointEnd.frustum, nFrames);
    origin  = InterpolateFrames(waypointStart.origin, waypointEnd.origin, nFrames);
    
end

function vector = InterpolateFrames(start, finish, nFrames)
    nEntries = length(start);
    vector = zeros(nFrames, nEntries);
    for i = 1:nEntries
        if (start(i) == finish(i))
            vector(:,i) = start(i);
            continue;
        end
        
        delta       = finish(i) - start(i);
        vector(:,i) = start(i):(delta/(nFrames - 1)):finish(i);
    end
    
end

function waypoint = GetNextWaypoint(events, startInd)
    waypoint = [];
    for i = startInd:length(events)
       if (strcmp(events{i}.eventType, 'waypoint'))
           waypoint = events{i};
           return;
       end
    end
end

function bool = AreEventsWellFormed(handles)
    events  = handles.events;
    nEvents = length(events);
    
    if (nEvents < 2) % Need at least 2 events (waypoint + pause) to proceed
        bool = false;
        return;
    end
    
    event = events{1};
    if (~(strcmp(event.eventType, 'waypoint'))) % First event needs to be a waypoint
        bool = false;
        return;
    end
    
    balanceCounter  = 0;
    hasFrames       = 0;
    for i = 2:nEvents
        event = events{i};
        if (~hasFrames && (strcmp(event.eventType, 'pause') || strcmp(event.eventType, 'transition')))
            hasFrames = 1;
        end
        
        if (strcmp(event.eventType, 'transition'))
            if (balanceCounter), bool = false; return; end
            balanceCounter = balanceCounter + 1;
        elseif (strcmp(event.eventType, 'waypoint'))
            if (~balanceCounter), continue; end
            balanceCounter = balanceCounter - 1;
        elseif (strcmp(event.eventType, 'pause'))
            if (balanceCounter), bool = false; return; end
        end
    end
    if (~hasFrames || balanceCounter), bool = false; return; end
    bool = true;
end

function EditEvent_Callback(hObject, eventdata, handles)
    events = handles.events;
    nEvents = length(events);
    if (nEvents < 1), return; end
    selected = get(handles.EventList, 'Value');
    editData = events{selected};
    
    switch (editData.eventType)
        case 'waypoint'
            waitfor(mrmMakeMovieGUI_Waypoint(handles.MakeMovieGUI, handles.meshID, editData));

        case 'transition'
            waitfor(mrmMakeMovieGUI_Transition(handles.MakeMovieGUI, editData));
            
        case 'pause'
            waitfor(mrmMakeMovieGUI_Pause(handles.MakeMovieGUI, editData));
            
        otherwise
            fprintf(1, 'Unrecognized radio button selected.\n');
            
    end
    
    editData = get(handles.MakeMovieGUI, 'UserData');
    if (isempty(editData)), return; end
    
    handles.events{selected} = editData;
    
    strings = get(handles.EventList, 'String');
    strings{selected} = GetListString(editData);
    set(handles.EventList, 'String', strings);
    
    handles = UpdateFileStatus(handles, false);
    set(handles.MakeMovieGUI, 'UserData', []); % Clear it out to not muck up future use of this var
    guidata(hObject, handles);
end

function SaveData(handles)
    if (~isempty(handles.filename))
        fileID      = 'EventsList';
        version     = 1;
        events      = handles.events;
        save(fullfile(handles.filedir,handles.filename), 'fileID', 'version', 'events');
    end
end
        
function SaveCheck(hObject, eventdata, handles)
    if (~handles.isSaved)
        buttonChosen = questdlg('Save changes?', 'MakeMovieGUI', 'Yes', 'No', 'Yes');
        if (strcmp(buttonChosen,'Yes'))
            Save_Callback(hObject, eventdata, handles);
        end
    end
end

function New_Callback(hObject, eventdata, handles)
    SaveCheck(hObject, eventdata, handles);
    handles.events = [];
    set(handles.EventList, 'String', []);
    set(handles.EventList, 'Value', 1);
    handles.filename = [];
    handles.filedir = [];
    handles = UpdateFileStatus(handles, true);
    guidata(hObject, handles);
end

function Open_Callback(hObject, eventdata, handles)
    [filename filedir] = uigetfile('*.mat');
    if (filename == 0), return; end
    
    file = load(fullfile(filedir,filename));
    if (strcmp(file.fileID, 'EventsList'))
        if (file.version <= 1)
            handles.filename    = filename;
            handles.filedir     = filedir;
            handles.events      = {};
            set(handles.EventList, 'String', []);
            set(handles.EventList, 'Value', 1);
            
            for i = 1:length(file.events)
                handles = InsertEvent(hObject, handles, file.events{i}, i);
            end
            
            handles = UpdateFileStatus(handles, true);
            guidata(hObject, handles);
        else
            errordlg('Incompatible eventsList file.');
        end
    else
        errordlg('Corrupt/invalid eventsList file.');
    end
end
 
function Save_Callback(hObject, eventdata, handles)
    if (isempty(handles.filename))
        SaveAs_Callback(hObject, eventdata, handles);
    else
        handles = UpdateFileStatus(handles, true);
        SaveData(handles);
        guidata(hObject, handles);
    end
end

function SaveAs_Callback(hObject, eventdata, handles)
    [filename, filedir]   = uiputfile('brainMovie.mat');
    if (filename == 0), return; end
    
    handles.filename    = filename;
    handles.filedir     = filedir;
    handles             = UpdateFileStatus(handles, true);
    
    SaveData(handles);
    guidata(hObject, handles);
end
 
function Quit_Callback(hObject, eventdata, handles)
    SaveCheck(hObject, eventdata, handles);
    close(handles.MakeMovieGUI);
end

function EventList_KeyPressFcn(hObject, eventdata, handles)
    if (~isempty(cellfind(eventdata.Modifier, 'control')) || ...
            ~isempty(cellfind(eventdata.Modifier, 'command'))) % done to support mac as well as linux
        switch (eventdata.Key)
            case 'x'
                CutEvent_Callback(hObject, eventdata, handles);
            case 'c'
                CopyEvent_Callback(hObject, eventdata, handles);
            case 'v'
                PasteEvent_Callback(hObject, eventdata, handles);
            case 'm'
                EditEvent_Callback(hObject, eventdata, handles);
            case 'd'
                DeleteEvent_Callback(hObject, eventdata, handles);
            case 'n'
                New_Callback(hObject, eventdata, handles);
            case 'o'
                Open_Callback(hObject, eventdata, handles);
            case 's'
                Save_Callback(hObject, eventdata, handles);
            case 'q'
                Quit_Callback(hObject, eventdata, handles);
            case 'p'
                RenderMovie_Callback(hObject, eventdata, handles, 1);
            case 'e'
                RenderMovie_Callback(hObject, eventdata, handles, 0);
            otherwise
        end         
    else      
        switch (eventdata.Key)
            case 'a'
                MoveUpButton_Callback(hObject, eventdata, handles);
            case 'z'
                MoveDownButton_Callback(hObject, eventdata, handles);
            case 'delete'
                DeleteEvent_Callback(hObject, eventdata, handles);
            otherwise
        end
    end
end

function CutEvent_Callback(hObject, eventdata, handles)
    if (length(handles.events) < 1), return; end
    selected = get(handles.EventList, 'Value');
    handles.clipboard = handles.events{selected};
    DeleteEvent_Callback(hObject, eventdata, handles);
end

function CopyEvent_Callback(hObject, eventdata, handles)
    if (length(handles.events) < 1), return; end
    selected = get(handles.EventList, 'Value');
    handles.clipboard = handles.events{selected};
    handles = TurnOffInvalidButtons(handles);
    guidata(hObject, handles);
end

function PasteEvent_Callback(hObject, eventdata, handles)
    if (~isempty(handles.clipboard))
        if (length(handles.events) < 1)
            handles = InsertEvent(hObject, handles, handles.clipboard, 1);
        else
            selected = get(handles.EventList, 'Value');
            handles = InsertEvent(hObject, handles, handles.clipboard, selected + 1);
        end
        guidata(hObject, handles);
    end
end
