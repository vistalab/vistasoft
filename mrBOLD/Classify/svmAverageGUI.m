function varargout = svmAverageGUI(varargin)
% svmAverageGUI
%   Given an svm structure, opens a GUI displaying the contents with the
%   ability to select, modify, and average across fields describing the
%   data.
%
% Usage:
%   svmAverageGUI(svm)
%
% Proper comments and ability to return the structure (even more
% important!) forthcoming.
%
% [renobowen@gmail.com 2010]
%

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @svmAverageGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @svmAverageGUI_OutputFcn, ...
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

function svmAverageGUI_OpeningFcn(hObject, eventdata, handles, svm, varargin)
    if ~(exist('svm','var'))
        svm = [];        
    end
    
    % Choose default command line output for svmAverageGUI
    handles.output      = hObject;
    handles.svm         = svm;
    handles.saveToVar   = [];
    
    for i = 1:2:length(varargin)
        switch (lower(varargin{i}))
            case {'savetovar'}
                handles.saveToVar = varargin{i + 1};
            otherwise
                fprintf(1, 'Unrecognized option ''%s''\n', varargin{i});
        end
    end

    handles.changed     = 0;

    % Update handles structure
    guidata(hObject, handles);

    if (~isempty(svm))
        svmAverageGUI_InitFcn(hObject, handles);
    end
end

function svmAverageGUI_InitFcn(hObject, handles)
    handles = DataList_InitFcn(hObject, handles);
    handles = RunList_InitFcn(hObject, handles);
    handles = GroupList_InitFcn(hObject, handles);
    handles = TrialList_InitFcn(hObject, handles);
    guidata(hObject, handles);
end

function varargout = svmAverageGUI_OutputFcn(hObject, eventdata, handles) 
    
    if (isempty(handles.svm))
        fprintf(1, 'No svm structure specified - closing GUI.\n');
        close(handles.AverageGUI);
    end
    
end

function DataList_UpdateSelections(hObject, handles)
    runValues       = unique(handles.svm.run);
    groupValues     = unique(handles.svm.group);
    trialValues     = unique(handles.svm.trial);
    
    selectedRuns    = runValues(get(handles.RunList, 'Value'));
    selectedGroups  = groupValues(get(handles.GroupList, 'Value'));
    selectedTrials  = trialValues(get(handles.TrialList, 'Value'));
    
    mask =  ismember(handles.svm.run, selectedRuns) & ...
            ismember(handles.svm.group, selectedGroups) & ...
            ismember(handles.svm.trial, selectedTrials);
        
    set(handles.DataList, 'Value', find(mask));
    guidata(hObject, handles);
end

function handles = DataList_InitFcn(hObject, handles)
    strings = num2str([handles.svm.run handles.svm.group handles.svm.trial]);
    set(handles.DataList, 'String', strings);
    set(handles.DataList, 'Max', size(strings,1));
    set(handles.DataList, 'Value', 1);
    set(handles.DataList, 'ListboxTop', 1);
    
end

function handles = RunList_InitFcn(hObject, handles)
    strings = num2str(unique(handles.svm.run));
    set(handles.RunList, 'String', strings);
    set(handles.RunList, 'Max', size(strings,1));
    set(handles.RunList, 'Value', 1);
    set(handles.RunList, 'ListboxTop', 1);
end

function handles = GroupList_InitFcn(hObject, handles)
    strings = handles.svm.grouplabel;
    set(handles.GroupList, 'String', strings);
    set(handles.GroupList, 'Max', length(strings));
    set(handles.GroupList, 'Value', 1);
    set(handles.GroupList, 'ListboxTop', 1);
end

function handles = TrialList_InitFcn(hObject, handles)
    strings = num2str(unique(handles.svm.trial));
    set(handles.TrialList, 'String', strings);
    set(handles.TrialList, 'Max', size(strings,1));
    set(handles.TrialList, 'Value', 1);
    set(handles.TrialList, 'ListboxTop', 1);

end

function ResetDetailSelectors(hObject, handles)
    set(handles.RunList, 'Value', 1);
    set(handles.RunList, 'ListboxTop', 1);
    set(handles.GroupList, 'Value', 1);
    set(handles.GroupList, 'ListboxTop', 1);
    set(handles.TrialList, 'Value', 1);
    set(handles.TrialList, 'ListboxTop', 1);
    guidata(hObject, handles);
end

function UpdateLists(hObject, handles)
    svmAverageGUI_InitFcn(hObject, handles);
end

function handles = RepairIndices(hObject, handles)
    nLabels = length(handles.svm.grouplabel);
    markedForDeletion = zeros(1,nLabels);
    subFromInds = 0;
    for i = 1:length(handles.svm.grouplabel)
        if (sum(ismember(handles.svm.group, i)) == 0)
            markedForDeletion(i) = 1;
            subFromInds = subFromInds + 1;
        else
            inds = ismember(handles.svm.group, i);
            handles.svm.group(inds) = i - subFromInds;
        end
    end
    
    handles.svm.grouplabel = handles.svm.grouplabel(~markedForDeletion);
end

%% List callbacks
function DataList_Callback(hObject, eventdata, handles)
% DataList_Callback
%   Selecting within this window resets the selected run/group/trial in the
%   other lists (we're now manually editing the selection and the remaining
%   lists will no longer contain info representative of what we've
%   selected.

    ResetDetailSelectors(hObject, handles);
end

function RunList_Callback(hObject, eventdata, handles)
    DataList_UpdateSelections(hObject, handles);
end

function GroupList_Callback(hObject, eventdata, handles)
    DataList_UpdateSelections(hObject, handles);
end

function TrialList_Callback(hObject, eventdata, handles)
    DataList_UpdateSelections(hObject, handles);
end

%% Action button callbacks - used to modify data
function RelabelButton_Callback(hObject, eventdata, handles)
    % hObject    handle to AverageButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    run         = str2num(get(handles.RunInput, 'String'));
    trial       = str2num(get(handles.TrialInput, 'String'));
    groupLabel  = get(handles.GroupInput, 'String');

    if (isempty(run) && isempty(trial) && isempty(groupLabel))
        fprintf(1, 'Empty assignment fields!\n');
        return;
    end

    mask        = false(get(handles.DataList, 'Max'),1);
    inds        = get(handles.DataList, 'Value');
    mask(inds)  = true;
    
    if (~isempty(run))
        handles.svm.run(mask) = run;
    end
    
    if (~isempty(trial))
        handles.svm.trial(mask) = trial;
    end
    
    if (~isempty(groupLabel))
        group = cellfind(handles.svm.grouplabel, groupLabel);
        if (isempty(group))
            group = max(handles.svm.group) + 1;
            handles.svm.grouplabel{group} = groupLabel;
        end
        handles.svm.group(mask) = group;
        handles = RepairIndices(hObject, handles);
    end
    
    handles.changed = 1;
    UpdateLists(hObject, handles);
end

function AverageButton_Callback(hObject, eventdata, handles)
        
    run         = str2num(get(handles.RunInput, 'String'));
    trial       = str2num(get(handles.TrialInput, 'String'));
    groupLabel  = get(handles.GroupInput, 'String');
    
    if (isempty(run) || isempty(trial) || isempty(groupLabel))
        fprintf(1, 'Empty assignment fields!\n');
        return;
    end
    
    group = cellfind(handles.svm.grouplabel, groupLabel);
    if (isempty(group))
        group = max(handles.svm.group) + 1;
        handles.svm.grouplabel{group} = groupLabel;
    end
    
    mask        = false(get(handles.DataList, 'Max'),1);
    inds        = get(handles.DataList, 'Value');
    mask(inds)  = true;
    
    newsvm          = handles.svm;
    newsvm.data     = newsvm.data(~mask,:);
    newsvm.run      = newsvm.run(~mask,:);
    newsvm.group    = newsvm.group(~mask,:);
    newsvm.trial    = newsvm.trial(~mask,:);
    
    newsvm.data     = [newsvm.data; mean(handles.svm.data(mask,:), 1)];
    newsvm.run      = [newsvm.run; run];
    newsvm.group    = [newsvm.group; group];
    newsvm.trial    = [newsvm.trial; trial];
    
    handles.svm     = newsvm;
    handles         = RepairIndices(hObject, handles);
    handles.changed = 1;
    UpdateLists(hObject, handles);
end

function SaveAsButton_Callback(hObject, eventdata, handles)
    if (handles.changed)
        default = {'svm'};
        if (~isempty(handles.saveToVar))
            default = handles.saveToVar;
        end
        varName = inputdlg('Assign to variable: ', 'svmAverageGUI', 1, default);
        if (isempty(varName)) return; end
        
        assignin('base', varName{1}, handles.svm);
        
        fprintf(1, 'Saved data to variable ''%s''.\n', varName{1});

        handles.changed = 0;
        guidata(hObject, handles);
    else
        fprintf(1, 'No changes to save.\n');
    end
end

function SaveButton_Callback(hObject, eventdata, handles)
    if (handles.changed)
        if (isempty(handles.saveToVar))
            handles.saveToVar = inputdlg('Assign to variable: ', 'svmAverageGUI', 1, {'svm'});
            if (isempty(handles.saveToVar)) return; end
        end
        assignin('base', handles.saveToVar{1}, handles.svm);
        
        fprintf(1, 'Saved data to variable ''%s''.\n', handles.saveToVar{1});
        
        handles.changed = 0;
        guidata(hObject, handles);
    else
        fprintf(1, 'No changes to save.\n');
    end
end

function AverageGUI_DeleteFcn(hObject, eventdata, handles)
    if (handles.changed)
        buttonChosen = questdlg('Save changes?', 'svmAverageGUI', 'Yes', 'No', 'Yes');
        if (strcmp(buttonChosen,'Yes'))
            SaveButton_Callback(hObject, eventdata, handles);
        end
    end
end

function HelpButton_Callback(hObject, eventdata, handles)
    help svmAverageGUI;
end

%% Generated by GUIDE, necessary to run
% Create functions
function DataList_CreateFcn(hObject, eventdata, handles), end
function RunList_CreateFcn(hObject, eventdata, handles), end
function GroupList_CreateFcn(hObject, eventdata, handles), end
function TrialList_CreateFcn(hObject, eventdata, handles), end
function RunInput_CreateFcn(hObject, eventdata, handles), end
function GroupInput_CreateFcn(hObject, eventdata, handles), end
function TrialInput_CreateFcn(hObject, eventdata, handles), end

% Callbacks I didn't need
function RunInput_Callback(hObject, eventdata, handles), end
function TrialInput_Callback(hObject, eventdata, handles), end
function GroupInput_Callback(hObject, eventdata, handles), end
