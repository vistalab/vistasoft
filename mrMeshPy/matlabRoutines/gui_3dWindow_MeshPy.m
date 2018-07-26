function varargout = gui_3dWindow_MeshPy(varargin)
% GUI_3DWINDOW_MESHPY MATLAB code for gui_3dWindow_MeshPy.fig
%      GUI_3DWINDOW_MESHPY, by itself, creates a new GUI_3DWINDOW_MESHPY or raises the existing
%      singleton*.
%
%      H = GUI_3DWINDOW_MESHPY returns the handle to a new GUI_3DWINDOW_MESHPY or the handle to
%      the existing singleton*.
%
%      GUI_3DWINDOW_MESHPY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_3DWINDOW_MESHPY.M with the given input arguments.
%
%      GUI_3DWINDOW_MESHPY('Property','Value',...) creates a new GUI_3DWINDOW_MESHPY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_3dWindow_MeshPy_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_3dWindow_MeshPy_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui_3dWindow_MeshPy

% Last Modified by GUIDE v2.5 26-Sep-2017 13:56:57
% Andre' Gouws 2017
debug = 1;

if debug
    pwd
    fileparts(mfilename('fullpath'))
end

% If this function is called, we are going to assume that the user wants to
% use mrMeshPy and not mrMesh - we we will add some altered routines to the
% top of the search path

mrMeshMFileDir = fileparts(mfilename('fullpath')); %get the directory that holds THIS script
addpath(genpath(mrMeshMFileDir)); % add it to the top of the search path.
% TODO - there must be a better way of doing this - maybe just drop mrMesh!


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_3dWindow_MeshPy_OpeningFcn, ...
    'gui_OutputFcn',  @gui_3dWindow_MeshPy_OutputFcn, ...
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

try
    % Hack - TODO fix - this puts the VOLUME in the scope of this gui
    VOLUME = evalin('base','VOLUME','VOLUME'); %% HACK TODO fix
catch
    disp('no VOLUME loaded yet')
end

% --- Executes just before gui_3dWindow_MeshPy is made visible.
function gui_3dWindow_MeshPy_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui_3dWindow_MeshPy (see VARARGIN)

% Choose default command line output for gui_3dWindow_MeshPy
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui_3dWindow_MeshPy wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gui_3dWindow_MeshPy_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%% disabled for now - TODO
% --- Executes on button press in launch_button.
function launch_button_Callback(hObject, eventdata, handles)

[myfile,mydir]= uigetfile({'*.mat','MAT-files (*.mat)'});
meshFilePath = [mydir,myfile];
myPid = num2str(feature('getpid'));

if ~isfield(VOLUME{1},'meshNum3d') %% TODO - this willneed to reflect the current volume and x-ref the correct mesh
    meshInstance = '1';
else
    meshInstance = num2str(VOLUME{1}.meshNum3d + 1);
end

evalstr = ['/home/andre/mrMeshPy/launchMeshPy.sh /home/andre/mrMeshPy/meshPy_v03.py ',meshFilePath,' ',myPid,' ',meshInstance,' &'];
disp(['ran command: ', evalstr]);

system(evalstr);
%%



% --- Executes on button press in pushbutton_update.
function pushbutton_update_Callback(hObject, eventdata, handles)

mrGlobals;
set( findall(handles.uipanel1, '-property', 'Enable'), 'Enable', 'off')

try
    currMesh = VOLUME{1}.meshNum3d;

    [VOLUME{1},~,~,~,VOLUME{1}.mesh{currMesh}] = meshColorOverlay(VOLUME{1},0);
    mrMeshPySend('updateMeshData',VOLUME{1});
catch
    disp 'error in update mesh routine';
end

set( findall(handles.uipanel1, '-property', 'Enable'), 'Enable', 'On')



% --- Executes on button press in pushbutton_LoadMesh.
function pushbutton_LoadMesh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_LoadMesh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mrGlobals;

% keep tack of whether the VOLUME actually changes - i.e. make sure a new
% mesh has been loaded and the user hasn't hit cancel
try
    currMeshCount = length(VOLUME{1}.mesh);
catch
    currMeshCount = 0;
end

% load the mesh to the VOLUME struct
VOLUME{1} = meshLoad(VOLUME{1},'./'); %start in the current directory for now %TODO later give options?

try length(VOLUME{1}.mesh)
    
    if length(VOLUME{1}.mesh) > currMeshCount %a new mesh has been added
        
        % create a unique ID for the mesh based on a timestamp (clock)
        VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID = makeUniqueID;
        
        % send the newly loaded mesh to the viewer via the VOLUME
        mrMeshPySend('sendNewMeshData',VOLUME{1});
        
        handles = guidata(hObject);  % Update!
        currString = get(handles.popupmenu_Meshes,'string')
        
        if strcmp(currString,'None')
            newstring = char(['mesh-',VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID]);
        else
            newstring = char(currString,['mesh-',VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID]);
        end
        %disp 'here1'
        %VOLUME{1}.meshNum3d
        set(handles.popupmenu_Meshes,'value',VOLUME{1}.meshNum3d) ;
        set(handles.popupmenu_Meshes,'string',newstring);
        %disp 'here2'
    else % no new mesh added
        disp('User cancelled mesh load or there was an error loading ...');
    end
    
    
catch % no new mesh added
    disp('User cancelled mesh load or there was an error loading ...');
end



% --- Executes on selection change in popupmenu_Meshes.
function popupmenu_Meshes_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Meshes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Meshes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Meshes

mrGlobals;

% % %assignin('base','hObj',hObject)
% % %contents = cellstr(get(hObject,'String'))
% % %meshNum = contents{get(hObject,'Value')}

meshNum = hObject.Value; %should be the index

%%%meshNum = meshNum(5:end); %TODO improve
VOLUME{1}.meshNum3d = meshNum;


% --- Executes during object creation, after setting all properties.
function popupmenu_Meshes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Meshes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_getROI.
function pushbutton_getROI_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_getROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mrGlobals;

mrMeshPySend('checkMeshROI',VOLUME{1});


% --- Executes on button press in pushbutton_smooth.
function pushbutton_smooth_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_smooth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mrGlobals;

handles = guidata(hObject);  % Update!
relax = get(handles.edit_relaxationFactor,'String')
iterations = get(handles.edit_iterations,'String')

relax = str2num(relax);
iterations = str2num(iterations);

%assignin('base','iterations',iterations);
%assignin('base','relax',relax);

currMeshID = VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID;

%disp('here1')

% send (with VOLUME also)
mrMeshPySend('smoothMesh',{currMeshID,iterations,relax,VOLUME{1}});


function edit_relaxationFactor_Callback(hObject, eventdata, handles)
% hObject    handle to edit_relaxationFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_relaxationFactor as text
%        str2double(get(hObject,'String')) returns contents of edit_relaxationFactor as a double


% --- Executes during object creation, after setting all properties.
function edit_relaxationFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_relaxationFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_iterations_Callback(hObject, eventdata, handles)
% hObject    handle to edit_iterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_iterations as text
%        str2double(get(hObject,'String')) returns contents of edit_iterations as a double


% --- Executes during object creation, after setting all properties.
function edit_iterations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_iterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_buildMesh.
function pushbutton_buildMesh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_buildMesh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mrGlobals;
handles = guidata(hObject)
set( findall(handles.uipanel1, '-property', 'Enable'), 'Enable', 'off')

%try
    % get user option or left or right
    [s,v] = listdlg('PromptString','Select hemisphere:',...
        'SelectionMode','single',...
        'ListString',{'left','right'});
    
    if s == 1
        hemi = 'left';
    elseif s == 2
        hemi = 'right';
    else
        disp('error selecting mesh');
        return
    end
    
    % build the mesh
    VOLUME{1} = meshBuild_mrMeshPy(VOLUME{1}, hemi);
        
    % ask if we would like to load to mrMeshPy?
    
    % Include the desired Default answer
    options.Interpreter = 'tex';
    options.Default = 'Yes';
    % Use the TeX interpreter in the question
    qstring = 'Would you like to load the mesh to mrMeshPy?';
    loadNow = questdlg(qstring,'Mesh ready .. load?',...
        'Yes','No',options)
    
    if strcmp(loadNow,'No')
        return
    else
        %assume yes
        
        % create a unique ID for the mesh based on a timestamp (clock)
        VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID = makeUniqueID;
        
        % send the newly loaded mesh to the viewer
        mrMeshPySend('sendNewMeshData',VOLUME{1});
        
        handles = guidata(hObject);  % Update!
        currString = get(handles.popupmenu_Meshes,'string')
        
        if strcmp(currString,'None')
            newstring = char(['mesh-',VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID]);
        else
            newstring = char(currString,['mesh-',VOLUME{1}.mesh{VOLUME{1}.meshNum3d}.mrMeshPyID]);
        end
        
        set(handles.popupmenu_Meshes,'value',VOLUME{1}.meshNum3d) ;
        set(handles.popupmenu_Meshes,'string',newstring);
    end
    
%catch
%    disp 'error in build mesh routine';
%end

set( findall(handles.uipanel1, '-property', 'Enable'), 'Enable', 'On')







