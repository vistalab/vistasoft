function varargout = rmLoadInterface(varargin)
% rmLoadInterface - M-file for rmLoadInterface.fig
%      RMLOADINTERFACE, by itself, creates a new RMLOADINTERFACE or raises the existing
%      singleton*.
%
%      H = RMLOADINTERFACE returns the handle to a new RMLOADINTERFACE or the handle to
%      the existing singleton*.
%
%      RMLOADINTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RMLOADINTERFACE.M with the given input arguments.
%
%      RMLOADINTERFACE('Property','Value',...) creates a new RMLOADINTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rmLoadInterface_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rmLoadInterface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rmLoadInterface

% Last Modified by GUIDE v2.5 03-Feb-2006 11:59:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rmLoadInterface_OpeningFcn, ...
                   'gui_OutputFcn',  @rmLoadInterface_OutputFcn, ...
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


% --- Executes just before rmLoadInterface is made visible.
function rmLoadInterface_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rmLoadInterface (see VARARGIN)

% Choose default menu params
set(handles.modelMenu,    'String',varargin{1});
set(handles.parameterMenu,'String',varargin{2});
set(handles.fieldMenu,    'String',varargin{3});

% default command line output
data.model      = get(handles.modelMenu(1),'Value');
data.parameter  = get(handles.parameterMenu(1),'Value');
data.field      = get(handles.fieldMenu(1),'Value');

% Choose default command line output for rmLoadInterface
handles.data   = data;
%handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rmLoadInterface wait for user response (see UIRESUME)
uiwait(handles.figure1);
return;

% --- Outputs from this function are returned to the command line.
function varargout = rmLoadInterface_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.data;

% quit
delete(handles.figure1);
return;


% --- Executes on selection change in modelMenu.
function modelMenu_Callback(hObject, eventdata, handles)
%contents           =  get(hObject,'String');
handles.data.model = get(hObject,'Value'); 
guidata(hObject,handles);
return;
function modelMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on selection change in parameterMenu.
function parameterMenu_Callback(hObject, eventdata, handles)
%contents           =  get(hObject,'String');
%handles.data.parameter = contents{get(hObject,'Value')}; 
handles.data.parameter = get(hObject,'Value');
% here we change the (default) field the parameter goes to
contents  =  get(hObject,'String');
switch contents{get(hObject,'Value')},
 case {'variance explained' 'max of all possible log10(p)s' 'coherence'},
  % this one usually goes to the coherence field
  handles.data.field = find(strcmp(get(handles.fieldMenu,'String'),'co'));
 case {'polar-angle'},
  % this one usually goes to the phase field
  handles.data.field = find(strcmp(get(handles.fieldMenu,'String'),'ph'));
 otherwise,
  % rest will typically go to the map field
  handles.data.field = find(strcmp(get(handles.fieldMenu,'String'),'map'));  
end;
% update in gui
set(handles.fieldMenu,'value',handles.data.field);
guidata(hObject,handles);
return;
function parameterMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


% --- Executes on selection change in fieldMenu.
function fieldMenu_Callback(hObject, eventdata, handles)
%contents           =  get(hObject,'String');
%handles.data.field = contents{get(hObject,'Value')}; 
handles.data.field = get(hObject,'Value'); 
guidata(hObject,handles);
return;
function fieldMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on button press in cancelbutton.
function cancelbutton_Callback(hObject, eventdata, handles)
% clear output
handles.data = [];
guidata(hObject,handles);
% now continue and finish
uiresume(handles.figure1);
return;



% --- Executes on button press in gobutton.
function gobutton_Callback(hObject, eventdata, handles)
% now continue and finish
uiresume(handles.figure1);
return;

