function varargout = ctrInit(varargin)
% CTRINIT M-file for ctrInit.fig
%      CTRINIT, by itself, creates a new CTRINIT or raises the existing
%      singleton*.
%
%      H = CTRINIT returns the handle to a new CTRINIT or the handle to
%      the existing singleton*.
%
%      CTRINIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CTRINIT.M with the given input arguments.
%
%      CTRINIT('Property','Value',...) creates a new CTRINIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ctrInit_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ctrInit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ctrInit

% Last Modified by GUIDE v2.5 17-Sep-2008 16:05:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ctrInit_OpeningFcn, ...
                   'gui_OutputFcn',  @ctrInit_OutputFcn, ...
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

return;


% --- Executes just before ctrInit is made visible.
function ctrInit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ctrInit (see VARARGIN)

% Choose default command line output for ctrInit
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ctrInit wait for user response (see UIRESUME)
% uiwait(handles.figure1);
btnTimeStamp_Callback(hObject, eventdata, handles);

menuEditRefresh_Callback(hObject, eventdata, handles)

return;

% --- Outputs from this function are returned to the command line.
function varargout = ctrInit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

return;

% --- Executes on button press in btnCreateContrackFiles.
function btnCreateContrackFiles_Callback(hObject, eventdata, handles)
% Button:  Generate Fibers

params = getParams(hObject);

% This does ALMOST EVERYTHING
% 1. Creates wmprob.nii.gz
% 2. Creates pdf.nii.gz
% 3. Create ROI mask.nii.gz
% 4. Create the ctrSampler_timestamp.txt file
params = ctrInitParamsFile(params);

% One last thing: make the ctrScript_timestamp.sh file
ctrScript(params);

return;

% --- Executes on button press in btnDT6file.
function btnDT6File_Callback(hObject, eventdata, handles)
% Button:  Browse for DT6 file
hndl = guihandles(hObject);
fullName = mrvSelectFile('r','*','DT6');
if isempty(fullName), return; end
set(hndl.editFilenameDti6,'String',fullName);
menuEditRefresh_Callback(gcbf);
return;

% --- Executes on button press in btnROI1file.
function btnROI1File_Callback(hObject, eventdata, handles)
% Button:  Browse for ROI1 file
hndl = guihandles(hObject);
startDir = fileparts(get(hndl.editFilenameDti6,'String'));
fullName = mrvSelectFile('r','*','ROI 1',startDir);
if isempty(fullName), return; end
set(hndl.editFilenameROI1,'String',fullName);
menuEditRefresh_Callback(gcbf);
return;

% --- Executes on button press in btnROI2file.
function btnROI2File_Callback(hObject, eventdata, handles)
% Button:  Browse for ROI1 file
hndl = guihandles(hObject);
startDir = fileparts(get(hndl.editFilenameROI1,'String'));
if(isempty(startDir))
    startDir = fileparts(get(hndl.editFilenameDti6,'String'));
end
fullName = mrvSelectFile('r','*','ROI 2',startDir);
if isempty(fullName), return; end
set(hndl.editFilenameROI2,'String',fullName);
menuEditRefresh_Callback(gcbf);
return;

function editFilenameDti6_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;

% --- Executes during object creation, after setting all properties.
function editFilenameDti6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editFilenameROI1_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;

% --- Executes during object creation, after setting all properties.
function editFilenameROI1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes during object creation, after setting all properties.
function editFilenameROI2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editFilenameROI2_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;

% --------------------------------------------------------------------
function menuEdit_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuFileLoad_Callback(hObject, eventdata, handles)
% File | Load params
ctr = ctrLoad;
setParams(hObject,ctr);
return;
% --------------------------------------------------------------------
function menuFileSave_Callback(hObject, eventdata, handles)
% File | Save params
params = getParams(hObject);
ctrInitParamsFile(params);
return;

% --------------------------------------------------------------------
function menuFileClose_Callback(hObject, eventdata, handles)
% File | Close
closereq;
return;

% --------------------------------------------------------------------
function menuFileSaveClose_Callback(hObject, eventdata, handles)
% File | Save and close
params = getParams(hObject);
ctrInitParamsFile(params);
closereq;
return;

% --------------------------------------------------------------------
function menuHelpVistaWiki_Callback(hObject, eventdata, handles)
% Help | Vista Wiki ConTrack
web('http://white.stanford.edu/newlm/index.php/DTI#ConTrack','-browser');
return;

function editDesiredSamples_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return

% --- Executes during object creation, after setting all properties.
function editDesiredSamples_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editMaxNodes_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;
% --- Executes during object creation, after setting all properties.
function editMaxNodes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editMinNodes_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;

% --- Executes during object creation, after setting all properties.
function editMinNodes_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editStepSize_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return;

% --- Executes during object creation, after setting all properties.
function editStepSize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --------------------------------------------------------------------
function menuHelp_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuEditClearFilenames_Callback(hObject, eventdata, handles)
% Edit | Clear file names

gd = guidata(hObject);

set(gd.editFilenameDti6,'String','');
set(gd.editFilenameROI1,'String','');
set(gd.editFilenameROI2,'String','');
set(gd.editWaypointFilename,'String','');

return;

% --------------------------------------------------------------------
function menuEditResetDefaultParameters_Callback(hObject, eventdata, handles)
disp('Todo: Reset default parameters');
return

% --- Executes on button press in checkboxROI1.
function checkboxROI1_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return

% --- Executes on button press in checkboxROI2.
function checkboxROI2_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return

% --- Executes on button press in checkboxPDDPDF.
function checkboxPDDPDF_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return

% --- Executes on button press in checkboxWMFile.
function checkboxWMFile_Callback(hObject, eventdata, handles)
menuEditRefresh_Callback(gcbf);
return

% --------------------------------------------------------------------
function menuEditFullParameters_Callback(hObject, eventdata, handles)
disp('ToDO:  Bring up window with full parameter list and store the list');

params = getParams(hObject);
[params]=ctrSetParamsDlg(hObject,params);
menuEditRefresh_Callback(gcbf);
%guidata(hObject);
return;

% --------------------------------------------------------------------
function menuEditRefresh_Callback(hObject, eventdata, handles)
% Edit | Refresh
% Updates changes to the information panel

gd = guidata(hObject);

% File name section - Show user computed file names
str = get(gd.editFilenameDti6,'String');
if isempty(str), return; end

% Otherwise, we fill in some of the fields: Subject directory
subjDir = fileparts(str);
if length(subjDir) > 30, str = subjDir((end-30):end); else str = subjDir; end
txt = sprintf('Subject''s DT6 dir: ... %s\n\n',str);

% Processed ROI file, derived from names and a time stamp. We should
% probably store the time stamp in the guidata of the window. Perhaps we
% update the time stamp whenever we change a file name?
[p,str1] = fileparts(get(gd.editFilenameROI1,'String'));
[p,str2] = fileparts(get(gd.editFilenameROI2,'String'));
tString = get(gd.txtTimeStamp,'String');
str = ctrFilename(str1,str2,tString,'roi');
txt = sprintf('%sROI mask: %s\n\n',txt,str);

% Attach the text to the window
set(gd.txtInfo,'String',txt);

return;

% --- Executes on button press in btnTimeStamp.
function btnTimeStamp_Callback(hObject, eventdata, handles)
% Time Stamp button

gd  = guidata(hObject);
str = datestr(now,30);
set(gd.txtTimeStamp,'String',str);
menuEditRefresh_Callback(hObject);

return;

%---------------
function params = getParams(hObject)
% Create the parameters structure that we send to ctInitParams

hndl = guidata(hObject);

% Figure out what the user selected and send it to the script that
% generates the fibers.
params.dt6File      = get(hndl.editFilenameDti6,'String');
params.roi1File     = get(hndl.editFilenameROI1,'String');
params.roi2File     = get(hndl.editFilenameROI2,'String');
params.dSamples     = str2double(get(hndl.editDesiredSamples','string'));
params.maxNodes     = str2double(get(hndl.editMaxNodes','string'));
params.minNodes     = str2double(get(hndl.editMinNodes','string'));
params.stepSize     = str2double(get(hndl.editStepSize','string'));
params.pddpdf       = get(hndl.checkboxPDDPDF,'Value');
params.wm           = get(hndl.checkboxWMFile,'Value');
params.roi1Seed     = get(hndl.checkboxROI1,'Value');
params.roi2Seed     = get(hndl.checkboxROI2,'Value');
params.timeStamp    = get(hndl.txtTimeStamp,'String');

return;

%--------------

function setParams(hObject,ctr)
% Set the interface based on the contrack parameters structure

if notDefined('ctr'), error('contrack structure required.'); end

hndl = guidata(hObject);

%Copy the contrack structure to the interface
%The ctr structure could have more stuff, like this file information 

% set(hndl.editFilenameDti6,'String',params.dt6File);
% set(hndl.editFilenameROI1,'String',params.roi1File);
% set(hndl.editFilenameROI2,'String',params.roi2File);
% set(hndl.editWaypointFilename,'String',params.wayPointFile);

set(hndl.editDesiredSamples,'string',num2str(ctrGet(ctr,'desired_samples')));
set(hndl.editMaxNodes,'string',num2str(ctrGet(ctr,'max_nodes')));
set(hndl.editMinNodes,'string',num2str(ctrGet(ctr,'min_nodes')));
set(hndl.editStepSize,'string',num2str(ctrGet(ctr,'step_size')));
set(hndl.checkboxWMFile,'Value',1);
set(hndl.checkboxROI1,'Value',1);
set(hndl.checkboxROI2,'Value',1);
set(hndl.txtTimeStamp,'String',datestr(now,30));

menuEditRefresh_Callback(hObject);

return;


% --- Executes on button press in btnFiberGeneration.
function btnFiberGeneration_Callback(hObject, eventdata, handles)
% hObject    handle to btnFiberGeneration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


