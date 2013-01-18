function varargout = TimeSeriesDataGUI(varargin)
    % TIMESERIESDATAGUI M-file for TimeSeriesDataGUI.fig
    %      TIMESERIESDATAGUI, by itself, creates a new TIMESERIESDATAGUI or raises the existing
    %      singleton*.
    %
    %      H = TIMESERIESDATAGUI returns the handle to a new TIMESERIESDATAGUI or the handle to
    %      the existing singleton*.
    %
    %      TIMESERIESDATAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in TIMESERIESDATAGUI.M with the given input arguments.
    %
    %      TIMESERIESDATAGUI('Property','Value',...) creates a new TIMESERIESDATAGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before TimeSeriesDataGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to TimeSeriesDataGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help TimeSeriesDataGUI

    % Last Modified by GUIDE v2.5 19-Mar-2010 19:07:01

    % Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @TimeSeriesDataGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @TimeSeriesDataGUI_OutputFcn, ...
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

% --- Executes just before TimeSeriesDataGUI is made visible.
function TimeSeriesDataGUI_OpeningFcn(hObject, eventdata, handles, timeSeries, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to TimeSeriesDataGUI (see VARARGIN)

    % Choose default command line output for TimeSeriesDataGUI
    handles.output = hObject;
    
    % Check if TimeSeriesData has been loaded
    if (isempty(timeSeries.data)), timeSeries.loadTimeCourses(); end
    
    % Place data into handles struct
    handles.timeSeries  = timeSeries;
    
    handles.select = 'voxels';
    
    % Update handles structure
    guidata(hObject, handles);
    
    TimeSeriesDataGUI_InitFcn(handles);
end

function TimeSeriesDataGUI_InitFcn(handles, varargin)
    % Function to populate all of the drop down menus, since create
    % functions don't have access to the handles struct yet and thus cannot
    % be relied upon to do this.
    % handles   structure with handles and user data (see GUIDATA)
    % varargin  optional arguments if you want to add any
    
    % Populate MainTitle
    set(handles.MainTitle, 'String', handles.timeSeries.getLoadedROI);
    
    % Populate ConditionSelector
    set(handles.ConditionSelector, 'String', handles.timeSeries.data.trials.condNames);
    
    % Populate TrialSelector
    set(handles.TrialSelector, 'String', ['Mean Of All' getTrialsArray(handles, 1)]);
    
    % Populate ColorMapSelector
    set(handles.ColorMapSelector, 'String', {'autumn', 'bone', 'cool', ...
        'copper', 'gray', 'hot', 'hsv', 'jet', 'pink', 'spring', 'summer', ...
        'winter'}); % Hardcoded - couldn't find a function to return this
    
    % Set default ColorMapSelector to 'jet'
    set(handles.ColorMapSelector, ...
        'Value', cellfind(get(handles.ColorMapSelector, 'String'), 'jet'));
    
    % Populate plot
    plotData(handles);
    
    % Set up selection routines and callbacks
    handles.xStartLine   = line(0,0);
    handles.xEndLine     = line(0,0);
    handles.yStartLine   = line(0,0);
    handles.yEndLine     = line(0,0);
    handles.limits      = [0.5, size(handles.timeSeries.analysis(1).meanTcs,1) + 0.5, ...
                           0.5, size(handles.timeSeries.analysis,2) + 0.5];
    handles.clicks      = handles.limits;
    handles.limitsHistory = handles.limits;
    set(handles.TimeSeriesGUI,...
        'WindowButtonUpFcn', @(src,event)StopDrag_Callback(handles,src,event), ...
        'WindowButtonDownFcn', @(src,event)StartDrag_Callback(handles,src,event));
    
    % Export results to handles
    guidata(handles.TimeSeriesGUI, handles);
end

% UIWAIT makes TimeSeriesDataGUI wait for user response (see UIRESUME)
% uiwait(handles.TimeSeriesGUI);

function trials = getTrialsArray(handles, condition)
    nConds = length(handles.timeSeries.data.trials.condNames);
    if (condition > nConds || condition < 1), error('No such condition'); end
    
    trials = cellfun(@num2str, num2cell( ...
        1:handles.timeSeries.analysis(1).nTrials(condition)), ...
        'UniformOutput', false);
end

function plotData(handles)
    condition   = get(handles.ConditionSelector, 'Value');
    trial       = get(handles.TrialSelector, 'Value');
    
    numVoxels = size(handles.timeSeries.analysis,2);
    numTimePoints = size(handles.timeSeries.analysis(1).meanTcs,1);
    
    plotData = zeros(numVoxels, numTimePoints);
    if (trial == 1)
        for i = 1:numVoxels
            plotData(i, :) = handles.timeSeries.analysis(i).meanTcs(:, condition)';
        end
    else
        trial = trial - 1;
        for i = 1:numVoxels
            plotData(i, :) = handles.timeSeries.analysis(i).allTcs(:, trial, condition)';
        end
    end
    
    imagesc(plotData);
    handles.xStartLine   = line(0,0);
    handles.xEndLine     = line(0,0);
    handles.yStartLine   = line(0,0);
    handles.yEndLine     = line(0,0);
    guidata(handles.TimeSeriesGUI, handles);
    updateColorMap(handles);
    
end

function updateColorMap(handles)
    menuContents = get(handles.ColorMapSelector, 'String');
    colorMapName = menuContents{get(handles.ColorMapSelector,'Value')};
    colormap(handles.TimeSeriesPlot, colorMapName);
end

% --- Outputs from this function are returned to the command line.
function varargout = TimeSeriesDataGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to FileMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to OpenMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    file = uigetfile('*.fig');
    if ~isequal(file, 0)
        open(file);
    end
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to PrintMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    printdlg(handles.TimeSeriesGUI)
end

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to CloseMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    selection = questdlg(['Close ' get(handles.TimeSeriesGUI,'Name') '?'],...
                         ['Close ' get(handles.TimeSeriesGUI,'Name') '...'],...
                         'Yes','No','Yes');
    if strcmp(selection,'No')
        return;
    end

    delete(handles.TimeSeriesGUI)
end


% --- Executes on selection change in ConditionSelector.
function ConditionSelector_Callback(hObject, eventdata, handles)
    % hObject    handle to ConditionSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = get(hObject,'String') returns ConditionSelector contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from ConditionSelector
    
    % Retrieves selected value
    condition = get(hObject,'Value');
    
    % Set selected value back to default
    set(handles.TrialSelector, 'Value', 1);
    
    % Repopulates trial selector with relevant trial numbers
    set(handles.TrialSelector, 'String', ['Mean Of All' getTrialsArray(handles, condition)]);
    
    plotData(handles);
end


% --- Executes during object creation, after setting all properties.
function ConditionSelector_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ConditionSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    
    % Set ConditionSelector to contain condition strings
    %set(handles.ConditionSelector, 'String', handles.timeSeries.data.trials.condNames);
    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
         set(hObject,'BackgroundColor','white');
    end

end


% --- Executes on selection change in ColorMapSelector.
function ColorMapSelector_Callback(hObject, eventdata, handles)
    % hObject    handle to ColorMapSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = get(hObject,'String') returns ColorMapSelector contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from ColorMapSelector
    
    updateColorMap(handles);
    
end


% --- Executes during object creation, after setting all properties.
function ColorMapSelector_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ColorMapSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function MainTitle_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to MainTitle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
end


% --- Executes on selection change in TrialSelector.
function TrialSelector_Callback(hObject, eventdata, handles)
    % hObject    handle to TrialSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = get(hObject,'String') returns TrialSelector contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from TrialSelector
    
    plotData(handles);

    
end

% --- Executes during object creation, after setting all properties.
function TrialSelector_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to TrialSelector (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function StartDrag_Callback(handles, src, event)
    handles = guidata(handles.TimeSeriesGUI);
    point = get(handles.TimeSeriesPlot,'CurrentPoint');

    xValue = graphRound(point(1, 1));
    yValue = graphRound(point(1, 2));
    if (xValue >= handles.limits(1) || xValue <= handles.limits(2) || ...
        yValue >= handles.limits(3) || yValue <= handles.limits(4))
        set(handles.xStartLine, ...
            'XData', [xValue xValue], ...
            'YData', [yValue yValue]);
        set(handles.xEndLine, ...
            'XData', [xValue xValue], ...
            'YData', [yValue yValue]);
        set(handles.yStartLine, ...
            'XData', [xValue xValue], ...
            'YData', [yValue yValue]);
        set(handles.yEndLine, ...
            'XData', [xValue xValue], ...
            'YData', [yValue yValue]);
        handles.clicks = [xValue xValue yValue yValue];
        set(handles.TimeSeriesGUI, 'WindowButtonMotionFcn', @(src,event)Dragging_Callback(handles,src,event))
    end
    
    guidata(handles.TimeSeriesGUI, handles);
end
            
function StopDrag_Callback(handles, src, event)
    handles = guidata(handles.TimeSeriesGUI);
    set(handles.TimeSeriesGUI, 'WindowButtonMotionFcn', '');
    set(handles.xStartLine, 'XData', 0, 'YData', 0);
    set(handles.xEndLine, 'XData', 0, 'YData', 0);
    set(handles.yStartLine, 'XData', 0, 'YData', 0);
    set(handles.yEndLine, 'XData', 0, 'YData', 0);
            
    if (handles.clicks(1) < handles.clicks(2) && handles.clicks(3) < handles.clicks(4)) % Mouse is to the right of where they first clicked
        handles.limitsHistory = [handles.limitsHistory; handles.clicks];
    end
    
    if (handles.clicks(1) > handles.clicks(2) || handles.clicks(3) > handles.clicks(4)) % Mouse is at a location to the left of where they first clicked

        if (handles.clicks(1) > handles.clicks(2))
            handles.clicks(1:2) = fliplr(handles.clicks(1:2));
        end
        if (handles.clicks(3) > handles.clicks(4))
            handles.clicks(3:4) = fliplr(handles.clicks(3:4));
        end
                
        handles.limitsHistory = [handles.limitsHistory; handles.clicks];
    end

    if (handles.clicks(1) == handles.clicks(2) || handles.clicks(3) == handles.clicks(4)) % Clicked but didn't move mouse
        lastClick = size(handles.limitsHistory,1);
        if (lastClick > 1)
            handles.limitsHistory(lastClick,:) = [];
            handles.clicks = handles.limitsHistory(lastClick - 1,:);
        elseif (lastClick == 1)
            handles.clicks = handles.limitsHistory(1,:);
        end

    end
    
    handles.limits = handles.clicks;
    set(handles.TimeSeriesPlot, 'XLim', handles.clicks(1:2), 'YLim', handles.clicks(3:4));
    guidata(handles.TimeSeriesGUI, handles);
end

function Dragging_Callback(handles, src, event)  
    handles = guidata(handles.TimeSeriesGUI);
    point = get(handles.TimeSeriesPlot,'CurrentPoint');
    
    xValue = graphRound(point(1, 1));
    yValue = graphRound(point(1, 2));
    if (xValue >= handles.limits(1) || xValue <= handles.limits(2) || ...
        yValue >= handles.limits(3) || yValue <= handles.limits(4))
        set(handles.xStartLine, ...
            'XData', [handles.clicks(1) handles.clicks(1)], ...
            'YData', [handles.clicks(3) yValue]);
        set(handles.xEndLine, ...
            'XData', [xValue xValue], ...
            'YData', [handles.clicks(3) yValue]);
        set(handles.yStartLine, ...
            'XData', [handles.clicks(1) xValue], ...
            'YData', [handles.clicks(3) handles.clicks(3)]);
        set(handles.yEndLine, ...
            'XData', [handles.clicks(1) xValue], ...
            'YData', [yValue yValue]);
        handles.clicks(2) = xValue;
        handles.clicks(4) = yValue;
    end
    
    guidata(handles.TimeSeriesGUI, handles);
end

function rounded = graphRound(number)
    rounded = round(number);
    add = sign(number - rounded) * .5;
    if (number == 0 && rounded == 0), add = -.5; end
    if (add == 0), add = .5; end
    rounded = rounded + add;
end

% --- Executes on button press in SelectVoxels.
function SelectVoxels_Callback(hObject, eventdata, handles)
    % hObject    handle to SelectVoxels (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of SelectVoxels
    handles.select = lower(get(hObject,'String'));
    guidata(handles.TimeSeriesGUI, handles);
end


% --- Executes on button press in SelectTimePoints.
function SelectTimePoints_Callback(hObject, eventdata, handles)
    % hObject    handle to SelectTimePoints (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of SelectTimePoints
    handles.select = lower(get(hObject,'String'));
    guidata(handles.TimeSeriesGUI, handles);
end