function varargout = setUnderlayFig(varargin)
% SETUNDERLAYFIG M-file for setUnderlayFig.fig
%      SETUNDERLAYFIG, by itself, creates a new SETUNDERLAYFIG or raises the existing
%      singleton*.
%
%      H = SETUNDERLAYFIG returns the handle to a new SETUNDERLAYFIG or the handle to
%      the existing singleton*.
%
%      SETUNDERLAYFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETUNDERLAYFIG.M with the given input arguments.
%
%      SETUNDERLAYFIG('Property','Value',...) creates a new SETUNDERLAYFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before setUnderlayFig_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to setUnderlayFig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help setUnderlayFig

% Last Modified by GUIDE v2.5 10-Aug-2004 12:54:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @setUnderlayFig_OpeningFcn, ...
                   'gui_OutputFcn',  @setUnderlayFig_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before setUnderlayFig is made visible.
function setUnderlayFig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to setUnderlayFig (see VARARGIN)

% Choose default command line output for setUnderlayFig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes setUnderlayFig wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = setUnderlayFig_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function UnderlayListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UnderlayListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in UnderlayListbox.
function UnderlayListbox_Callback(hObject, eventdata, handles)
% hObject    handle to UnderlayListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in SaveButton.
function SaveButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global underlay;
mrGlobals; 

hunderlay = findobj('Parent',gcf,'Tag','UnderlayListbox');
whichUnderlay = get(hunderlay,'Value');
viewName = get(gcf,'UserData');
% set the default anat variable as the selected underlay
anat = underlay(whichUnderlay).data;
% set as anat field for this view
cmd = sprintf('%s.anat = anat;',viewName);
eval(cmd);
% save the underlay data in anat.mat
anatFile = fullfile(HOMEDIR,'Inplane','anat.mat');
save(anatFile,'anat','underlay','-append');
fprintf('Updated anat.mat with underlay data. Updated default.\n');
% close the fig
close(gcf);
% % refresh the view in the workspace
% if ~isequal(underlay(whichUnderlay).name,'T1 Anatomicals')
%     eval(sprintf('setAnatClip(%s,[0 1]);',viewName));
% end
eval(sprintf('refreshScreen(%s);',viewName));
return


% --- Executes on button press in UseButton.
function UseButton_Callback(hObject, eventdata, handles)
% hObject    handle to UseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save the underlay data in anat.mat
global underlay;
mrGlobals;
hunderlay = findobj('Parent',gcf,'Tag','UnderlayListbox');
whichUnderlay = get(hunderlay,'Value');
viewName = get(gcf,'UserData');
% set as anat field for this view
cmd = sprintf('%s.anat = underlay(%i).data;',viewName,whichUnderlay);
eval(cmd);
% save the underlay data in anat.mat
anatFile = fullfile(HOMEDIR,'Inplane','anat.mat');
save(anatFile,'underlay','-append');
fprintf('Updated anat.mat with underlay data.\n');
% close the fig
close(gcf);
% refresh the view in the workspace
% if ~isequal(underlay(whichUnderlay).name,'T1 Anatomicals')
%     eval(sprintf('setAnatClip(%s,[0 1]);',viewName));
% end
eval(sprintf('refreshScreen(%s);',viewName));
return


% --- Executes on button press in InterpInplaneButton.
function InterpInplaneButton_Callback(hObject, eventdata, handles)
% hObject    handle to InterpInplaneButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global underlay;
mrGlobals;

h = msgbox('Loading alignment info...');

interp = interpInplanes;

% save the underlay data in anat.mat
anatFile = fullfile(HOMEDIR,'Inplane','anat.mat');
save(anatFile,'underlay','-append');
fprintf('Updated anat.mat with underlay data.\n');

close(h);

% add as a new possibility to the underlays list
num = length(underlay) + 1;
underlay(num).name = 'Interpolated Inplanes';
underlay(num).data = interp;

% update the listbox of available underlays
for i = 1:length(underlay)
    unames{i} = underlay(i).name;
end
hunderlay = findobj('Parent',gcf,'Tag','UnderlayListbox');
set(hunderlay,'String',unames);

return


% --- Executes during object creation, after setting all properties.
function ScansEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScansEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function ScansEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ScansEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScansEdit as text
%        str2double(get(hObject,'String')) returns contents of ScansEdit as a double


% --- Executes on button press in LoadTSeriesButton.
function LoadTSeriesButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadTSeriesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global underlay;
mrGlobals;

hdt = findobj('Parent',gcf,'Tag','DataTypePopup');
dt = get(hdt,'Value');
hscans = findobj('Parent',gcf,'Tag','ScansEdit');
scans = str2num(get(hscans,'String'));

cmd = sprintf('vw = %s;',get(gcf,'UserData'));
eval(cmd);

% view = viewSet(view,'curdt',dt);
vw.curDataType = dt;

%%%%% ALT STRATEGY: go through the mean maps;
% since the caclulation of mean is linear,
% averaging several mean maps across several
% scans is the same as doing it from scractch.
meanMapPath = fullfile(dataDir(vw),'meanMap.mat');
if ~exist(meanMapPath,'file');
    computeMeanMap(vw,scans);
end

load(meanMapPath);

% check maps exist for each scan
reload = 0;
for s = scans
    if isempty(map{s})
        computeMeanMap(vw,s);
        reload = 1;
    end
end
% redundant sometimes, but reload
if reload==1
    load(meanMapPath);
end

fprintf(' done.\nResizing to viewSize...');

% rescale, resize it to the view's sliceDims
anatSize = viewGet(vw,'Size');
funcSize = dataSize(vw,scans(1));
nFrames = numFrames(vw,scans(1));
for slice = 1:numSlices(vw)
    if length(scans) > 1
        % take avg across scans
        for s = 1:length(scans)
            im(:,:,s) = map{scans(s)}(:,:,slice);
        end
        im = mean(im,3);
    else
        im = map{scans(1)}(:,:,slice);
    end
    im = rescale2(im,[],[0,255]);
    im = uint8(im);
    im = reshape(im,funcSize(1:2));
    anat(:,:,slice) = imresize(im,anatSize(1:2));
end
fprintf(' done.\n');

% add as a new possibility to the underlays list
num = length(underlay) + 1;
dtname = dataTYPES(dt).name;
underlay(num).name = sprintf('Mean tSeries %s scans %s',dtname,num2str(scans));
underlay(num).data = histoThresh(anat);

% save the underlay data in anat.mat
anatFile = fullfile(HOMEDIR,'Inplane','anat.mat');
save(anatFile,'underlay','-append');
fprintf('Updated anat.mat with underlay data.\n');

% update the listbox of available underlays
for i = 1:length(underlay)
    unames{i} = underlay(i).name;
end
hunderlay = findobj('Parent',gcf,'Tag','UnderlayListbox');
set(hunderlay,'String',unames);

return



