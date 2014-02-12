function varargout = rmEditStimParams(varargin)
% RMEDITSTIMPARAMS M-file for rmEditStimParams.fig
%      RMEDITSTIMPARAMS, by itself, creates a new RMEDITSTIMPARAMS or raises the existing
%      singleton*.
%
%      H = RMEDITSTIMPARAMS returns the handle to a new RMEDITSTIMPARAMS or the handle to
%      the existing singleton*.
%
%      RMEDITSTIMPARAMS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RMEDITSTIMPARAMS.M with the given input arguments.
%
%      RMEDITSTIMPARAMS('Property','Value',...) creates a new RMEDITSTIMPARAMS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rmEditStimParams_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rmEditStimParams_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% NOTE: You can also pass in a view structure as the first option:
%	rmEditStimParams(view, [options...]).   (ras, 01/09)
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rmEditStimParams

% Last Modified by GUIDE v2.5 16-Jan-2009 16:56:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rmEditStimParams_OpeningFcn, ...
                   'gui_OutputFcn',  @rmEditStimParams_OutputFcn, ...
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



% --- Executes just before rmEditStimParams is made visible.
function rmEditStimParams_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
%
% The key subroutines are:
% 1. rmEditStimParams_OpeningFcn (this one), which initializes values in
% the UI window
% 2. paramsToWindow: writes values from the parameters to the UI window
% 3. paramsFromWindow: writes values from the UI window to the parameters 
% 4. btnDone_Callback: writes values to parameters and then to vista view

% Choose default command line output for rmEditStimParams
handles.output = hObject;

%% get the view associated with these parameters
% (ras, 01/09, change from original): does not require that you're using a
% global VOLUME view. Should allow inplanes and hidden view structures. So,
% we allow you to pass the view in as the first argument, if it's a hidden
% view. Otherwise, finds the currently-selected view.
if ~isempty(varargin) & isstruct(varargin{1}) & isfield(varargin{1}, 'viewType')
	handles.vw = varargin{1};
else
	handles.vw = getCurView; % does not always get current view because it is order dependent
end

handles.dt = viewGet(handles.vw, 'currentdatatypestructure');

% Put values into the window.  We first check the stimulus
% parameterization for the currently loaded rm model.  
sParams = viewGet(handles.vw,'rmStimParams');

%  If there is no currently loaded model, we try to get the values from the
%  dataTYPES.
if isempty(sParams), sParams = dtGet(handles.dt, 'rmParams'); end

% We enforce the stimulus parameters organization. If no values were found
% in a current model or in the dataTYPES, we put in defaults. If values
% were found, we check that all necessary fields are present, and that
% unrecognized fields are removed. Older computed data such as 'images' and
% 'images_org' are deleted here.  We create the new images and related
% fields when we push the Done button.
sParams = rmCreateStim(handles.vw,sParams);

% Store the current stimulus parameters
handles.sParams = sParams;

% Initialize the scan slider
nScans = length(sParams);
setScanSlider(hObject, nScans);

% We need to a separate variable which will tell us the previous scan after
% the slider or edit box are changed clicked. Since we always initialize at
% scan 1, we set prior scan to 1 when we open the GUI.  
handles.priorScan = 1;  

% Identify the number of scans in the session
% set(handles.txtScanNum,'String',sprintf('Scan (%d)',nScans));
set(handles.editNumScans,'String',num2str(nScans));
guidata(hObject,handles);

% Refresh the UI using the fields in the stimulus parameters (sParams)
whichScan = 1; paramsToWindow(hObject,whichScan);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rmEditStimParams wait for user response (see UIRESUME)
% uiwait(handles.rmEditStimParams);
return;




% --- Outputs from this function are returned to the command line.
function varargout = rmEditStimParams_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
return;



% - Refresh the window using current values of stimulus parameters
function paramsToWindow(hObject,whichScan)
% Copy parameters from the view structure into the window

% Get current state of handles and stimulus parameters
handles = guidata(hObject);
thisParams = handles.sParams(whichScan);

% The popupClass must be set before calling this routine
refreshImagePopups(hObject,whichScan);

% Set the edit boxes
set(handles.editRadius,'String',num2str(thisParams.stimSize));
set(handles.editWidth,'String',num2str(thisParams.stimWidth));
set(handles.editStartPhase,'String',num2str(thisParams.stimStart));
set(handles.editCycles,'String',num2str(thisParams.nCycles)); 
set(handles.editMeanBlocks,'String',num2str(thisParams.nStimOnOff)); 
set(handles.editRep,'String',num2str(thisParams.nUniqueRep)); 
set(handles.editDetrend,'String',num2str(thisParams.nDCT)); 
set(handles.editRemoved,'String',num2str(thisParams.prescanDuration)); 
set(handles.editFrames,'String',num2str(thisParams.nFrames)); 
set(handles.editInterval,'String',num2str(thisParams.framePeriod)); 

% Check boxes
if ~checkfields(thisParams, 'fliprotate'), thisParams.fliprotate = [0 0 0]; end
flip = thisParams.fliprotate;
if length(flip) < 3, thisParams.fliprotate = padarray(flip,3-length(flip), 'post'); end
set(handles.cboxLR,'Value',thisParams.fliprotate(1));
set(handles.cboxUD,'Value',thisParams.fliprotate(2));
set(handles.cboxCCW,'Value',thisParams.fliprotate(3));

guidata(hObject,handles);

return;



% - Should be a separate utility function
function ii = getPopupValue(h,target)
% Given a handle to a popup, h, find the value

str = get(h,'String');
if ~iscell(str)  % Only one term
    if strcmpi(str,target), ii = 1; return; end
else
    for ii=1:length(str)
        if strcmpi(str{ii},target)
            return;
        end
    end
end

% Returns a safe value, but maybe it should be null?
ii = 1;

% if strcmpi(target,'none'), return;
% else fprintf('Target string [%s] not found\n',target);
% end

return;



% - Refresh the parameters using current values window objects
function paramsFromWindow(hObject,handles,whichScan)

% Current parameter values
thisParams = handles.sParams(whichScan);

% Update the values from the handles
% Copy parameters from the view structure into the window

% Spatial grouping
%
classes = get(handles.popupClass,'String');
thisParams.stimType = classes{get(handles.popupClass,'value')};

thisParams.stimSize = str2double(get(handles.editRadius,'String'));
thisParams.stimWidth = str2double(get(handles.editWidth,'String'));
thisParams.stimStart = str2double(get(handles.editStartPhase,'String'));

% An integer that defines in/out or cw/ccw
thisParams.stimDir = get(handles.popupDirection,'value') - 1;

thisParams.nCycles         = str2double(get(handles.editCycles,'String'));
thisParams.nStimOnOff      = str2double(get(handles.editMeanBlocks,'String')); 
thisParams.nUniqueRep      = str2double(get(handles.editRep,'String')); 
thisParams.nDCT            = str2double(get(handles.editDetrend,'String')); 

% Timing grouping
thisParams.prescanDuration = str2double(get(handles.editRemoved,'String')); 
thisParams.nFrames         = str2double(get(handles.editFrames,'String')); 
thisParams.framePeriod     = str2double(get(handles.editInterval,'String')); 

% Timing grouping
classes = get(handles.popupHRFModel,'String');
v = get(handles.popupHRFModel,'value');
thisParams.hrfType = classes{v};

% These are the Boynton and SPM HRF parameters and now an impulse HRF
% We are guessing that the hrfType field is used to choose between these
% two (now three) parameter sets
%
% hrfModelParams = {[1.68,3 ,2.05],[5.4,5.2 ,10.8,7.35,0.35], [1]};
% thisParams.hrfParams = hrfModelParams{v};

% Image Grouping
thisParams.fliprotate(1) = get(handles.cboxLR, 'Value'); 
thisParams.fliprotate(2) = get(handles.cboxUD, 'Value'); 
thisParams.fliprotate(3) = get(handles.cboxCCW,'Value'); 

classes = get(handles.popupImageFile,'String');
thisParams.imFile = classes;
if iscell(classes)
    thisParams.imFile = classes{get(handles.popupImageFile,'value')};
end

classes = get(handles.popupParamsFile,'String');
thisParams.paramsFile = classes;
if iscell(classes)
    thisParams.paramsFile = classes{get(handles.popupParamsFile,'value')};
end

classes = get(handles.popupImageFilter,'String');
thisParams.imFilter = classes;
if iscell(classes)
    thisParams.imFilter = classes{get(handles.popupImageFilter,'value')};
end

classes = get(handles.popupJitter,'String');
thisParams.jitterFile = classes;
if iscell(classes)
    thisParams.jitterFile = classes{get(handles.popupJitter,'value')};
end

% Put them back in the handles structure
handles.sParams(whichScan) = thisParams;

guidata(hObject,handles);

return;




% --- Executes on slider movement.
function sliderScan_Callback(hObject, eventdata, handles)
% We copy the data in the window to the handles.sParams entries.

% The user clicked on the slider and changed the scan to this new value
v = get(handles.sliderScan,'Value');

% make sure the value is an integer.
v = round(v);

% We update the edit box as well.
set(handles.editScan,'String',num2str(v));

% Before we clicked, we were operating on a prior scan.
% We take the parameters in the window and copy them into the parameter
% fields of that scan.
whichScan = handles.priorScan;
paramsFromWindow(hObject,handles,whichScan);
handles = guidata(hObject);

% Copy the parameters in thisParams from the new scan into the window
whichScan = v;
paramsToWindow(hObject,whichScan);

% The present becomes past
handles.priorScan=v;

guidata(hObject,handles);

return;

% --- Executes during object creation, after setting all properties.
function sliderScan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

return;


function editScan_Callback(hObject, eventdata, handles)
% When the edit box for scan number is changed

% Make sure we are in range
nScans = length(handles.sParams); 
v = str2double(get(handles.editScan,'string')); v = min(v,nScans); v = max(1,v);

% Adjust the slider
set(handles.sliderScan,'value',v);
set(handles.editScan,'string',num2str(v));

% Move the stimulus parameter data from the window
whichScan = handles.priorScan;
paramsFromWindow(hObject,handles,whichScan);
handles = guidata(hObject);

% Copy the new parameters to the window
whichScan = v;
paramsToWindow(hObject,whichScan);

% The present becomes past
handles.priorScan=v;

guidata(hObject,handles);
return;

% --- Executes during object creation, after setting all properties.
function editScan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on selection change in popupClass.
function popupClass_Callback(hObject, eventdata, handles)
% Must update the popups because we may choose stimFromScan clas

whichScan = get(handles.sliderScan,'value');
paramsFromWindow(hObject,handles,whichScan)
refreshImagePopups(hObject,whichScan);

return;

% --- Executes during object creation, after setting all properties.
function popupClass_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editRadius_Callback(hObject, eventdata, handles)
return;

% --- Executes during object creation, after setting all properties.
function editRadius_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editWidth_Callback(hObject, eventdata, handles)
return;

% --- Executes during object creation, after setting all properties.
function editWidth_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editStartPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editStartPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartPhase as text
%        str2double(get(hObject,'String')) returns contents of editStartPhase as a double

return;

% --- Executes during object creation, after setting all properties.
function editStartPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStartPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on selection change in popupDirection.
function popupDirection_Callback(hObject, eventdata, handles)
% hObject    handle to popupDirection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupDirection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupDirection
return;

% --- Executes during object creation, after setting all properties.
function popupDirection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupDirection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editCycles_Callback(hObject, eventdata, handles)
% hObject    handle to editCycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCycles as text
%        str2double(get(hObject,'String')) returns contents of editCycles as a double

return;
% --- Executes during object creation, after setting all properties.
function editCycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editMeanBlocks_Callback(hObject, eventdata, handles)
% hObject    handle to editMeanBlocks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMeanBlocks as text
%        str2double(get(hObject,'String')) returns contents of editMeanBlocks as a double
return;

% --- Executes during object creation, after setting all properties.
function editMeanBlocks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMeanBlocks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editRep_Callback(hObject, eventdata, handles)
% hObject    handle to editRep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRep as text
%        str2double(get(hObject,'String')) returns contents of editRep as a double
return;

% --- Executes during object creation, after setting all properties.
function editRep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editDetrend_Callback(hObject, eventdata, handles)
% hObject    handle to editDetrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDetrend as text
%        str2double(get(hObject,'String')) returns contents of editDetrend as a double
return;

% --- Executes during object creation, after setting all properties.
function editDetrend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDetrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;


function editRemoved_Callback(hObject, eventdata, handles)
% hObject    handle to editRemoved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRemoved as text
%        str2double(get(hObject,'String')) returns contents of editRemoved as a double
return;

% --- Executes during object creation, after setting all properties.
function editRemoved_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRemoved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on button press in cboxLR.
function cboxLR_Callback(hObject, eventdata, handles)
% hObject    handle to cboxLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cboxLR

return;

% --- Executes on selection change in popupImageFile.
function popupImageFile_Callback(hObject, eventdata, handles)
% hObject    handle to popupImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupImageFile contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupImageFile
return;

% --- Executes during object creation, after setting all properties.
function popupImageFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupImageFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on selection change in popupParamsFile.
function popupParamsFile_Callback(hObject, eventdata, handles)
% hObject    handle to popupParamsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupParamsFile contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupParamsFile
return;

% --- Executes during object creation, after setting all properties.
function popupParamsFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupParamsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on selection change in popupImageFilter.
function popupImageFilter_Callback(hObject, eventdata, handles)
% hObject    handle to popupImageFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupImageFilter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupImageFilter
return;

% --- Executes during object creation, after setting all properties.
function popupImageFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupImageFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on button press in cboxJitter.
function cboxJitter_Callback(hObject, eventdata, handles)
% hObject    handle to cboxJitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cboxJitter
return;
% --- Executes on selection change in popupHRFModel.
function popupHRFModel_Callback(hObject, eventdata, handles)
% hObject    handle to popupHRFModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupHRFModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupHRFModel
return;

% --- Executes during object creation, after setting all properties.
function popupHRFModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupHRFModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

function editFrames_Callback(hObject, eventdata, handles)
% hObject    handle to editFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFrames as text
%        str2double(get(hObject,'String')) returns contents of editFrames as a double
return;

% --- Executes during object creation, after setting all properties.
function editFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

return;

function editInterval_Callback(hObject, eventdata, handles)
% hObject    handle to editInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editInterval as text
%        str2double(get(hObject,'String')) returns contents of editInterval as a double
return;

% --- Executes during object creation, after setting all properties.
function editInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

% --- Executes on button press in btnCancel.
function btnCancel_Callback(hObject, eventdata, handles)
% hObject    handle to btnCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;
return;

% --- Executes on button press in btnDone.
function btnDone_Callback(hObject, eventdata, handles)
% User is finished.  Parameters from window to sParams
% Then we attach it do dataTypes and view.

whichScan  = get(handles.sliderScan,'Value');
paramsFromWindow(hObject,handles,whichScan);
handles = guidata(hObject);
paramsToVista(hObject,handles);

closereq

return;


% Copy the final set of stimulus parameters into the view and dataTypes
function paramsToVista(hObject,handles)
% Assign the new values to the view structure and dataType

% Make the current view variable (INPLANE, VOLUME) and dataTYPE accessible
mrGlobals;

handles = guidata(hObject);
handles = fileFullPath(handles);

handles.vw = viewSet(handles.vw, 'rmStimParams',handles.sParams);
                            
% save to data types if selected
% (see discussion in the change log for this file)
hSave = findobj('Tag', 'cbox_saveToDataTYPES');
hSaveValue = get(hSave, 'Value');
if iscell(hSaveValue) % hSaveValue is a cell struct.
    hSaveValue = hSaveValue{1};
end
if hSaveValue==1
	dtNum = viewGet(handles.vw,'dtNumber');
	handles.dt = dtSet(handles.dt,'retinotopyModelParams',handles.sParams);
	dataTYPES(dtNum).retinotopyModelParams = [];
    dataTYPES(dtNum) = handles.dt;
	fprintf('Updated stored stimulus parameters in dataTYPES.\n');
	saveSession;
end

% rmLoadParameters builds the stimuli (images) and computes various things
% and puts them into the view.
handles.vw = rmLoadParameters(handles.vw);

% if this is a global variable (INPLANE, VOLUME), update the global
% variable to match this view
if strncmp(handles.vw.name, 'INPL', 4) | strncmp(handles.vw.name, 'VOLU', 4)
	updateGlobal(handles.vw);
end

return

function h = fileFullPath(h)
% Convert the file names to full paths for this session.

nScans  = length(h.sParams);
homeDir = viewGet(h.vw,'homeDir');

for ii=1:nScans

    [p,n,e] = fileparts(h.sParams(ii).imFile);
    h.sParams(ii).imFile = fullfile(homeDir,'Stimuli',[n,e]);

    [p,n,e] = fileparts(h.sParams(ii).jitterFile);
    h.sParams(ii).jitterFile = fullfile(homeDir,'Stimuli',[n,e]);

    [p,n,e] = fileparts(h.sParams(ii).paramsFile);
    h.sParams(ii).paramsFile = fullfile(homeDir,'Stimuli',[n,e]);
end

return;

function setScanSlider(hObject, nScans)

handles = guidata(hObject);

% get the current scan number
scanNum = str2num(get(handles.editScan, 'String'));

% check that it is not greater than the number of scans being set
if scanNum > nScans, 
    error('Number of scans is less than the current scan number'); 
end


% The user clicked on the slider and changed the scan to this new value


if nScans > 1
    % Multiple scans - possibility of changing
    set(handles.sliderScan,'min',1);
    set(handles.sliderScan,'max',nScans);
    set(handles.sliderScan,'sliderStep',[1/(nScans-1) 1/(nScans-1)])
    set(handles.sliderScan,'Value',scanNum);
    set(handles.editScan,'String',num2str(scanNum));
    set(handles.sliderScan,'Visible','on');
    set(handles.editScan,'Visible','on');
else
    % Only one scan - so no possibility of changing
    set(handles.sliderScan,'min',1);
    set(handles.sliderScan,'max',1);
    set(handles.sliderScan,'Value',1);
    set(handles.sliderScan,'Visible','off');
    set(handles.editScan,'Visible','off');
end
guidata(hObject,handles);
return


% --- Executes on selection change in popupJitter.
function popupJitter_Callback(hObject, eventdata, handles)
% hObject    handle to popupJitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupJitter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupJitter
return;

% --- Executes during object creation, after setting all properties.
function popupJitter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupJitter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return;

%  --- Manage the image popup strings depending on context
function refreshImagePopups(hObject,whichScan)
% Fill fields when StimFromScan field in class
% Gray out the text when popups are irrelevant

handles = guidata(hObject);
thisParams = handles.sParams(whichScan);

% Set Class poup
switch thisParams.stimType
    case '8Bars',        v = 1;
    case 'Ring',         v = 2; 
    case 'RoughBars',    v = 3; 
    case 'Wedge',        v = 4;
    case 'StimFromScan', v = 5;
    case 'StimFromScan1D', v = 6;
    otherwise,           
        warndlg('Unknown stimulus type')
        v = 1;
end
set(handles.popupClass,'value',v);

% Set stimulus direction popup
switch thisParams.stimDir
    case 0,  v = 1;
    case 1,  v = 2; 
    otherwise,           
        warndlg('Unknown direction')
        v = 1;
end
set(handles.popupDirection,'value',v);

% HRF type
switch thisParams.hrfType
    case 'one gamma (Boynton style)', v = 1;
    case 'two gammas (SPM style)',    v = 2; 
    case 'impulse',                   v = 3; 
    otherwise,           
        warndlg('Unknown HRF model %s',thisParams.hrfType)
        v = 1;
end
set(handles.popupHRFModel,'value',v);

% Define the Stimuli directory for finding local files
sDir = fullfile(viewGet(handles.vw,'homeDir'),'Stimuli');

% Populate the pulldown strings
switch lower(thisParams.stimType)
    case {'stimfromscan','stimfromscan1d'}
        grayEditText(handles,whichScan);  % Stim from scan
        
        % If stimfromscan, we populate with files in the Stimuli
        % directory.
        
        if exist(sDir,'dir')
            % Image pulldown
            f = dir(fullfile(sDir,'*image*.mat'));
            str = cell(length(f),1);
            if ~isempty(f)
                for ii=1:length(f)
                    str{ii} = f(ii).name;
                end
                set(handles.popupImageFile,'String',str);
            end
            set(handles.txtImgFile,'foregroundcolor',[0 0 0]);
            
            % Image pulldown
            f = dir(fullfile(sDir,'*params*.mat'));
            str = cell(length(f),1);
            if ~isempty(f)
                for ii=1:length(f)
                    str{ii} = f(ii).name;
                end
                set(handles.popupParamsFile,'String',str);
            end
            set(handles.txtPFile,'foregroundcolor',[0 0 0]);
            
            % Filter definitions
            d = fullfile(mrvRootPath,'Analysis',...
                'retinotopyModel',...
                'FilterDefinitions','*.m');
            f = dir(d);
            str = cell(length(f)+1,1);
            str{1} = 'none';
            for ii=1:length(f)
                s = findstr(f(ii).name,'_');
                [p,str{ii+1},e] = fileparts(f(ii).name((s+1):end));
            end
            set(handles.popupImageFilter,'String',str);
            set(handles.txtIFilter,'foregroundcolor',[0 0 0]);
        end
        
    otherwise
        grayEditText(handles,whichScan);  % Not stim from scan
        
        % For most cases, these are not options so we gray them out
        set(handles.popupImageFile,'String','none');
        set(handles.popupImageFile,'Value',1);
        set(handles.popupParamsFile,'String','none');
        set(handles.popupParamsFile,'Value',1);
        set(handles.popupImageFilter,'String','none');
        set(handles.popupImageFilter,'Value',1);
        
        
end

% Populate the pulldown Jitter files
f = dir(fullfile(sDir,'*jitter*.mat'));
str = cell(length(f)+1,1); str{1} = 'none';
if ~isempty(f)
    for ii=1:length(f)
        str{ii+1} = f(ii).name;
    end
end
set(handles.popupJitter,'String',str);

% We set the pulldown values
bName = mrvFileNameExt(thisParams.imFile);
v = getPopupValue(handles.popupImageFile,bName);
set(handles.popupImageFile,'Value',v);

bName = mrvFileNameExt(thisParams.paramsFile);
v = getPopupValue(handles.popupParamsFile,bName);
set(handles.popupParamsFile,'Value',v);

bName = mrvFileNameExt(thisParams.imFilter);
v = getPopupValue(handles.popupImageFilter,bName);
set(handles.popupImageFilter,'Value',v);

% jitter file popup
if ~checkfields(thisParams,'jitterFile'), return;
else
    bName = mrvFileNameExt(thisParams.jitterFile);
    v = getPopupValue(handles.popupJitter,bName);
    set(handles.popupJitter,'Value',v);
end

guidata(hObject,handles);

return;

% Gray out irrelevant text edit boxes
function grayEditText(handles,whichScan)

thisParams = handles.sParams(whichScan);
switch lower(thisParams.stimType)
    case {'stimfromscan','stimfromscan1d'}
        val1 = [.5 .5 .5]; val2 = [ 0 0 0];
    otherwise
        val1 = [ 0 0 0]; val2 = [.5 .5 .5];
end

set(handles.txtImgFile,'foregroundcolor', val2);
set(handles.txtPFile,'foregroundcolor',val2);
set(handles.txtIFilter,'foregroundcolor',val2);

set(handles.txtCycles,'foregroundcolor',val1);
set(handles.txtDirection,'foregroundcolor',val1);
set(handles.txtFrames,'foregroundcolor',val1);
set(handles.txtFrameInt,'foregroundcolor',val1);
set(handles.txtMeanLumBlk,'foregroundcolor',val1);
set(handles.txtRemoved,'foregroundcolor',val1);
set(handles.txtReps,'foregroundcolor',val1);
set(handles.txtPhase,'foregroundcolor',val1);
set(handles.txtWidth,'foregroundcolor',val1);

return;

% --- Executes on button press in cboxUD.
function cboxUD_Callback(hObject, eventdata, handles)
% hObject    handle to cboxUD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cboxUD
return;

% --- Executes on button press in cboxCCW.
function cboxCCW_Callback(hObject, eventdata, handles)
% hObject    handle to cboxCCW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cboxCCW
return;



function editNumScans_Callback(hObject, eventdata, handles)
% hObject    handle to editNumScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumScans as text
%        str2double(get(hObject,'String')) returns contents of editNumScans as a double

nScans = str2double(get(hObject,'String'));
n = length(handles.sParams);
setScanSlider(hObject, nScans)

if     nScans > n, handles.sParams(n+1:nScans) = handles.sParams(n);
elseif nScans < n, handles.sParams(nScans+1:n) = [];
end

guidata(hObject,handles);

return

% --- Executes during object creation, after setting all properties.
function editNumScans_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return
