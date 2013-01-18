function varargout = mrMessageBox(varargin)
% MRMESSAGEBOX M-file for mrMessageBox.fig
%      MRMESSAGEBOX, by itself, creates a new MRMESSAGEBOX or raises the existing
%      singleton*.
%
%      H = MRMESSAGEBOX returns the handle to a new MRMESSAGEBOX or the handle to
%      the existing singleton*.
%
%      MRMESSAGEBOX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MRMESSAGEBOX.M with the given input arguments.
%
%      MRMESSAGEBOX('Property','Value',...) creates a new MRMESSAGEBOX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mrMessageBox_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mrMessageBox_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mrMessageBox

% Last Modified by GUIDE v2.5 25-Mar-2002 12:19:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mrMessageBox_OpeningFcn, ...
                   'gui_OutputFcn',  @mrMessageBox_OutputFcn, ...
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


% --- Executes just before mrMessageBox is made visible.
function mrMessageBox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mrMessageBox (see VARARGIN)

% Choose default command line output for mrMessageBox
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mrMessageBox wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mrMessageBox_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function setMessage(hObject,eventdata,handles,str)
%
% Author; ImagEval
% Purpose:
%

set(handles.txtMessage,'String',str,'FontName','Comic Sans','FontWeight','Bold');

return;
