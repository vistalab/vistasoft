function varargout = DICOMViewer(varargin)
% DICOMViewer M-file for DICOMViewer.fig
%      DICOMViewer, by itself, creates a new DICOMViewer or raises the existing
%      singleton*.
%
%      H = DICOMViewer returns the handle to a new DICOMViewer or the handle to
%      the existing singleton*.
%
%      DICOMViewer('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DICOMViewer.M with the given input arguments.
%
%      DICOMViewer('Property','Value',...) creates a new DICOMViewer or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DICOMViewer_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DICOMViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% HISTORY:
%  2003.??.?? written by Michael Wunder.
%  2004.01.27 RFD: fixed windows-centric path assumption by using
%  'fullfile'.
% 

% Edit the above text to modify the response to help DICOMFILES

% Last Modified by GUIDE v2.5 01-Dec-2003 09:43:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DICOMViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @DICOMViewer_OutputFcn, ...
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


% --- Executes just before DICOMFiles is made visible.
function DICOMViewer_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DICOMFiles
handles.output = hObject;
handles.hidden = [];
guidata(hObject, handles);
colormap gray(256)

% use push-button callback
if length(varargin) & ischar (varargin{1})
   handles.dfolder = varargin{1};
   SetFolder(handles);
   ListBox_Callback(hObject, eventdata, handles);
else
   newFolder_Callback(hObject, eventdata, handles)
end

% UIWAIT makes DICOMFiles wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = DICOMViewer_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in newFolder.
function newFolder_Callback(hObject, eventdata, handles)

P = fileparts(mfilename('fullpath'));
nfolder=uigetdir(P,'Select DICOM Directory');
if ~ischar(nfolder)
    disp('no valid Directory selected.')
    return;
end
handles.dfolder=nfolder;
guidata(hObject, handles);
SetFolder(handles);
ListBox_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetFolder (handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dfiles=dir(handles.dfolder);
dfiles=dfiles(3:end);                   % avoid . and ..
nfiles=length(dfiles);
if nfiles<1
    disp('no files availabel.')
    return;
end
set(handles.ListBox,'String',char(dfiles.name),'value',1);
s = [num2str(nfiles) ' files in: ' handles.dfolder];
set(handles.NofFiles,'String', s);
guidata(handles.figure1, handles);

% --- Executes during object creation, after setting all properties.
function ListBox_CreateFcn(hObject, eventdata, handles)

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on selection change in ListBox.
function ListBox_Callback(hObject, eventdata, handles)

fname = get(handles.ListBox,'String');
fname = fname(get(handles.ListBox,'value'),:);
try
   metadata = dicominfo(fullfile(handles.dfolder, fname));
catch
   disp ('apparently not a DICOM file');
   return
end
img      = dicomread(fullfile(handles.dfolder, fname));
imagesc(img);
axis off

ch = get(handles.HeaderList, 'value');
fields=char(fieldnames(metadata));
len = setdiff (1:size(fields,1), handles.hidden);
id=0;
for k=len,
    estr=eval(['metadata.' fields(k,:)]);
    if ischar(estr)
        str=[fields(k,:) ' : ' estr];
    elseif isnumeric(estr)
        str=[fields(k,:) ' : ' num2str(estr(1:min(3,end))')];
    else
        str=[fields(k,:) ' : ...'];
    end
    id = id+1;
    cstr{id}=sprintf('%3d %s',k,str);
end
set(handles.HeaderList,'Value',ch);
set(handles.HeaderList,'String',cstr);
guidata(hObject, handles);
return;

% --- Executes during object creation, after setting all properties.
function HeaderList_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on button press in cmdHide.
function cmdHide_Callback(hObject, eventdata, handles)
st = get (handles.HeaderList, 'string');
hide = get(handles.HeaderList, 'value');
if length(hide)==length(st)
   disp ('WARNING: at least one field must be shown');
   return
end
hidev=[];
for id=hide
   hidev = [hidev str2num(st{id}(1:3))];
end
handles.hidden = union (handles.hidden, hidev);
set(handles.HeaderList,'Value',1);
guidata (hObject, handles);
ListBox_Callback(hObject, eventdata, handles);

% --- Executes on button press in cmdShowAll.
function cmdShowAll_Callback(hObject, eventdata, handles)

handles.hidden = [];
guidata (hObject, handles);
ListBox_Callback(hObject, eventdata, handles);

