function varargout = atlasfitGUI(varargin)
% ATLASFITGUI M-file for atlasfitGUI.fig
% 
%      written by Jens Heyder, SAFIR-Group 2006
%
%      ATLASFITGUI, by itself, creates a new ATLASFITGUI or raises the existing
%      singleton*.
%
%      H = ATLASFITGUI returns the handle to a new ATLASFITGUI or the handle to
%      the existing singleton*.
%      
%      ATLASFITGUI(images) initializes the ATLASFITGUI with the images given by the
%      structure images.
%      For the format of the images structure refer to the function
%      initFromArgument(hObject,handles,images) in atlasfitGUI.m
%
%      *See ATLASFITGUI Options on GUIDE's Tools menu.  Choose "ATLASFITGUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 25-Nov-2006 12:11:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @atlasfitGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @atlasfitGUI_OutputFcn, ...
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


% --- Executes just before atlasfitGUI is made visible.
function atlasfitGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to atlasfitGUI (see VARARGIN)

% Choose default command line output for atlasfitGUI
handles.output = hObject;

angleData_CreateFcn(hObject, eventdata, handles)

% UIWAIT makes atlasfitGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%%% initialize
% loads the default-preferences stored in the file defaults.mat
handles=loadDefaults(hObject,handles);

if isempty(varargin)
% if no argument to ATLASFITGUI is given, data is loaded from
% the file specified by filename in defaults.mat
handles=initFromFile(hObject,handles);
else
% initializes ATLASFITGUI with images structure given as first argument
% like ATLASFITGUI(images)
handles=initFromArgument(hObject,handles,varargin{1});
end

% Update handles structure
guidata(hObject, handles);

% calculates masks from given parameters and updates ATLASFITGUI
handles=displayImages(hObject,handles);

% --- Outputs from this function are returned to the command line.
function varargout = atlasfitGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function popMask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popMask.
function popMask_Callback(hObject, eventdata, handles)
% hObject    handle to popMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update mask parameter and display
handles.useMask=get(hObject,'Value');
handles=displayImages(hObject,handles);

% Update handles structure
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.filename=get(hObject,'String')
handles=initFromFile(hObject,handles)
handles=displayImages(hObject,handles)
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popResolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popResolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popResolution.
function popResolution_Callback(hObject, eventdata, handles)
% hObject    handle to popResolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates resolution parameter
% maxLevel is element of {6,7,8} resulting in images of sizes
% {64x64,128x128,256x256}
handles.maxLevel=get(hObject,'Value')+5;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popInterpolationMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popInterpolationMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popInterpolationMode.
function popInterpolationMode_Callback(hObject, eventdata, handles)
% hObject    handle to popInterpolationMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates interpolation mode (1 = linear, 2 = linear-periodic)
handles.ipMode=get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbuttonStart.
function pushbuttonStart_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);


switch handles.ipMode
    case 1
    interpolationMode='linear';
    case 2
    interpolationMode='linear-periodic';
    otherwise
        % this should never happen
        error('invalid interpolation mode selected')
end
switch handles.regMode
    case 1
        regularizationMode='diffusive';
    case 2
        regularizationMode='elastic';
    otherwise
        % this should never happen
        error('invalid regularizer selected')
end

% prepare data for SAFIR image registration framework
RD1 = handles.M1;
RD2 = handles.M2;
TD1 = handles.A1;
TD2 = handles.A2;
WD1 = handles.W1;
WD2 = handles.W2;
areasImg = handles.areasImg;
alpha = handles.w3;
beta = handles.w4;
maxLevel = handles.maxLevel;
doParametric = handles.doParametric;
maxIterNPIR = handles.maxIter;
tol = handles.tol;

save('safirData.mat','interpolationMode','regularizationMode',...
    'RD1','RD2','TD1','TD2','WD1','WD2','areasImg','alpha',...
    'beta','maxLevel','doParametric','maxIterNPIR','tol');

% run registration algorithm with selected parameters
% yOpt is the resulting transformation field on a staggered-grid
% for use in interpolation-routines (see there) first transform to
% cell-centered grid by yCentered=stg2center(yOpt,m,'Py'), where
% m is the grid resolution [2^maxLevel 2^maxLevel]
% Example: yCentered=stg2center(yOpt,[128 128],'Py')
tic
yOpt=runMLIR;
fprintf('runMLIR time: %s\n.', secs2text(toc))

yOpt_inv = inverse_yOpt(yOpt);

% store result in safirResult.mat
% feel free to add a ATLASFITGUI-element to change this in the ATLASFITGUI
% save('safirResult.mat','yOpt');
save('safirResult.mat','yOpt');

% visualizes the result in a few figures
showResults(yOpt,'safirData.mat');
% showResults2(yOpt,yOpt_inv,'safirData.mat');

% --- Executes during object creation, after setting all properties.
function popRegMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popRegMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popRegMode.
function popRegMode_Callback(hObject, eventdata, handles)
% hObject    handle to popRegMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the regularizer mode (1 = diffusive, 2 = elastic)
handles.regMode=get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editAngleWeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAngleWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function editAngleWeight_Callback(hObject, eventdata, handles)
% hObject    handle to editAngleWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the weighting parameter for the angle data
% increasing w2 will result in a higher influence of the angle atlas-data
% difference to the objective function.
% setting w2 to zero will result in a single eccentricity matching (if
% w1>0)
handles.w2=str2double(get(hObject,'String'));
handles=displayImages(hObject,handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editSmoother_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSmoother (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function editSmoother_Callback(hObject, eventdata, handles)
% hObject    handle to editSmoother (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the weighting parameter (alpha) for the smoother term
% high = smooth, low = flexible
handles.w3=str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editVolume_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVolume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function editVolume_Callback(hObject, eventdata, handles)
% hObject    handle to editVolume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the weighting parameter (beta) for the volume preservation term
handles.w4=str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editTol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function editTol_Callback(hObject, eventdata, handles)
% hObject    handle to editTol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the tolerance value for the stopping criterion
% the lower the more accurate may be the results, but the more iterations
% will be made
handles.tol=str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushSave.
% saves the current parameters into the file defaults.mat
function pushSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tol=handles.tol;
maxIter=handles.maxIter;
ipMode=handles.ipMode;
regMode=handles.regMode;
minLevel=handles.minLevel;
maxLevel=handles.maxLevel;
w1=handles.w1;
w2=handles.w2;
w3=handles.w3;
w4=handles.w4;
filename=handles.filename;
useMask=handles.useMask;
doParametric=handles.doParametric;
save('defaults.mat','tol','maxIter','ipMode','regMode','minLevel','maxLevel','w1','w2','w3','w4','filename','useMask','doParametric');

% --- Executes during object creation, after setting all properties.
function angleData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angleData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on editing editIterations
function editIterations_Callback(hObject, eventdata, handles)
% hObject    handle to editIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates maximal number of iterations
handles.maxIter=str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editIterations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on editing editEccentricityWeight
function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates the weighting parameter for the eccentricity data
% increasing w1 will result in a higher influence of the eccentricity atlas-data
% difference to the objective function.
% setting w1 to zero will result in a single angle matching (if
% w2>0)
handles.w1=str2double(get(hObject,'String'));
handles=displayImages(hObject,handles);
% Update handles structure
guidata(hObject, handles);

 
% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% 
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% calculates the mask from the current parameters and displays the images
function handles=displayImages(hObject,handles)
axes(handles.angleData);
image(mergedImage(handles.M2,0,hsv,2*pi));axis off;
axes(handles.angleAtlas);
image(mergedImage(handles.A2,0,hsv,2*pi));axis off;
axes(handles.eccentricityData);
image(mergedImage(handles.M1,0,hsv,2*pi));axis off;
axes(handles.eccentricityAtlas);
image(mergedImage(handles.A1,0,hsv,2*pi));axis off;
axes(handles.coherenceMap1);
handles.W1=getMask(handles.W1orig,handles.A1,handles.areasImg,handles.useMask,handles.w1);
handles.W2=getMask(handles.W2orig,handles.A2,handles.areasImg,handles.useMask,handles.w2);
maxGrayValue=max(handles.w1,handles.w2);
image(mergedImage(handles.W2,0,1-gray,maxGrayValue));axis off;
axes(handles.coherenceMap2);
image(mergedImage(handles.W1,0,1-gray,maxGrayValue));axis off;
colormap(gray)
% Update handles structure
guidata(hObject, handles);

% if no argument is given to ATLASFITGUI, the data is loaded from the
% file specified by handles.filename
% also called when entering a new filename in editFilename
function handles=initFromFile(hObject,handles)
load(handles.filename)
handles.M1orig=M1;
handles.A1orig=A1;
handles.A2orig=A2;
handles.M2orig=M2;
handles.W1orig=W1;
handles.W2orig=W2; 
handles.M1=M1;
handles.A1=A1;
handles.A2=A2;
handles.M2=M2;
handles.W1=W1;
handles.W2=W2;
handles.areasImg=areasImg;
% Update handles structure
guidata(hObject, handles);

% initializes data with the image structure given as argument
% to ATLASFITGUI(images)
function handles=initFromArgument(hObject,handles,images)
%%%
%%%  change this code to fit to your needs
%%%
handles.M1orig=images.M1;
handles.A1orig=images.A1;
handles.A2orig=images.A2;
handles.M2orig=images.M2;
%%% the algorithm works with two different coherence maps
%%% if only one is available assign it to both W1 and W2
handles.W1orig=images.CO;
handles.W2orig=images.CO; 
handles.M1=images.M1;
handles.A1=images.A1;
handles.A2=images.A2;
handles.M2=images.M2;
%%% the algorithm works with two different coherence maps
%%% if only one is available assign it to both W1 and W2
handles.W1=images.CO;
handles.W2=images.CO;
handles.areasImg=images.areasImg;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushLoadDefaults.
function pushLoadDefaults_Callback(hObject, eventdata, handles)
% hObject    handle to pushLoadDefaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load default parameters as stored in the file defaults.mat
handles=loadDefaults(hObject,handles);
% update images
handles=displayImages(hObject,handles)
% Update handles structure
guidata(hObject, handles);

% load default parameters as stored in the file defaults.mat
function handles=loadDefaults(hObject,handles)
load defaults
% update ATLASFITGUI
set(handles.editSmoother,'String',num2str(w3));
set(handles.editVolume,'String',num2str(w4));
set(handles.editTol,'String',num2str(tol));
set(handles.editAngleWeight,'String',num2str(w1));
set(handles.editEccWeight,'String',num2str(w2));
set(handles.editFilename,'String',filename);
set(handles.popMask,'Value',useMask);
set(handles.popResolution,'Value',maxLevel-5);
set(handles.popInterpolationMode,'Value',ipMode);
set(handles.popRegMode,'Value',regMode);
set(handles.checkParametric,'Value',doParametric);
set(handles.editIterations,'String',num2str(maxIter));
% Update handles structure
handles.tol=tol;
handles.maxIter=maxIter;
handles.ipMode=ipMode;
handles.regMode=regMode;
handles.minLevel=minLevel;
handles.maxLevel=maxLevel;
handles.w1=w1;
handles.w2=w2;
handles.w3=w3;
handles.w4=w4;
handles.filename=filename;
handles.useMask=useMask;
handles.doParametric=doParametric;
% Update handles structure
guidata(hObject, handles);

% calculates mask image
function C=getMask(C,A,OV,useMask,w)
switch useMask
    case 1
        % coherence map is nulled where atlas is NaN or zero
        C(isnan(A))=0;
        C(A==0)=0;
    case 2
        % coherence map is nulled where no area of interest is specified
        C(isnan(OV))=0;
        C(OV==0)=0;
    otherwise
        % do nothing
end
% weight mask with weighting parameter (w1 or w2)
C=w*C;

%%% now external
% function rgb = mergedImage(img, overlay, cmap,maxGrayValue)
% % transform the image into RGB
% if isempty(overlay)
%     overlay=1;
% else
%     overlay=1-overlay;
% end
% img = ceil(img*size(cmap,1)/maxGrayValue);
% img(isnan(img)) = 1;
% img(img<1) = 1;
% img(img>size(cmap,1)) = size(cmap,1);
% cmap(1,:)=[1 1 1];
% rgb(:,:,1) = reshape(cmap(img,1),size(img));
% rgb(:,:,2) = reshape(cmap(img,2),size(img));
% rgb(:,:,3) = reshape(cmap(img,3),size(img));
% rgb(:,:,1) = rgb(:,:,1).*overlay;
% rgb(:,:,2) = rgb(:,:,2).*overlay;
% rgb(:,:,3) = rgb(:,:,3).*overlay;
% return;


% --- Executes on button press in checkParametric.
function checkParametric_Callback(hObject, eventdata, handles)
% hObject    handle to checkParametric (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates doParametric value
% 1 if rigid preregistration is wanted, 0 else
% 0 is recommended since pre-registration is already done by hand
handles.doParametric=get(hObject,'Value');

% use this if you like to overrule the ATLASFITGUI and prevent accidential use
% handles.doParametric=0;

% Update handles structure
guidata(hObject,handles)

