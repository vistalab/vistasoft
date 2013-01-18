function varargout = mrmViewer(varargin)
% MRMVIEWER M-file for mrmViewer.fig
%      MRMVIEWER, by itself, creates a new MRMVIEWER or raises the existing
%      singleton*.
%
%      H = MRMVIEWER returns the handle to a new MRMVIEWER or the handle to
%      the existing singleton*.
%
%      MRMVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MRMVIEWER.M with the given input arguments.
%
%      MRMVIEWER('Property','Value',...) creates a new MRMVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mrmViewer_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mrmViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mrmViewer

% Last Modified by GUIDE v2.5 13-Jul-2011 13:55:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mrmViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @mrmViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
return;


% --- Executes just before mrmViewer is made visible.
function mrmViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mrmViewer (see VARARGIN)

% Choose default command line output for mrmViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'Position',[0.8706    0.8308    0.1263    0.1250]);

% UIWAIT makes mrmViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);
return;


% --- Outputs from this function are returned to the command line.
function varargout = mrmViewer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
return;

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuLoad_Callback(hObject, eventdata, handles)
%
% Load a mesh file saved by mrVista/mrTools
%

uData = get(hObject,'userdata');

% It would be best to be able to read the list of currently open windows
% and assign a number based on that.
if ~checkfields(uData,'windowID'), 
    nextWindow = 500; 
    uData.windowID = nextWindow;
else 
    nextWindow = max(uData.windowID(:))+1; 
    uData.windowID(end+1) = nextWindow;
end

% Read a mesh starting in the Matlab working directory.
msh = mrmReadMeshFile(pwd);

if  isempty(msh), return; end

msh = meshSet(msh,'windowid',nextWindow);

% Display the mesh.  Turn off the origin lines.
msh = mrmInitMesh(msh);

mrmSet(msh,'hidecursor'); 
name = meshGet(msh,'name');
if isempty(name), [p,name] = fileparts(filename); end

mrmSet(msh,'title',name);
% Save the file information in the window object's user data.  We should be
% doing this for mrDiffusion, too.  And we should use this saved
% information when we ask about Editing windows.
set(hObject,'userdata',uData);

% Added in ability to open associated movie maker - RFB 06/2010
if (get(handles.OpenMovieMakerCheckbox, 'Value'))
    mrmMakeMovieGUI(nextWindow);
end

return;


% --------------------------------------------------------------------
function menuFileLoadMRD_Callback(hObject, eventdata, handles)
% Read a Matlab file containing a mrDiffusion mrMesh data set.  Then
% display the data.

% This should contain information about previously loaded data.  Here we
% store the new file information in uData.  --- Or we should ... not yet
% implemented.
uData = get(hObject,'userdata');

% Locate the file
persistent mrdPath;
persistent lastMshID;
curPath = pwd;

if(isempty(mrdPath) || isequal(mrdPath,0)), mrdPath = curPath; end
chdir(mrdPath);
[f, mrdPath] = uigetfile({'*.mat'}, 'Load MRD mesh...');
chdir(curPath);

if(isnumeric(f)), disp('Load Mesh (MRD) cancelled.'); return; end
fname = fullfile(mrdPath, f);


% Load the Mesh File.
d = load(fname);
msh = d.handles.mrMesh;
if isempty(lastMshID), lastMshID = msh.id; 
else
    if msh.id == lastMshID
        lastMshID = lastMshID + 1; 
        msh.id = lastMshID+1; 
    end
end

% Make sure the mrMesh server is running
if ~mrmCheckServer('localhost'), mrmStart(msh.id,msh.host); end
mrmSet(msh,'refresh');

% Create the window and insert the data
msh = dtiInitMrMeshWindow(msh);
dtiMrMeshAddROIs(d.handles,msh);
dtiMrMeshAddFGs(d.handles,msh);
dtiMrMeshAddImages(d.handles,msh,d.origin,d.xIm,d.yIm,d.zIm);

% Make sure the window number is part of the title.  This way we can change the
% title later if we by an Edt | Set Window Title pull down.  Probably we
% should keep track of all the loaded meshes and the window numbers.
[p,fname,e] = fileparts(f);
str = mrmSet(msh,'windowtitle',sprintf('%.0f %s',meshGet(msh,'id'),fname));

% Added in ability to open associated movie maker - RFB 06/2010
if (get(handles.OpenMovieMakerCheckbox, 'Value'))
    mrmMakeMovieGUI(msh.id);
end

return;

% --------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)
closereq;
return;

% --------------------------------------------------------------------
function menuQuit_Callback(hObject, eventdata, handles)
closereq;
return;

% --------------------------------------------------------------------
function menuEdit_Callback(hObject, eventdata, handles)

return;

% --------------------------------------------------------------------
function menuDelete_Callback(hObject, eventdata, handles)
return;


% --------------------------------------------------------------------
function menuHelp_Callback(hObject, eventdata, handles)
return;


% --------------------------------------------------------------------
function menuHelpGeneral_Callback(hObject, eventdata, handles)
% hObject    handle to menuHelpGeneral (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
helpMessage = 'Use mrmViewer to view Mesh Files.  Ordinarily these have been saved by mrVista''s 3D window viewer or mrDiffusion.';
hdl = mrMessage(helpMessage,'left',[0.7,0.85,0.15, 0.1]);

return

% --------------------------------------------------------------------
function menuHelpMovie_Callback(hObject, eventdata, handles)
% hObject    handle to menuHelpMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doc('mrmMakeMovieGUI');
return

% --- Executes on button press in btnLoad.
function btnLoad_Callback(hObject, eventdata, handles)
menuLoad_Callback(hObject, eventdata, handles)
return;

% --- Executes on button press in btnLoadMRD.
function btnLoadMRD_Callback(hObject, eventdata, handles)
menuFileLoadMRD_Callback(hObject, eventdata, handles)
return;

% --------------------------------------------------------------------
function menuOriginOff_Callback(hObject, eventdata, handles)
msh.host = 'localhost';
msh.id = whichMeshWindow;
msh.actor = 32;
mrmSet(msh,'hidecursor') 
return;

% --------------------------------------------------------------------
function id = whichMeshWindow
%
%  This should be a check on uData values or something.

prompt={'Enter mesh window'};
def={'1'};
dlgTitle='Select mesh window';
lineNo=1;
answer=inputdlg(prompt,dlgTitle,lineNo,def);

if isempty(answer), id = [];
else id = str2num(answer{1});
end

return;


% --------------------------------------------------------------------
function menuEditWindowTitle_Callback(hObject, eventdata, handles)
% hObject    handle to menuEditWindowTitle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msh.host = 'localhost';
msh.id = whichMeshWindow;
dlgTitle='mrmViewer Edit|Title';
prompt={'Enter window title'};
lineNo=1;
def = {'Title'};
answer=inputdlg(prompt,dlgTitle,lineNo,def);

if isempty(answer), disp('User canceled.'); return; 
else  mrmSet(msh,'title',answer{1}); end

return;


